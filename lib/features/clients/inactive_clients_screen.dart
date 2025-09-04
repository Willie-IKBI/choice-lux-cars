import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/clients/providers/clients_provider.dart';
import 'package:choice_lux_cars/features/clients/widgets/client_card.dart';
import 'package:choice_lux_cars/features/clients/models/client.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/shared/utils/background_pattern_utils.dart';

class InactiveClientsScreen extends ConsumerStatefulWidget {
  const InactiveClientsScreen({super.key});

  @override
  ConsumerState<InactiveClientsScreen> createState() =>
      _InactiveClientsScreenState();
}

class _InactiveClientsScreenState extends ConsumerState<InactiveClientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inactiveClientsAsync = ref.watch(inactiveClientsProvider);

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
            title: 'Inactive Clients',
            subtitle: 'View and manage inactive clients',
            showBackButton: true,
            onBackPressed: () => context.go('/clients'),
            onSignOut: () async {
              await ref.read(authProvider.notifier).signOut();
            },
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () {
                  ref.invalidate(inactiveClientsProvider);
                },
              ),
            ],
          ),
          body: SafeArea(
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search inactive clients...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: ChoiceLuxTheme.platinumSilver,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: ChoiceLuxTheme.platinumSilver,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: ChoiceLuxTheme.platinumSilver,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: ChoiceLuxTheme.platinumSilver,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: ChoiceLuxTheme.richGold,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: ChoiceLuxTheme.charcoalGray,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Inactive Clients List
              Expanded(
                child: inactiveClientsAsync.when(
                  data: (clients) {
                    final filteredClients = _searchQuery.isEmpty
                        ? clients
                        : clients
                              .where(
                                (client) =>
                                    client.companyName.toLowerCase().contains(
                                      _searchQuery.toLowerCase(),
                                    ) ||
                                    client.contactPerson.toLowerCase().contains(
                                      _searchQuery.toLowerCase(),
                                    ),
                              )
                              .toList();

                    if (filteredClients.isEmpty) {
                      return _buildEmptyState();
                    }
                    return _buildInactiveClientsGrid(filteredClients);
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: ChoiceLuxTheme.richGold,
                    ),
                  ),
                  error: (error, stackTrace) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: ChoiceLuxTheme.errorColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading inactive clients',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: ChoiceLuxTheme.softWhite),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: ChoiceLuxTheme.platinumSilver),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.invalidate(inactiveClientsProvider);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isEmpty ? Icons.archive : Icons.search_off,
            size: 64,
            color: ChoiceLuxTheme.platinumSilver,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No inactive clients found'
                : 'No inactive clients match your search',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: ChoiceLuxTheme.softWhite,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'All clients are currently active'
                : 'Try adjusting your search terms',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ChoiceLuxTheme.platinumSilver,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInactiveClientsGrid(List<Client> clients) {
    final clientCards = clients
        .map(
          (client) => ClientCard(
            client: client,
            isSelected: false,
            onTap: () {
              context.go('/clients/${client.id}');
            },
            onEdit: () {
              context.go('/clients/edit/${client.id}');
            },
            onDelete: () => _showRestoreDialog(client),
            onViewAgents: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Viewing agents for ${client.companyName}'),
                  backgroundColor: ChoiceLuxTheme.richGold,
                ),
              );
            },
          ),
        )
        .toList();

    return ResponsiveGrid(children: clientCards);
  }

  void _showRestoreDialog(Client client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ChoiceLuxTheme.charcoalGray,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ChoiceLuxTheme.successColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.restore,
                color: ChoiceLuxTheme.successColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Restore Client',
                style: TextStyle(
                  color: ChoiceLuxTheme.softWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to restore this client?',
              style: TextStyle(color: ChoiceLuxTheme.softWhite, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ChoiceLuxTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ChoiceLuxTheme.successColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.business,
                    color: ChoiceLuxTheme.successColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      client.companyName,
                      style: TextStyle(
                        color: ChoiceLuxTheme.softWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The client will be restored to active status and will appear in the main clients list.',
              style: TextStyle(
                color: ChoiceLuxTheme.platinumSilver,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: ChoiceLuxTheme.platinumSilver,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(clientsProvider.notifier)
                  .restoreClient(client.id.toString());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: ChoiceLuxTheme.softWhite),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('${client.companyName} has been restored'),
                      ),
                    ],
                  ),
                  backgroundColor: ChoiceLuxTheme.successColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ChoiceLuxTheme.successColor,
              foregroundColor: ChoiceLuxTheme.softWhite,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Restore Client'),
          ),
        ],
      ),
    );
  }
}
