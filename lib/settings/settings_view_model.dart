import 'package:flutter/foundation.dart';

import '../auth/sign_in/sign_in_view_model.dart';

class SettingsViewModel extends ChangeNotifier {
  bool _isSigningOut = false;
  String? _errorMessage;

  String get screenTitle => 'Settings';
  bool get isSigningOut => _isSigningOut;
  String? get errorMessage => _errorMessage;

  final List<Map<String, dynamic>> _settingsItems = <Map<String, dynamic>>[
    <String, dynamic>{
      'title': 'Notifications',
      'subtitle': 'Manage message and request alerts',
      'icon': 'notifications',
    },
    <String, dynamic>{
      'title': 'Privacy',
      'subtitle': 'Control who can find and message you',
      'icon': 'privacy',
    },
    <String, dynamic>{
      'title': 'Storage',
      'subtitle': 'Review images and cached chat data',
      'icon': 'storage',
    },
  ];

  List<Map<String, dynamic>> get settingsItems =>
      List<Map<String, dynamic>>.unmodifiable(_settingsItems);

  Future<bool> signOut() async {
    if (_isSigningOut) {
      return false;
    }

    _isSigningOut = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await SignInViewModel().signOut();
      return true;
    } catch (_) {
      _errorMessage = 'Unable to sign out right now.';
      return false;
    } finally {
      _isSigningOut = false;
      notifyListeners();
    }
  }
}
