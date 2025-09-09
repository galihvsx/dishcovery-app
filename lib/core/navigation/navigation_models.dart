import 'package:flutter/material.dart';

enum NavigationTab { home, capture, history }

class NavigationItem {
  final IconData icon;
  final String title;
  final NavigationTab tab;
  final Widget screen;

  const NavigationItem({
    required this.icon,
    required this.title,
    required this.tab,
    required this.screen,
  });
}

abstract class NavigationService {
  void navigateToTab(NavigationTab tab);
  void pop();
  void popToRoot();
  NavigationTab get currentTab;
}
