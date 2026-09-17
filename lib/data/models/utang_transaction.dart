import 'package:hive/hive.dart';

enum UtangType { credit, payment }

class UtangTransaction {
  UtangTransaction({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.type,
    this.photoUrl,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String customerId;
  final double amount;
  final UtangType type;
  final String? photoUrl;
  final String? note;
  final DateTime createdAt;
}

class UtangTransactionAdapter extends TypeAdapter<UtangTransaction> {
  @override
  final int typeId = 3;

  @override
  UtangTransaction read(BinaryReader reader) {
    final map = Map<String, dynamic>.from(reader.readMap());
    return UtangTransaction(
      id: map['id'] as String,
      customerId: map['customerId'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: UtangType.values[(map['type'] as num).toInt()],
      photoUrl: map['photoUrl'] as String?,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  @override
  void write(BinaryWriter writer, UtangTransaction obj) {
    writer.writeMap({
      'id': obj.id,
      'customerId': obj.customerId,
      'amount': obj.amount,
      'type': obj.type.index,
      'photoUrl': obj.photoUrl,
      'note': obj.note,
      'createdAt': obj.createdAt.toIso8601String(),
    });
  }
}
