import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const sessionTimeout = Duration(minutes: 30);

  AuthProvider(this._repository) {
    WidgetsBinding.instance.addObserver(this);
    _startWithLoginRequired();
  }

  final AuthRepository _repository;

  User? _user;
  bool _loading = true;
  String? _error;
  Timer? _sessionTimer;
  DateTime? _lastActivity;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> _startWithLoginRequired() async {
    try {
      // Firebase persists its last session by default. Sign it out here so
      // every app launch requires the user to log in again.
      await _repository.logout();
    } catch (_) {
      // The local provider still starts logged out if Firebase is offline.
    } finally {
      _user = null;
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> login(String identifier, String password) async {
    _setLoading(true);
    _error = null;

    try {
      _user = await _repository.login(identifier, password);
      _startSessionTimer();
    } catch (e) {
      _error = e.toString().replaceFirst('AuthException: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signUp(
    String name,
    String email,
    String password,
  ) async {
    _setLoading(true);
    _error = null;

    try {
      _user = await _repository.signUp(
        name: name,
        email: email,
        password: password,
      );
      _startSessionTimer();
    } catch (e) {
      _error = e.toString().replaceFirst('AuthException: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> sendPasswordReset(String identifier) async {
    try {
      await _repository.sendPasswordReset(identifier);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('AuthException: ', '');
    }
  }

  Future<void> logout() async {
    _stopSessionTimer();
    _user = null;
    notifyListeners();

    try {
      await _repository.logout();
    } catch (_) {
      // The local session is already cleared, even if Firebase sign-out fails.
    }
  }

  /// Records user activity and keeps the session alive while the app is in use.
  void recordActivity() {
    if (!isAuthenticated) return;

    _lastActivity = DateTime.now();
    _scheduleSessionExpiry();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _expireIfIdle();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void _startSessionTimer() {
    _lastActivity = DateTime.now();
    _scheduleSessionExpiry();
  }

  void _scheduleSessionExpiry() {
    _sessionTimer?.cancel();
    final lastActivity = _lastActivity;
    if (lastActivity == null) return;

    final remaining = sessionTimeout - DateTime.now().difference(lastActivity);
    _sessionTimer = Timer(
      remaining.isNegative ? Duration.zero : remaining,
      _expireIfIdle,
    );
  }

  void _expireIfIdle() {
    final lastActivity = _lastActivity;
    if (_user == null || lastActivity == null) return;

    if (DateTime.now().difference(lastActivity) >= sessionTimeout) {
      unawaited(_expireSession());
    } else {
      _scheduleSessionExpiry();
    }
  }

  Future<void> _expireSession() async {
    if (_user == null) return;

    _stopSessionTimer();
    _user = null;
    notifyListeners();

    try {
      await _repository.logout();
    } catch (_) {
      // The local session is already cleared, even if Firebase sign-out fails.
    }
  }

  void _stopSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _lastActivity = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopSessionTimer();
    super.dispose();
  }
}
