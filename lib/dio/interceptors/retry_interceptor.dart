import 'dart:async';
import 'dart:io'; // For SocketException
import 'package:dio/dio.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart'; // Menggunakan versi plus yang lebih baru
import 'package:flutter/foundation.dart'; // For debugPrint

// --- DioConnectivityRequestRetrier ---
/// A class responsible for scheduling and executing Dio requests
/// when internet connectivity is restored.
class DioConnectivityRequestRetrier {
  final Dio dio;
  final InternetConnection connectionChecker;
  final Duration timeout; // Max time to wait for connection to retry

  DioConnectivityRequestRetrier({
    required this.dio,
    required this.connectionChecker,
    this.timeout = const Duration(seconds: 60), // Default timeout for retry
  });

  /// Schedules a request to be retried when internet connectivity is restored.
  ///
  /// It waits for the connection to be available, then retries the original request.
  /// If the connection doesn't come back within the specified [timeout],
  /// it will throw a [TimeoutException].
  Future<Response> scheduleRequestRetry(RequestOptions requestOptions) async {
    final responseCompleter = Completer<Response>();
    StreamSubscription? streamSubscription;
    Timer? timeoutTimer;

    debugPrint('DEBUG: Scheduling retry for ${requestOptions.path}...');

    // Start a timer for the overall retry attempt
    timeoutTimer = Timer(timeout, () {
      streamSubscription?.cancel(); // Cancel the subscription if timeout occurs
      if (!responseCompleter.isCompleted) {
        debugPrint(
          'ERROR: Retry for ${requestOptions.path} timed out after ${timeout.inSeconds} seconds.',
        );
        responseCompleter.completeError(
          TimeoutException(
            'Request retry timed out. No internet connection within ${timeout.inSeconds} seconds.',
          ),
        );
      }
    });

    // Listen for connection status changes
    streamSubscription = connectionChecker.onStatusChange.listen((
      InternetStatus status,
    ) async {
      if (status != InternetStatus.disconnected) {
        debugPrint(
          'DEBUG: Connection restored. Retrying request to ${requestOptions.path}...',
        );
        streamSubscription
            ?.cancel(); // Cancel subscription once connection is back
        timeoutTimer?.cancel(); // Cancel the timeout timer

        if (!responseCompleter.isCompleted) {
          try {
            // Retry the original request
            final response = await dio.fetch(requestOptions);
            responseCompleter.complete(response);
          } on DioException catch (e) {
            debugPrint(
              'ERROR: Retried request to ${requestOptions.path} failed again: ${e.message}',
            );
            responseCompleter.completeError(e); // Complete with the new error
          } catch (e) {
            debugPrint(
              'ERROR: Retried request to ${requestOptions.path} failed with unknown error: $e',
            );
            responseCompleter.completeError(e);
          }
        }
      } else {
        debugPrint('DEBUG: Still disconnected. Waiting for connection...');
      }
    });

    // Also check current status immediately in case connection is already back
    final currentStatus = await connectionChecker.hasInternetAccess;
    if (currentStatus) {
      debugPrint(
        'DEBUG: Connection already active. Retrying immediately for ${requestOptions.path}...',
      );
      streamSubscription.cancel(); // Cancel the subscription as it's not needed
      timeoutTimer.cancel(); // Cancel the timeout timer

      if (!responseCompleter.isCompleted) {
        try {
          final response = await dio.fetch(requestOptions);
          responseCompleter.complete(response);
        } on DioException catch (e) {
          debugPrint(
            'ERROR: Immediate retry for ${requestOptions.path} failed: ${e.message}',
          );
          responseCompleter.completeError(e);
        } catch (e) {
          debugPrint(
            'ERROR: Immediate retry for ${requestOptions.path} failed with unknown error: $e',
          );
          responseCompleter.completeError(e);
        }
      }
    }

    return responseCompleter.future;
  }
}

// --- RetryOnConnectionChangeInterceptor ---
/// Dio Interceptor that automatically retries requests when a
/// network connection error occurs and the connection status changes.
class RetryOnConnectionChangeInterceptor extends Interceptor {
  final DioConnectivityRequestRetrier requestRetrier;

  RetryOnConnectionChangeInterceptor({required this.requestRetrier});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Check if the error is a connection error and if it's retryable
    if (_shouldRetry(err)) {
      debugPrint(
        'DEBUG: Connection error detected for ${err.requestOptions.path}. Attempting retry...',
      );
      try {
        // Schedule the request to be retried when connection is back
        final response = await requestRetrier.scheduleRequestRetry(
          err.requestOptions,
        );
        // Resolve the original request with the new successful response
        return handler.resolve(response);
      } on DioException catch (e) {
        // If the retry itself fails (e.g., timeout, or another DioException),
        // reject the handler with the new error.
        debugPrint(
          'ERROR: Retry mechanism failed for ${err.requestOptions.path}: ${e.message}',
        );
        return handler.reject(e);
      } catch (e) {
        // Catch any other unexpected errors from the retrier
        debugPrint(
          'ERROR: Unexpected error during retry for ${err.requestOptions.path}: $e',
        );
        return handler.reject(
          DioException(requestOptions: err.requestOptions, error: e),
        );
      }
    }
    // If it's not a connection error we're looking for, or not retryable,
    // let the error pass through to the next handler.
    return handler.next(err);
  }

  /// Determines if a given DioException should trigger a retry.
  /// We specifically look for connection-related errors.
  bool _shouldRetry(DioException err) {
    // DioExceptionType.connectionError is the most direct way to check for network issues
    // in Dio 5.x+. It covers SocketException, HandshakeException, etc.
    if (err.type == DioExceptionType.connectionError) {
      debugPrint('DEBUG: Detected DioExceptionType.connectionError.');
      return true;
    }

    // Fallback for older Dio versions or specific cases where connectionError might not be caught
    // by checking for SocketException directly.
    if (err.type == DioExceptionType.unknown && err.error is SocketException) {
      debugPrint(
        'DEBUG: Detected SocketException via DioExceptionType.unknown.',
      );
      return true;
    }

    // You might also consider other types if your API returns specific status codes
    // for temporary network issues, e.g., 503 Service Unavailable, 504 Gateway Timeout.
    // However, for pure "no internet" retry, connectionError/SocketException is key.
    // if (err.response?.statusCode == 503 || err.response?.statusCode == 504) {
    //   return true;
    // }

    return false;
  }
}
