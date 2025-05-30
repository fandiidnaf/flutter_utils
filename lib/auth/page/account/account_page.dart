import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/auth_bloc.dart';
import '../../models/user.dart';
import '../../routes/app_routes.dart';

class AccountPage extends StatelessWidget {
  final User user;
  const AccountPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to Account, ${user.username}!'),
            Text('Email: ${user.email}'),
            ElevatedButton(
              onPressed: () => context.goNamed(AppRoutes.updateAccount.name),
              child: const Text('Update Account'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<AuthBloc>().add(LogoutEvent());
              },
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is AuthLoading) {
                    return const CircularProgressIndicator();
                  }
                  return const Text('Logout');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
