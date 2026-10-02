import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';

import '../data/data_sources/firestore_payment_data_source.dart';
import '../data/data_sources/payment_data_source.dart';
import '../data/models/payment_record.dart';
import '../data/repositories/payment_repository.dart';

typedef PaymentUserIdResolver = String? Function();

class PaymentService {
  PaymentService({
    required PaymentRepository repository,
    required PaymentUserIdResolver currentUserId,
  })  : _repository = repository,
        _currentUserId = currentUserId;

  factory PaymentService.forCurrentFirebaseApp() =>
      PaymentService.forFirebaseApp(app: Firebase.app());

  factory PaymentService.forFirebaseApp({required FirebaseApp app}) {
    // instanceFor keeps payment infrastructure injectable and independent
    // from the legacy UtangRepository's FirebaseFirestore.instance.
    final firestore = FirebaseFirestore.instanceFor(app: app);
    final auth = firebase_auth.FirebaseAuth.instanceFor(app: app);

    return PaymentService(
      repository: PaymentRepository(
        FirestorePaymentDataSource(firestore: firestore),
      ),
      currentUserId: () => auth.currentUser?.uid,
    );
  }

  final PaymentRepository _repository;
  final PaymentUserIdResolver _currentUserId;
  final Map<String, Future<PaymentRecord>> _inFlight = {};

  Future<PaymentRecord> recordPayment({
    required String customerId,
    required String customerName,
    required double amount,
    required DateTime paymentDate,
    double? outstandingBalance,
    String? note,
    String? requestId,
  }) {
    final recordedBy = _requireUserId();
    _validate(
      customerId: customerId,
      customerName: customerName,
      amount: amount,
      outstandingBalance: outstandingBalance,
    );

    final paymentId = requestId ??
        'p_${DateTime.now().microsecondsSinceEpoch}';
    final activeRequest = _inFlight[paymentId];
    if (activeRequest != null) return activeRequest;

    final now = DateTime.now();
    final payment = PaymentRecord(
      id: paymentId,
      customerId: customerId.trim(),
      customerName: customerName.trim(),
      amount: amount,
      paymentDate: paymentDate,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      recordedBy: recordedBy,
      createdAt: now,
      updatedAt: now,
    );

    final future = _guard(() => _repository.createPayment(payment));
    _inFlight[paymentId] = future;
    future.then<void>(
      (_) => _inFlight.remove(paymentId),
      onError: (Object _, StackTrace __) {
        _inFlight.remove(paymentId);
      },
    );
    return future;
  }

  Future<List<PaymentRecord>> getPayments(String customerId) {
    _requireUserId();
    return _guard(
      () => _repository.getPayments(
        customerId: customerId,
      ),
    );
  }

  Future<List<PaymentRecord>> getAllPayments() {
    _requireUserId();
    return _guard(
      () => _repository.getAllPayments(),
    );
  }

  Future<double> getTotalPayments(String customerId) {
    _requireUserId();
    return _guard(
      () => _repository.getTotalPayments(
        customerId: customerId,
      ),
    );
  }

  String _requireUserId() {
    final userId = _currentUserId()?.trim();
    if (userId == null || userId.isEmpty) {
      throw const PaymentAuthenticationException(
        'You must be signed in to manage payments.',
      );
    }
    return userId;
  }

  void _validate({
    required String customerId,
    required String customerName,
    required double amount,
    double? outstandingBalance,
  }) {
    if (customerId.trim().isEmpty || customerName.trim().isEmpty) {
      throw const PaymentValidationException(
        'Customer information is required.',
      );
    }
    if (!amount.isFinite || amount <= 0) {
      throw const PaymentValidationException(
        'Payment amount must be greater than zero.',
      );
    }
    if (outstandingBalance != null &&
        (!outstandingBalance.isFinite || outstandingBalance < 0)) {
      throw const PaymentValidationException(
        'The customer balance is not valid. Please refresh and try again.',
      );
    }
    if (outstandingBalance != null && amount > outstandingBalance + 0.000001) {
      throw const PaymentValidationException(
        'Payment cannot be greater than the remaining balance.',
      );
    }
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PaymentException {
      rethrow;
    } on PaymentDataSourceException catch (error) {
      throw _mapDataSourceError(error);
    } catch (_) {
      throw const PaymentNetworkException(
        'Unable to reach the payment service. Please try again.',
      );
    }
  }

  PaymentException _mapDataSourceError(PaymentDataSourceException error) {
    switch (error.code) {
      case 'permission-denied':
      case 'unauthenticated':
        return const PaymentPermissionException(
          'You do not have permission to manage payment records.',
        );
      case 'already-exists':
        return PaymentDuplicateException(error.message);
      case 'unavailable':
      case 'deadline-exceeded':
      case 'network-request-failed':
        return const PaymentNetworkException(
          'The payment service is unavailable. Please try again.',
        );
      default:
        return PaymentException(error.message);
    }
  }
}

class PaymentException implements Exception {
  const PaymentException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PaymentAuthenticationException extends PaymentException {
  const PaymentAuthenticationException(super.message);
}

class PaymentValidationException extends PaymentException {
  const PaymentValidationException(super.message);
}

class PaymentPermissionException extends PaymentException {
  const PaymentPermissionException(super.message);
}

class PaymentNetworkException extends PaymentException {
  const PaymentNetworkException(super.message);
}

class PaymentDuplicateException extends PaymentException {
  const PaymentDuplicateException(super.message);
}
