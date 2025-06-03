import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../local_notification/helper/app_notification_helper.dart';

/// A top-level function to handle background messages.
/// This function must be a top-level function (outside of any class)
/// and annotated with `@pragma('vm:entry-point')` to work correctly
/// when the app is in the background or terminated.
///
/// This is where you would integrate your `flutter_local_notification`
/// logic to display the notification.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.data}");
  await AppNotificationHelper.onNotificationReceived(message);
}

/// A singleton class to manage Firebase Cloud Messaging (FCM) services.
/// This class handles FCM initialization, permission requests, token management,
/// and listening for incoming messages in various app states.
///
/// It provides callbacks for external logic to process notifications
/// and send FCM tokens to your backend.
///
///
/// THE JOB OF FCM IS FOR CALL 'LOCAL NOTIFICATION'
///
/// LOCAL NOTIFICATION MUST BE CALL, IN FOREGROUND AND IN THE BACKGROUNDHANDLER
///
/// IF MESSAGE HAS ARRIVE FROM FIREBASE, THEN TRIGGER LOCAL NOTIFICATION PLUGIN TO SHOW THE LOCAL NOTIFICATION
///
/// FOR HANDLING ROUTE IN APP ITU MUST BE LOCAL NOTIFICATION
final class FcmService {
  // Private constructor for the singleton pattern.
  FcmService._();

  /// The single instance of [FcmService].
  static final FcmService instance = FcmService._();

  // Flag to ensure setup runs only once.
  static bool _setupAlreadyRunning = false;

  // Stores the initial message received when the app was terminated.
  static RemoteMessage? _initialMessageFromTerminated;

  /// The Firebase Messaging plugin instance.
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  FirebaseMessaging get fcm => _fcm;

  /// Callback function to be executed when a notification is received
  /// in the foreground or when the app is opened from a background/terminated state.
  /// This is where you would typically show a local notification or navigate.
  static late Function(RemoteMessage message) _onNotificationReceived;

  /// Callback function to be executed when the FCM token is generated or refreshed.
  /// This is where you would send the token to your backend server.
  late Function(String token) _onTokenRefreshCallback;

  /// Initializes the FCM service.
  ///
  /// This method should be called once, typically early in your application's lifecycle.
  ///
  /// [onNotificationReceived]: A required callback to handle incoming [RemoteMessage]s.
  ///   This callback will be invoked for messages received in the foreground,
  ///   or when the app is opened from background/terminated state via a notification.
  ///   It's responsible for showing local notifications.
  ///   This function must be top level function with @pragma(vm:entry-point)
  ///
  /// [onTokenRefresh]: A required callback to handle FCM token generation and refresh.
  ///   Use this to send the FCM token to your backend server.
  ///
  Future<void> setup({
    required Function(RemoteMessage message) onNotificationReceived,
    required Function(String token) onTokenRefresh,
  }) async {
    if (_setupAlreadyRunning) {
      debugPrint("FcmService setup already running, skipping.");
      return;
    }

    _onNotificationReceived = onNotificationReceived;
    _onTokenRefreshCallback = onTokenRefresh;

    // Register the top-level background message handler.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Set up listeners for all notification states.
    await _setupNotificationListeners();

    _setupAlreadyRunning = true;
    debugPrint("FcmService setup completed.");
  }

  /// Asserts that `setup()` has been called.
  /// This method should be called in `WidgetsBinding.instance.addPostFrameCallback`
  /// to handle notifications that opened the app from a terminated state.
  ///
  /// Example usage in a StatefulWidget's `initState`:
  /// ```dart
  /// @override
  /// void initState() {
  ///   super.initState();
  ///   WidgetsBinding.instance.addPostFrameCallback(
  ///     (_) => FcmService.instance.handleNotificationFromTerminated(),
  ///   );
  /// }
  /// ```
  // Future<void> handleNotificationFromTerminated() async {
  //   assert(
  //     _setupAlreadyRunning,
  //     "Call 'setup' method first before handling terminated messages.",
  //   );
  //   if (_initialMessageFromTerminated == null) {
  //     debugPrint("No initial message from terminated state.");
  //     return;
  //   }
  //   debugPrint(
  //     "Handling initial message from terminated state: ${_initialMessageFromTerminated!.data}",
  //   );
  //   _onNotificationReceived(_initialMessageFromTerminated!);
  //   _initialMessageFromTerminated = null; // Clear the message after handling
  // }

  /// Processes the FCM token: requests permission, gets the token,
  /// and sets up a listener for token refreshes.
  ///
  /// Asserts that `setup()` has already been called.
  Future<void> processToken() async {
    assert(
      _setupAlreadyRunning,
      "Call 'setup' method first before processing token.",
    );
    await _requestNotificationPermission();
    await _retrieveAndMonitorToken();
  }

  /// Requests notification permissions from the user.
  /// Handles platform-specific permissions (e.g., APNS token for iOS).
  Future<void> _requestNotificationPermission() async {
    debugPrint("Requesting notification permissions...");
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false, // Request full permission initially
      sound: true,
    );

    if (Platform.isIOS) {
      // Get APNS token for iOS devices
      String? apnsToken = await _fcm.getAPNSToken();
      debugPrint("APNS Token: $apnsToken");
    }

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint("User denied notification permission.");
      // Optionally, you might want to guide the user to app settings
      // or offer a provisional permission request again if needed.
      // For a more robust solution, consider showing a custom dialog
      // instead of relying on default system prompts.
    } else if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint("User granted notification permission.");
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint("User granted provisional notification permission.");
    }
  }

  /// Sets up listeners for messages received in different app states.
  Future<void> _setupNotificationListeners() async {
    // Get any message that caused the app to be opened from a terminated state.
    _initialMessageFromTerminated = await _fcm.getInitialMessage();
    if (_initialMessageFromTerminated != null) {
      debugPrint(
        "App launched from terminated state with message: ${_initialMessageFromTerminated!.data}",
      );
    }

    // Listen for messages when the app is in the foreground.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Received foreground message: ${message.data}");
      _onNotificationReceived(message);
    });

    // Listen for messages when the app is opened from a background state.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("App opened from background with message: ${message.data}");
      // _onNotificationReceived(message); // DON'T ENABLE THIS, IF YOU ENABLE, THE NOTIFICATION WILL SHOW TWICE
    });
  }

  /// Retrieves the FCM token and sets up a listener for token refreshes.
  Future<void> _retrieveAndMonitorToken() async {
    // Ensure auto-initialization is enabled (usually true by default).
    await _fcm.setAutoInitEnabled(true);

    // Get the current FCM token.
    final String? fcmToken = await _fcm.getToken();
    if (fcmToken != null) {
      debugPrint("Current FCM Token: $fcmToken");
      await _onTokenRefreshCallback(fcmToken); // Send initial token to server
    } else {
      debugPrint("FCM Token is null.");
    }

    // Listen for token refreshes and send the new token to the server.
    _fcm.onTokenRefresh
        .listen((String newToken) {
          debugPrint("FCM Token refreshed: $newToken");
          _onTokenRefreshCallback(newToken); // Send refreshed token to server
        })
        .onError((error) {
          debugPrint("Error listening to token refresh: $error");
        });
  }

  /// Subscripe a topic
  Future<void> subscribeToTopic({required String topic}) async {
    return await _fcm.subscribeToTopic(topic);
  }

  /// Unsubscribe a topic
  Future<void> unsubscribeFromTopic({required String topic}) async {
    return await _fcm.unsubscribeFromTopic(topic);
  }
}
