import 'dart:io';
import 'package:dishcovery_app/app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dishcovery_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dotenv for API keys - conditionally load .env file
  await _initializeEnvironment();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize SharedPreferences
  final preferences = await SharedPreferences.getInstance();

  runApp(App(preferences: preferences));
}

/// Initialize environment variables from .env file or system environment
Future<void> _initializeEnvironment() async {
  try {
    // Check if .env file exists
    final envFile = File('.env');
    if (await envFile.exists()) {
      // Load from .env file
      await dotenv.load(fileName: ".env");
      print('✅ Loaded environment variables from .env file');
    } else {
      // Load from system environment variables
      dotenv.env.addAll(Platform.environment);
      print('✅ Loaded environment variables from system environment');
    }
  } catch (e) {
    // Fallback to system environment variables if .env loading fails
    dotenv.env.addAll(Platform.environment);
    print('⚠️ Failed to load .env file, using system environment variables: $e');
  }
}
