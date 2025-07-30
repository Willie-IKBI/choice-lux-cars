import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/simple_app_bar.dart';

class VouchersScreen extends StatelessWidget {
  const VouchersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleAppBar(
        title: 'Vouchers',
        subtitle: 'Manage vouchers',
        showBackButton: true,
        onBackPressed: () => context.go('/'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_giftcard,
              size: 64,
              color: Colors.teal,
            ),
            SizedBox(height: 16),
            Text(
              'Vouchers Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Coming soon...'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add voucher
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 