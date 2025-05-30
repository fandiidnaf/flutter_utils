import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/auth_bloc.dart';
import '../../routes/app_routes.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Please log in'),
            ElevatedButton(
              onPressed: () {
                // Simulasi login sukses (ganti menjadi true untuk sukses)
                // final dummyUser = User(
                //   id: 1,
                //   username: 'john_doe',
                //   email: 'john@example.com',
                //   password: 'password123',
                //   profilePicturePath: null,
                //   token: 'dummy_token_123',
                // );

                context.read<AuthBloc>().add(
                  LoginEvent(username: 'john_doe', password: "123456"),
                );
              },
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is AuthLoading) {
                    return const CircularProgressIndicator();
                  }
                  return const Text('Login');
                },
              ),
            ),
            TextButton(
              onPressed: () => context.goNamed(AppRoutes.register.name),
              child: const Text('Don\'t have an account? Register'),
            ),
            // Menampilkan pesan error jika AuthBloc mengeluarkan AuthError
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthError && state.statusCode != 401) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Error: ${state.message}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
