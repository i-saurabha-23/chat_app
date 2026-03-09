import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../constants/firebase_constants.dart';

class UserPublicProfileViewModel extends ChangeNotifier {
  UserPublicProfileViewModel({
    required this.userId,
    this.initialData,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String userId;
  final Map<String, dynamic>? initialData;
  final FirebaseFirestore _firestore;

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _userData = <String, dynamic>{};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get name =>
      (_userData[FirebaseFields.name] as String?)?.trim().isNotEmpty == true
      ? (_userData[FirebaseFields.name] as String)
      : 'Unknown User';
  String get username =>
      (_userData[FirebaseFields.username] as String?)?.trim() ?? '';
  String get profilePic =>
      (_userData[FirebaseFields.profilePic] as String?)?.trim() ?? '';
  String get publicUserId =>
      (_userData[FirebaseFields.userId] as String?)?.trim() ?? userId;
  bool get isOnline => (_userData[FirebaseFields.isOnline] as bool?) ?? false;

  Future<void> loadUser() async {
    _isLoading = true;
    _errorMessage = null;

    if (initialData != null) {
      _userData = <String, dynamic>{...initialData!};
    }
    notifyListeners();

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .get();

      if (!snapshot.exists || snapshot.data() == null) {
        _errorMessage = 'User not found.';
      } else {
        _userData = <String, dynamic>{
          ...snapshot.data()!,
          FirebaseFields.userId:
              (snapshot.data()?[FirebaseFields.userId] as String?) ??
              snapshot.id,
        };
      }
    } on FirebaseException catch (error) {
      _errorMessage = error.message ?? 'Unable to load user profile.';
    } catch (_) {
      _errorMessage = 'Unable to load user profile.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
