import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/utils/background_pattern_utils.dart';

class VouchersScreen extends StatelessWidget {
  const VouchersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Layer 1: The background that fills the entire screen
        Container(
          decoration: const BoxDecoration(
            gradient: ChoiceLuxTheme.backgroundGradient,
          ),
        ),
        // Layer 2: Background pattern that covers the entire screen
        Positioned.fill(
          child: CustomPaint(painter: BackgroundPatterns.dashboard),
        ),
        // Layer 3: The Scaffold with a transparent background
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: LuxuryAppBar(
            title: 'Vouchers',
            subtitle: 'Manage vouchers',
            showBackButton: true,
            onBackPressed: () => context.go('/'),
          ),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.card_giftcard, size: 64, color: Colors.teal),
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
        ),
      ],
    );
  }
}
