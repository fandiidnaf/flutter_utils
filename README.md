# flutter_utils

A collection of useful utilities and common implementations for Flutter applications, designed to streamline development and promote best practices.

---

## 🚀 Features & Modules

### 🎨 Theme Management

Provides robust theme management capabilities, supporting Light, Dark, and System modes for a dynamic user experience.

#### Dependencies:
* `flutter_bloc`: For state management.
* `hive_ce_flutter`: For local data persistence (e.g., saving theme preferences).

### 🌈 Color Extension

Enhances Flutter's `Color` class with additional utility methods for easier color manipulation and usage.

#### Dependencies:
* (Inherits dependencies from Theme Management if integrated, otherwise specify if standalone)

### 🔐 Auth Wrapper

A flexible authentication wrapper designed to simplify user authentication flows, integrating with common routing and state management solutions.

#### Dependencies:
* `go_router`: For declarative routing.
* `flutter_bloc`: For state management.
* `equatable`: For value equality comparisons in BLoC states.
* `fpdart`: For functional programming paradigms (e.g., handling `Either` for success/failure states).

### 🌐 DIO Interceptors

A comprehensive set of interceptors for the `dio` HTTP client, providing common functionalities like token handling, logging, caching, and retry mechanisms.

#### 🔑 Token Interceptor
Automatically attaches authentication tokens to requests and handles token refreshing.

##### Dependencies:
* `dio`: The HTTP client.
* `synchronized`: For ensuring thread-safe operations, especially during token refreshing.

#### 📝 Logger Interceptor
Provides detailed logging of HTTP requests and responses for debugging and monitoring.

##### Dependencies:
* `dio`: The HTTP client.
* `pretty_dio_logger`: For formatted and readable console output.

#### 📦 Cache Interceptor
Implements caching strategies for HTTP responses to improve performance and reduce network calls.

##### Dependencies:
* `dio`: The HTTP client.
* `dio_cache_interceptor`: The core caching library for Dio.
* `http_cache_hive_store`: A Hive-based store for caching HTTP responses.
* `path_provider`: For accessing platform-specific file system paths (required by `http_cache_hive_store`).

#### 🔄 Retry on Connectivity Change Interceptor
Automatically retries failed network requests when internet connectivity is restored.

##### Dependencies:
* `dio`: The HTTP client.
* `internet_connection_checker_plus`: For checking internet connectivity status.

##### Permissions Required:
To use the `RetryOnConnectivityChange Interceptor`, ensure the following permissions are added to your project:

* **Android (`AndroidManifest.xml`):**
    ```xml
    <uses-permission android:name="android.permission.INTERNET" />
    ```

* **macOS (`.entitlements` file, e.g., `Release.entitlements`):**
    ```xml
    <key>com.apple.security.network.client</key>
    <true/>
    ```

# Firebase
    1. create project in firebase
    2. run command 'firebase login' in your local bash
    3. install flutterfire_cli : dart pub global activate flutterfire_cli
    4. run command: flutterfire configure --project=flutter-utils-92a2e
    5. update minSdk to 21
    6. fvm flutter pub add firebase_core

## 1. Firebase Messaging
    1. fvm flutter pub add firebase_messaging
    2. on Ios: enable push notification in xcode
    3. fvm flutter pub add url_launcher
    4. configure android in 'AndroidManifest.xml':
       '''
        <meta-data
            android:name="firebase_messaging_auto_init_enabled"
            android:value="false" />
        <meta-data
            android:name="firebase_analytics_collection_enabled"
            android:value="false" />
       '''
    5. configure ios in 'Info.plist':
    FirebaseMessagingAutoInitEnabled = NO


# Flutter Local Notifications
1. fvm flutter pub add flutter_local_notifications
2. read the documentation of flutter_local_notification 
3. fvm flutter pub add timezone
4. configure :
    android:
        1. edit android/app/build.gradle.kts:
            '''

            ...

            android {
                ...
                compileSdk = 35
                ...

                compileOptions {
                    isCoreLibraryDesugaringEnabled = true
                    ...
                }
                
                ...
                defaultConfig {
                    ...
                    targetSdk = 35
                    ...
                    multiDexEnabled = true
                }
                ...

            }

            ...

            // FLUTTTER LOCAL NOTIFICATIONS
            dependencies {
                coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
                implementation("androidx.window:window:1.0.0")
                implementation("androidx.window:window-java:1.0.0")
            }
            // FLUTTTER LOCAL NOTIFICATIONS
            '''

        2. edit AndroidManifest.xml:
            '''
            <manifest>
                ...
                <!-- FLUTTER LOCAL NOTIFICATIONS -->
                <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
                <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
                <uses-permission android:name="android.permission.USE_EXACT_ALARM" />
                <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
                <uses-permission android:name="android.permission.ACCESS_NOTIFICATION_POLICY" />
                <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
                <uses-permission android:name="android.permission.VIBRATE" />
                <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
                <!-- FLUTTER LOCAL NOTIFICATIONS -->
                ...

                <application
                    ...
                    <activity
                        ...
                        android:showWhenLocked="true"
                        android:turnScreenOn="true">
                        ...
                    </activity>
                    ...
                    <!-- FLUTTER LOCAL NOTIFICATIONS -->
                    <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
                    <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
                        <intent-filter>
                            <action android:name="android.intent.action.BOOT_COMPLETED"/>
                            <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                            <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                            <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
                        </intent-filter>
                    </receiver>

                    <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver" />

                    <service
                        android:name="com.dexterous.flutterlocalnotifications.ForegroundService"
                        android:exported="false"
                        android:stopWithTask="false"
                        android:foregroundServiceType="mediaPlayback"/>
                    <!-- FLUTTER LOCAL NOTIFICATIONS -->
                    ...
                </applcication>
            </manifest>
            '''

        3. add raw folder in android/app/src/main/res/ -> android/app/src/main/res/raw
            3.a add keep.xml:
                '''
                <resources xmlns:tools="http://schemas.android.com/tools"
                    tools:keep="@drawable/*, @mipmap/*, @raw/*" />
                '''
            3.b add custom_sound_notification (Optional)
                ex : local_notif.mp3
    
    2. ios:
        1. edit file ios/Runner/AppDelegate.swift:
            '''
            import Flutter
            import UIKit

            // FLUTTER LOCAL NOTIFICATIONS
            import flutter_local_notifications
            // FLUTTER LOCAL NOTIFICATIONS

            @main
            @objc class AppDelegate: FlutterAppDelegate {
                override func application(
                    _ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
                ) -> Bool {
                    
                    // FLUTTER LOCAL NOTIFICATIONS
                    // This is required to make any communication available in the action isolate.
                    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
                        GeneratedPluginRegistrant.register(with: registry)
                    }

                    if #available(iOS 10.0, *) {
                    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
                    }

                    if(!UserDefaults.standard.bool(forKey: "Notification")) {
                    UIApplication.shared.cancelAllLocalNotifications()
                    UserDefaults.standard.set(true, forKey: "Notification")
                    }
                    // FLUTTER LOCAL NOTIFICATIONS

                    GeneratedPluginRegistrant.register(with: self)
                    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
                }
            }
            '''
        2. add custom sound notification in ios/xx.airf (Optional)
            ex: ios/custom_sound.airf
