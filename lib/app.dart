import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/theme.dart';
import 'providers/theme_provider.dart';
import 'views/home/home_page.dart';

class App extends StatelessWidget {
  final SharedPreferences preferences;

  const App({super.key, required this.preferences});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(preferences),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Dishcovery',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            // Masih default ke home page, nanti diubah sesuai kebutuhan
            home: const HomePage(),
          );
        },
      ),
    );
  }
}
