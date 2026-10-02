import '../data_sources/payment_data_source.dart';
import '../models/payment_record.dart';

class PaymentRepository {
  const PaymentRepository(this._dataSource);

  final PaymentDataSource _dataSource;

  Future<PaymentRecord> createPayment(PaymentRecord payment) =>
      _dataSource.createPayment(payment);

  Future<List<PaymentRecord>> getPayments({
    required String customerId,
  }) =>
      _dataSource.getPayments(
        customerId: customerId,
      );

  Future<List<PaymentRecord>> getAllPayments() =>
      _dataSource.getAllPayments();

  Future<double> getTotalPayments({
    required String customerId,
  }) =>
      _dataSource.getTotalPayments(
        customerId: customerId,
      );
}
