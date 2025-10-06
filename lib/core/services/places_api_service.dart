import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';

import 'package:dishcovery_app/core/models/place_model.dart';
import 'package:dishcovery_app/core/services/http_service.dart';

/// Service for interacting with Google Places API
class PlacesApiService {
  static PlacesApiService? _instance;
  final HttpService _httpService = HttpService.instance;

  // Google Places API endpoint
  static const String _baseUrl =
      'https://places.googleapis.com/v1/places:searchText';

  PlacesApiService._();

  static PlacesApiService get instance {
    _instance ??= PlacesApiService._();
    return _instance!;
  }

  /// Search for restaurants that serve a specific food
  ///
  /// [foodName] - The name of the food to search for (e.g., "Nasi Goreng", "Sate Ayam")
  /// [location] - Current user location for proximity search
  /// [radius] - Search radius in meters (default: 5000m / 5km)
  /// [maxResults] - Maximum number of results to return (default: 20, max: 20)
  /// [includeOnlyOpenNow] - Whether to include only currently open places
  /// [minRating] - Minimum rating filter (0.0 to 5.0)
  /// [priceLevel] - Price level filter (1-4, null for all)
  Future<PlacesSearchResponse> searchNearbyRestaurants({
    required String foodName,
    Position? location,
    double radius = 5000.0,
    int maxResults = 20,
    bool includeOnlyOpenNow = false,
    double? minRating,
    List<int>? priceLevels,
  }) async {
    try {
      // Validate inputs
      if (foodName.isEmpty) {
        throw ArgumentError('Food name cannot be empty');
      }

      if (maxResults < 1 || maxResults > 20) {
        maxResults = 20;
      }

      if (radius < 0 || radius > 50000) {
        radius = 5000;
      }

      // Detect if we're in Indonesia based on location
      bool isIndonesia = false;
      String regionCode = 'US'; // Default to US
      String languageCode = 'en'; // Default to English

      if (location != null) {
        // Check if location is roughly in Indonesia
        // Indonesia roughly spans:
        // Latitude: -11 to 6
        // Longitude: 95 to 141
        if (location.latitude >= -11 &&
            location.latitude <= 6 &&
            location.longitude >= 95 &&
            location.longitude <= 141) {
          isIndonesia = true;
          regionCode = 'ID';
          languageCode = 'id';
        }
      }

      // Build search queries with fallback strategy
      List<String> searchQueries = [];

      if (isIndonesia) {
        // In Indonesia, search specifically for the food
        searchQueries.add('restaurants serving $foodName');
        searchQueries.add('$foodName restaurant');
        searchQueries.add('warung $foodName'); // Local term
      } else {
        // Outside Indonesia, search more broadly
        searchQueries.add(
          'Indonesian restaurant',
        ); // Generic Indonesian restaurants
        searchQueries.add('Asian restaurant'); // Broader category
        searchQueries.add('$foodName restaurant'); // Still try specific food
      }

      // Try each search query until we get results
      PlacesSearchResponse? finalResponse;

      for (int i = 0; i < searchQueries.length; i++) {
        final searchQuery = searchQueries[i];

        // Build request body
        final Map<String, dynamic> requestBody = {
          'textQuery': searchQuery,
          'maxResultCount': maxResults,
          'languageCode': languageCode,
          'regionCode': regionCode,
        };

        // Add location bias if available
        if (location != null) {
          requestBody['locationBias'] = {
            'circle': {
              'center': {
                'latitude': location.latitude,
                'longitude': location.longitude,
              },
              'radius': radius,
            },
          };
        }

        // Add filters
        if (includeOnlyOpenNow) {
          requestBody['openNow'] = true;
        }

        if (minRating != null && minRating >= 0 && minRating <= 5) {
          // Round to nearest 0.5
          requestBody['minRating'] = (minRating * 2).round() / 2;
        }

        if (priceLevels != null && priceLevels.isNotEmpty) {
          requestBody['priceLevels'] = priceLevels
              .where((level) => level >= 1 && level <= 4)
              .map((level) => 'PRICE_LEVEL_${'I' * level}')
              .toList();
        }

        // Rank by distance if location is provided, otherwise by relevance
        requestBody['rankPreference'] = location != null
            ? 'DISTANCE'
            : 'RELEVANCE';

        // Include restaurant type filter
        requestBody['includedType'] = 'restaurant';
        requestBody['strictTypeFiltering'] =
            false; // Allow other food places too

        // Log request for debugging
        if (kDebugMode) {
          print(
            '🔍 Places API Request (Attempt ${i + 1}/${searchQueries.length}):',
          );
          print('   Query: $searchQuery');
          print('   Location: ${location?.latitude}, ${location?.longitude}');
          print('   Radius: $radius meters');
          print('   Max Results: $maxResults');
          print('   Region: $regionCode');
        }

        // Make the API request
        final response = await _httpService.post(
          _baseUrl,
          data: requestBody,
          options: Options(
            headers: {
              'X-Goog-Api-Key': dotenv.env['GOOGLE_PLACES_API_KEY'],
              'X-Goog-FieldMask': _getFieldMask(),
            },
          ),
        );

        // Parse response
        final searchResponse = PlacesSearchResponse.fromJson(response.data);

        if (kDebugMode) {
          print(
            '✅ Places API Response: Found ${searchResponse.places.length} places',
          );
        }

        // If we found results, use them
        if (searchResponse.places.isNotEmpty) {
          // Determine if this is a generic search
          bool isGeneric =
              !isIndonesia && (i > 0 || !searchQuery.contains(foodName));

          finalResponse = PlacesSearchResponse(
            places: searchResponse.places,
            nextPageToken: searchResponse.nextPageToken,
            searchQuery: searchQuery,
            isGenericSearch: isGeneric,
          );
          break;
        }

        // If this was the last query and no results, return empty response
        if (i == searchQueries.length - 1) {
          finalResponse = PlacesSearchResponse(
            places: [],
            searchQuery: searchQuery,
            isGenericSearch: !isIndonesia,
          );
        }
      }

      return finalResponse ??
          PlacesSearchResponse(places: [], isGenericSearch: !isIndonesia);
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Places API Error: ${e.message}');
        print('❌ Error Response: ${e.response?.data}');
      }

      // Check for specific API errors
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData != null && errorData['error'] != null) {
          final errorMessage =
              errorData['error']['message'] ?? 'Invalid request';
          throw PlacesApiException(errorMessage, e.response?.statusCode);
        }
      }

      throw PlacesApiException(
        e.message ?? 'Failed to search for restaurants',
        e.response?.statusCode,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error in Places API: $e');
      }
      throw PlacesApiException('An unexpected error occurred: $e', null);
    }
  }

  /// Search for places with custom query
  ///
  /// [query] - Custom search query
  /// [location] - Optional location for proximity search
  /// [radius] - Search radius in meters
  Future<PlacesSearchResponse> searchPlaces({
    required String query,
    Position? location,
    double radius = 5000.0,
    int maxResults = 20,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'textQuery': query,
        'maxResultCount': maxResults,
        'languageCode': 'id',
        'regionCode': 'ID',
      };

      if (location != null) {
        requestBody['locationBias'] = {
          'circle': {
            'center': {
              'latitude': location.latitude,
              'longitude': location.longitude,
            },
            'radius': radius,
          },
        };
      }

      final response = await _httpService.post(
        _baseUrl,
        data: requestBody,
        options: Options(
          headers: {
            'X-Goog-Api-Key': dotenv.env['GOOGLE_PLACES_API_KEY'],
            'X-Goog-FieldMask': _getFieldMask(),
          },
        ),
      );

      return PlacesSearchResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw PlacesApiException(
        e.message ?? 'Failed to search places',
        e.response?.statusCode,
      );
    }
  }

  /// Get detailed information about a specific place
  ///
  /// [placeId] - The place ID to get details for
  Future<PlaceModel> getPlaceDetails(String placeId) async {
    try {
      final String url = 'https://places.googleapis.com/v1/places/$placeId';

      final response = await _httpService.get(
        url,
        options: Options(
          headers: {
            'X-Goog-Api-Key': dotenv.env['GOOGLE_PLACES_API_KEY'],
            'X-Goog-FieldMask': _getDetailedFieldMask(),
          },
        ),
      );

      return PlaceModel.fromJson(response.data);
    } on DioException catch (e) {
      throw PlacesApiException(
        e.message ?? 'Failed to get place details',
        e.response?.statusCode,
      );
    }
  }

  /// Build field mask for API requests to optimize costs
  /// Only request fields that we actually need
  String _getFieldMask() {
    return [
      // ID Only fields (cheapest)
      'places.id',
      'places.displayName',
      'places.primaryType',
      'places.primaryTypeDisplayName',

      // Location fields (Pro SKU)
      'places.formattedAddress',
      'places.shortFormattedAddress',
      'places.location',
      'places.googleMapsUri',
      'places.photos',

      // Business fields (Enterprise SKU)
      'places.rating',
      'places.userRatingCount',
      'places.priceLevel',
      'places.currentOpeningHours',
      'places.websiteUri',
      'places.internationalPhoneNumber',
    ].join(',');
  }

  /// Build detailed field mask for place details
  String _getDetailedFieldMask() {
    return [
      'id',
      'displayName',
      'primaryType',
      'primaryTypeDisplayName',
      'formattedAddress',
      'shortFormattedAddress',
      'addressComponents',
      'location',
      'viewport',
      'googleMapsUri',
      'photos',
      'rating',
      'userRatingCount',
      'priceLevel',
      'currentOpeningHours',
      'regularOpeningHours',
      'websiteUri',
      'internationalPhoneNumber',
      'nationalPhoneNumber',
      'businessStatus',
      'accessibilityOptions',
      'plusCode',
      'types',
    ].join(',');
  }

  /// Get current user location
  /// Returns null if location permission is denied or location service is disabled
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) {
          print('⚠️ Location services are disabled');
        }
        return null;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (kDebugMode) {
            print('⚠️ Location permission denied');
          }
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (kDebugMode) {
          print('⚠️ Location permission permanently denied');
        }
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        ),
      );

      if (kDebugMode) {
        print(
          '📍 Current location: ${position.latitude}, ${position.longitude}',
        );
      }

      return position;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting location: $e');
      }
      return null;
    }
  }

  /// Calculate distance between two locations in kilometers
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
          startLatitude,
          startLongitude,
          endLatitude,
          endLongitude,
        ) /
        1000; // Convert to kilometers
  }
}

/// Custom exception for Places API errors
class PlacesApiException implements Exception {
  final String message;
  final int? statusCode;

  PlacesApiException(this.message, this.statusCode);

  @override
  String toString() => 'PlacesApiException: $message (Status: $statusCode)';
}
