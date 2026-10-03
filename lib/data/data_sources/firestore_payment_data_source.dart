import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/payment_record.dart';
import 'payment_data_source.dart';

class FirestorePaymentDataSource implements PaymentDataSource {
  FirestorePaymentDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore,
        _payments = firestore.collection('payment_records');

  final FirebaseFirestore _firestore;
  final CollectionReference<Map<String, dynamic>> _payments;
  late final CollectionReference<Map<String, dynamic>> _customers =
      _firestore.collection('customers');

  @override
  Future<PaymentRecord> createPayment(PaymentRecord payment) async {
    final reference = payment.id.trim().isEmpty
        ? _payments.doc()
        : _payments.doc(payment.id);
    final normalizedPayment = payment.copyWith(
      id: reference.id,
      utangId: payment.utangId ?? payment.customerId,
    );
    final fallbackPaidTotal = await _totalForCustomer(payment.customerId);
    final customerReference = _customers.doc(payment.customerId);

    try {
      return await _firestore.runTransaction<PaymentRecord>(
        (transaction) async {
          final snapshot = await transaction.get(reference);

          if (snapshot.exists) {
            final existing = _fromSnapshot(snapshot);
            if (_matches(existing, normalizedPayment)) {
              return existing;
            }

            throw const PaymentDataSourceException(
              code: 'already-exists',
              message: 'A payment with this request ID already exists.',
            );
          }

          final customerSnapshot = await transaction.get(customerReference);
          final customerData = customerSnapshot.data();
          if (!customerSnapshot.exists || customerData == null) {
            throw const PaymentDataSourceException(
              code: 'customer-not-found',
              message: 'The selected customer no longer exists.',
            );
          }

          final debt = _debtBalance(customerData);
          final paidTotal = _paymentTotal(customerData) ?? fallbackPaidTotal;
          _validateAgainstBalance(
            amount: normalizedPayment.amount,
            paidTotal: paidTotal,
            debt: debt,
          );

          transaction.set(reference, _toMap(normalizedPayment));
          transaction.update(
            customerReference,
            _paymentAggregateUpdate(
              debt: debt,
              paidTotal: paidTotal + normalizedPayment.amount,
            ),
          );
          return normalizedPayment;
        },
      );
    } on FirebaseException catch (error) {
      throw PaymentDataSourceException(
        code: error.code,
        message: error.message ?? 'Unable to save the payment.',
      );
    }
  }

  @override
  Future<PaymentRecord> updatePayment(PaymentRecord payment) async {
    if (payment.id.trim().isEmpty) {
      throw const PaymentDataSourceException(
        code: 'invalid-payment',
        message: 'The payment record is missing its id.',
      );
    }

    final reference = _payments.doc(payment.id);
    final customerReference = _customers.doc(payment.customerId);
    final fallbackPaidTotal = await _totalForCustomer(payment.customerId);

    try {
      return await _firestore.runTransaction<PaymentRecord>(
        (transaction) async {
          final snapshot = await transaction.get(reference);
          if (!snapshot.exists || snapshot.data() == null) {
            throw const PaymentDataSourceException(
              code: 'payment-not-found',
              message: 'The payment record no longer exists.',
            );
          }

          final existing = _fromSnapshot(snapshot);
          if (existing.customerId != payment.customerId) {
            throw const PaymentDataSourceException(
              code: 'invalid-payment',
              message: 'The payment does not belong to this customer.',
            );
          }

          final customerSnapshot = await transaction.get(customerReference);
          final customerData = customerSnapshot.data();
          if (!customerSnapshot.exists || customerData == null) {
            throw const PaymentDataSourceException(
              code: 'customer-not-found',
              message: 'The selected customer no longer exists.',
            );
          }

          final debt = _debtBalance(customerData);
          final paidTotal = _paymentTotal(customerData) ?? fallbackPaidTotal;
          final adjustedPaidTotal = paidTotal - existing.amount;
          _validateAgainstBalance(
            amount: payment.amount,
            paidTotal: adjustedPaidTotal,
            debt: debt,
          );

          final normalizedPayment = payment.copyWith(
            id: reference.id,
            customerId: existing.customerId,
            customerName: existing.customerName,
            utangId: existing.utangId ?? existing.customerId,
            createdAt: existing.createdAt,
            recordedBy: existing.recordedBy,
          );

          transaction.update(reference, _toMap(normalizedPayment));
          transaction.update(
            customerReference,
            _paymentAggregateUpdate(
              debt: debt,
              paidTotal: adjustedPaidTotal + normalizedPayment.amount,
            ),
          );
          return normalizedPayment;
        },
      );
    } on FirebaseException catch (error) {
      throw PaymentDataSourceException(
        code: error.code,
        message: error.message ?? 'Unable to update the payment.',
      );
    }
  }

  @override
  Future<void> deletePayment({required String paymentId}) async {
    if (paymentId.trim().isEmpty) {
      throw const PaymentDataSourceException(
        code: 'invalid-payment',
        message: 'The payment record is missing its id.',
      );
    }

    final reference = _payments.doc(paymentId);
    try {
      final snapshot = await reference.get();
      if (!snapshot.exists || snapshot.data() == null) {
        throw const PaymentDataSourceException(
          code: 'payment-not-found',
          message: 'The payment record no longer exists.',
        );
      }
      final existingPayment = _fromSnapshot(snapshot);
      final fallbackPaidTotal = await _totalForCustomer(
        existingPayment.customerId,
      );

      await _firestore.runTransaction<void>((transaction) async {
        final snapshot = await transaction.get(reference);
        if (!snapshot.exists || snapshot.data() == null) {
          throw const PaymentDataSourceException(
            code: 'payment-not-found',
            message: 'The payment record no longer exists.',
          );
        }

        final payment = _fromSnapshot(snapshot);
        final customerReference = _customers.doc(payment.customerId);
        final customerSnapshot = await transaction.get(customerReference);
        final customerData = customerSnapshot.data();
        if (!customerSnapshot.exists || customerData == null) {
          throw const PaymentDataSourceException(
            code: 'customer-not-found',
            message: 'The selected customer no longer exists.',
          );
        }

        final debt = _debtBalance(customerData);
        final paidTotal = _paymentTotal(customerData) ?? fallbackPaidTotal;

        transaction.delete(reference);
        transaction.update(
          customerReference,
          _paymentAggregateUpdate(
            debt: debt,
            paidTotal: paidTotal - payment.amount,
          ),
        );
      });
    } on FirebaseException catch (error) {
      throw PaymentDataSourceException(
        code: error.code,
        message: error.message ?? 'Unable to delete the payment.',
      );
    }
  }

  @override
  Future<List<PaymentRecord>> getPayments({
    required String customerId,
  }) async {
    final payments = await getAllPayments();
    final customerPayments = payments
        .where((payment) => payment.customerId == customerId)
        .toList();

    customerPayments.sort(
      (a, b) => b.paymentDate.compareTo(a.paymentDate),
    );
    return customerPayments;
  }

  @override
  Future<List<PaymentRecord>> getAllPayments() async {
    try {
      final snapshot = await _payments.get();

      final payments = snapshot.docs.map(_fromSnapshot).toList();
      payments.sort(
        (a, b) => b.paymentDate.compareTo(a.paymentDate),
      );
      return payments;
    } on FirebaseException catch (error) {
      throw PaymentDataSourceException(
        code: error.code,
        message: error.message ?? 'Unable to load payment records.',
      );
    }
  }

  @override
  Future<double> getTotalPayments({
    required String customerId,
  }) async {
    final payments = await getPayments(
      customerId: customerId,
    );
    return payments.fold<double>(
      0,
      (total, payment) => total + payment.amount,
    );
  }

  Map<String, dynamic> _toMap(PaymentRecord payment) => {
        'id': payment.id,
        'customerId': payment.customerId,
        'customerName': payment.customerName,
        'utangId': payment.utangId,
        'amount': payment.amount,
        'paymentDate': Timestamp.fromDate(payment.paymentDate),
        'note': payment.note,
        'recordedBy': payment.recordedBy,
        'createdAt': Timestamp.fromDate(payment.createdAt),
        'updatedAt': Timestamp.fromDate(payment.updatedAt),
      };

  PaymentRecord _fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    final createdAt = _dateFrom(data['createdAt']) ?? DateTime.now();
    final updatedAt = _dateFrom(data['updatedAt']) ?? createdAt;

    return PaymentRecord(
      id: data['id'] as String? ?? snapshot.id,
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      utangId: data['utangId'] as String?,
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      paymentDate: _dateFrom(data['paymentDate']) ?? createdAt,
      note: data['note'] as String?,
      recordedBy: data['recordedBy'] as String? ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  DateTime? _dateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  bool _matches(PaymentRecord first, PaymentRecord second) =>
      first.customerId == second.customerId &&
      first.recordedBy == second.recordedBy &&
      first.amount == second.amount &&
      first.paymentDate == second.paymentDate;

  Future<double> _totalForCustomer(String customerId) async {
    try {
      final snapshot = await _payments
          .where('customerId', isEqualTo: customerId)
          .get();
      return snapshot.docs.fold<double>(
        0,
        (total, document) =>
            total + ((document.data()['amount'] as num?)?.toDouble() ?? 0),
      );
    } on FirebaseException catch (error) {
      throw PaymentDataSourceException(
        code: error.code,
        message: error.message ?? 'Unable to load payment records.',
      );
    }
  }

  double _debtBalance(Map<String, dynamic> customerData) {
    final debt = (customerData['balance'] as num?)?.toDouble();
    if (debt == null || !debt.isFinite || debt < 0) {
      throw const PaymentDataSourceException(
        code: 'invalid-balance',
        message: 'The customer balance is invalid. Please refresh and try again.',
      );
    }
    return debt;
  }

  double? _paymentTotal(Map<String, dynamic> customerData) {
    final value = (customerData['paymentTotal'] as num?)?.toDouble();
    if (value == null || !value.isFinite || value < 0) return null;
    return value;
  }

  void _validateAgainstBalance({
    required double amount,
    required double paidTotal,
    required double debt,
  }) {
    if (!amount.isFinite || amount <= 0) {
      throw const PaymentDataSourceException(
        code: 'invalid-payment',
        message: 'Payment amount must be greater than zero.',
      );
    }
    if (!paidTotal.isFinite || paidTotal < 0) {
      throw const PaymentDataSourceException(
        code: 'invalid-balance',
        message: 'The customer balance is invalid. Please refresh and try again.',
      );
    }
    final remaining = debt - paidTotal;
    if (remaining < -0.000001 || amount > remaining + 0.000001) {
      throw const PaymentDataSourceException(
        code: 'exceeds-balance',
        message: 'Payment cannot be greater than the remaining balance.',
      );
    }
  }

  Map<String, dynamic> _paymentAggregateUpdate({
    required double debt,
    required double paidTotal,
  }) {
    final normalizedPaid = paidTotal <= 0.000001 ? 0 : paidTotal;
    final remaining = (debt - normalizedPaid).clamp(0, double.infinity).toDouble();
    final status = remaining <= 0.000001
        ? 'PAID'
        : normalizedPaid > 0
            ? 'PARTIALLY PAID'
            : 'UNPAID';

    return {
      'paymentTotal': normalizedPaid,
      'remainingBalance': remaining,
      'paymentStatus': status,
      'updatedAt': Timestamp.now(),
    };
  }
}
