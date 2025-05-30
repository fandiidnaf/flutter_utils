import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/auth_bloc.dart';
import '../../routes/app_routes.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Register new account'),
            ElevatedButton(
              onPressed: () {
                context.read<AuthBloc>().add(
                  RegisterEvent(
                    username: "username",
                    password: "password",
                    email: "email",
                    profilePicturePath: null,
                  ),
                );
              },
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is AuthLoading) {
                    return const CircularProgressIndicator();
                  }
                  return const Text('Register Now');
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.goNamed(AppRoutes.login.name);
              },
              child: Text("Already have a account? back to login"),
            ),
          ],
        ),
      ),
    );
  }
}
