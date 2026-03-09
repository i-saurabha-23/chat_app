import 'package:flutter/foundation.dart';

class ChatsViewModel extends ChangeNotifier {
  String get screenTitle => 'Chats';

  final List<Map<String, dynamic>> _chatItems = <Map<String, dynamic>>[
    <String, dynamic>{
      'friendName': 'Alex',
      'lastMessage': 'See you at 6 PM',
      'lastMessageTime': DateTime.now().subtract(const Duration(minutes: 4)),
      'unreadCount': 2,
      'isOnline': true,
    },
    <String, dynamic>{
      'friendName': 'Sophia',
      'lastMessage': 'Shared the document with you',
      'lastMessageTime': DateTime.now().subtract(const Duration(hours: 1)),
      'unreadCount': 0,
      'isOnline': false,
    },
    <String, dynamic>{
      'friendName': 'Ethan',
      'lastMessage': 'Let us catch up tomorrow',
      'lastMessageTime': DateTime.now().subtract(const Duration(days: 1)),
      'unreadCount': 1,
      'isOnline': true,
    },
  ];

  List<Map<String, dynamic>> get chatItems =>
      List<Map<String, dynamic>>.unmodifiable(_chatItems);
}
