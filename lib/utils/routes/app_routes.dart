import 'package:flutter/material.dart';
import '../../features/home/presentation/dishcovery_home_page.dart';
import '../../features/capture/presentation/capture_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../core/navigation/main_navigation.dart';
import '../../features/examples/ai_logic_example_screen.dart';

class AppRoutes {
  // Route names
  static const String main = '/';
  static const String home = '/home';
  static const String capture = '/capture';
  static const String history = '/history';
  static const String settings = '/settings';
  static const String result = '/result';
  static const String aiExample = '/ai-example';

  // Route generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case main:
        return MaterialPageRoute(builder: (_) => const MainNavigation());
      case home:
        return MaterialPageRoute(builder: (_) => const DishcoveryHomePage());
      case capture:
        return MaterialPageRoute(builder: (_) => const CaptureScreen());
      case history:
        return MaterialPageRoute(builder: (_) => const HistoryScreen());
      case result:
        final args = settings.arguments as Map<String, dynamic>?;
        final imagePath = args?['imagePath'] ?? '';
        return MaterialPageRoute(
          builder: (_) => ResultScreen(imagePath: imagePath),
      case aiExample:
        return MaterialPageRoute(
          builder: (_) => const AiLogicExampleScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Page not found'))),
        );
    }
  }

  // Navigation helper methods
  static Future<void> pushToCapture(BuildContext context) async {
    await Navigator.of(context).pushNamed(capture);
  }

  static Future<void> pushToHistory(BuildContext context) async {
    await Navigator.of(context).pushNamed(history);
  }

  static Future<void> pushToSettings(BuildContext context) async {
    await Navigator.of(context).pushNamed(settings);
  }

  static Future<void> pushToResult(
    BuildContext context, {
    Map<String, dynamic>? arguments,
  }) async {
    await Navigator.of(context).pushNamed(result, arguments: arguments);
  }

  static void pop(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  static void popUntilRoot(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  static void popUntilRoute(BuildContext context, String routeName) {
    Navigator.of(context).popUntil(ModalRoute.withName(routeName));
  }
}
