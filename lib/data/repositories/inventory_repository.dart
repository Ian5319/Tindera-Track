import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';

class InventoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');

  Future<List<Product>> getAll() async {
    final snapshot = await _products.get();

    final products = snapshot.docs
        .map(_productFromFirestore)
        .toList();

    products.sort(
      (a, b) => a.name.toLowerCase().compareTo(
            b.name.toLowerCase(),
          ),
    );

    return products;
  }

  Future<void> save(Product product) async {
    if (product.id.trim().isEmpty || product.name.trim().isEmpty) {
      throw ArgumentError('A product must have an id and name.');
    }
    if (!product.price.isFinite || product.price <= 0 ||
        product.stockQuantity < 0 || product.threshold < 0) {
      throw ArgumentError('Product values are outside the allowed range.');
    }

    await _products.doc(product.id).set({
      'id': product.id,
      'name': product.name,
      'price': product.price,
      'stockQuantity': product.stockQuantity,
      'photoUrl': product.photoUrl,
      'threshold': product.threshold,
      'createdAt': Timestamp.fromDate(product.createdAt),
    });
  }

  Future<void> delete(String id) async {
    await _products.doc(id).delete();
  }

  Future<Product> adjustStock({
    required String productId,
    required int delta,
  }) async {
    if (productId.trim().isEmpty || delta == 0) {
      throw const InventoryOperationException('Enter a valid stock quantity.');
    }

    final reference = _products.doc(productId);
    return _firestore.runTransaction<Product>((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists || snapshot.data() == null) {
        throw const InventoryOperationException('The product no longer exists.');
      }

      final product = _productFromSnapshot(snapshot);
      final nextStock = product.stockQuantity + delta;
      if (nextStock < 0) {
        throw InventoryOperationException(
          'Insufficient stock. Only ${product.stockQuantity} items are available.',
        );
      }

      transaction.update(reference, {
        'stockQuantity': nextStock,
        'updatedAt': Timestamp.now(),
      });
      return product.copyWith(stockQuantity: nextStock);
    });
  }

  Future<List<Product>> lowStock() async {
    final products = await getAll();

    return products.where((p) => p.isLowStock).toList();
  }

  Product _productFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final createdAt = data['createdAt'];

    return Product(
      id: doc.id,
      name: data['name'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      stockQuantity: (data['stockQuantity'] as num?)?.toInt() ?? 0,
      photoUrl: data['photoUrl'] as String?,
      threshold: (data['threshold'] as num?)?.toInt() ?? 0,
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.now(),
    );
  }

  Product _productFromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) => _productFromSnapshot(doc);
}

class InventoryOperationException implements Exception {
  const InventoryOperationException(this.message);

  final String message;

  @override
  String toString() => message;
}
