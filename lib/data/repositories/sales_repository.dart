import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/sale_record.dart';
import 'inventory_repository.dart';

class SalesRepository {
  SalesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _sales =>
      _firestore.collection('sales');

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');

  Future<List<SaleRecord>> getAll() async {
    final snapshot = await _sales.get();
    final records = snapshot.docs.map(_saleFromSnapshot).toList()
      ..sort((a, b) => b.soldAt.compareTo(a.soldAt));
    return records;
  }

  Future<SaleRecord> recordSale({
    required String productId,
    required int quantity,
  }) async {
    if (productId.trim().isEmpty || quantity <= 0) {
      throw const InventoryOperationException('Enter a valid sale quantity.');
    }

    final productReference = _products.doc(productId);
    final saleReference = _sales.doc();

    return _firestore.runTransaction<SaleRecord>((transaction) async {
      final productSnapshot = await transaction.get(productReference);
      if (!productSnapshot.exists || productSnapshot.data() == null) {
        throw const InventoryOperationException('The product no longer exists.');
      }

      final data = productSnapshot.data()!;
      final stock = (data['stockQuantity'] as num?)?.toInt() ?? 0;
      if (quantity > stock) {
        throw InventoryOperationException(
          'Insufficient stock. Only $stock items are available.',
        );
      }

      final price = (data['price'] as num?)?.toDouble() ?? 0;
      final productName = data['name'] as String? ?? '';
      if (productName.trim().isEmpty || !price.isFinite || price <= 0) {
        throw const InventoryOperationException(
          'The product information is invalid.',
        );
      }

      final soldAt = DateTime.now();
      final sale = SaleRecord(
        id: saleReference.id,
        productId: productReference.id,
        productName: productName,
        quantity: quantity,
        sellingPrice: price,
        totalAmount: price * quantity,
        soldAt: soldAt,
      );

      transaction.update(productReference, {
        'stockQuantity': stock - quantity,
        'updatedAt': Timestamp.now(),
      });
      transaction.set(saleReference, _toMap(sale));
      return sale;
    });
  }

  Map<String, dynamic> _toMap(SaleRecord sale) => {
        'id': sale.id,
        'productId': sale.productId,
        'productName': sale.productName,
        'quantity': sale.quantity,
        'sellingPrice': sale.sellingPrice,
        'totalAmount': sale.totalAmount,
        'soldAt': Timestamp.fromDate(sale.soldAt),
      };

  SaleRecord _saleFromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final soldAt = data['soldAt'];
    return SaleRecord(
      id: data['id'] as String? ?? doc.id,
      productId: data['productId'] as String? ?? '',
      productName: data['productName'] as String? ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      sellingPrice: (data['sellingPrice'] as num?)?.toDouble() ?? 0,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      soldAt: soldAt is Timestamp ? soldAt.toDate() : DateTime.now(),
    );
  }
}
