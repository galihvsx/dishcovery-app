import 'package:dishcovery_app/features/result/presentation/result_screen.dart';
import 'package:flutter/material.dart';

import 'package:dishcovery_app/core/navigation/auth_guard.dart';
import 'package:dishcovery_app/core/navigation/auth_preferences_guard.dart';
import 'package:dishcovery_app/core/navigation/main_navigation.dart';
import 'package:dishcovery_app/features/auth/forgot_password/presentation/forgot_password_screen.dart';
import 'package:dishcovery_app/features/auth/login/presentation/login_screen.dart';
import 'package:dishcovery_app/features/auth/register/presentation/register_screen.dart';
import 'package:dishcovery_app/features/capture/presentation/capture_screen.dart';
import 'package:dishcovery_app/features/history/presentation/history_screen.dart';
import 'package:dishcovery_app/features/home/presentation/dishcovery_home_page.dart';
import 'package:dishcovery_app/features/onboarding/presentation/app_onboarding_screen.dart';
import 'package:dishcovery_app/features/preference_onboarding/presentation/preferences_onboarding_screen.dart';
import 'package:dishcovery_app/features/settings/presentation/edit_profile_screen.dart';
import 'package:dishcovery_app/features/settings/presentation/setting_screen.dart';
import 'package:dishcovery_app/features/user_preference/presentation/user_preferences_screen.dart';

class AppRoutes {
  static const String onboarding = '/onboarding';

  static const String main = '/';
  static const String preferences = '/preferences';
  static const String preferencesOnboarding = '/preferences-onboarding';
  static const String editProfile = '/edit-profile';

  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboarding:
        return MaterialPageRoute(builder: (_) => const AppOnboardingScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      case main:
        return createAuthenticatedRouteWithPreferences(
          settings,
          (_) => const MainNavigation(),
        );
      case DishcoveryHomePage.path:
        return createAuthenticatedRouteWithPreferences(
          settings,
          (_) => const DishcoveryHomePage(),
        );
      case CaptureScreen.path:
        return createAuthenticatedRouteWithPreferences(
          settings,
          (_) => const CaptureScreen(),
        );
      case HistoryScreen.path:
        return createAuthenticatedRouteWithPreferences(
          settings,
          (_) => const HistoryScreen(),
        );
      case SettingScreen.path:
        return createAuthenticatedRouteWithPreferences(
          settings,
          (_) => const SettingScreen(),
        );
      case ResultScreen.path:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final imagePath = args['imagePath'] as String? ?? '';
        return createAuthenticatedRouteWithPreferences(
          settings,
          (_) => ResultScreen(imagePath: imagePath),
        );

      case preferences:
        return createAuthenticatedRoute(
          settings,
          (_) => const UserPreferencesScreen(),
        );
      case preferencesOnboarding:
        return createAuthenticatedRoute(
          settings,
          (_) => const PreferencesOnboardingScreen(),
        );
      case editProfile:
        return createAuthenticatedRoute(
          settings,
          (_) => const EditProfileScreen(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Page not found'))),
        );
    }
  }

  static final Map<String, WidgetBuilder> routes = {
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),
    forgotPassword: (_) => const ForgotPasswordScreen(),

    main: (_) => const AuthGuard(child: MainNavigation()),
    DishcoveryHomePage.path: (_) =>
        const AuthGuard(child: DishcoveryHomePage()),
    CaptureScreen.path: (_) => const AuthGuard(child: CaptureScreen()),
    HistoryScreen.path: (_) => const AuthGuard(child: HistoryScreen()),
    SettingScreen.path: (_) => const AuthGuard(child: SettingScreen()),

  };

  static Map<String, dynamic> createArguments({
    String? imagePath,
    Map<String, dynamic>? additionalArgs,
  }) {
    final args = <String, dynamic>{};

    if (imagePath != null) {
      args['imagePath'] = imagePath;
    }

    if (additionalArgs != null) {
      args.addAll(additionalArgs);
    }

    return args;
  }
}
