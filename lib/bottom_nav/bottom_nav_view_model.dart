import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_session_manager.dart';
import '../constants/firebase_constants.dart';

class BottomNavViewModel extends ChangeNotifier {
  BottomNavViewModel({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  int _selectedIndex = 0;
  int _pendingRequestCount = 0;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _pendingRequestSubscription;

  int get selectedIndex => _selectedIndex;
  int get pendingRequestCount => _pendingRequestCount;

  Future<void> initialize() async {
    final String? userId = await AuthSessionManager.getUserId();
    if (userId == null || userId.isEmpty) {
      _pendingRequestCount = 0;
      notifyListeners();
      return;
    }

    await _pendingRequestSubscription?.cancel();
    _pendingRequestSubscription = _firestore
        .collection(FirebaseCollections.friendRequests)
        .where(FirebaseFields.receiverId, isEqualTo: userId)
        .where(FirebaseFields.status, isEqualTo: FriendRequestStatus.pending)
        .snapshots()
        .listen((QuerySnapshot<Map<String, dynamic>> snapshot) {
          if (_pendingRequestCount == snapshot.docs.length) {
            return;
          }
          _pendingRequestCount = snapshot.docs.length;
          notifyListeners();
        });
  }

  void selectTab(int index) {
    if (index == _selectedIndex) {
      return;
    }
    _selectedIndex = index;
    notifyListeners();
  }

  @override
  void dispose() {
    _pendingRequestSubscription?.cancel();
    super.dispose();
  }
}
