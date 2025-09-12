import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import '../../features/home/presentation/dishcovery_home_page.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/settings/presentation/setting_screen.dart';
import '../../utils/constants/navigation_constants.dart';
import 'navigation_models.dart';
import 'navigation_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late PersistentTabController _controller;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(
      initialIndex: NavigationConstants.homeTabIndex,
    );

    // Initialize NavigationService
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NavigationService().initialize(
        tabController: _controller,
        navigatorKey: _navigatorKey,
        onTabChanged: () {
          if (mounted) setState(() {});
        },
      );
    });
  }

  // Configuration for navigation items
  List<NavigationItem> get _navigationItems => [
    const NavigationItem(
      icon: Icons.home,
      title: 'Home',
      tab: NavigationTab.home,
      screen: DishcoveryHomePage(),
    ),
    const NavigationItem(
      icon: Icons.history,
      title: 'History',
      tab: NavigationTab.history,
      screen: HistoryScreen(),
    ),
    const NavigationItem(
      icon: Icons.settings,
      title: 'Settings',
      tab: NavigationTab.settings,
      screen: SettingScreen(),
    ),
  ];

  List<PersistentTabConfig> _buildTabs(BuildContext context) {
    final theme = Theme.of(context);

    return _navigationItems.map((item) {
      return PersistentTabConfig(
        screen: item.screen,
        item: ItemConfig(
          icon: Icon(item.icon, size: NavigationConstants.iconSize),
          title: item.title,
          activeForegroundColor: theme.primaryColor,
          inactiveForegroundColor: Colors.grey,
          textStyle: TextStyle(
            fontSize: NavigationConstants.navBarTextSize,
            fontWeight: FontWeight.w500,
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
      navBarBuilder: (navBarConfig) => Style3BottomNavBar(
        navBarConfig: navBarConfig,
        navBarDecoration: NavBarDecoration(
          color:
              theme.bottomNavigationBarTheme.backgroundColor ??
              theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.dividerColor.withAlpha(
                (NavigationConstants.borderOpacity * 255).round(),
              ),
              width: NavigationConstants.borderWidth,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withAlpha((0.08 * 255).round()),
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
      onTabChanged: (index) {
        // Update NavigationService dengan tab yang baru
        NavigationService().updateCurrentTab(index);
      },
    );
  }

  @override
  void dispose() {
    NavigationService().dispose();
    _controller.dispose();
    super.dispose();
  }
}
