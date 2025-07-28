import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/clients/providers/clients_provider.dart';
import 'package:choice_lux_cars/features/clients/widgets/client_card.dart';
import 'package:choice_lux_cars/features/clients/models/client.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = _searchQuery.isEmpty
        ? ref.watch(clientsNotifierProvider)
        : ref.watch(clientSearchProvider(_searchQuery));

    return Scaffold(
      floatingActionButton: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          return FloatingActionButton(
            onPressed: () {
              context.go('/clients/add');
            },
            backgroundColor: ChoiceLuxTheme.richGold,
            foregroundColor: Colors.black,
            elevation: 4,
            child: Icon(
              Icons.add,
              size: isMobile ? 24 : 28,
            ),
          );
        },
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: ChoiceLuxTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: ChoiceLuxTheme.softWhite,
                      ),
                      onPressed: () => context.go('/'),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Clients',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: ChoiceLuxTheme.softWhite,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.archive,
                        color: ChoiceLuxTheme.platinumSilver,
                      ),
                      onPressed: () {
                        context.go('/clients/inactive');
                      },
                      tooltip: 'View Inactive Clients',
                    ),
                  ],
                ),
              ),

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
                    hintText: 'Search clients...',
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

              // Clients List
              Expanded(
                child: clientsAsync.when(
                  data: (clients) {
                    if (clients.isEmpty) {
                      return _buildEmptyState();
                    }
                    return _buildClientsGrid(clients);
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
                          'Error loading clients',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: ChoiceLuxTheme.softWhite,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: ChoiceLuxTheme.platinumSilver,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.invalidate(clientsNotifierProvider);
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isEmpty ? Icons.people : Icons.search_off,
            size: 64,
            color: ChoiceLuxTheme.platinumSilver,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No clients found'
                : 'No clients match your search',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: ChoiceLuxTheme.softWhite,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Add your first client to get started'
                : 'Try adjusting your search terms',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ChoiceLuxTheme.platinumSilver,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context.go('/clients/add');
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Client'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClientsGrid(List<Client> clients) {
    final clientCards = clients.map((client) => ClientCard(
      client: client,
      isSelected: false, // TODO: Implement selection state
      onTap: () {
        context.go('/clients/${client.id}');
      },
      onEdit: () {
        context.go('/clients/edit/${client.id}');
      },
      onDelete: () => _showDeleteDialog(client),
      onViewAgents: () {
        // Navigate to client detail screen with agents tab
        context.go('/clients/${client.id}?tab=agents');
      },
    )).toList();

    return ResponsiveGrid(
      children: clientCards,
    );
  }

  void _showDeleteDialog(Client client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ChoiceLuxTheme.charcoalGray,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.archive,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Deactivate Client',
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
              'Are you sure you want to deactivate this client?',
              style: TextStyle(
                color: ChoiceLuxTheme.softWhite,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.business,
                    color: Colors.orange,
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
              'The client will be moved to inactive status. All data will be preserved and can be restored later.',
              style: TextStyle(
                color: ChoiceLuxTheme.platinumSilver,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: ChoiceLuxTheme.richGold,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Related quotes, invoices, and agent data will remain intact.',
                      style: TextStyle(
                        color: ChoiceLuxTheme.richGold,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
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
              ref.read(clientsNotifierProvider.notifier).deleteClient(client.id.toString());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        Icons.archive,
                        color: ChoiceLuxTheme.softWhite,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('${client.companyName} has been deactivated'),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  action: SnackBarAction(
                    label: 'Undo',
                    textColor: ChoiceLuxTheme.softWhite,
                    onPressed: () {
                      ref.read(clientsNotifierProvider.notifier).restoreClient(client.id.toString());
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${client.companyName} has been restored'),
                          backgroundColor: ChoiceLuxTheme.successColor,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: ChoiceLuxTheme.softWhite,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Deactivate Client'),
          ),
        ],
      ),
    );
  }
} 