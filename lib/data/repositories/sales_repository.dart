import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  String get _ownerId {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('An authenticated owner is required.');
    }
    return uid;
  }

  Future<List<SaleRecord>> getAll() async {
    final snapshot = await _sales
        .where('ownerId', isEqualTo: _ownerId)
        .get();
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
      if (data['ownerId'] != _ownerId) {
        throw const InventoryOperationException('The product is not available.');
      }
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

      final totalAmount = price * quantity;
      if (!totalAmount.isFinite) {
        throw const InventoryOperationException(
          'The sale total is outside the allowed range.',
        );
      }

      final soldAt = DateTime.now();
      final sale = SaleRecord(
        id: saleReference.id,
        ownerId: _ownerId,
        productId: productReference.id,
        productName: productName,
        quantity: quantity,
        sellingPrice: price,
        totalAmount: totalAmount,
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
        'ownerId': sale.ownerId,
        'productId': sale.productId,
        'productName': sale.productName,
        'quantity': sale.quantity,
        'sellingPrice': sale.sellingPrice,
        'totalAmount': sale.calculatedTotalAmount,
        'soldAt': Timestamp.fromDate(sale.soldAt),
      };

  SaleRecord _saleFromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final soldAt = data['soldAt'];
    final quantity = data['quantity'] is num
        ? (data['quantity'] as num).toInt()
        : 0;
    final sellingPrice = data['sellingPrice'] is num
        ? (data['sellingPrice'] as num).toDouble()
        : 0.0;
    final double calculatedTotalAmount = quantity * sellingPrice;
    return SaleRecord(
      id: data['id'] is String ? data['id'] as String : doc.id,
      ownerId: data['ownerId'] is String ? data['ownerId'] as String : '',
      productId: data['productId'] is String ? data['productId'] as String : '',
      productName: data['productName'] is String
          ? data['productName'] as String
          : '',
      quantity: quantity,
      sellingPrice: sellingPrice,
      totalAmount: calculatedTotalAmount.isFinite &&
              quantity > 0 &&
              sellingPrice.isFinite &&
              sellingPrice > 0
          ? calculatedTotalAmount
          : 0,
      soldAt: soldAt is Timestamp ? soldAt.toDate() : DateTime.now(),
    );
  }
}
