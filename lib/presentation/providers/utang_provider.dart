import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/customer.dart';
import '../../data/models/utang_transaction.dart';
import '../../data/repositories/utang_repository.dart';

class UtangProvider extends ChangeNotifier {
  UtangProvider(this._repo);

  final UtangRepository _repo;

  List<Customer> _customers = [];
  List<UtangTransaction> _transactions = [];
  bool loading = false;
  String? error;
  bool _authenticated = false;
  int _authGeneration = 0;
  bool _disposed = false;

  List<Customer> get customers => List.unmodifiable(_customers);

  List<UtangTransaction> get transactionsHistory =>
      List.unmodifiable(_transactions);

  List<UtangTransaction> get completedSales => List.unmodifiable(
        _transactions.where((transaction) =>
            transaction.type == UtangType.credit),
      );

  double get totalSales => completedSales.fold<double>(
        0,
        (total, transaction) => total + transaction.amount,
      );

  double get todaysSales =>
      salesBetween(_startOfDay(DateTime.now()), DateTime.now());

  double get currentWeekSales => salesBetween(
        _startOfWeek(DateTime.now()),
        DateTime.now(),
      );

  double get outstanding =>
      _customers.fold(
        0,
        (total, customer) => total + customer.balance,
      );

  void setAuthenticated(bool authenticated) {
    if (_authenticated == authenticated) return;

    _authenticated = authenticated;
    final generation = ++_authGeneration;

    if (!authenticated) {
      _customers = [];
      _transactions = [];
      error = null;
      loading = false;
      notifyListeners();
      return;
    }

    unawaited(Future<void>.microtask(() async {
      if (_disposed || !_authenticated || generation != _authGeneration) {
        return;
      }
      await load();
    }));
  }

  Future<void> load() async {
    if (!_authenticated) return;

    final generation = _authGeneration;
    loading = true;
    notifyListeners();

    try {
      await _repo.recalculate();
      final customers = await _repo.getCustomers();
      final transactions = await _repo.getAllTransactions();
      if (_authenticated && generation == _authGeneration) {
        _customers = customers;
        _transactions = transactions;
        error = null;
      }
    } catch (_) {
      if (_authenticated && generation == _authGeneration) {
        error = 'Unable to load customer records.';
      }
    } finally {
      if (_authenticated && generation == _authGeneration) {
        loading = false;
        notifyListeners();
      }
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

  double salesBetween(DateTime start, DateTime end) => completedSales
      .where((transaction) {
        final localCreatedAt = transaction.createdAt.toLocal();
        return !localCreatedAt.isBefore(start) &&
            localCreatedAt.isBefore(end);
      })
      .fold<double>(0, (total, transaction) => total + transaction.amount);

  List<double> dailySalesByHour() {
    final today = _startOfDay(DateTime.now());
    final values = List<double>.filled(24, 0);

    for (final sale in completedSales) {
      final localSaleDate = sale.createdAt.toLocal();
      if (_startOfDay(localSaleDate) == today) {
        values[localSaleDate.hour] += sale.amount;
      }
    }

    return values;
  }

  List<double> salesByWeekday() {
    final values = List<double>.filled(DateTime.daysPerWeek, 0);

    for (final sale in completedSales) {
      final weekdayIndex = sale.createdAt.toLocal().weekday - DateTime.monday;
      values[weekdayIndex] += sale.amount;
    }

    return values;
  }

  List<double> weeklySalesByDay() {
    final weekStart = _startOfWeek(DateTime.now());
    final values = List<double>.filled(7, 0);

    for (final sale in completedSales) {
      final dayOffset = sale.createdAt
          .toLocal()
          .difference(weekStart)
          .inDays;
      if (dayOffset >= 0 && dayOffset < values.length) {
        values[dayOffset] += sale.amount;
      }
    }

    return values;
  }

  List<double> weeklySalesByWeek({int weeks = 5}) {
    if (weeks <= 0) return [];
    final values = List<double>.filled(weeks, 0);

    final currentWeekStart = _startOfWeek(DateTime.now());
    final firstWeekStart = currentWeekStart.subtract(
      Duration(days: DateTime.daysPerWeek * (weeks - 1)),
    );

    for (final sale in completedSales) {
      final saleWeekStart = _startOfWeek(sale.createdAt.toLocal());
      final weekIndex =
          saleWeekStart.difference(firstWeekStart).inDays ~/ DateTime.daysPerWeek;
      if (weekIndex >= 0 && weekIndex < values.length) {
        values[weekIndex] += sale.amount;
      }
    }

    return values;
  }

  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _startOfWeek(DateTime date) {
    final start = _startOfDay(date);
    return start.subtract(Duration(days: start.weekday - DateTime.monday));
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

  Future<void> deletePaidCustomer({
    required String customerId,
    required double remainingBalance,
  }) async {
    if (!remainingBalance.isFinite || remainingBalance > 0.000001) {
      throw ArgumentError('Only fully paid Utang records can be deleted.');
    }

    await _repo.deleteCustomer(customerId);
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

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
