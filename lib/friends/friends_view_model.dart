import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

import '../auth/auth_session_manager.dart';
import '../constants/firebase_constants.dart';

class FriendsViewModel extends ChangeNotifier {
  FriendsViewModel({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _statusNone = 'none';
  static const String _statusFriend = 'friend';
  static const String _statusSent = 'sent';
  static const String _statusReceived = 'received';

  final FirebaseFirestore _firestore;

  bool _isInitializing = true;
  bool _isSearching = false;
  String? _errorMessage;
  String _currentUserId = '';
  int _receivedRequestCount = 0;
  String _searchQuery = '';
  final List<Map<String, dynamic>> _searchResults = <Map<String, dynamic>>[];
  final Set<String> _sendingRequestUserIds = <String>{};
  final Map<String, String> _connectionStatusByUserId = <String, String>{};
  final Map<String, Map<String, dynamic>> _userCache =
      <String, Map<String, dynamic>>{};
  final Set<String> _processingRequestIds = <String>{};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _receivedRequestCountSubscription;

  String get screenTitle => 'Friends';
  bool get isInitializing => _isInitializing;
  bool get isSearching => _isSearching;
  String? get errorMessage => _errorMessage;
  int get receivedRequestCount => _receivedRequestCount;
  String get searchQuery => _searchQuery;
  List<Map<String, dynamic>> get searchResults =>
      List<Map<String, dynamic>>.unmodifiable(_searchResults);

  Future<void> initialize() async {
    _isInitializing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String? userId = await AuthSessionManager.getUserId();
      if (userId == null || userId.isEmpty) {
        _errorMessage = 'Session expired. Please sign in again.';
      } else {
        _currentUserId = userId;
        await _listenToReceivedRequestCount();
      }
    } catch (_) {
      _errorMessage = 'Unable to initialize friends.';
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> _listenToReceivedRequestCount() async {
    await _receivedRequestCountSubscription?.cancel();
    _receivedRequestCountSubscription = _firestore
        .collection(FirebaseCollections.friendRequests)
        .where(FirebaseFields.receiverId, isEqualTo: _currentUserId)
        .where(FirebaseFields.status, isEqualTo: FriendRequestStatus.pending)
        .snapshots()
        .listen((QuerySnapshot<Map<String, dynamic>> snapshot) {
          if (_receivedRequestCount == snapshot.docs.length) {
            return;
          }
          _receivedRequestCount = snapshot.docs.length;
          notifyListeners();
        });
  }

  Future<void> searchUsers(String query) async {
    final String cleanQuery = query.trim();
    _searchQuery = cleanQuery;
    _errorMessage = null;

    if (_currentUserId.isEmpty) {
      _searchResults.clear();
      notifyListeners();
      return;
    }

    if (cleanQuery.isEmpty) {
      _searchResults.clear();
      _connectionStatusByUserId.clear();
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      final String lowerQuery = cleanQuery.toLowerCase();
      final String capitalizedQuery = _capitalize(cleanQuery);
      final CollectionReference<Map<String, dynamic>> usersRef = _firestore
          .collection(FirebaseCollections.users);

      final QuerySnapshot<Map<String, dynamic>> usernameSnapshot =
          await usersRef
              .where(
                FirebaseFields.usernameLower,
                isGreaterThanOrEqualTo: lowerQuery,
              )
              .where(
                FirebaseFields.usernameLower,
                isLessThanOrEqualTo: '$lowerQuery\uf8ff',
              )
              .limit(25)
              .get();

      final QuerySnapshot<Map<String, dynamic>> nameLowerSnapshot =
          await usersRef
              .where(
                FirebaseFields.nameLower,
                isGreaterThanOrEqualTo: lowerQuery,
              )
              .where(
                FirebaseFields.nameLower,
                isLessThanOrEqualTo: '$lowerQuery\uf8ff',
              )
              .limit(25)
              .get();

      final QuerySnapshot<Map<String, dynamic>> nameSnapshot = await usersRef
          .where(FirebaseFields.name, isGreaterThanOrEqualTo: capitalizedQuery)
          .where(
            FirebaseFields.name,
            isLessThanOrEqualTo: '$capitalizedQuery\uf8ff',
          )
          .limit(25)
          .get();

      final Map<String, Map<String, dynamic>> mergedUsers =
          <String, Map<String, dynamic>>{};

      void mergeUsers(QuerySnapshot<Map<String, dynamic>> snapshot) {
        for (final QueryDocumentSnapshot<Map<String, dynamic>> document
            in snapshot.docs) {
          final Map<String, dynamic> data = document.data();
          final String userId =
              (data[FirebaseFields.userId] as String?)?.trim() ?? document.id;

          if (userId.isEmpty || userId == _currentUserId) {
            continue;
          }

          final Map<String, dynamic> mapped = <String, dynamic>{
            ...data,
            FirebaseFields.userId: userId,
          };
          mergedUsers[userId] = mapped;
          _userCache[userId] = mapped;
        }
      }

      mergeUsers(usernameSnapshot);
      mergeUsers(nameLowerSnapshot);
      mergeUsers(nameSnapshot);

      final List<String> userIds = mergedUsers.keys.toList(growable: false);
      final Map<String, String> statuses = await _resolveConnectionStatuses(
        userIds,
      );

      _connectionStatusByUserId
        ..clear()
        ..addAll(statuses);

      _searchResults
        ..clear()
        ..addAll(mergedUsers.values);
      _searchResults.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
        final String nameA = ((a[FirebaseFields.name] as String?) ?? '')
            .toLowerCase();
        final String nameB = ((b[FirebaseFields.name] as String?) ?? '')
            .toLowerCase();
        return nameA.compareTo(nameB);
      });
    } on FirebaseException catch (error) {
      _errorMessage = error.message ?? 'Unable to search users right now.';
      _searchResults.clear();
    } catch (_) {
      _errorMessage = 'Unable to search users right now.';
      _searchResults.clear();
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  String connectionStatusFor(String userId) {
    return _connectionStatusByUserId[userId] ?? _statusNone;
  }

  bool isSendingRequest(String userId) {
    return _sendingRequestUserIds.contains(userId);
  }

  Stream<List<Map<String, dynamic>>> receivedRequestsStream() {
    if (_currentUserId.isEmpty) {
      return Stream<List<Map<String, dynamic>>>.value(
        const <Map<String, dynamic>>[],
      );
    }

    return _firestore
        .collection(FirebaseCollections.friendRequests)
        .where(FirebaseFields.receiverId, isEqualTo: _currentUserId)
        .where(FirebaseFields.status, isEqualTo: FriendRequestStatus.pending)
        .snapshots()
        .asyncMap(
          (QuerySnapshot<Map<String, dynamic>> snapshot) =>
              _mapRequestsWithUser(snapshot: snapshot, fromSender: true),
        );
  }

  Stream<List<Map<String, dynamic>>> sentRequestsStream() {
    if (_currentUserId.isEmpty) {
      return Stream<List<Map<String, dynamic>>>.value(
        const <Map<String, dynamic>>[],
      );
    }

    return _firestore
        .collection(FirebaseCollections.friendRequests)
        .where(FirebaseFields.senderId, isEqualTo: _currentUserId)
        .where(FirebaseFields.status, isEqualTo: FriendRequestStatus.pending)
        .snapshots()
        .asyncMap(
          (QuerySnapshot<Map<String, dynamic>> snapshot) =>
              _mapRequestsWithUser(snapshot: snapshot, fromSender: false),
        );
  }

  Future<String?> sendFriendRequest(Map<String, dynamic> user) async {
    final String targetUserId = ((user[FirebaseFields.userId] as String?) ?? '')
        .trim();

    if (_currentUserId.isEmpty) {
      return 'Please sign in again.';
    }
    if (targetUserId.isEmpty || targetUserId == _currentUserId) {
      return 'Invalid user selected.';
    }
    if (_sendingRequestUserIds.contains(targetUserId)) {
      return null;
    }

    final String currentStatus = connectionStatusFor(targetUserId);
    if (currentStatus == _statusFriend) {
      return 'You are already friends.';
    }
    if (currentStatus == _statusSent) {
      return 'Friend request already sent.';
    }
    if (currentStatus == _statusReceived) {
      return 'User already sent you a request. Check Received tab.';
    }

    _sendingRequestUserIds.add(targetUserId);
    notifyListeners();

    try {
      final CollectionReference<Map<String, dynamic>> requestRef = _firestore
          .collection(FirebaseCollections.friendRequests);

      final QuerySnapshot<Map<String, dynamic>> outgoingPending =
          await requestRef
              .where(FirebaseFields.senderId, isEqualTo: _currentUserId)
              .where(FirebaseFields.receiverId, isEqualTo: targetUserId)
              .where(
                FirebaseFields.status,
                isEqualTo: FriendRequestStatus.pending,
              )
              .limit(1)
              .get();

      if (outgoingPending.docs.isNotEmpty) {
        return 'Friend request already sent.';
      }

      final QuerySnapshot<Map<String, dynamic>> incomingPending =
          await requestRef
              .where(FirebaseFields.senderId, isEqualTo: targetUserId)
              .where(FirebaseFields.receiverId, isEqualTo: _currentUserId)
              .where(
                FirebaseFields.status,
                isEqualTo: FriendRequestStatus.pending,
              )
              .limit(1)
              .get();

      if (incomingPending.docs.isNotEmpty) {
        return 'User already sent you a request. Check Received tab.';
      }

      final String friendshipId = _friendshipId(_currentUserId, targetUserId);
      final DocumentSnapshot<Map<String, dynamic>> friendshipDoc =
          await _firestore
              .collection(FirebaseCollections.friends)
              .doc(friendshipId)
              .get();
      if (friendshipDoc.exists) {
        return 'You are already friends.';
      }

      await requestRef.add(<String, dynamic>{
        FirebaseFields.senderId: _currentUserId,
        FirebaseFields.receiverId: targetUserId,
        FirebaseFields.status: FriendRequestStatus.pending,
        FirebaseFields.createdAt: FieldValue.serverTimestamp(),
      });

      await refreshSearch();
      return null;
    } on FirebaseException catch (error) {
      return error.message ?? 'Unable to send friend request.';
    } catch (_) {
      return 'Unable to send friend request.';
    } finally {
      _sendingRequestUserIds.remove(targetUserId);
      notifyListeners();
    }
  }

  Future<String?> acceptFriendRequest({
    required String requestId,
    required String senderId,
  }) async {
    if (_currentUserId.isEmpty) {
      return 'Please sign in again.';
    }
    if (_processingRequestIds.contains(requestId)) {
      return null;
    }
    _processingRequestIds.add(requestId);

    try {
      final String friendshipId = _friendshipId(_currentUserId, senderId);
      final WriteBatch batch = _firestore.batch();

      final DocumentReference<Map<String, dynamic>> requestDoc = _firestore
          .collection(FirebaseCollections.friendRequests)
          .doc(requestId);
      final DocumentReference<Map<String, dynamic>> friendDoc = _firestore
          .collection(FirebaseCollections.friends)
          .doc(friendshipId);

      batch.update(requestDoc, <String, dynamic>{
        FirebaseFields.status: FriendRequestStatus.accepted,
      });
      batch.set(friendDoc, <String, dynamic>{
        FirebaseFields.participants: <String>[_currentUserId, senderId]..sort(),
        FirebaseFields.createdAt: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
      await refreshSearch();
      return null;
    } on FirebaseException catch (error) {
      return error.message ?? 'Unable to accept request.';
    } catch (_) {
      return 'Unable to accept request.';
    } finally {
      _processingRequestIds.remove(requestId);
    }
  }

  Future<String?> rejectFriendRequest({required String requestId}) async {
    if (_processingRequestIds.contains(requestId)) {
      return null;
    }
    _processingRequestIds.add(requestId);

    try {
      await _firestore
          .collection(FirebaseCollections.friendRequests)
          .doc(requestId)
          .update(<String, dynamic>{
            FirebaseFields.status: FriendRequestStatus.rejected,
          });
      await refreshSearch();
      return null;
    } on FirebaseException catch (error) {
      return error.message ?? 'Unable to reject request.';
    } catch (_) {
      return 'Unable to reject request.';
    } finally {
      _processingRequestIds.remove(requestId);
    }
  }

  Future<void> refreshSearch() async {
    if (_searchQuery.isEmpty) {
      return;
    }
    await searchUsers(_searchQuery);
  }

  Future<Map<String, String>> _resolveConnectionStatuses(
    List<String> targetUserIds,
  ) async {
    if (targetUserIds.isEmpty || _currentUserId.isEmpty) {
      return <String, String>{};
    }

    final QuerySnapshot<Map<String, dynamic>> friendsSnapshot = await _firestore
        .collection(FirebaseCollections.friends)
        .where(FirebaseFields.participants, arrayContains: _currentUserId)
        .get();

    final QuerySnapshot<Map<String, dynamic>> sentSnapshot = await _firestore
        .collection(FirebaseCollections.friendRequests)
        .where(FirebaseFields.senderId, isEqualTo: _currentUserId)
        .where(FirebaseFields.status, isEqualTo: FriendRequestStatus.pending)
        .get();

    final QuerySnapshot<Map<String, dynamic>> receivedSnapshot =
        await _firestore
            .collection(FirebaseCollections.friendRequests)
            .where(FirebaseFields.receiverId, isEqualTo: _currentUserId)
            .where(
              FirebaseFields.status,
              isEqualTo: FriendRequestStatus.pending,
            )
            .get();

    final Set<String> friendIds = <String>{};
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in friendsSnapshot.docs) {
      final List<dynamic> participants =
          (doc.data()[FirebaseFields.participants] as List<dynamic>?) ??
          <dynamic>[];
      for (final dynamic item in participants) {
        if (item is String && item != _currentUserId) {
          friendIds.add(item);
        }
      }
    }

    final Set<String> sentIds = sentSnapshot.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
          return (doc.data()[FirebaseFields.receiverId] as String?) ?? '';
        })
        .where((String id) => id.isNotEmpty)
        .toSet();

    final Set<String> receivedIds = receivedSnapshot.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
          return (doc.data()[FirebaseFields.senderId] as String?) ?? '';
        })
        .where((String id) => id.isNotEmpty)
        .toSet();

    final Map<String, String> statuses = <String, String>{};
    for (final String userId in targetUserIds) {
      if (friendIds.contains(userId)) {
        statuses[userId] = _statusFriend;
      } else if (sentIds.contains(userId)) {
        statuses[userId] = _statusSent;
      } else if (receivedIds.contains(userId)) {
        statuses[userId] = _statusReceived;
      } else {
        statuses[userId] = _statusNone;
      }
    }
    return statuses;
  }

  Future<List<Map<String, dynamic>>> _mapRequestsWithUser({
    required QuerySnapshot<Map<String, dynamic>> snapshot,
    required bool fromSender,
  }) async {
    final List<Map<String, dynamic>> mapped = <Map<String, dynamic>>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> requestDoc
        in snapshot.docs) {
      final Map<String, dynamic> data = requestDoc.data();
      final String otherUserId = fromSender
          ? ((data[FirebaseFields.senderId] as String?) ?? '')
          : ((data[FirebaseFields.receiverId] as String?) ?? '');
      final Map<String, dynamic> userData = await _getUserData(otherUserId);
      mapped.add(<String, dynamic>{
        ...data,
        'requestId': requestDoc.id,
        FirebaseFields.userId: otherUserId,
        FirebaseFields.name:
            (userData[FirebaseFields.name] as String?) ?? 'Unknown User',
        FirebaseFields.username:
            (userData[FirebaseFields.username] as String?) ?? '',
        FirebaseFields.profilePic:
            (userData[FirebaseFields.profilePic] as String?) ?? '',
        FirebaseFields.isOnline:
            (userData[FirebaseFields.isOnline] as bool?) ?? false,
      });
    }

    mapped.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      final DateTime aTime = _toDateTime(a[FirebaseFields.createdAt]);
      final DateTime bTime = _toDateTime(b[FirebaseFields.createdAt]);
      return bTime.compareTo(aTime);
    });
    return mapped;
  }

  Future<Map<String, dynamic>> _getUserData(String userId) async {
    if (userId.isEmpty) {
      return <String, dynamic>{};
    }
    if (_userCache.containsKey(userId)) {
      return _userCache[userId]!;
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection(FirebaseCollections.users)
        .doc(userId)
        .get();
    final Map<String, dynamic> data = snapshot.data() ?? <String, dynamic>{};
    _userCache[userId] = data;
    return data;
  }

  DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _friendshipId(String first, String second) {
    final List<String> ids = <String>[first, second]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  String _capitalize(String value) {
    final String clean = value.trim();
    if (clean.isEmpty) {
      return clean;
    }
    return clean[0].toUpperCase() + clean.substring(1).toLowerCase();
  }

  @override
  void dispose() {
    _receivedRequestCountSubscription?.cancel();
    super.dispose();
  }
}
