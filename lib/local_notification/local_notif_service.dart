// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_utils/local_notification/helper/app_notification_helper.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:flutter_utils/main_firebase_fcm.dart';

// --- Navigation Handlers (Decoupled) ---
// Define a type for your navigation callback
// typedef NotificationNavigationCallback =
//     void Function(String? payload, BuildContext context);
typedef NotificationNavigationCallback =
    void Function(
      NotificationResponse notificationResponse,
      BuildContext context,
    );

// Default navigation callback (can be overridden)
void _defaultNotificationNavigation(
  // String? payload,
  NotificationResponse notificationResponse,
  BuildContext context,
) {
  // You can define a default behavior, e.g., navigate to a generic detail screen
  // or just print the payload. For a truly general service, avoid hardcoding routes.
  debugPrint(
    'Handling notification with payload: ${notificationResponse.payload}',
  );
  // Example: Navigate to a simple screen to display the payload
  navigatorKey.currentState?.push(
    MaterialPageRoute<void>(
      builder: (context) => GenericNotificationDisplayScreen(
        payload: notificationResponse.payload,
      ),
    ),
  );
}

// A generic screen to display notification payload for demonstration
class GenericNotificationDisplayScreen extends StatelessWidget {
  const GenericNotificationDisplayScreen({super.key, this.payload});

  final String? payload;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Detail')),
      body: Center(
        child: Text(
          payload ?? 'No payload',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}

@pragma('vm:entry-point')
void onDidReceiveBackgroundNotificationResponse(
  NotificationResponse notificationResponse,
) async {
  debugPrint(
    'Background notification payload: ${notificationResponse.payload}',
  );
  await AppNotificationHelper.onDidReceiveBackgroundNotificationResponse(
    notificationResponse,
  );
}

// --- Local Notification Service ---
class LocalNotifService {
  const LocalNotifService._();

  static final LocalNotifService instance = LocalNotifService._();
  static final FlutterLocalNotificationsPlugin
  _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static NotificationResponse? _notificationFromTerminated;
  static NotificationNavigationCallback? _onNavigation;

  // --- Notification Response Handlers ---
  // These functions should ideally trigger a callback that is provided
  // to the LocalNotifService instance, rather than directly navigating.
  // This ensures greater flexibility.

  void onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse,
  ) {
    // final String? payload = notificationResponse.payload;
    debugPrint(
      'Foreground/Opened notification payload: ${notificationResponse.payload}',
    );

    // Trigger the navigation callback if it's set
    if (LocalNotifService._onNavigation != null &&
        navigatorKey.currentState?.context != null) {
      LocalNotifService._onNavigation!(
        // payload,
        notificationResponse,
        navigatorKey.currentState!.context,
      );
    } else {
      _defaultNotificationNavigation(
        // payload,
        notificationResponse,
        navigatorKey.currentState!.context,
      );
    }
  }

  /// Sets up the local notification plugin.
  /// This should be called early in your `main` function before `runApp`.
  ///
  /// Optionally accepts a `navigationCallback` to handle what happens
  /// when a notification is tapped.
  ///
  /// ```dart
  /// Future<void> main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await LocalNotifService.instance.setup(
  ///     navigationCallback: (payload, context) {
  ///       // Your custom navigation logic here
  ///       Navigator.of(context).push(MaterialPageRoute(
  ///         builder: (_) => MyCustomNotificationScreen(data: payload),
  ///       ));
  ///     },
  ///   );
  ///   runApp(MyApp());
  /// }
  /// ```
  Future<void> setup({
    NotificationNavigationCallback? navigationCallback,
  }) async {
    _onNavigation = navigationCallback ?? _defaultNotificationNavigation;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Request permissions more granularly for iOS/macOS later in `requestPermissions`
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestSoundPermission: false,
          requestBadgePermission: false,
          requestAlertPermission: false,
        );
    final DarwinInitializationSettings initializationSettingsDarwinMac =
        DarwinInitializationSettings(
          requestSoundPermission: false,
          requestBadgePermission: false,
          requestAlertPermission: false,
        );

    final LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');
    final WindowsInitializationSettings
    initializationSettingsWindows = WindowsInitializationSettings(
      appName: 'Flutter Local Notifications Example', // Customize this
      appUserModelId: 'Com.YourCompany.YourApp', // Change this to your app's ID
      guid: 'd49b0314-ee7a-4626-bf79-97cdb8a991bb', // Generate your own GUID
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
          macOS: initializationSettingsDarwinMac,
          linux: initializationSettingsLinux,
          windows: initializationSettingsWindows,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
    );

    tz.initializeTimeZones(); // Initialize time zones for scheduled notifications
    await _getNotificationFromTerminatedState();
  }

  /// Requests notification permissions from the user.
  /// Call this in your app's main flow, e.g., after successful login or
  /// in the app's home screen after a brief delay.
  Future<void> requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        await androidImplementation?.requestNotificationsPermission();
        // You might want to consider when to request these:
        await androidImplementation?.requestFullScreenIntentPermission();
        await androidImplementation?.requestExactAlarmsPermission();
      } else if (Platform.isIOS) {
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
              critical: true,
              provisional: true,
            );
      } else if (Platform.isMacOS) {
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
              critical: true,
              provisional: true,
            );
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  /// Checks if the app was launched by tapping a notification when terminated.
  /// This method is for internal use during setup.
  Future<void> _getNotificationFromTerminatedState() async {
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      final NotificationAppLaunchDetails? notificationLaunchDetails =
          await _flutterLocalNotificationsPlugin
              .getNotificationAppLaunchDetails();

      if (notificationLaunchDetails != null &&
          notificationLaunchDetails.didNotificationLaunchApp &&
          notificationLaunchDetails.notificationResponse != null) {
        _notificationFromTerminated =
            notificationLaunchDetails.notificationResponse!;
      }
    }
  }

  /// Handles notification taps that launched the app from a terminated state.
  /// Call this in your main app widget's `initState` wrapped with
  /// `WidgetsBinding.instance.addPostFrameCallback`.
  ///
  /// ```dart
  /// @override
  /// void initState() {
  ///   super.initState();
  ///   WidgetsBinding.instance.addPostFrameCallback((_) {
  ///     LocalNotifService.instance.handleNotificationLaunch();
  ///   });
  /// }
  /// ```
  void handleNotificationLaunch() {
    if (_notificationFromTerminated != null) {
      debugPrint(
        'Handling terminated notification payload: ${_notificationFromTerminated!.payload}',
      );
      onDidReceiveNotificationResponse(_notificationFromTerminated!);
      _notificationFromTerminated = null; // Clear it after handling
    }
  }

  /// Shows an immediate notification.
  ///
  /// [id]: A unique identifier for the notification.
  /// [title]: The title of the notification.
  /// [body]: The body text of the notification.
  /// [payload]: Optional data associated with the notification (e.g., JSON string).
  /// [androidSpecifics]: Optional Android-specific notification details.
  /// [iOSSpecifics]: Optional iOS-specific notification details.
  /// [platformSpecifics]: Optional general platform-specific details (overrides android/iOS if provided).
  Future<void> showNotification({
    required int id,
    String? title,
    String? body,
    String? payload,
    AndroidNotificationDetails? androidSpecifics,
    DarwinNotificationDetails? iOSSpecifics,
    NotificationDetails? platformSpecifics,
  }) async {
    final NotificationDetails notificationDetails =
        platformSpecifics ??
        NotificationDetails(
          android:
              androidSpecifics ??
              const AndroidNotificationDetails(
                'channel_id', // Must be a unique ID
                'channel_name',
                channelDescription: 'channel_description',
                importance: Importance.max,
                priority: Priority.high,
                ticker: 'ticker',
              ),
          iOS:
              iOSSpecifics ??
              const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
        );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Schedules a notification to appear at a specific time.
  ///
  /// [id]: A unique identifier for the notification.
  /// [title]: The title of the notification.
  /// [body]: The body text of the notification.
  /// [scheduledDate]: The exact date and time to show the notification.
  /// [payload]: Optional data associated with the notification (e.g., JSON string).
  /// [androidSpecifics]: Optional Android-specific notification details.
  /// [iOSSpecifics]: Optional iOS-specific notification details.
  /// [platformSpecifics]: Optional general platform-specific details.
  Future<void> scheduleNotification({
    required int id,
    String? title,
    String? body,
    required DateTime scheduledDate,
    String? payload,
    AndroidNotificationDetails? androidSpecifics,
    DarwinNotificationDetails? iOSSpecifics,
    NotificationDetails? platformSpecifics,
  }) async {
    final NotificationDetails notificationDetails =
        platformSpecifics ??
        NotificationDetails(
          android:
              androidSpecifics ??
              const AndroidNotificationDetails(
                'scheduled_channel_id',
                'Scheduled Notifications',
                channelDescription: 'Notifications scheduled for a future time',
                importance: Importance.max,
                priority: Priority.high,
              ),
          iOS:
              iOSSpecifics ??
              const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
        );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      payload: payload,
    );
  }

  /// Schedules a notification to appear periodically.
  ///
  /// [id]: A unique identifier for the notification.
  /// [title]: The title of the notification.
  /// [body]: The body text of the notification.
  /// [repeatInterval]: The interval at which the notification should repeat.
  /// [payload]: Optional data associated with the notification (e.g., JSON string).
  /// [androidSpecifics]: Optional Android-specific notification details.
  /// [iOSSpecifics]: Optional iOS-specific notification details.
  /// [platformSpecifics]: Optional general platform-specific details.
  Future<void> scheduleNotificationPeriodically({
    required int id,
    String? title,
    String? body,
    required RepeatInterval repeatInterval,
    String? payload,
    AndroidNotificationDetails? androidSpecifics,
    DarwinNotificationDetails? iOSSpecifics,
    NotificationDetails? platformSpecifics,
  }) async {
    final NotificationDetails notificationDetails =
        platformSpecifics ??
        NotificationDetails(
          android:
              androidSpecifics ??
              const AndroidNotificationDetails(
                'periodic_channel_id',
                'Periodic Notifications',
                channelDescription: 'Notifications that repeat periodically',
                importance: Importance.max,
                priority: Priority.high,
              ),
          iOS:
              iOSSpecifics ??
              const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
        );

    await _flutterLocalNotificationsPlugin.periodicallyShow(
      id,
      title,
      body,
      repeatInterval,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  /// Cancels a specific notification by its ID.
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Cancels all pending notifications.
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Retrieves a list of all pending notifications.
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }
}
