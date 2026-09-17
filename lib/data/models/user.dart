import 'package:hive/hive.dart';

class User {
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.storeName,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String storeName;
}

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 4;

  @override
  User read(BinaryReader reader) {
    final map = Map<String, dynamic>.from(reader.readMap());
    return User(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      storeName: map['storeName'] as String,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer.writeMap({
      'id': obj.id,
      'name': obj.name,
      'email': obj.email,
      'phone': obj.phone,
      'storeName': obj.storeName,
    });
  }
}
