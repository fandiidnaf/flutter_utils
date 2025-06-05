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

## 🔥 Firebase Integration

Firebase integration is essential for push notifications and other backend services. Below are the complete setup instructions.

> **Note:** If you're using `firebase_messaging`, it is **mandatory** to use `flutter_local_notifications` to properly display notifications on both Android and iOS.

---

### ✅ Initial Firebase Setup

1. Create a new project at [Firebase Console](https://console.firebase.google.com/).
2. In your terminal, run:

   ```bash
   firebase login
   ```
3. Install FlutterFire CLI:

   ```bash
   dart pub global activate flutterfire_cli
   ```
4. Configure Firebase with your project:

   ```bash
   flutterfire configure --project=flutter-utils-92a2e
   ```
5. Set `minSdkVersion` to `21` in `android/app/build.gradle`.
6. Add core Firebase package:

   ```bash
   fvm flutter pub add firebase_core
   ```

---

### 📬 Firebase Messaging Setup

1. Add the messaging package:

   ```bash
   fvm flutter pub add firebase_messaging
   ```
2. Add deep link support:

   ```bash
   fvm flutter pub add url_launcher
   ```
3. iOS Configuration:

   * Enable **Push Notifications** in Xcode capabilities.
   * Add to `ios/Runner/Info.plist`:

     ```xml
     <key>FirebaseMessagingAutoInitEnabled</key>
     <false/>
     ```
4. Android Configuration:

   * Add the following to `android/app/src/main/AndroidManifest.xml`:

     ```xml
     <meta-data
         android:name="firebase_messaging_auto_init_enabled"
         android:value="false" />
     <meta-data
         android:name="firebase_analytics_collection_enabled"
         android:value="false" />
     ```

---

## 🔔 Flutter Local Notifications Setup

To display notifications on the device using `firebase_messaging`, `flutter_local_notifications` is required.

### 📦 Install Dependencies

```bash
fvm flutter pub add flutter_local_notifications
fvm flutter pub add timezone
```

### ⚙️ Android Configuration

#### 1. `android/app/build.gradle.kts`

```kotlin
android {
    compileSdk = 35

    defaultConfig {
        targetSdk = 35
        multiDexEnabled = true
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.window:window:1.0.0")
    implementation("androidx.window:window-java:1.0.0")
}
```

#### 2. `AndroidManifest.xml`

```xml
<manifest>
    <!-- FLUTTER LOCAL NOTIFICATIONS -->
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.USE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
    <uses-permission android:name="android.permission.ACCESS_NOTIFICATION_POLICY" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <application>
        <activity
            android:showWhenLocked="true"
            android:turnScreenOn="true">
        </activity>

        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />

        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON" />
            </intent-filter>
        </receiver>

        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver" />

        <service
            android:name="com.dexterous.flutterlocalnotifications.ForegroundService"
            android:exported="false"
            android:stopWithTask="false"
            android:foregroundServiceType="mediaPlayback" />
    </application>
</manifest>
```

#### 3. Add raw assets

* Create folder: `android/app/src/main/res/raw`
* Add a custom sound file (optional): `local_notif.mp3`
* Add a `keep.xml` file:

```xml
<resources xmlns:tools="http://schemas.android.com/tools"
    tools:keep="@drawable/*, @mipmap/*, @raw/*" />
```

---

### 🍏 iOS Configuration

1. Edit `ios/Runner/AppDelegate.swift`:

```swift
import Flutter
import UIKit

// FLUTTER LOCAL NOTIFICATIONS
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // Required to make communication available in action isolate
        FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
            GeneratedPluginRegistrant.register(with: registry)
        }

        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
        }

        if !UserDefaults.standard.bool(forKey: "Notification") {
            UIApplication.shared.cancelAllLocalNotifications()
            UserDefaults.standard.set(true, forKey: "Notification")
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
```

2. (Optional) Add custom sound to `ios/Runner` (e.g., `custom_sound.airf`).
