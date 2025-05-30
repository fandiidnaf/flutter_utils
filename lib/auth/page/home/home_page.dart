import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/auth_bloc.dart';
import '../../routes/app_routes.dart';

class HomePage extends StatelessWidget {
  final int userId;
  const HomePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to Transactions, User ID: $userId'),
            ElevatedButton(
              onPressed: () {
                context.goNamed(
                  AppRoutes.formTransaction.name,
                  extra: {"userId": userId, "existing": false},
                );
              },
              child: const Text('Add New Transaction'),
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
