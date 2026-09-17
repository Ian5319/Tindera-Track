import 'package:hive/hive.dart';

class Product {
  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stockQuantity,
    this.photoUrl,
    required this.threshold,
    required this.createdAt,
  });

  final String id;
  final String name;
  final double price;
  final int stockQuantity;
  final String? photoUrl;
  final int threshold;
  final DateTime createdAt;

  Product copyWith({
    String? name,
    double? price,
    int? stockQuantity,
    String? photoUrl,
    int? threshold,
  }) => Product(
        id: id,
        name: name ?? this.name,
        price: price ?? this.price,
        stockQuantity: stockQuantity ?? this.stockQuantity,
        photoUrl: photoUrl ?? this.photoUrl,
        threshold: threshold ?? this.threshold,
        createdAt: createdAt,
      );

  bool get isLowStock => stockQuantity <= threshold;
}

class ProductAdapter extends TypeAdapter<Product> {
  @override
  final int typeId = 1;

  @override
  Product read(BinaryReader reader) {
    final map = Map<String, dynamic>.from(reader.readMap());
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      stockQuantity: (map['stockQuantity'] as num).toInt(),
      photoUrl: map['photoUrl'] as String?,
      threshold: (map['threshold'] as num).toInt(),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  @override
  void write(BinaryWriter writer, Product obj) {
    writer.writeMap({
      'id': obj.id,
      'name': obj.name,
      'price': obj.price,
      'stockQuantity': obj.stockQuantity,
      'photoUrl': obj.photoUrl,
      'threshold': obj.threshold,
      'createdAt': obj.createdAt.toIso8601String(),
    });
  }
}
