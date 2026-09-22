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

  Future<List<Product>> lowStock() async {
    final products = await getAll();

    return products.where((p) => p.isLowStock).toList();
  }

  Product _productFromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

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
}