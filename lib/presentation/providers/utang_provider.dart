import 'package:flutter/foundation.dart';
import '../../data/models/customer.dart';
import '../../data/models/utang_transaction.dart';
import '../../data/repositories/utang_repository.dart';

class UtangProvider extends ChangeNotifier {
  UtangProvider(this._repo) { load(); }
  final UtangRepository _repo;
  List<Customer> _customers = [];
  bool loading = false;
  String? error;

  List<Customer> get customers => List.unmodifiable(_customers);
  double get outstanding => _customers.fold(0, (sum, c) => sum + c.balance);

  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      await _repo.recalculate();
      _customers = _repo.getCustomers();
      error = null;
    } catch (_) {
      error = 'Unable to load customer records.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Customer? customer(String id) => _repo.getCustomer(id);
  List<UtangTransaction> transactions(String id) => _repo.getTransactionsFor(id);
  double balance(String id) => _repo.currentBalance(id);

  Future<void> addTransaction(UtangTransaction tx) async {
    await _repo.addTransaction(tx);
    await load();
  }
}
