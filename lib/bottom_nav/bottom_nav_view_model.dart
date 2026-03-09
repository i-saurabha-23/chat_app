import 'package:flutter/foundation.dart';

class BottomNavViewModel extends ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void selectTab(int index) {
    if (index == _selectedIndex) {
      return;
    }
    _selectedIndex = index;
    notifyListeners();
  }
}
