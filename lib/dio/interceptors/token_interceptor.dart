import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:synchronized/synchronized.dart';

// --- Abstraksi untuk Penyimpanan Token ---
/// Abstract interface for token storage.
/// This allows for easy swapping of storage implementations (e.g., FlutterSecureStorage, SharedPreferences, etc.)
/// and makes the TokenInterceptor more testable and modular.
abstract class TokenStorage {
  Future<String?> readAccessToken();
  Future<void> writeAccessToken(String? token);
  Future<String?> readRefreshToken();
  Future<void> writeRefreshToken(String? token);
  Future<void> clearAllTokens();
}

// --- Implementasi Mock untuk Pengembangan/Pengujian ---
/// Mock implementation of TokenStorage for development or testing.
/// In a real Flutter app, this would be replaced by `FlutterSecureStorage`.
class MockTokenStorage implements TokenStorage {
  final Map<String, dynamic> _storage = {};

  @override
  Future<String?> readAccessToken() async {
    return _storage['access_token'] as String?;
  }

  @override
  Future<void> writeAccessToken(String? token) async {
    _storage['access_token'] = token;
  }

  @override
  Future<String?> readRefreshToken() async {
    return _storage['refresh_token'] as String?;
  }

  @override
  Future<void> writeRefreshToken(String? token) async {
    _storage['refresh_token'] = token;
  }

  @override
  Future<void> clearAllTokens() async {
    _storage.clear();
    debugPrint(
      'DEBUG: All tokens cleared from storage.',
    ); // Use proper logging in production
  }
}

// --- Callback untuk Navigasi Login ---
/// A type definition for the function that handles redirection to the login screen.
/// This separates UI concerns from the interceptor logic.
typedef OnLogoutCallback = Future<void> Function();

// --- Interceptor Dio untuk Penanganan Token Otentikasi ---
/// Dio Interceptor for handling authentication tokens.
/// It automatically adds access tokens to outgoing requests,
/// handles 401 Unauthorized errors by attempting to refresh the token,
/// and redirects to the login screen if token refresh fails or tokens are missing.
class TokenInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;
  final Dio _dio; // The main Dio instance
  final OnLogoutCallback _onLogout; // Callback for redirecting to login
  final Lock _lock = Lock(); // Ensures only one token refresh request at a time

  // Configuration for endpoints and token keys
  final String refreshTokenPath;
  final String accessTokenKey;
  final String refreshTokenKey;
  final List<String> publicPaths;

  TokenInterceptor(
    this._tokenStorage,
    this._dio,
    this._onLogout, {
    this.refreshTokenPath = '/refresh-token',
    this.accessTokenKey = 'access_token',
    this.refreshTokenKey = 'refresh_token',
    this.publicPaths = const [],
  });

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip adding token if it's a login request
    final isPublicPath = publicPaths.any((path) => options.path.contains(path));
    if (isPublicPath) {
      debugPrint('DEBUG: Skipping token for public path: ${options.path}');
      return handler.next(options);
    }

    final accessToken = await _tokenStorage.readAccessToken();

    if (accessToken != null) {
      // Add access token to the Authorization header
      options.headers['Authorization'] = 'Bearer $accessToken';
      debugPrint(
        'DEBUG: Adding Authorization header with token for ${options.path}',
      ); // Use proper logging
    } else {
      // If no access token is available, clear all tokens and trigger logout
      debugPrint(
        'DEBUG: Access token is null for ${options.path}. Triggering logout.',
      ); // Use proper logging
      await _tokenStorage.clearAllTokens();
      await _onLogout(); // Redirect to login
      // Reject the request to prevent it from proceeding without a token
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType
              .cancel, // Indicate that the request was cancelled
          error: 'No access token available, redirecting to login.',
        ),
      );
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final isUnauthorized = statusCode == 401;
    final isRefreshEndpoint = err.requestOptions.path.contains(
      refreshTokenPath,
    );

    // Only handle 401 errors for non-refresh token requests
    if (isUnauthorized && !isRefreshEndpoint) {
      debugPrint(
        'DEBUG: Received 401 for ${err.requestOptions.path}. Attempting token refresh.',
      ); // Use proper logging

      // Use a lock to prevent multiple concurrent token refresh attempts
      await _lock.synchronized(() async {
        final currentAccessToken = await _tokenStorage.readAccessToken();
        final requestAccessToken = err.requestOptions.headers['Authorization']
            ?.toString()
            .replaceFirst('Bearer ', '');

        // Check if the token has already been refreshed by another request
        if (currentAccessToken != null &&
            currentAccessToken != requestAccessToken) {
          debugPrint(
            'DEBUG: Token already refreshed by another request. Retrying original request with new token.',
          ); // Use proper logging
          // Retry the original request with the newly obtained token
          final newOptions = _copyRequestOptions(
            err.requestOptions,
            currentAccessToken,
          );
          try {
            final retryResponse = await _dio.fetch(newOptions);
            return handler.resolve(retryResponse);
          } catch (e) {
            // If retry fails even with the new token, propagate the error
            debugPrint(
              'ERROR: Retry with new token failed: $e',
            ); // Use proper logging
            return handler.reject(err);
          }
        }

        // If the token hasn't been refreshed, attempt to refresh it now
        try {
          final refreshToken = await _tokenStorage.readRefreshToken();

          if (refreshToken != null) {
            debugPrint(
              'DEBUG: Refreshing token using stored refresh token.',
            ); // Use proper logging
            // Make a request to the refresh token endpoint
            // IMPORTANT: This request should NOT go through this interceptor to avoid infinite loops
            // A separate Dio instance or specific request options might be needed if the main _dio instance
            // has other interceptors that should not apply to the refresh token call.
            final Response refreshResponse = await _dio.post(
              refreshTokenPath,
              data: {refreshTokenKey: refreshToken},
              options: Options(
                // You might need to add specific headers here if your refresh endpoint requires them
                // e.g., contentType: Headers.jsonContentType,
                headers: {'Accept': 'application/json'},
              ),
            );

            final newAccessToken = refreshResponse.data?[accessTokenKey];
            final newRefreshToken = refreshResponse
                .data?[refreshTokenKey]; // If refresh token also updates

            if (newAccessToken != null) {
              await _tokenStorage.writeAccessToken(newAccessToken);
              if (newRefreshToken != null) {
                await _tokenStorage.writeRefreshToken(newRefreshToken);
              }
              debugPrint(
                'DEBUG: Token refreshed successfully. Retrying original request.',
              ); // Use proper logging

              // Retry the original failed request with the new access token
              final retryOptions = _copyRequestOptions(
                err.requestOptions,
                newAccessToken,
              );
              final retryResponse = await _dio.fetch(retryOptions);
              return handler.resolve(retryResponse);
            } else {
              // If refresh response doesn't contain a new access token
              throw Exception(
                'Refresh token response missing new access token.',
              );
            }
          } else {
            // No refresh token available, force logout
            throw Exception('Refresh token not found. Cannot refresh.');
          }
        } catch (e) {
          debugPrint(
            'ERROR: Failed to refresh token: $e. Clearing tokens and logging out.',
          ); // Use proper logging
          await _tokenStorage.clearAllTokens();
          await _onLogout(); // Redirect to login
          // Reject the original error, indicating a permanent failure
          return handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: 'Failed to refresh token, user logged out.',
              response: err.response, // Pass original response if available
              type: DioExceptionType.badResponse,
            ),
          );
        }
      });
    }

    // For any other error, or if 401 handling is skipped, pass the error along
    return handler.next(err);
  }

  /// Helper function to create a new RequestOptions with updated Authorization header.
  RequestOptions _copyRequestOptions(
    RequestOptions oldOptions,
    String newAccessToken,
  ) {
    return oldOptions.copyWith(
      headers: {
        ...oldOptions.headers,
        'Authorization': 'Bearer $newAccessToken',
      },
    );
  }
}
