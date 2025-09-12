import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'navigation_models.dart';

class NavigationService extends NavigationServiceBase {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  // Controllers dan keys
  PersistentTabController? _tabController;
  GlobalKey<NavigatorState>? _navigatorKey;

  // Current state
  NavigationTab _currentTab = NavigationTab.home;

  // Callbacks untuk komunikasi dengan UI
  VoidCallback? _onTabChanged;

  // Initialize service dengan controllers
  void initialize({
    required PersistentTabController tabController,
    required GlobalKey<NavigatorState> navigatorKey,
    VoidCallback? onTabChanged,
  }) {
    _tabController = tabController;
    _navigatorKey = navigatorKey;
    _onTabChanged = onTabChanged;
    _currentTab = NavigationTab.values[tabController.index];
  }

  @override
  void navigateToTab(NavigationTab tab) {
    if (_tabController == null) {
      debugPrint('NavigationService: TabController not initialized');
      return;
    }

    final tabIndex = tab.tabIndex;
    if (tabIndex != _tabController!.index) {
      _currentTab = tab;
      _tabController!.jumpToTab(tabIndex);
      _onTabChanged?.call();
      debugPrint('NavigationService: Navigated to ${tab.name} tab');
    }
  }

  @override
  void pop() {
    if (_navigatorKey?.currentState?.canPop() == true) {
      _navigatorKey!.currentState!.pop();
    } else {
      // Jika tidak bisa pop, kembali ke home tab
      navigateToTab(NavigationTab.home);
    }
  }

  @override
  void popToRoot() {
    if (_navigatorKey?.currentState != null) {
      _navigatorKey!.currentState!.popUntil((route) => route.isFirst);
    }
    navigateToTab(NavigationTab.home);
  }

  @override
  NavigationTab get currentTab => _currentTab;

  // Update current tab (dipanggil dari MainNavigation saat tab berubah)
  void updateCurrentTab(int index) {
    if (index >= 0 && index < NavigationTab.values.length) {
      _currentTab = NavigationTab.values[index];
    }
  }

  // Navigation helpers
  BuildContext? get context => _navigatorKey?.currentContext;

  bool get canPop => _navigatorKey?.currentState?.canPop() == true;

  // Push ke route tertentu
  Future<T?> pushNamed<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) async {
    return _navigatorKey?.currentState?.pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }

  // Push dan replace
  Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    Object? arguments,
    TO? result,
  }) async {
    return _navigatorKey?.currentState?.pushReplacementNamed<T, TO>(
      routeName,
      arguments: arguments,
      result: result,
    );
  }

  // Push dan hapus semua route sebelumnya
  Future<T?> pushNamedAndClearStack<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) async {
    return _navigatorKey?.currentState?.pushNamedAndRemoveUntil<T>(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  // Convenience methods untuk navigasi cepat ke tab tertentu
  void goToHome() => navigateToTab(NavigationTab.home);
  void goToHistory() => navigateToTab(NavigationTab.history);
  void goToSettings() => navigateToTab(NavigationTab.settings);

  // Show dialogs dan bottom sheets
  Future<T?> showAppDialog<T>({
    required Widget dialog,
    bool barrierDismissible = true,
  }) async {
    if (context == null) return null;
    return showDialog<T>(
      context: context!,
      barrierDismissible: barrierDismissible,
      builder: (_) => dialog,
    );
  }

  Future<T?> showAppBottomSheet<T>({
    required Widget bottomSheet,
    bool isScrollControlled = false,
  }) async {
    if (context == null) return null;
    return showModalBottomSheet<T>(
      context: context!,
      isScrollControlled: isScrollControlled,
      builder: (_) => bottomSheet,
    );
  }

  // Show snackbar
  void showSnackBar(
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (context == null) return;
    ScaffoldMessenger.of(context!).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
      ),
    );
  }

  // Cleanup
  void dispose() {
    _tabController = null;
    _navigatorKey = null;
    _onTabChanged = null;
  }
}

// Base class untuk interface
abstract class NavigationServiceBase {
  void navigateToTab(NavigationTab tab);
  void pop();
  void popToRoot();
  NavigationTab get currentTab;
}
