import '../models/customer.dart';
import '../models/utang_transaction.dart';
import '../../services/storage_service.dart';

class UtangRepository {
  List<Customer> getCustomers() => StorageService.customers.values.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  Customer? getCustomer(String id) => StorageService.customers.get(id);

  List<UtangTransaction> getTransactionsFor(String customerId) => StorageService.transactions.values
      .where((t) => t.customerId == customerId)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> addTransaction(UtangTransaction transaction) async {
    await StorageService.transactions.put(transaction.id, transaction);
    await StorageService.recalculateAllBalances();
  }

  Future<void> recalculate() => StorageService.recalculateAllBalances();

  double currentBalance(String customerId) {
    return getTransactionsFor(customerId).fold<double>(0, (sum, tx) => sum + (tx.type == UtangType.credit ? tx.amount : -tx.amount));
  }
}
