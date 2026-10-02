import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/payment_record.dart';
import '../../services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  PaymentProvider(this._service);

  final PaymentService _service;

  List<PaymentRecord> _payments = [];
  bool loading = false;
  bool saving = false;
  String? error;
  bool _authenticated = false;
  Future<void>? _loadFuture;

  List<PaymentRecord> get payments => List.unmodifiable(_payments);

  double get totalPayments => _payments.fold<double>(
        0,
        (total, payment) => total + payment.amount,
      );

  List<PaymentRecord> paymentsForCustomer(String customerId) =>
      List.unmodifiable(
        _payments
            .where((payment) => payment.customerId == customerId)
            .toList(),
      );

  double totalPaymentsFor(String customerId) => _payments
      .where((payment) => payment.customerId == customerId)
      .fold<double>(0, (total, payment) => total + payment.amount);

  double remainingFrom(double utangBalance) {
    final remaining = utangBalance - totalPayments;
    return remaining > 0 ? remaining : 0;
  }

  void setAuthenticated(bool authenticated) {
    if (_authenticated == authenticated) return;

    _authenticated = authenticated;
    if (!authenticated) {
      _payments = [];
      error = null;
      notifyListeners();
      return;
    }

    unawaited(load());
  }

  Future<void> load() {
    if (!_authenticated) return Future<void>.value();

    final activeLoad = _loadFuture;
    if (activeLoad != null) return activeLoad;

    final loadFuture = _loadInternal();
    _loadFuture = loadFuture;
    loadFuture.then<void>(
      (_) => _loadFuture = null,
      onError: (Object _, StackTrace __) {
        _loadFuture = null;
      },
    );
    return loadFuture;
  }

  Future<void> _loadInternal() async {
    loading = true;
    notifyListeners();

    try {
      _payments = await _service.getAllPayments();
      error = null;
    } catch (exception) {
      error = _messageFor(exception);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<PaymentRecord> recordPayment({
    required String customerId,
    required String customerName,
    required double amount,
    required DateTime paymentDate,
    String? note,
    String? requestId,
  }) async {
    if (saving) {
      throw const PaymentDuplicateException(
        'A payment is already being saved.',
      );
    }

    saving = true;
    notifyListeners();

    try {
      final payment = await _service.recordPayment(
        customerId: customerId,
        customerName: customerName,
        amount: amount,
        paymentDate: paymentDate,
        note: note,
        requestId: requestId,
      );
      _payments = [
        payment,
        ..._payments.where((item) => item.id != payment.id),
      ];
      error = null;
      return payment;
    } catch (exception) {
      error = _messageFor(exception);
      rethrow;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  String _messageFor(Object exception) {
    if (exception is PaymentException) return exception.message;
    return 'Unable to manage payment records. Please try again.';
  }
}
