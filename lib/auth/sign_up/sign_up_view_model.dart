import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../constants/encryption_keys.dart';
import '../../constants/firebase_constants.dart';
import '../../model/user_model.dart';

class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<bool> createAccount({
    required String name,
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    _errorMessage = null;
    _successMessage = null;

    final String cleanName = name.trim();
    final String cleanUsername = username.trim();
    final String usernameLower = cleanUsername.toLowerCase();

    final String? validationMessage = _validateInput(
      name: cleanName,
      username: cleanUsername,
      password: password,
      confirmPassword: confirmPassword,
    );

    if (validationMessage != null) {
      _errorMessage = validationMessage;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final DocumentReference<Map<String, dynamic>> userRef = _firestore
          .collection(FirebaseCollections.users)
          .doc();
      final DocumentReference<Map<String, dynamic>> usernameRef = _firestore
          .collection(FirebaseCollections.usernames)
          .doc(usernameLower);

      final UserModel user = UserModel(
        userId: userRef.id,
        name: cleanName,
        username: cleanUsername,
        usernameLower: usernameLower,
        passwordHash: _hashPassword(password),
        createdAt: DateTime.now(),
        isOnline: false,
        lastSeen: DateTime.now(),
      );

      await _firestore.runTransaction((Transaction transaction) async {
        final DocumentSnapshot<Map<String, dynamic>> usernameSnapshot =
            await transaction.get(usernameRef);

        if (usernameSnapshot.exists) {
          throw _UsernameAlreadyTakenException();
        }

        transaction.set(usernameRef, <String, dynamic>{
          FirebaseFields.userId: user.userId,
          FirebaseFields.username: user.username,
          FirebaseFields.createdAt: FieldValue.serverTimestamp(),
        });

        final Map<String, dynamic> userMap = user.toMap();
        userMap[FirebaseFields.nameLower] = cleanName.toLowerCase();
        transaction.set(userRef, userMap);
      });

      _successMessage = 'Account created successfully.';
      return true;
    } on _UsernameAlreadyTakenException {
      _errorMessage = 'Username is already taken.';
      return false;
    } on FirebaseException catch (error) {
      _errorMessage = error.message ?? 'Unable to create account right now.';
      return false;
    } catch (_) {
      _errorMessage = 'Unable to create account right now.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _hashPassword(String password) {
    final List<int> bytes = utf8.encode('$SHA256_KEY:$password');
    return sha256.convert(bytes).toString();
  }

  String? _validateInput({
    required String name,
    required String username,
    required String password,
    required String confirmPassword,
  }) {
    if (name.isEmpty) {
      return 'Please enter your name.';
    }
    if (username.isEmpty) {
      return 'Please enter username.';
    }
    if (username.contains(' ')) {
      return 'Username cannot contain spaces.';
    }
    if (username.length < 3) {
      return 'Username must be at least 3 characters.';
    }
    if (password.isEmpty) {
      return 'Please enter password.';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    if (confirmPassword.isEmpty) {
      return 'Please confirm password.';
    }
    if (password != confirmPassword) {
      return 'Password and confirm password do not match.';
    }
    return null;
  }
}

class _UsernameAlreadyTakenException implements Exception {}
