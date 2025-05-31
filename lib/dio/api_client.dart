import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'interceptors/cache_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'interceptors/token_interceptor.dart';

class ApiClient {
  // Singleton instance
  static final ApiClient _instance = ApiClient._internal();

  // Private constructor for singleton
  ApiClient._internal();

  // Factory constructor to return the singleton instance
  factory ApiClient() {
    return _instance;
  }

  late Dio _dio; // Late initialization, will be set in init()
  late TokenStorage _tokenStorage;
  late OnLogoutCallback _onLogout;
  bool _isInitCalled = false;

  // Configuration for the interceptor
  String _baseUrl = '';
  String _refreshTokenPath = '/refresh-token';
  String _accessTokenKey = 'access_token';
  String _refreshTokenKey = 'refresh_token';
  List<String> _publicPaths = const [];

  /// Initializes the ApiClient with necessary configurations.
  /// This method must be called once before any network requests are made.
  Future<void> init({
    required String baseUrl,
    required TokenStorage tokenStorage,
    required OnLogoutCallback onLogout,
    String refreshTokenPath = '/refresh-token',
    String accessTokenKey = 'access_token',
    String refreshTokenKey = 'refresh_token',
    List<String> publicPaths = const [
      '/login',
      '/register',
      '/forgot-password',
      '/verify-email',
    ], // Paths that don't require a token
    int connectTimeout = 30000, // 30 seconds
    int receiveTimeout = 30000, // 30 seconds
  }) async {
    _baseUrl = baseUrl;
    _tokenStorage = tokenStorage;
    _onLogout = onLogout;
    _refreshTokenPath = refreshTokenPath;
    _accessTokenKey = accessTokenKey;
    _refreshTokenKey = refreshTokenKey;
    _publicPaths = publicPaths;

    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: Duration(milliseconds: connectTimeout),
        receiveTimeout: Duration(milliseconds: receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // 1. Add the DioCacheInterceptor
    _dio.interceptors.add(
      DioCacheInterceptor(options: await CacheInterceptor.cacheOptions),
    );

    // 2. Add the RetryOnConnectionChangeInterceptor
    _dio.interceptors.add(
      RetryOnConnectionChangeInterceptor(
        requestRetrier: DioConnectivityRequestRetrier(
          dio: _dio,
          connectionChecker: InternetConnection(),
        ),
      ),
    );

    // 3. Add the TokenInterceptor
    _dio.interceptors.add(
      TokenInterceptor(
        _tokenStorage,
        _dio, // Pass the same Dio instance to the interceptor
        _onLogout,
        refreshTokenPath: _refreshTokenPath,
        accessTokenKey: _accessTokenKey,
        refreshTokenKey: _refreshTokenKey,
        publicPaths: _publicPaths, // Pass the public paths to the interceptor
      ),
    );

    // 4. Add the PrettyDioLogger for logging
    _dio.interceptors.add(PrettyDioLogger());

    _isInitCalled = true;

    debugPrint('ApiClient initialized with base URL: $_baseUrl');
  }

  /// Getter for the internal Dio instance, useful for direct access if needed,
  /// but generally, you should use the methods provided by ApiClient.
  Dio get dio => _dio;

  // --- Metode untuk Permintaan HTTP ---

  /// Performs a GET request.
  Future<Response<T>> get<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    _assertInitCalled();
    try {
      final response = await _dio.get<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } on DioException catch (e) {
      debugPrint('GET request failed for $path: ${e.message}');
      rethrow; // Re-throw the DioException for higher-level error handling
    }
  }

  /// Performs a POST request.
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    _assertInitCalled();

    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } on DioException catch (e) {
      debugPrint('POST request failed for $path: ${e.message}');
      rethrow;
    }
  }

  /// Performs a PUT request.
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    _assertInitCalled();

    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } on DioException catch (e) {
      debugPrint('PUT request failed for $path: ${e.message}');
      rethrow;
    }
  }

  /// Performs a DELETE request.
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    _assertInitCalled();
    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      debugPrint('DELETE request failed for $path: ${e.message}');
      rethrow;
    }
  }

  /// Uploads files using FormData and MultipartFile.
  ///
  /// The [data] map can contain both String fields and File/List<File> fields.
  /// For files, the key should correspond to the field name expected by the server.
  /// Example:
  /// ```dart
  /// await ApiClient().uploadFile(
  ///   '/upload-profile-picture',
  ///   data: {
  ///     'user_id': '123',
  ///     'profile_picture': File('path/to/image.jpg'),
  ///     'documents': [File('path/to/doc1.pdf'), File('path/to/doc2.pdf')],
  ///   },
  ///   onSendProgress: (sent, total) {
  ///     print('Upload progress: ${(sent / total * 100).toStringAsFixed(0)}%');
  ///   },
  /// );
  /// ```
  Future<Response<T>> uploadFile<T>(
    String path, {
    required Map<String, dynamic> data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    _assertInitCalled();

    try {
      final formData = FormData();

      for (var entry in data.entries) {
        if (entry.value is File) {
          // Handle single file
          formData.files.add(
            MapEntry(
              entry.key,
              await MultipartFile.fromFile(
                entry.value.path,
                filename: entry.value.path.split('/').last,
              ),
            ),
          );
        } else if (entry.value is List<File>) {
          // Handle list of files
          for (var file in entry.value) {
            formData.files.add(
              MapEntry(
                // Use array notation if the server expects it (e.g., 'documents[]')
                // Or just the key if server handles multiple files on one field
                entry.key,
                await MultipartFile.fromFile(
                  file.path,
                  filename: file.path.split('/').last,
                ),
              ),
            );
          }
        } else {
          // Handle other data types (e.g., String, int, bool)
          formData.fields.add(MapEntry(entry.key, entry.value.toString()));
        }
      }

      final response = await _dio.post<T>(
        path,
        data: formData,
        queryParameters: queryParameters,
        options:
            options?.copyWith(
              contentType:
                  'multipart/form-data', // Explicitly set, though Dio often handles this
            ) ??
            Options(contentType: 'multipart/form-data'),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } on DioException catch (e) {
      debugPrint('File upload failed for $path: ${e.message}');
      rethrow;
    }
  }

  /// Helper method to clear all tokens and trigger logout.
  /// Useful for explicit logout actions from the UI.
  Future<void> logout() async {
    _assertInitCalled();

    await _tokenStorage.clearAllTokens();
    await _onLogout();
    debugPrint('User logged out via ApiClient.logout().');
  }

  void _assertInitCalled() {
    assert(
      _isInitCalled,
      "You must called 'ApiClient().init(...)' first in your app'",
    );
  }
}
