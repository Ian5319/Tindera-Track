import '../models/product.dart';
import '../../services/storage_service.dart';

class InventoryRepository {
  List<Product> getAll() => StorageService.products.values.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  Future<void> save(Product product) async => StorageService.products.put(product.id, product);

  Future<void> delete(String id) async => StorageService.products.delete(id);

  List<Product> lowStock() => getAll().where((p) => p.isLowStock).toList();
}
