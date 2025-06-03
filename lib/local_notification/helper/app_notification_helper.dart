import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../local_notif_service.dart';

class AppNotificationHelper {
  const AppNotificationHelper._();

  static Future<void> onNotificationReceived(RemoteMessage message) async {
    debugPrint("notification must be created in here");

    debugPrint(
      "what 's data: ${Map.fromEntries(message.data.entries.where((entry) => !["title", "body"].contains(entry.key)))}",
    );

    await LocalNotifService.instance.showNotification(
      id: message.messageId.hashCode,
      title: message.data["title"],
      body: message.data["body"],
      androidSpecifics: AndroidNotificationDetails(
        "0",
        "test",
        importance: Importance.max,
        priority: Priority.max,
        actions: [
          AndroidNotificationAction(
            "msg",
            "message",
            inputs: [AndroidNotificationActionInput()],
          ),
          AndroidNotificationAction(
            "show",
            "Open App",
            showsUserInterface: true,
          ),
        ],
      ),
      payload: jsonEncode(
        Map.fromEntries(
          message.data.entries.where(
            (entry) => !["title", "body"].contains(entry.key),
          ),
        ),
      ),
    );
  }

  static Future<void> onTokenRefresh(String token) async {
    debugPrint("token has refreshed: $token");
    try {
      // Replace with your actual server endpoint and logic
      final response = await Dio().post(
        "http://192.168.5.228:8000/register-token", // IMPORTANT: Replace with your actual server URL
        data: {"token": token},
        // options: Options(headers: {"Content-Type": "application/json"}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint(
          "Token sent to server successfully: ${response.data["message"]}",
        );
      } else {
        debugPrint(
          "Failed to send token to server. Status: ${response.statusCode}, Response: ${response.data}",
        );
      }
    } on DioException catch (e) {
      debugPrint(
        'Failed to send token (DioError): ${e.message} - ${e.error} - ${e.type}\n${e.stackTrace}',
      );
      if (e.response != null) {
        debugPrint('Server response: ${e.response?.data}');
      }
    } catch (e, stackTrace) {
      debugPrint(
        'Failed to send token (Generic Error): $e, stackTrace: $stackTrace',
      );
    }
  }

  static void onNavigationCallback(
    NotificationResponse notificationResponse,
    BuildContext context,
  ) {
    if (notificationResponse.payload != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(
          notificationResponse.payload!,
        );
        final String? route = data['route'];
        if (route != null) {
          // Example: Navigate using named routes
          // context.pushNamed
          Navigator.of(context).pushNamed(route, arguments: data);
        } else {
          // Fallback: Display payload in a generic screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GenericNotificationDisplayScreen(
                payload: notificationResponse.payload!,
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('Failed to parse notification payload: $e');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GenericNotificationDisplayScreen(
              payload: notificationResponse.payload!,
            ),
          ),
        );
      }
    }
  }

  static Future<void> onDidReceiveBackgroundNotificationResponse(
    NotificationResponse notificationResponse,
  ) async {
    debugPrint("notificationResponse has come");
    debugPrint("action id: ${notificationResponse.actionId}");
    if (notificationResponse.actionId == "msg") {
      debugPrint("input: ${notificationResponse.input}");
    }
    // TODO HANDLE NOTIFICATION ACTION LIKE BALAS PESAN
    // This function runs in an isolate, so direct UI updates are not possible.
    // You would typically handle data processing or push to a stream here.
    // If you need to navigate, you might save the payload to shared preferences
    // and handle it when the app resumes/launches.

    // For demonstration, just print. In a real app, you might use:
    // final payload = notificationResponse.payload;
    // if (payload != null) {
    //   // Process payload, e.g., send to analytics, update database
    // }
  }
}
