import 'package:flutter/foundation.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository) : _user = _repository.currentUser();

  final AuthRepository _repository;
  User? _user;
  bool _loading = false;
  String? _error;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> login(String identifier, String password) async {
    _setLoading(true);
    _error = null;
    try {
      _user = await _repository.login(identifier, password);
    } catch (e) {
      _error = e.toString().replaceFirst('AuthException: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signUp(String name, String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      _user = await _repository.signUp(name: name, email: email, password: password);
    } catch (e) {
      _error = e.toString().replaceFirst('AuthException: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
