import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/user.dart';
import '../../routes/app_routes.dart';

class UpdateAccountPage extends StatelessWidget {
  final User user;
  const UpdateAccountPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Account')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Update Account for ${user.username}'),
            ElevatedButton(
              onPressed: () => context.goNamed(AppRoutes.home.name),
              child: const Text('Back to Account'),
            ),
          ],
        ),
      ),
    );
  }
}
