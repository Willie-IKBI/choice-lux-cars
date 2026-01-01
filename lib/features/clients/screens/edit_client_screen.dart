import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/clients/providers/clients_provider.dart';
import 'package:choice_lux_cars/features/clients/screens/add_edit_client_screen.dart';
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
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: ChoiceLuxTheme.backgroundGradient,
              ),
              child: const SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: ChoiceLuxTheme.errorColor,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Client not found',
                        style: TextStyle(
                          color: ChoiceLuxTheme.softWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return AddEditClientScreen(client: client);
      },
      loading: () => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: ChoiceLuxTheme.backgroundGradient,
          ),
          child: const SafeArea(
            child: Center(
              child: CircularProgressIndicator(color: ChoiceLuxTheme.richGold),
            ),
          ),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: ChoiceLuxTheme.backgroundGradient,
          ),
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
                  const SizedBox(height: 16),
                  const Text(
                    'Error loading client',
                    style: TextStyle(
                      color: ChoiceLuxTheme.softWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: const TextStyle(
                      color: ChoiceLuxTheme.platinumSilver,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
