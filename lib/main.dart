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
  final envFile = File('.env');
  final hasEnvFile = await envFile.exists();
  final systemEnv = Map<String, String>.from(Platform.environment);

  try {
    await dotenv.load(
      fileName: '.env',
      mergeWith: systemEnv,
      isOptional: !hasEnvFile,
    );

    if (hasEnvFile) {
      print('✅ Loaded environment variables from .env file');
    } else {
      print('✅ Loaded environment variables from system environment');
    }
  } catch (e) {
    dotenv.loadFromString(
      mergeWith: systemEnv,
      isOptional: true,
    );
    print('⚠️ Failed to load .env file, using system environment variables: $e');
  }
}
