import '../models/payment_record.dart';

abstract class PaymentDataSource {
  Future<PaymentRecord> createPayment(PaymentRecord payment);

  Future<List<PaymentRecord>> getPayments({
    required String customerId,
  });

  Future<List<PaymentRecord>> getAllPayments();

  Future<double> getTotalPayments({
    required String customerId,
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
