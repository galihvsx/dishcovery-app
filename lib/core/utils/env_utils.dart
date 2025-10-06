import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Utility class for accessing environment variables
class EnvUtils {
  /// Get environment variable value from either .env file or system environment
  /// 
  /// [key] - The environment variable key
  /// [defaultValue] - Default value if the key is not found
  /// 
  /// Returns the environment variable value or the default value
  static String? getEnv(String key, [String? defaultValue]) {
    // First try to get from dotenv (which could be loaded from .env file or system env)
    String? value = dotenv.env[key];
    
    // If not found in dotenv, try system environment directly
    value ??= Platform.environment[key];
    
    // Return the value or default
    return value ?? defaultValue;
  }

  /// Get required environment variable value
  /// 
  /// [key] - The environment variable key
  /// 
  /// Throws [StateError] if the key is not found
  /// Returns the environment variable value
  static String getRequiredEnv(String key) {
    final value = getEnv(key);
    if (value == null || value.isEmpty) {
      throw StateError('Required environment variable "$key" is not set');
    }
    return value;
  }

  /// Check if an environment variable exists and is not empty
  /// 
  /// [key] - The environment variable key
  /// 
  /// Returns true if the variable exists and is not empty
  static bool hasEnv(String key) {
    final value = getEnv(key);
    return value != null && value.isNotEmpty;
  }
}