import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase/messaging/fcm_service.dart';
import 'firebase_options.dart';
import 'local_notification/helper/app_notification_helper.dart';
import 'local_notification/local_notif_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FcmService.instance.setup(
    onNotificationReceived: AppNotificationHelper.onNotificationReceived,
    onTokenRefresh: AppNotificationHelper.onTokenRefresh,
  );

  // Setup the notification service with your custom navigation logic
  await LocalNotifService.instance.setup(
    navigationCallback: AppNotificationHelper.onNavigationCallback,
  );
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
    // Handle notifications that launched the app from a terminated state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocalNotifService.instance.handleNotificationLaunch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // IMPORTANT: Assign the key
      title: 'Flutter Notification Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginPage(), // Your app's home screen
      routes: {
        '/home': (context) => const HomeScreen(),
        '/message_detail': (context) {
          final Map<String, dynamic> args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return MessageDetailScreen(messageId: args['messageId']);
        },
        // Define other routes as needed
      },
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  void _onLoginSuccess(BuildContext context) async {
    // Simulasikan login berhasil
    debugPrint("Pengguna berhasil login!");
    final navigator = Navigator.of(context);

    // Setelah login berhasil, minta izin notifikasi dan proses token FCM.
    // Ini adalah praktik terbaik untuk meminta izin setelah pengguna memahami
    // mengapa aplikasi membutuhkan notifikasi.
    await FcmService.instance.processToken();
    await LocalNotifService.instance.requestPermissions();

    // Navigasi ke halaman beranda setelah login.
    navigator.pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Silakan login untuk melanjutkan.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => _onLoginSuccess(context),
                icon: const Icon(Icons.login),
                label: const Text('Simulasikan Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Example of a custom screen for notification detail
class MessageDetailScreen extends StatelessWidget {
  final int messageId;
  const MessageDetailScreen({super.key, required this.messageId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Message Detail')),
      body: Center(child: Text('Viewing message with ID: $messageId')),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Screen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await LocalNotifService.instance.showNotification(
                  id: 0,
                  title: 'Immediate Notification',
                  body: 'This is a test notification!',
                  payload: jsonEncode({
                    'route': '/message_detail',
                    'messageId': 456,
                  }),
                );
              },
              child: const Text('Show Notification Now'),
            ),
            ElevatedButton(
              onPressed: () async {
                final DateTime scheduledTime = DateTime.now().add(
                  const Duration(seconds: 10),
                );
                await LocalNotifService.instance.scheduleNotification(
                  id: 1,
                  title: 'Scheduled Notification',
                  body: 'This notification will appear in 10 seconds.',
                  scheduledDate: scheduledTime,
                  payload: jsonEncode({
                    'route': '/message_detail',
                    'messageId': 789,
                  }),
                );
              },
              child: const Text('Schedule Notification (10s)'),
            ),
            ElevatedButton(
              onPressed: () async {
                await LocalNotifService.instance
                    .scheduleNotificationPeriodically(
                      id: 2,
                      title: 'Periodic Notification',
                      body: 'This notification repeats daily.',
                      repeatInterval: RepeatInterval.daily,
                      payload: jsonEncode({
                        'route': '/some_other_route',
                        'data': 'periodic',
                      }),
                    );
              },
              child: const Text('Schedule Daily Notification'),
            ),
            ElevatedButton(
              onPressed: () async {
                await LocalNotifService.instance.cancelNotification(0);
                debugPrint('Cancelled notification with ID 0');
              },
              child: const Text('Cancel Notif ID 0'),
            ),
            ElevatedButton(
              onPressed: () async {
                await LocalNotifService.instance.cancelAllNotifications();
                debugPrint('Cancelled all notifications');
              },
              child: const Text('Cancel All Notifications'),
            ),
            ElevatedButton(
              onPressed: () async {
                debugPrint('Subscribe news message');
                await FcmService.instance.subscribeToTopic(topic: 'news');
              },
              child: const Text('Subscribe message news'),
            ),
            ElevatedButton(
              onPressed: () async {
                debugPrint('Unsubscribe news message');
                await FcmService.instance.unsubscribeFromTopic(topic: 'news');
              },
              child: const Text('Unsubscribe message news'),
            ),
          ],
        ),
      ),
    );
  }
}
