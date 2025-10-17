import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'package:dishcovery_app/core/models/place_model.dart';
import 'package:dishcovery_app/core/services/http_service.dart';
import 'package:dishcovery_app/core/config/api_constants.dart';

class PlacesApiService {
  static PlacesApiService? _instance;
  final HttpService _httpService = HttpService.instance;

  static const String _baseUrl = ApiConstants.placesApiBaseUrl;

  PlacesApiService._();

  static PlacesApiService get instance {
    _instance ??= PlacesApiService._();
    return _instance!;
  }

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
      if (foodName.isEmpty) {
        throw ArgumentError('Food name cannot be empty');
      }

      if (maxResults < 1 || maxResults > 20) {
        maxResults = 20;
      }

      if (radius < 0 || radius > 50000) {
        radius = 5000;
      }

      bool isIndonesia = false;
      String regionCode = 'US';
      String languageCode = 'en';

      if (location != null) {
        if (location.latitude >= -11 &&
            location.latitude <= 6 &&
            location.longitude >= 95 &&
            location.longitude <= 141) {
          isIndonesia = true;
          regionCode = 'ID';
          languageCode = 'id';
        }
      }

      List<String> searchQueries = [];

      if (isIndonesia) {
        searchQueries.add('restaurants serving $foodName');
        searchQueries.add('$foodName restaurant');
        searchQueries.add('warung $foodName');
      } else {
        searchQueries.add(
          'Indonesian restaurant',
        );
        searchQueries.add('Asian restaurant');
        searchQueries.add('$foodName restaurant');
      }

      PlacesSearchResponse? finalResponse;

      for (int i = 0; i < searchQueries.length; i++) {
        final searchQuery = searchQueries[i];

        final Map<String, dynamic> requestBody = {
          'textQuery': searchQuery,
          'maxResultCount': maxResults,
          'languageCode': languageCode,
          'regionCode': regionCode,
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

        if (includeOnlyOpenNow) {
          requestBody['openNow'] = true;
        }

        if (minRating != null && minRating >= 0 && minRating <= 5) {
          requestBody['minRating'] = (minRating * 2).round() / 2;
        }

        if (priceLevels != null && priceLevels.isNotEmpty) {
          requestBody['priceLevels'] = priceLevels
              .where((level) => level >= 1 && level <= 4)
              .map((level) => 'PRICE_LEVEL_${'I' * level}')
              .toList();
        }

        requestBody['rankPreference'] = location != null
            ? 'DISTANCE'
            : 'RELEVANCE';

        requestBody['includedType'] = 'restaurant';
        requestBody['strictTypeFiltering'] =
            false;

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

        final response = await _httpService.post(
          _baseUrl,
          data: requestBody,
          options: Options(
            headers: {
              'X-Goog-Api-Key': ApiConstants.googlePlacesApiKey(),
              'X-Goog-FieldMask': _getFieldMask(),
            },
          ),
        );

        final searchResponse = PlacesSearchResponse.fromJson(response.data);

        if (kDebugMode) {
          print(
            '✅ Places API Response: Found ${searchResponse.places.length} places',
          );
        }

        if (searchResponse.places.isNotEmpty) {
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
            'X-Goog-Api-Key': ApiConstants.googlePlacesApiKey(),
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

  Future<PlaceModel> getPlaceDetails(String placeId) async {
    try {
      final String url = 'https://places.googleapis.com/v1/places/$placeId';

      final response = await _httpService.get(
        url,
        options: Options(
          headers: {
            'X-Goog-Api-Key': ApiConstants.googlePlacesApiKey(),
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

  String _getFieldMask() {
    return [
      'places.id',
      'places.displayName',
      'places.primaryType',
      'places.primaryTypeDisplayName',

      'places.formattedAddress',
      'places.shortFormattedAddress',
      'places.location',
      'places.googleMapsUri',
      'places.photos',

      'places.rating',
      'places.userRatingCount',
      'places.priceLevel',
      'places.currentOpeningHours',
      'places.websiteUri',
      'places.internationalPhoneNumber',
    ].join(',');
  }

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

  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) {
          print('⚠️ Location services are disabled');
        }
        return null;
      }

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
        1000;
  }
}

class PlacesApiException implements Exception {
  final String message;
  final int? statusCode;

  PlacesApiException(this.message, this.statusCode);

  @override
  String toString() => 'PlacesApiException: $message (Status: $statusCode)';
}
