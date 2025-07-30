import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/simple_app_bar.dart';

class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleAppBar(
        title: 'Invoices',
        subtitle: 'Manage billing',
        showBackButton: true,
        onBackPressed: () => context.go('/'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt,
              size: 64,
              color: Colors.purple,
            ),
            SizedBox(height: 16),
            Text(
              'Invoices Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Coming soon...'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add invoice
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 