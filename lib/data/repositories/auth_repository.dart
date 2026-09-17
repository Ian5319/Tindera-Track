import '../models/user.dart';
import '../../services/storage_service.dart';

class AuthRepository {
  User? currentUser() {
    final id = StorageService.auth.get('sessionUserId') as String?;
    if (id == null) return null;
    return StorageService.users.get(id);
  }

  Future<User> login(String identifier, String password) async {
    final normalizedIdentifier = identifier.trim().toLowerCase();
    final user = StorageService.users.values.cast<User?>().firstWhere(
      (candidate) => candidate != null && _matchesIdentifier(candidate, normalizedIdentifier),
      orElse: () => null,
    );
    if (user == null) {
      throw const AuthException('Incorrect username/phone or password/PIN.');
    }
    final stored = StorageService.auth.get('credential:${user.id}') as String?;
    if (stored == null || stored != password) {
      throw const AuthException('Incorrect username/phone or password/PIN.');
    }
    await StorageService.auth.put('sessionUserId', user.id);
    return user;
  }

  Future<User> signUp({required String name, required String email, required String password}) async {
    final normalizedName = name.trim();
    final normalizedEmail = email.trim().toLowerCase();
    final exists = StorageService.users.values.any(
      (u) => u.email.toLowerCase() == normalizedEmail || u.name.toLowerCase() == normalizedName.toLowerCase(),
    );
    if (exists) throw const AuthException('That email is already registered.');
    final id = 'u${DateTime.now().microsecondsSinceEpoch}';
    final phone = '09${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final user = User(id: id, name: normalizedName, email: normalizedEmail, phone: phone, storeName: '$normalizedName Store');
    await StorageService.users.put(user.id, user);
    await StorageService.auth.put('credential:${user.id}', password);
    await StorageService.auth.put('credential:${user.email}', password);
    await StorageService.auth.put('credential:${user.phone}', password);
    await StorageService.auth.put('credential:${user.name.toLowerCase()}', password);
    await StorageService.auth.put('sessionUserId', user.id);
    return user;
  }

  bool _matchesIdentifier(User user, String identifier) {
    return user.email.toLowerCase() == identifier ||
        user.phone.toLowerCase() == identifier ||
        user.name.toLowerCase() == identifier ||
        (identifier == 'rosita' && user.id == 'u1');
  }

  Future<void> logout() async => StorageService.auth.delete('sessionUserId');
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}
