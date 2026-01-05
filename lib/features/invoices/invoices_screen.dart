import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/widgets/system_safe_scaffold.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/utils/background_pattern_utils.dart';

class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});

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
        // Layer 3: The SystemSafeScaffold with proper system UI handling
        SystemSafeScaffold(
          backgroundColor: Colors.transparent,
          appBar: LuxuryAppBar(
            title: 'Invoices',
            showBackButton: true,
            onBackPressed: () => context.go('/'),
          ),
          body: Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final spacing = ResponsiveTokens.getSpacing(screenWidth);
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt, size: ResponsiveTokens.getIconSize(screenWidth) * 2.5, color: Colors.purple),
                    SizedBox(height: spacing * 2),
                    Text(
                      'Invoices Management',
                      style: TextStyle(fontSize: ResponsiveTokens.getFontSize(screenWidth, baseSize: 24), fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: spacing * 2),
                    Text('Coming soon...'),
                  ],
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              // TODO: Implement add invoice
            },
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
