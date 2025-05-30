import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/auth_bloc.dart';
import '../page/account/account_page.dart';
import '../page/account/update_account_page.dart';
import '../page/base_app.dart';
import '../page/home/home_page.dart';
import '../page/home/transaction_form_page.dart';
import '../page/login/login_page.dart';
import '../page/login/register_page.dart';
import '../page/splash_page.dart';

// Kelas untuk struktur rute
final class RouteStructure {
  final String name;
  final String path;

  const RouteStructure({required this.name, required this.path});
}

class AppRoutes {
  const AppRoutes._();

  static final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>();

  // Daftar rute yang dapat diakses publik (tanpa autentikasi)
  static final _publicRoutes = [login.path, register.path];

  static final router = GoRouter(
    debugLogDiagnostics: true,
    navigatorKey: _navigatorKey,
    initialLocation:
        splashScreen.path, // Menggunakan splashScreen yang sudah diperbaiki
    // Callback redirect akan dieksekusi setiap kali ada perubahan state navigasi atau AuthBloc
    redirect: (BuildContext context, GoRouterState state) async {
      // Ambil state autentikasi saat ini dari AuthBloc
      final authState = context.read<AuthBloc>().state;

      // Cek apakah rute saat ini adalah rute publik (login/register)
      final bool isAuthRoute = _publicRoutes.contains(state.uri.path);
      // Cek apakah rute saat ini adalah splash screen
      final bool isSplashScreen = state.uri.path == splashScreen.path;

      // --- Logika Redirect ---

      // 1. Jika di Splash Screen:
      // Biarkan tetap di splash screen selama AuthBloc masih dalam keadaan initial atau loading.
      if (isSplashScreen) {
        if (authState is AuthInitial || authState is AuthLoading) {
          return null; // Tetap di splash screen
        }
        // Setelah loading selesai, arahkan ke rute yang sesuai
        return authState is Authenticated ? home.path : login.path;
      }

      // 2. Jika Pengguna Belum Terautentikasi (Unauthenticated) atau ada Error:
      // Arahkan ke halaman login jika mencoba mengakses rute yang memerlukan autentikasi.
      // Biarkan navigasi berlanjut jika sudah di rute publik (login/register).
      if (authState is Unauthenticated || authState is AuthError) {
        return isAuthRoute ? null : login.path;
      }

      // 3. Jika Pengguna Sudah Terautentikasi (Authenticated):
      // Jika pengguna sudah login dan mencoba mengakses rute publik (login/register),
      // arahkan mereka ke halaman transaksi (atau home).
      // Untuk rute lain yang memerlukan autentikasi, biarkan navigasi berlanjut.
      if (authState is Authenticated) {
        if (isAuthRoute) {
          return home.path; // Atau home.path
        }
        return null; // Biarkan navigasi lanjut ke rute yang diminta
      }

      // 4. Kasus Default:
      // Jika tidak ada kondisi redirect yang terpenuhi (misalnya, AuthBloc masih di AuthInitial/AuthLoading
      // tapi bukan di splash screen, atau state yang tidak terduga), biarkan navigasi berlanjut.
      return null;
    },

    routes: [
      // Splash Screen
      GoRoute(
        path: splashScreen.path,
        name: splashScreen.name,
        builder: (context, state) {
          return const SplashPage();
        },
      ),

      // Login Page
      GoRoute(
        path: login.path,
        name: login.name,
        builder: (context, state) => const LoginPage(),
      ),

      // Register Page
      GoRoute(
        path: register.path,
        name: register.name,
        builder: (context, state) => const RegisterPage(),
      ),

      // StatefulShellRoute untuk navigasi dengan bottom navigation bar
      StatefulShellRoute.indexedStack(
        branches: [
          // Branch untuk Transaction
          StatefulShellBranch(
            preload: true, // Preload rute di branch ini
            routes: [
              // Home Page
              GoRoute(
                path: home.path,
                name: home.name,
                builder: (context, state) {
                  // Akses User dari AuthBloc state secara langsung
                  final authState = context.read<AuthBloc>().state;
                  if (authState is Authenticated) {
                    return HomePage(userId: authState.user.id);
                  }
                  // Ini seharusnya tidak tercapai karena redirect akan mengarahkan
                  // jika tidak authenticated. Namun, sebagai fallback yang aman:
                  return const Text(
                    'Error: User not authenticated for Transaction Screen',
                  );
                },
              ),
              // Transaction Form Screen
              GoRoute(
                path: formTransaction.path,
                name: formTransaction.name,
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>;
                  return TransactionFormScreen(
                    userId: extra["userId"],
                    existing: extra["existing"],
                  );
                },
              ),
            ],
          ),
          // Branch untuk Account (Home)
          StatefulShellBranch(
            routes: [
              // Home (Root) - Menggunakan AccountPage sebagai home
              GoRoute(
                path: account.path,
                name: account.name,
                builder: (context, state) {
                  // Akses User dari AuthBloc state secara langsung
                  final authState = context.read<AuthBloc>().state;
                  if (authState is Authenticated) {
                    return AccountPage(user: authState.user);
                  }
                  // Fallback yang aman
                  return const Text(
                    'Error: User not authenticated for Account Page',
                  );
                },
              ),
              // Update Account Page
              GoRoute(
                path: updateAccount.path,
                name: updateAccount.name,
                builder: (context, state) {
                  // Akses User dari AuthBloc state secara langsung
                  final authState = context.read<AuthBloc>().state;
                  if (authState is Authenticated) {
                    return UpdateAccountPage(user: authState.user);
                  }
                  // Fallback yang aman
                  return const Text(
                    'Error: User not authenticated for Update Account Page',
                  );
                },
              ),
            ],
          ),
        ],
        builder: (context, state, navigationShell) =>
            BaseApp(navigationShell: navigationShell),
      ),
    ],
  );

  // Definisi rute
  static final RouteStructure splashScreen = RouteStructure(
    name: 'splash-screen',
    path: '/splash',
  );

  static final RouteStructure login = RouteStructure(
    name: 'login',
    path: '/login',
  );

  static final RouteStructure register = RouteStructure(
    name: 'register',
    path: '/register',
  );

  static final RouteStructure home = RouteStructure(name: 'home', path: '/');

  static final RouteStructure formTransaction = RouteStructure(
    name: 'form-transaction',
    path: '/form-transaction',
  );

  static final RouteStructure account = RouteStructure(
    name: 'account',
    path: '/account',
  );

  static final RouteStructure updateAccount = RouteStructure(
    name: "update_account",
    path: "/update-account",
  );
}
