import 'package:hive/hive.dart';

class Customer {
  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.balance,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String phone;
  final double balance;
  final DateTime createdAt;

  Customer copyWith({double? balance}) => Customer(
        id: id,
        name: name,
        phone: phone,
        balance: balance ?? this.balance,
        createdAt: createdAt,
      );
}

class CustomerAdapter extends TypeAdapter<Customer> {
  @override
  final int typeId = 2;

  @override
  Customer read(BinaryReader reader) {
    final map = Map<String, dynamic>.from(reader.readMap());
    return Customer(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      balance: (map['balance'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  @override
  void write(BinaryWriter writer, Customer obj) {
    writer.writeMap({
      'id': obj.id,
      'name': obj.name,
      'phone': obj.phone,
      'balance': obj.balance,
      'createdAt': obj.createdAt.toIso8601String(),
    });
  }
}
