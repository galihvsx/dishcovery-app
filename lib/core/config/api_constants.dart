import 'package:flutter/foundation.dart';

/// Central place for API-related constants.
class ApiConstants {
  ApiConstants._();

  static const String androidGooglePlacesApiKey =
      'AIzaSyC7Mx_hpZvjmm6F_wp4FmrJdPNN7VtldRo';
  static const String iosGooglePlacesApiKey =
      'AIzaSyC7Mx_hpZvjmm6F_wp4FmrJdPNN7VtldRo';
  static const String placesApiBaseUrl =
      'https://places.googleapis.com/v1/places:searchText';

  /// Returns the Google Places API key appropriate for the current platform.
  static String googlePlacesApiKey({TargetPlatform? platform}) {
    final resolvedPlatform = platform ?? defaultTargetPlatform;

    if (resolvedPlatform == TargetPlatform.iOS) {
      return iosGooglePlacesApiKey;
    }

    return androidGooglePlacesApiKey;
  }
}
