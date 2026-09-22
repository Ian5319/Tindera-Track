import 'package:flutter/foundation.dart';

import '../../data/models/customer.dart';
import '../../data/models/utang_transaction.dart';
import '../../data/repositories/utang_repository.dart';

class UtangProvider extends ChangeNotifier {
  UtangProvider(this._repo) {
    load();
  }

  final UtangRepository _repo;

  List<Customer> _customers = [];
  bool loading = false;
  String? error;

  List<Customer> get customers => List.unmodifiable(_customers);

  double get outstanding =>
      _customers.fold(
        0,
        (total, customer) => total + customer.balance,
      );

  Future<void> load() async {
    loading = true;
    notifyListeners();

    try {
      await _repo.recalculate();
      _customers = await _repo.getCustomers();
      error = null;
    } catch (_) {
      error = 'Unable to load customer records.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<Customer?> customer(String id) {
    return _repo.getCustomer(id);
  }

  Future<List<UtangTransaction>> transactions(
    String id,
  ) {
    return _repo.getTransactionsFor(id);
  }

  Future<double> balance(String id) {
    return _repo.currentBalance(id);
  }

  Future<void> addTransaction(
    UtangTransaction tx,
  ) async {
    await _repo.addTransaction(tx);
    await load();
  }

  // Create a customer manually.
  Future<Customer> createCustomer({
    required String name,
    String phone = '',
  }) async {
    final customer = await _repo.createCustomer(
      name: name,
      phone: phone,
    );

    await load();

    return customer;
  }
}
