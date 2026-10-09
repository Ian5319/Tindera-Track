import 'package:flutter/foundation.dart';

import '../../data/models/product.dart';
import '../../data/models/sale_record.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../data/repositories/sales_repository.dart';

class InventoryProvider extends ChangeNotifier {
  InventoryProvider(this._repo, this._salesRepo) {
    load();
    loadSales();
  }

  final InventoryRepository _repo;
  final SalesRepository _salesRepo;

  List<Product> _items = [];
  List<SaleRecord> _sales = [];
  bool loading = false;
  bool salesLoading = false;
  String? error;
  String? salesError;

  List<Product> get items => List.unmodifiable(_items);

  List<Product> get lowStockItems =>
      _items.where((p) => p.isLowStock).toList();

  double get totalSales => _sales.fold<double>(
        0,
        (total, sale) => total + sale.totalAmount,
      );

  double get todaysSales =>
      salesBetween(_startOfDay(DateTime.now()), DateTime.now());

  List<SaleRecord> salesForProduct(String productId) => _sales
      .where((sale) => sale.productId == productId)
      .toList()
    ..sort((a, b) => b.soldAt.compareTo(a.soldAt));

  double salesBetween(DateTime start, DateTime end) => _sales
      .where((sale) {
        final localSaleDate = sale.soldAt.toLocal();
        return !localSaleDate.isBefore(start) &&
            localSaleDate.isBefore(end);
      })
      .fold<double>(0, (total, sale) => total + sale.totalAmount);

  List<double> dailySalesByHour() {
    final today = _startOfDay(DateTime.now());
    final values = List<double>.filled(24, 0);

    for (final sale in _sales) {
      final localSaleDate = sale.soldAt.toLocal();
      if (_startOfDay(localSaleDate) == today) {
        values[localSaleDate.hour] += sale.totalAmount;
      }
    }

    return values;
  }

  List<double> weeklySalesByDay() {
    final weekStart = _startOfWeek(DateTime.now());
    final values = List<double>.filled(7, 0);

    for (final sale in _sales) {
      final localSaleDate = sale.soldAt.toLocal();
      final dayOffset =
          _startOfDay(localSaleDate).difference(weekStart).inDays;
      if (dayOffset >= 0 && dayOffset < values.length) {
        values[dayOffset] += sale.totalAmount;
      }
    }

    return values;
  }

  Future<void> load() async {
    loading = true;
    notifyListeners();

    try {
      _items = await _repo.getAll();
      error = null;
    } catch (_) {
      error = 'Unable to load inventory. Please try again.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> saveProduct(Product product) async {
    await _repo.save(product);
    await load();
  }

  Future<void> addStock(String productId, int quantity) async {
    if (quantity <= 0) {
      throw const InventoryOperationException('Enter a quantity greater than 0.');
    }
    await _repo.adjustStock(productId: productId, delta: quantity);
    await load();
  }

  Future<void> removeStock(String productId, int quantity) async {
    if (quantity <= 0) {
      throw const InventoryOperationException('Enter a quantity greater than 0.');
    }
    await _repo.adjustStock(productId: productId, delta: -quantity);
    await load();
  }

  Future<SaleRecord> recordSale(String productId, int quantity) async {
    final sale = await _salesRepo.recordSale(
      productId: productId,
      quantity: quantity,
    );
    await Future.wait([load(), loadSales()]);
    return sale;
  }

  Future<void> loadSales() async {
    salesLoading = true;
    notifyListeners();
    try {
      _sales = await _salesRepo.getAll();
      salesError = null;
    } catch (_) {
      salesError = 'Unable to load sales history.';
    } finally {
      salesLoading = false;
      notifyListeners();
    }
  }

  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _startOfWeek(DateTime date) {
    final start = _startOfDay(date);
    return start.subtract(Duration(days: start.weekday - DateTime.monday));
  }

  Future<void> deleteProduct(String id) async {
    await _repo.delete(id);
    await load();
  }

  Product? find(String id) {
    try {
      return _items.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
