import 'package:flutter/foundation.dart';

class FriendsViewModel extends ChangeNotifier {
  String get screenTitle => 'Friends';

  final List<Map<String, dynamic>> _users = <Map<String, dynamic>>[
    <String, dynamic>{
      'username': 'alex_07',
      'name': 'Alex',
      'isOnline': true,
      'isFriend': false,
    },
    <String, dynamic>{
      'username': 'sophia_ui',
      'name': 'Sophia',
      'isOnline': false,
      'isFriend': true,
    },
    <String, dynamic>{
      'username': 'ethan.codes',
      'name': 'Ethan',
      'isOnline': true,
      'isFriend': false,
    },
  ];

  List<Map<String, dynamic>> get users =>
      List<Map<String, dynamic>>.unmodifiable(_users);

  bool isFriend(String username) {
    final int index = _users.indexWhere(
      (Map<String, dynamic> user) => user['username'] == username,
    );
    if (index == -1) {
      return false;
    }
    return _users[index]['isFriend'] as bool? ?? false;
  }

  void addFriend(String username) {
    final int index = _users.indexWhere(
      (Map<String, dynamic> user) => user['username'] == username,
    );
    if (index == -1) {
      return;
    }
    _users[index]['isFriend'] = true;
    notifyListeners();
  }
}
