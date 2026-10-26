import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../models/user.dart';

class AuthRepository {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> currentUser() async {
    final firebaseUser = _auth.currentUser;

    if (firebaseUser == null) {
      return null;
    }

    final doc =
        await _firestore.collection('users').doc(firebaseUser.uid).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return _userFromFirestore(doc);
  }

  Future<User> login(
    String username,
    String email,
    String password,
  ) async {
    final normalizedUsername = username.trim();
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedUsername.length < 3 ||
        normalizedUsername.length > 100 ||
        normalizedEmail.length > 320 ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalizedEmail)) {
      throw const AuthException('Enter a valid username, email, and password.');
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw const AuthException(
          'Unable to sign in. Please try again.',
        );
      }

      final doc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (!doc.exists || doc.data() == null) {
        await _auth.signOut();
        throw const AuthException(
          'User profile was not found.',
        );
      }

      final user = _userFromFirestore(doc);
      if (user.name.toLowerCase() != normalizedUsername.toLowerCase()) {
        await _auth.signOut();
        throw const AuthException('Username and email do not match.');
      }

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found') {
        throw const AuthException(
          'Incorrect email or password.',
        );
      }

      throw AuthException(
        e.message ?? 'Unable to sign in. Please try again.',
      );
    }
  }

  Future<User> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    final normalizedUsername = username.trim();
    final normalizedEmail = email.trim().toLowerCase();

    if (!RegExp(r'^[A-Za-z0-9._-]{3,32}$').hasMatch(normalizedUsername)) {
      throw const AuthException(
        'Use a username with 3–32 letters, numbers, dots, underscores, or hyphens.',
      );
    }
    if (normalizedEmail.length > 320 ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalizedEmail)) {
      throw const AuthException('Enter a valid email address.');
    }
    if (password.length < 8 ||
        password.length > 128 ||
        !RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password) ||
        !RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      throw const AuthException(
        'Use 8+ characters with letters, numbers, and symbols.',
      );
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw const AuthException(
          'Unable to create account. Please try again.',
        );
      }

      final user = User(
        id: firebaseUser.uid,
        // Keep the existing profile field for compatibility; it now stores
        // the required username entered during account creation.
        name: normalizedUsername,
        email: normalizedEmail,
        phone: '',
        storeName: '$normalizedUsername Store',
      );

      try {
        await _firestore.collection('users').doc(firebaseUser.uid).set({
          'id': user.id,
          'name': user.name,
          'nameLowercase': user.name.toLowerCase(),
          'email': user.email,
          'phone': user.phone,
          'storeName': user.storeName,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        // Do not leave an authenticated Firebase session without a profile.
        try {
          await _auth.signOut();
        } catch (_) {
          // The profile write failure is still the useful error to surface.
        }
        throw const AuthException(
          'Unable to finish account setup. Please try again.',
        );
      }

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw const AuthException(
          'That email is already registered.',
        );
      }

      if (e.code == 'weak-password') {
        throw const AuthException(
          'Password is too weak.',
        );
      }

      throw AuthException(
        e.message ?? 'Unable to create account.',
      );
    }
  }

  Future<void> sendPasswordReset(String identifier) async {
    final normalizedIdentifier = identifier.trim().toLowerCase();

    if (normalizedIdentifier.isEmpty ||
        normalizedIdentifier.length > 320 ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalizedIdentifier)) {
      throw const AuthException(
        'Enter the email address for your account.',
      );
    }

    try {
      await _auth.sendPasswordResetEmail(email: normalizedIdentifier);
    } on AuthException {
      rethrow;
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        // Do not reveal whether an account exists.
        return;
      }

      if (e.code == 'too-many-requests') {
        throw const AuthException(
          'Too many reset requests. Please wait a moment and try again.',
        );
      }

      if (e.code == 'network-request-failed') {
        throw const AuthException(
          'No internet connection. Check your connection and try again.',
        );
      }

      throw AuthException(
        e.message ?? 'Unable to send the password reset email.',
      );
    } catch (_) {
      throw const AuthException(
        'Unable to reach the account service. Please try again.',
      );
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  User _userFromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;

    return User(
      id: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      storeName: data['storeName'] as String? ?? '',
    );
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
