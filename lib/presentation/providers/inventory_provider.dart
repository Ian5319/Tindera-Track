import 'package:flutter/foundation.dart';
import '../../data/models/product.dart';
import '../../data/repositories/inventory_repository.dart';

class InventoryProvider extends ChangeNotifier {
  InventoryProvider(this._repo) { load(); }
  final InventoryRepository _repo;
  List<Product> _items = [];
  bool loading = false;
  String? error;

  List<Product> get items => List.unmodifiable(_items);
  List<Product> get lowStockItems => _items.where((p) => p.isLowStock).toList();

  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      _items = _repo.getAll();
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

  Product? find(String id) {
    try { return _items.firstWhere((p) => p.id == id); } catch (_) { return null; }
  }
}
