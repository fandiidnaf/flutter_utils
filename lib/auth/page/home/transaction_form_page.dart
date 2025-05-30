import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_routes.dart';

class TransactionFormScreen extends StatelessWidget {
  final int userId;
  final bool existing;
  const TransactionFormScreen({
    super.key,
    required this.userId,
    required this.existing,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(existing ? 'Edit Transaction' : 'New Transaction'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Transaction Form for User ID: $userId (Existing: $existing)'),
            ElevatedButton(
              onPressed: () => context.goNamed(AppRoutes.home.name),
              child: const Text('Back to Transactions'),
            ),
          ],
        ),
      ),
    );
  }
}
