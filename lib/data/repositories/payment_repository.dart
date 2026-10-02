import '../data_sources/payment_data_source.dart';
import '../models/payment_record.dart';

class PaymentRepository {
  const PaymentRepository(this._dataSource);

  final PaymentDataSource _dataSource;

  Future<PaymentRecord> createPayment(PaymentRecord payment) =>
      _dataSource.createPayment(payment);

  Future<List<PaymentRecord>> getPayments({
    required String customerId,
    required String recordedBy,
  }) =>
      _dataSource.getPayments(
        customerId: customerId,
        recordedBy: recordedBy,
      );

  Future<List<PaymentRecord>> getAllPayments({
    required String recordedBy,
  }) =>
      _dataSource.getAllPayments(recordedBy: recordedBy);

  Future<double> getTotalPayments({
    required String customerId,
    required String recordedBy,
  }) =>
      _dataSource.getTotalPayments(
        customerId: customerId,
        recordedBy: recordedBy,
      );
}
