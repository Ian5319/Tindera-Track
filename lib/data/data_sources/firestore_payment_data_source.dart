import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/payment_record.dart';
import 'payment_data_source.dart';

class FirestorePaymentDataSource implements PaymentDataSource {
  FirestorePaymentDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore,
        _payments = firestore.collection('payment_records');

  final FirebaseFirestore _firestore;
  final CollectionReference<Map<String, dynamic>> _payments;

  @override
  Future<PaymentRecord> createPayment(PaymentRecord payment) async {
    final reference = payment.id.trim().isEmpty
        ? _payments.doc()
        : _payments.doc(payment.id);
    final normalizedPayment = payment.copyWith(id: reference.id);

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

          transaction.set(reference, _toMap(normalizedPayment));
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
  Future<List<PaymentRecord>> getPayments({
    required String customerId,
    required String recordedBy,
  }) async {
    final payments = await getAllPayments(recordedBy: recordedBy);
    final customerPayments = payments
        .where((payment) => payment.customerId == customerId)
        .toList();

    customerPayments.sort(
      (a, b) => b.paymentDate.compareTo(a.paymentDate),
    );
    return customerPayments;
  }

  @override
  Future<List<PaymentRecord>> getAllPayments({
    required String recordedBy,
  }) async {
    try {
      // Filtering by recordedBy keeps this query compatible with the
      // payment project's per-user Firestore rule.
      final snapshot = await _payments
          .where('recordedBy', isEqualTo: recordedBy)
          .get();

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
    required String recordedBy,
  }) async {
    final payments = await getPayments(
      customerId: customerId,
      recordedBy: recordedBy,
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
}
