import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HttpService {
  static HttpService? _instance;
  late Dio _dio;

  HttpService._() {
    _initializeDio();
  }

  static HttpService get instance {
    _instance ??= HttpService._();
    return _instance!;
  }

  Dio get dio => _dio;

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _addInterceptors();
  }

  void _addInterceptors() {
    // Add Chucker interceptor for debugging (only in debug mode)
    if (kDebugMode) {
      _dio.interceptors.add(ChuckerDioInterceptor());
    }

    // Add logging interceptor
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
          error: true,
          logPrint: (object) {
            if (kDebugMode) {
              print('🌐 HTTP: $object');
            }
          },
        ),
      );
    }

    // Add custom interceptor for API key and error handling
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add API key to headers if needed for Places API
          if (options.path.contains('places.googleapis.com')) {
            final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'];
            if (apiKey != null) {
              options.headers['X-Goog-Api-Key'] = apiKey;
            }
          }
          handler.next(options);
        },
        onError: (DioException error, handler) {
          // Handle common errors
          String errorMessage = _getErrorMessage(error);

          if (kDebugMode) {
            print('❌ HTTP Error: $errorMessage');
            print('❌ Status Code: ${error.response?.statusCode}');
            print('❌ Error Data: ${error.response?.data}');
          }

          // Create a custom error with user-friendly message
          final customError = DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: errorMessage,
            message: errorMessage,
          );

          handler.next(customError);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print('✅ HTTP Response: ${response.statusCode}');
          }
          handler.next(response);
        },
      ),
    );
  }

  String _getErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.sendTimeout:
        return 'Send timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout. Please try again.';
      case DioExceptionType.badResponse:
        return _handleStatusCode(error.response?.statusCode);
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      case DioExceptionType.unknown:
        if (error.message?.contains('SocketException') ?? false) {
          return 'No internet connection. Please check your network.';
        }
        return 'An unexpected error occurred. Please try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  String _handleStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Unauthorized. Please check your API key.';
      case 403:
        return 'Forbidden. You don\'t have permission to access this resource.';
      case 404:
        return 'Resource not found.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
        return 'Bad gateway. Please try again later.';
      case 503:
        return 'Service unavailable. Please try again later.';
      default:
        return 'Error occurred with status code: $statusCode';
    }
  }

  // Method to make GET requests
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Method to make POST requests
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Method to make PUT requests
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Method to make DELETE requests
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Method to cancel all requests
  void cancelAllRequests() {
    _dio.close(force: true);
    _initializeDio(); // Reinitialize after closing
  }
}