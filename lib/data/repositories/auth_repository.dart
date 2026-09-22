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

    final doc = await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return _userFromFirestore(doc);
  }

  Future<User> login(String identifier, String password) async {
    final normalizedIdentifier = identifier.trim().toLowerCase();

    String email = normalizedIdentifier;

    // If the user entered phone number or name,
    // find the corresponding email in Firestore.
    if (!normalizedIdentifier.contains('@')) {
      final byPhone = await _firestore
          .collection('users')
          .where('phone', isEqualTo: normalizedIdentifier)
          .limit(1)
          .get();

      if (byPhone.docs.isNotEmpty) {
        email = (byPhone.docs.first.data()['email'] as String).toLowerCase();
      } else {
        final byName = await _firestore
            .collection('users')
            .where('nameLowercase', isEqualTo: normalizedIdentifier)
            .limit(1)
            .get();

        if (byName.docs.isNotEmpty) {
          email = (byName.docs.first.data()['email'] as String).toLowerCase();
        } else if (normalizedIdentifier == 'rosita') {
          email = 'rosita@example.com';
        } else {
          throw const AuthException(
            'Incorrect username/phone or password/PIN.',
          );
        }
      }
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw const AuthException(
          'Unable to sign in. Please try again.',
        );
      }

      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!doc.exists || doc.data() == null) {
        throw const AuthException(
          'User profile was not found.',
        );
      }

      return _userFromFirestore(doc);
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found') {
        throw const AuthException(
          'Incorrect username/phone or password/PIN.',
        );
      }

      throw AuthException(
        e.message ?? 'Unable to sign in. Please try again.',
      );
    }
  }

  Future<User> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedName = name.trim();
    final normalizedEmail = email.trim().toLowerCase();

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
        name: normalizedName,
        email: normalizedEmail,
        phone: '',
        storeName: '$normalizedName Store',
      );

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set({
        'id': user.id,
        'name': user.name,
        'nameLowercase': user.name.toLowerCase(),
        'email': user.email,
        'phone': user.phone,
        'storeName': user.storeName,
        'createdAt': FieldValue.serverTimestamp(),
      });

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