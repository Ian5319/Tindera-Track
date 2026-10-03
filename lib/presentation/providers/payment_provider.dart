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
  int _authGeneration = 0;
  bool _disposed = false;

  List<PaymentRecord> get payments => List.unmodifiable(_payments);

  double get totalPayments => _payments.fold<double>(
        0,
        (total, payment) => total + payment.amount,
      );

  List<PaymentRecord> paymentsForCustomer(String customerId) {
    final payments = _payments
        .where((payment) => payment.customerId == customerId)
        .toList()
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    return List.unmodifiable(payments);
  }

  double totalPaymentsFor(String customerId) => _payments
      .where((payment) => payment.customerId == customerId)
      .fold<double>(0, (total, payment) => total + payment.amount);

  double remainingFrom(double utangBalance) {
    final remaining = utangBalance - totalPayments;
    return remaining > 0 ? remaining : 0;
  }

  double remainingForCustomer({
    required String customerId,
    required double utangBalance,
  }) {
    final remaining = utangBalance - totalPaymentsFor(customerId);
    return remaining > 0 ? remaining : 0;
  }

  void setAuthenticated(bool authenticated) {
    if (_authenticated == authenticated) return;

    _authenticated = authenticated;
    final generation = ++_authGeneration;
    if (!authenticated) {
      _loadFuture = null;
      _payments = [];
      error = null;
      loading = false;
      _notifyAfterProviderUpdate();
      return;
    }

    // ProxyProvider may invoke this during a widget update. Defer the load
    // and notification until that update has finished.
    unawaited(Future<void>.microtask(() async {
      if (_disposed || !_authenticated || generation != _authGeneration) {
        return;
      }
      await load();
    }));
  }

  Future<void> load() {
    if (!_authenticated) return Future<void>.value();

    final activeLoad = _loadFuture;
    if (activeLoad != null) return activeLoad;

    final generation = _authGeneration;
    final loadFuture = _loadInternal(generation);
    _loadFuture = loadFuture;
    loadFuture.then<void>(
      (_) {
        if (identical(_loadFuture, loadFuture)) _loadFuture = null;
      },
      onError: (Object _, StackTrace __) {
        if (identical(_loadFuture, loadFuture)) _loadFuture = null;
      },
    );
    return loadFuture;
  }

  Future<void> _loadInternal(int generation) async {
    if (_disposed || !_authenticated || generation != _authGeneration) {
      return;
    }

    loading = true;
    notifyListeners();

    try {
      final loadedPayments = await _service.getAllPayments();
      if (_authenticated && generation == _authGeneration) {
        _payments = loadedPayments;
        error = null;
      }
    } catch (exception) {
      if (_authenticated && generation == _authGeneration) {
        error = _messageFor(exception);
      }
    } finally {
      if (!_disposed && generation == _authGeneration) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<PaymentRecord> recordPayment({
    required String customerId,
    required String customerName,
    required double amount,
    required DateTime paymentDate,
    double? outstandingBalance,
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
        outstandingBalance: outstandingBalance,
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

  Future<PaymentRecord> updatePayment({
    required PaymentRecord payment,
    required double amount,
    required DateTime paymentDate,
    String? note,
  }) async {
    if (saving) {
      throw const PaymentDuplicateException(
        'A payment operation is already in progress.',
      );
    }

    saving = true;
    notifyListeners();

    try {
      final updated = await _service.updatePayment(
        payment: payment,
        amount: amount,
        paymentDate: paymentDate,
        note: note,
      );
      _payments = [
        updated,
        ..._payments.where((item) => item.id != updated.id),
      ];
      error = null;
      return updated;
    } catch (exception) {
      error = _messageFor(exception);
      rethrow;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> deletePayment(String paymentId) async {
    if (saving) {
      throw const PaymentDuplicateException(
        'A payment operation is already in progress.',
      );
    }

    saving = true;
    notifyListeners();

    try {
      await _service.deletePayment(paymentId);
      _payments = _payments.where((item) => item.id != paymentId).toList();
      error = null;
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

  void _notifyAfterProviderUpdate() {
    unawaited(Future<void>.microtask(() {
      if (!_disposed) notifyListeners();
    }));
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
