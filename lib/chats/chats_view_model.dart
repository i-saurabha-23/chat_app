import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_session_manager.dart';
import '../constants/firebase_constants.dart';
import '../utils/message_encryption.dart';

class ChatsViewModel extends ChangeNotifier {
  ChatsViewModel({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  bool _isInitializing = true;
  String? _errorMessage;
  String _currentUserId = '';
  final Map<String, Map<String, dynamic>> _userCache =
      <String, Map<String, dynamic>>{};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _deliveredSubscription;

  bool get isInitializing => _isInitializing;
  String? get errorMessage => _errorMessage;
  String get screenTitle => 'Chats';
  String get currentUserId => _currentUserId;

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
        await _listenForDeliveredMessages();
      }
    } catch (_) {
      _errorMessage = 'Unable to load chats.';
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Stream<List<Map<String, dynamic>>> friendsStream() {
    if (_currentUserId.isEmpty) {
      return Stream<List<Map<String, dynamic>>>.value(
        const <Map<String, dynamic>>[],
      );
    }

    return _firestore
        .collection(FirebaseCollections.friends)
        .where(FirebaseFields.participants, arrayContains: _currentUserId)
        .snapshots()
        .asyncMap(_mapFriendsSnapshot);
  }

  Stream<Map<String, dynamic>> chatTileStream({
    required Map<String, dynamic> friend,
  }) {
    final String friendId = ((friend[FirebaseFields.userId] as String?) ?? '')
        .trim();
    if (friendId.isEmpty) {
      return Stream<Map<String, dynamic>>.value(friend);
    }

    final String chatId = chatIdForFriend(friendId);

    return _firestore
        .collection(FirebaseCollections.chats)
        .doc(chatId)
        .snapshots()
        .asyncMap((DocumentSnapshot<Map<String, dynamic>> snapshot) async {
          final Map<String, dynamic> chatData =
              snapshot.data() ?? <String, dynamic>{};
          final Map<String, dynamic> unreadCounts =
              (chatData[FirebaseFields.unreadCounts]
                  as Map<String, dynamic>?) ??
              <String, dynamic>{};

          final dynamic unreadRaw = unreadCounts[_currentUserId];
          int unreadCount = _toInt(unreadRaw);
          if (unreadCount <= 0) {
            unreadCount = await _fetchUnreadCountFromMessages(chatId);
          }

          final DateTime? lastMessageTime = _toDateTime(
            chatData[FirebaseFields.lastMessageTime],
          );
          final String encryptedLastMessage =
              (chatData[FirebaseFields.lastMessage] as String?) ?? '';
          final String lastMessageIv =
              (chatData[FirebaseFields.lastMessageIv] as String?) ?? '';
          final String friendName =
              ((friend[FirebaseFields.name] as String?) ?? '').trim().isNotEmpty
              ? (friend[FirebaseFields.name] as String)
              : ((friend[FirebaseFields.username] as String?) ??
                    'Unknown User');

          final String decryptedLastMessage = MessageEncryption.decryptText(
            cipherText: encryptedLastMessage,
            ivBase64: lastMessageIv,
            fallbackToRawWhenInvalid: true,
          );

          return <String, dynamic>{
            ...friend,
            'chatId': chatId,
            'friendId': friendId,
            'friendName': friendName,
            'lastMessage': decryptedLastMessage.trim().isEmpty
                ? 'Start chatting with $friendName'
                : decryptedLastMessage,
            'lastMessageTime': lastMessageTime,
            'unreadCount': unreadCount,
          };
        });
  }

  Stream<Map<String, dynamic>> friendProfileStream(String friendId) {
    if (friendId.trim().isEmpty) {
      return Stream<Map<String, dynamic>>.value(<String, dynamic>{});
    }

    return _firestore
        .collection(FirebaseCollections.users)
        .doc(friendId)
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> snapshot) {
          final Map<String, dynamic> data =
              snapshot.data() ?? <String, dynamic>{};
          return <String, dynamic>{
            ...data,
            FirebaseFields.userId:
                (data[FirebaseFields.userId] as String?) ?? friendId,
          };
        });
  }

  String chatIdForFriend(String friendId) {
    final List<String> ids = <String>[_currentUserId, friendId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<List<Map<String, dynamic>>> _mapFriendsSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    final List<Map<String, dynamic>> friends = <Map<String, dynamic>>[];

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in snapshot.docs) {
      final List<dynamic> participants =
          (doc.data()[FirebaseFields.participants] as List<dynamic>?) ??
          <dynamic>[];
      final String friendId = participants.whereType<String>().firstWhere(
        (String id) => id != _currentUserId,
        orElse: () => '',
      );
      if (friendId.isEmpty) {
        continue;
      }

      final Map<String, dynamic> userData = await _getUser(friendId);
      friends.add(<String, dynamic>{
        FirebaseFields.userId: friendId,
        FirebaseFields.name: (userData[FirebaseFields.name] as String?) ?? '',
        FirebaseFields.username:
            (userData[FirebaseFields.username] as String?) ?? '',
        FirebaseFields.profilePic:
            (userData[FirebaseFields.profilePic] as String?) ?? '',
        FirebaseFields.isOnline:
            (userData[FirebaseFields.isOnline] as bool?) ?? false,
      });
    }

    friends.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      final String nameA = ((a[FirebaseFields.name] as String?) ?? '')
          .toLowerCase();
      final String nameB = ((b[FirebaseFields.name] as String?) ?? '')
          .toLowerCase();
      return nameA.compareTo(nameB);
    });

    return friends;
  }

  Future<Map<String, dynamic>> _getUser(String userId) async {
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

  Future<void> _listenForDeliveredMessages() async {
    await _deliveredSubscription?.cancel();
    _deliveredSubscription = _firestore
        .collectionGroup(FirebaseCollections.messages)
        .where(FirebaseFields.receiverId, isEqualTo: _currentUserId)
        .where(FirebaseFields.status, isEqualTo: MessageStatus.sent)
        .snapshots()
        .listen((QuerySnapshot<Map<String, dynamic>> snapshot) async {
          if (snapshot.docs.isEmpty) {
            return;
          }

          final WriteBatch batch = _firestore.batch();
          for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
              in snapshot.docs) {
            batch.update(doc.reference, <String, dynamic>{
              FirebaseFields.status: MessageStatus.delivered,
            });
          }
          await batch.commit();
        });
  }

  DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  Future<int> _fetchUnreadCountFromMessages(String chatId) async {
    if (_currentUserId.isEmpty || chatId.trim().isEmpty) {
      return 0;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection(FirebaseCollections.chats)
          .doc(chatId)
          .collection(FirebaseCollections.messages)
          .where(FirebaseFields.receiverId, isEqualTo: _currentUserId)
          .where(
            FirebaseFields.status,
            whereIn: <String>[MessageStatus.sent, MessageStatus.delivered],
          )
          .get();
      return snapshot.docs.length;
    } catch (_) {
      return 0;
    }
  }

  @override
  void dispose() {
    _deliveredSubscription?.cancel();
    super.dispose();
  }
}
