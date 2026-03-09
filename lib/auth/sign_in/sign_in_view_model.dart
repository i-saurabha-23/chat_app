import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../constants/encryption_keys.dart';
import '../../constants/firebase_constants.dart';
import '../../model/user_model.dart';
import '../../notifications/push_notification_service.dart';
import '../auth_session_manager.dart';

class SignInViewModel extends ChangeNotifier {
  SignInViewModel({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<UserModel?> signIn({
    required String username,
    required String password,
  }) async {
    _errorMessage = null;
    final String cleanUsername = username.trim();
    final String cleanPassword = password.trim();

    if (cleanUsername.isEmpty) {
      _errorMessage = 'Please enter username.';
      notifyListeners();
      return null;
    }
    if (cleanPassword.isEmpty) {
      _errorMessage = 'Please enter password.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final String usernameLower = cleanUsername.toLowerCase();
      final DocumentSnapshot<Map<String, dynamic>> usernameSnapshot =
          await _firestore
              .collection(FirebaseCollections.usernames)
              .doc(usernameLower)
              .get();

      if (!usernameSnapshot.exists) {
        _errorMessage = 'Invalid username or password.';
        return null;
      }

      final String userId =
          (usernameSnapshot.data()?[FirebaseFields.userId] as String?) ?? '';
      if (userId.isEmpty) {
        _errorMessage = 'Invalid username or password.';
        return null;
      }

      final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
          await _firestore
              .collection(FirebaseCollections.users)
              .doc(userId)
              .get();

      if (!userSnapshot.exists || userSnapshot.data() == null) {
        _errorMessage = 'Invalid username or password.';
        return null;
      }

      final UserModel user = UserModel.fromMap(userSnapshot.data()!);
      final String hashedInputPassword = _hashPassword(cleanPassword);

      if (user.passwordHash != hashedInputPassword) {
        _errorMessage = 'Invalid username or password.';
        return null;
      }

      await AuthSessionManager.saveSession(
        userId: user.userId,
        username: user.username,
        name: user.name,
      );
      await userSnapshot.reference
          .update(<String, dynamic>{
            FirebaseFields.isOnline: true,
            FirebaseFields.lastSeen: FieldValue.serverTimestamp(),
          })
          .catchError((_) {});
      await PushNotificationService.instance
          .registerTokenForUser(user.userId)
          .catchError((_) {});

      return user;
    } on FirebaseException catch (error) {
      _errorMessage = error.message ?? 'Unable to sign in right now.';
      return null;
    } catch (_) {
      _errorMessage = 'Unable to sign in right now.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut({String? userId}) async {
    final String? activeUserId = userId ?? await AuthSessionManager.getUserId();

    if (activeUserId != null && activeUserId.isNotEmpty) {
      await PushNotificationService.instance
          .unregisterTokenForUser(activeUserId)
          .catchError((_) {});
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(activeUserId)
          .update(<String, dynamic>{
            FirebaseFields.isOnline: false,
            FirebaseFields.lastSeen: FieldValue.serverTimestamp(),
          })
          .catchError((_) {});
    }

    await AuthSessionManager.clearSession();
  }

  String _hashPassword(String password) {
    final List<int> bytes = utf8.encode('$SHA256_KEY:$password');
    return sha256.convert(bytes).toString();
  }
}
