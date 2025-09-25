import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/theme.dart';
import 'providers/theme_provider.dart';
import 'utils/routes/app_routes.dart';
import 'features/history/providers/history_provider.dart';

class App extends StatelessWidget {
  final SharedPreferences preferences;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  App({super.key, required this.preferences});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(preferences)),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Dishcovery',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            onGenerateRoute: AppRoutes.generateRoute,
            initialRoute: AppRoutes.main,
          );
        },
      ),
    );
  }
}
