import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/capture/presentation/capture_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../utils/constants/navigation_constants.dart';
import 'navigation_models.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late PersistentTabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(
      initialIndex: NavigationConstants.homeTabIndex,
    );
  }

  // Configuration for navigation items
  List<NavigationItem> get _navigationItems => [
    const NavigationItem(
      icon: Icons.home,
      title: 'Home',
      tab: NavigationTab.home,
      screen: HomeScreen(),
    ),
    const NavigationItem(
      icon: Icons.camera_alt,
      title: 'Capture',
      tab: NavigationTab.capture,
      screen: CaptureScreen(),
    ),
    const NavigationItem(
      icon: Icons.history,
      title: 'History',
      tab: NavigationTab.history,
      screen: HistoryScreen(),
    ),
  ];

  List<PersistentTabConfig> _buildTabs(BuildContext context) {
    final theme = Theme.of(context);

    return _navigationItems.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;

      // Special styling for center tab (Capture)
      final isCenter = index == NavigationConstants.captureTabIndex;

      return PersistentTabConfig(
        screen: item.screen,
        item: ItemConfig(
          icon: Icon(
            item.icon,
            size: isCenter
                ? NavigationConstants.iconSize + 4
                : NavigationConstants.iconSize,
          ),
          title: item.title,
          activeForegroundColor: theme.primaryColor,
          inactiveForegroundColor: Colors.grey,
          textStyle: TextStyle(
            fontSize: NavigationConstants.navBarTextSize,
            fontWeight: isCenter ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PersistentTabView(
      tabs: _buildTabs(context),
      navBarBuilder: (navBarConfig) => Style15BottomNavBar(
        navBarConfig: navBarConfig,
        navBarDecoration: NavBarDecoration(
          color:
              theme.bottomNavigationBarTheme.backgroundColor ??
              theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.dividerColor.withOpacity(
                NavigationConstants.borderOpacity,
              ),
              width: NavigationConstants.borderWidth,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
      ),
      controller: _controller,
      backgroundColor: theme.scaffoldBackgroundColor,
      handleAndroidBackButtonPress: true,
      resizeToAvoidBottomInset: true,
      stateManagement: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
