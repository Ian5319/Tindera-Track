import '../models/payment_record.dart';

abstract class PaymentDataSource {
  Future<PaymentRecord> createPayment(PaymentRecord payment);

  Future<List<PaymentRecord>> getPayments({
    required String customerId,
    required String recordedBy,
  });

  Future<List<PaymentRecord>> getAllPayments({
    required String recordedBy,
  });

  Future<double> getTotalPayments({
    required String customerId,
    required String recordedBy,
  });
}

class PaymentDataSourceException implements Exception {
  const PaymentDataSourceException({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;

  @override
  String toString() => 'PaymentDataSourceException($code): $message';
}
