import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/widgets/system_safe_scaffold.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';
import 'package:choice_lux_cars/app/theme.dart';

class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: ChoiceLuxTheme.jetBlack),
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
