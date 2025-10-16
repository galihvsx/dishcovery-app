import 'package:dishcovery_app/core/database/objectbox_database.dart';
import 'package:dishcovery_app/core/services/user_preferences_service.dart';
import 'package:dishcovery_app/core/theme/theme.dart';
import 'package:dishcovery_app/providers/auth_provider.dart';
import 'package:dishcovery_app/providers/camera_provider.dart';
import 'package:dishcovery_app/providers/comment_provider.dart';
import 'package:dishcovery_app/providers/feeds_provider.dart';
import 'package:dishcovery_app/providers/history_provider.dart';
import 'package:dishcovery_app/providers/scan_provider.dart';
import 'package:dishcovery_app/providers/theme_provider.dart';
import 'package:dishcovery_app/providers/user_preferences_provider.dart';
import 'package:dishcovery_app/utils/routes/app_routes.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class App extends StatelessWidget {
  final SharedPreferences preferences;
  final ObjectBoxDatabase objectBoxDatabase;

  const App({
    super.key,
    required this.preferences,
    required this.objectBoxDatabase,
  });

  String get _initialRoute {
    final hasSeenOnboarding = preferences.getBool('hasSeenOnboarding') ?? false;

    if (!hasSeenOnboarding) {
      return AppRoutes.onboarding;
    }

    return AppRoutes.main;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(preferences)),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ScanProvider()),
        ChangeNotifierProvider(create: (_) => CameraProvider()),
        ChangeNotifierProvider(
          create: (_) => HistoryProvider(objectBoxDatabase),
        ),
        ChangeNotifierProvider(create: (_) => FeedsProvider()),
        ChangeNotifierProvider(create: (_) => CommentProvider()),
        ChangeNotifierProxyProvider<AuthProvider, UserPreferencesProvider>(
          create: (context) => UserPreferencesProvider(
            service: UserPreferencesService(),
            auth: Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, previous) {
            if (previous != null) {
              previous.auth = auth;
              return previous;
            }
            return UserPreferencesProvider(
              service: UserPreferencesService(),
              auth: auth,
            );
          },
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Dishcovery',
            themeMode: Provider.of<ThemeProvider>(context).themeMode,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            initialRoute: _initialRoute,
            onGenerateRoute: AppRoutes.generateRoute,
          );
        },
      ),
    );
  }
}
