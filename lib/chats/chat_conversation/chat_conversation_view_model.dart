import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../auth/auth_session_manager.dart';
import '../../constants/firebase_constants.dart';
import '../../utils/message_encryption.dart';

class ChatConversationViewModel extends ChangeNotifier {
  ChatConversationViewModel({
    required this.friendData,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final Map<String, dynamic> friendData;
  final FirebaseFirestore _firestore;

  bool _isInitializing = true;
  bool _isSending = false;
  bool _isFriendTyping = false;
  bool _isMarkingRead = false;
  bool _lastTypingState = false;
  String? _errorMessage;
  String _currentUserId = '';
  String _friendId = '';
  String _chatId = '';
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _typingSubscription;

  bool get isInitializing => _isInitializing;
  bool get isSending => _isSending;
  bool get isFriendTyping => _isFriendTyping;
  String? get errorMessage => _errorMessage;
  String get currentUserId => _currentUserId;
  String get friendId => _friendId;
  String get chatId => _chatId;

  String get friendName =>
      ((friendData[FirebaseFields.name] as String?) ?? '').trim().isNotEmpty
      ? (friendData[FirebaseFields.name] as String)
      : (((friendData[FirebaseFields.username] as String?) ?? 'Friend').trim());
  String get friendUsername =>
      ((friendData[FirebaseFields.username] as String?) ?? '').trim();
  String get friendProfilePic =>
      ((friendData[FirebaseFields.profilePic] as String?) ?? '').trim();
  bool get friendIsOnline =>
      (friendData[FirebaseFields.isOnline] as bool?) ?? false;

  Future<void> initialize() async {
    _isInitializing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String? userId = await AuthSessionManager.getUserId();
      final String friendId =
          ((friendData[FirebaseFields.userId] as String?) ?? '').trim();
      if (userId == null || userId.isEmpty || friendId.isEmpty) {
        _errorMessage = 'Unable to open this conversation.';
      } else {
        _currentUserId = userId;
        _friendId = friendId;
        _chatId = _buildChatId(_currentUserId, _friendId);
        await _listenFriendTyping();
        await _markAllIncomingAsRead();
      }
    } catch (_) {
      _errorMessage = 'Unable to open this conversation.';
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> messagesStream() {
    if (_chatId.isEmpty) {
      return Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>.value(
        const <QueryDocumentSnapshot<Map<String, dynamic>>>[],
      );
    }

    return _firestore
        .collection(FirebaseCollections.chats)
        .doc(_chatId)
        .collection(FirebaseCollections.messages)
        .orderBy(FirebaseFields.timestamp, descending: false)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs);
  }

  Stream<Map<String, dynamic>> friendProfileStream() {
    if (_friendId.isEmpty) {
      return Stream<Map<String, dynamic>>.value(friendData);
    }

    return _firestore
        .collection(FirebaseCollections.users)
        .doc(_friendId)
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> snapshot) {
          final Map<String, dynamic> data =
              snapshot.data() ?? <String, dynamic>{};
          return <String, dynamic>{
            ...friendData,
            ...data,
            FirebaseFields.userId: _friendId,
          };
        });
  }

  Future<String?> sendMessage(String text) async {
    final String message = text.trim();
    if (message.isEmpty) {
      return null;
    }
    if (_chatId.isEmpty || _currentUserId.isEmpty || _friendId.isEmpty) {
      return 'Unable to send message.';
    }

    _isSending = true;
    notifyListeners();

    try {
      final Map<String, String> encryptedPayload =
          MessageEncryption.encryptText(message);

      final DocumentReference<Map<String, dynamic>> chatRef = _firestore
          .collection(FirebaseCollections.chats)
          .doc(_chatId);
      final DocumentReference<Map<String, dynamic>> messageRef = chatRef
          .collection(FirebaseCollections.messages)
          .doc();

      final WriteBatch batch = _firestore.batch();

      batch.set(chatRef, <String, dynamic>{
        FirebaseFields.participants: <String>[_currentUserId, _friendId]
          ..sort(),
        FirebaseFields.lastMessage: encryptedPayload['cipherText'],
        FirebaseFields.lastMessageIv: encryptedPayload['iv'],
        FirebaseFields.lastMessageSender: _currentUserId,
        FirebaseFields.lastMessageTime: FieldValue.serverTimestamp(),
        '${FirebaseFields.unreadCounts}.$_friendId': FieldValue.increment(1),
        '${FirebaseFields.unreadCounts}.$_currentUserId': 0,
      }, SetOptions(merge: true));

      batch.set(messageRef, <String, dynamic>{
        FirebaseFields.senderId: _currentUserId,
        FirebaseFields.receiverId: _friendId,
        FirebaseFields.text: encryptedPayload['cipherText'],
        FirebaseFields.iv: encryptedPayload['iv'],
        FirebaseFields.timestamp: FieldValue.serverTimestamp(),
        FirebaseFields.status: MessageStatus.sent,
      });

      await batch.commit();
      await setTyping('');
      return null;
    } on FirebaseException catch (error) {
      return error.message ?? 'Unable to send message.';
    } catch (_) {
      return 'Unable to send message.';
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> setTyping(String value) async {
    if (_chatId.isEmpty || _currentUserId.isEmpty) {
      return;
    }

    final bool isTyping = value.trim().isNotEmpty;
    if (_lastTypingState == isTyping) {
      return;
    }
    _lastTypingState = isTyping;

    await _firestore
        .collection(FirebaseCollections.chats)
        .doc(_chatId)
        .collection(FirebaseCollections.typing)
        .doc(_currentUserId)
        .set(<String, dynamic>{
          FirebaseFields.userId: _currentUserId,
          FirebaseFields.isTyping: isTyping,
          FirebaseFields.updatedAt: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true))
        .catchError((_) {});
  }

  Future<void> handleVisibleMessages(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    if (_chatId.isEmpty || _currentUserId.isEmpty || _isMarkingRead) {
      return;
    }

    final List<QueryDocumentSnapshot<Map<String, dynamic>>> incoming = docs
        .where((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
          final Map<String, dynamic> data = doc.data();
          final String receiver =
              (data[FirebaseFields.receiverId] as String?) ?? '';
          final String status = (data[FirebaseFields.status] as String?) ?? '';
          return receiver == _currentUserId && status != MessageStatus.read;
        })
        .toList();

    if (incoming.isEmpty) {
      return;
    }

    _isMarkingRead = true;
    try {
      final WriteBatch batch = _firestore.batch();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in incoming) {
        batch.update(doc.reference, <String, dynamic>{
          FirebaseFields.status: MessageStatus.read,
        });
      }

      batch.set(
        _firestore.collection(FirebaseCollections.chats).doc(_chatId),
        <String, dynamic>{'${FirebaseFields.unreadCounts}.$_currentUserId': 0},
        SetOptions(merge: true),
      );

      await batch.commit();
    } catch (_) {
    } finally {
      _isMarkingRead = false;
    }
  }

  Future<void> _markAllIncomingAsRead() async {
    if (_chatId.isEmpty || _currentUserId.isEmpty) {
      return;
    }

    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection(FirebaseCollections.chats)
        .doc(_chatId)
        .collection(FirebaseCollections.messages)
        .where(FirebaseFields.receiverId, isEqualTo: _currentUserId)
        .where(
          FirebaseFields.status,
          whereIn: <String>[MessageStatus.sent, MessageStatus.delivered],
        )
        .get();

    if (snapshot.docs.isEmpty) {
      await _firestore.collection(FirebaseCollections.chats).doc(_chatId).set({
        '${FirebaseFields.unreadCounts}.$_currentUserId': 0,
      }, SetOptions(merge: true));
      return;
    }

    final WriteBatch batch = _firestore.batch();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in snapshot.docs) {
      batch.update(doc.reference, <String, dynamic>{
        FirebaseFields.status: MessageStatus.read,
      });
    }
    batch.set(
      _firestore.collection(FirebaseCollections.chats).doc(_chatId),
      <String, dynamic>{'${FirebaseFields.unreadCounts}.$_currentUserId': 0},
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<void> _listenFriendTyping() async {
    await _typingSubscription?.cancel();
    _typingSubscription = _firestore
        .collection(FirebaseCollections.chats)
        .doc(_chatId)
        .collection(FirebaseCollections.typing)
        .doc(_friendId)
        .snapshots()
        .listen((DocumentSnapshot<Map<String, dynamic>> snapshot) {
          final bool isTyping =
              (snapshot.data()?[FirebaseFields.isTyping] as bool?) ?? false;
          if (_isFriendTyping == isTyping) {
            return;
          }
          _isFriendTyping = isTyping;
          notifyListeners();
        });
  }

  String _buildChatId(String first, String second) {
    final List<String> ids = <String>[first, second]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  @override
  void dispose() {
    setTyping('');
    _typingSubscription?.cancel();
    super.dispose();
  }
}
