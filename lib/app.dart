import 'package:dishcovery_app/features/capture/presentation/camera_test_screen.dart';
import 'package:dishcovery_app/features/home/presentation/dishcovery_home_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/theme.dart';
import 'features/home/presentation/home_page.dart';
import 'providers/theme_provider.dart';

class App extends StatelessWidget {
  final SharedPreferences preferences;

  const App({super.key, required this.preferences});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(preferences)),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Dishcovery',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            // Masih default ke home page, nanti diubah sesuai kebutuhan
            home: const DishcoveryHomePage(),
          );
        },
      ),
    );
  }
}
