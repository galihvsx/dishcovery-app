import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  static const String androidGooglePlacesApiKey =
      'AIzaSyC7Mx_hpZvjmm6F_wp4FmrJdPNN7VtldRo';
  static const String iosGooglePlacesApiKey =
      'AIzaSyC7Mx_hpZvjmm6F_wp4FmrJdPNN7VtldRo';
  static const String placesApiBaseUrl =
      'https://places.googleapis.com/v1/places:searchText';

  static String googlePlacesApiKey({TargetPlatform? platform}) {
    final resolvedPlatform = platform ?? defaultTargetPlatform;

    if (resolvedPlatform == TargetPlatform.iOS) {
      return iosGooglePlacesApiKey;
    }

    return androidGooglePlacesApiKey;
  }
}
