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
