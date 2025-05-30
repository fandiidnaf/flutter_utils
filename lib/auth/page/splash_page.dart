import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart'; // Untuk navigasi menggunakan GoRouter

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Tunggu selama 2 detik
    await Future.delayed(const Duration(seconds: 2));
    // // Navigasi ke halaman login. Gunakan pushReplacementNamed agar pengguna tidak bisa kembali ke splash screen.
    // if (mounted) {
    //   // Pastikan widget masih ada di widget tree
    //   context.goNamed(
    //     AppRoutes.login.name,
    //   ); // Menggunakan GoRouter untuk navigasi
    // }

    // Di SplashScreen, kita bisa memicu pengecekan status autentikasi
    // Ini akan memicu redirect setelah status diketahui
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(CheckAuthStatusEvent());
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme
          .primaryColor, // Latar belakang splash screen sesuai primaryColor
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Anda bisa menggunakan Image.asset untuk logo gambar Anda
            // Contoh: Image.asset('assets/images/logo.png', width: 150, height: 150),
            Icon(
              Icons.local_car_wash, // Contoh ikon logo
              size: 120, // Ukuran ikon yang lebih besar
              color: Colors
                  .white, // Warna ikon putih agar kontras dengan primaryColor
            ),
            const SizedBox(height: 24), // Jarak antara ikon dan teks
            Text(
              'Splash Screen App', // Nama aplikasi Anda
              style: theme.textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5, // Sedikit jarak antar huruf
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Test Splash Screen', // Slogan atau deskripsi singkat
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white70, // Warna teks sedikit transparan
              ),
            ),
            const SizedBox(height: 48), // Jarak sebelum loading indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withValues(alpha: 0.8),
              ), // Warna loading indicator
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
