import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/features/clients/providers/clients_provider.dart';
import 'package:choice_lux_cars/features/clients/screens/add_edit_client_screen.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/widgets/system_safe_scaffold.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';
import 'package:choice_lux_cars/app/theme.dart';

class EditClientScreen extends ConsumerWidget {
  final String clientId;

  const EditClientScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(clientProvider(clientId));

    return clientAsync.when(
      data: (client) {
        if (client == null) {
          return SystemSafeScaffold(
            backgroundColor: Colors.transparent,
            appBar: LuxuryAppBar(
              title: 'Edit Client',
              showBackButton: true,
              onBackPressed: () => context.go('/clients'),
            ),
            body: Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                final spacing = ResponsiveTokens.getSpacing(screenWidth);
                return Container(
                  color: ChoiceLuxTheme.jetBlack,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: ChoiceLuxTheme.errorColor,
                        ),
                        SizedBox(height: spacing * 2),
                        Text(
                          'Client not found',
                          style: TextStyle(
                            color: ChoiceLuxTheme.softWhite,
                            fontSize: ResponsiveTokens.getFontSize(screenWidth, baseSize: 18),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }

        return AddEditClientScreen(client: client);
      },
      loading: () => Scaffold(
        body: Container(
          color: ChoiceLuxTheme.jetBlack,
          child: const SafeArea(
            child: Center(
              child: CircularProgressIndicator(color: ChoiceLuxTheme.richGold),
            ),
          ),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Builder(
          builder: (context) {
            final screenWidth = MediaQuery.of(context).size.width;
            final spacing = ResponsiveTokens.getSpacing(screenWidth);
            return Container(
              color: ChoiceLuxTheme.jetBlack,
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: ChoiceLuxTheme.errorColor,
                      ),
                      SizedBox(height: spacing * 2),
                      Text(
                        'Error loading client',
                        style: TextStyle(
                          color: ChoiceLuxTheme.softWhite,
                          fontSize: ResponsiveTokens.getFontSize(screenWidth, baseSize: 18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: spacing),
                      Text(
                        error.toString(),
                        style: TextStyle(
                          color: ChoiceLuxTheme.platinumSilver,
                          fontSize: ResponsiveTokens.getFontSize(screenWidth, baseSize: 14),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
