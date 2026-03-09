import 'package:flutter/foundation.dart';

import '../auth/auth_session_manager.dart';

class ProfileViewModel extends ChangeNotifier {
  bool _isLoading = true;
  String _name = 'Guest User';
  String _username = 'guest_user';
  String _userId = '-';

  bool get isLoading => _isLoading;
  String get screenTitle => 'Profile';
  String get name => _name;
  String get username => _username;
  String get userId => _userId;

  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();

    final String? name = await AuthSessionManager.getName();
    final String? username = await AuthSessionManager.getUsername();
    final String? userId = await AuthSessionManager.getUserId();

    _name = (name == null || name.trim().isEmpty) ? 'Guest User' : name;
    _username = (username == null || username.trim().isEmpty)
        ? 'guest_user'
        : username;
    _userId = (userId == null || userId.trim().isEmpty) ? '-' : userId;
    _isLoading = false;
    notifyListeners();
  }
}
