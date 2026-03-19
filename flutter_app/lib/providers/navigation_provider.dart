import 'package:flutter/material.dart';
import 'package:jarvis_ui/theme/jarvis_theme.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentTab = 0;

  int get currentTab => _currentTab;
  Color get sectionColor => JarvisTheme.sectionColorFor(_currentTab);
  String get sectionName => JarvisTheme.sectionNameFor(_currentTab);

  double get sidebarWidth => switch (_currentTab) {
        0 => 64, // Chat — minimal, maximize chat space
        1 => 48, // Dashboard — nearly hidden, robot office needs space
        2 => 180, // Skills
        3 => 260, // Admin — expanded with sub-navigation
        4 => 180, // Identity
        _ => 180,
      };

  void setTab(int index) {
    if (index != _currentTab) {
      _currentTab = index;
      notifyListeners();
    }
  }
}
