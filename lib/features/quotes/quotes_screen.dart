import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/simple_app_bar.dart';
import '../../app/theme.dart';

class QuotesScreen extends StatelessWidget {
  const QuotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleAppBar(
        title: 'Quotes',
        subtitle: 'Manage quotations',
        showBackButton: true,
        onBackPressed: () => context.go('/'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description,
              size: 64,
              color: Colors.green,
            ),
            SizedBox(height: 16),
            Text(
              'Quotes Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Coming soon...'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add quote
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 