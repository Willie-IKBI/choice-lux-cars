import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/clients/providers/clients_provider.dart';
import 'package:choice_lux_cars/features/clients/widgets/client_card.dart';
import 'package:choice_lux_cars/features/clients/models/client.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/widgets/system_safe_scaffold.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';

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
    // Responsive breakpoints for mobile optimization
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(screenWidth);
    final isTablet = ResponsiveBreakpoints.isTablet(screenWidth);
    final isDesktop = ResponsiveBreakpoints.isDesktop(screenWidth);
    final padding = ResponsiveTokens.getPadding(screenWidth);
    final spacing = ResponsiveTokens.getSpacing(screenWidth);

    final clientsAsync = _searchQuery.isEmpty
        ? ref.watch(clientsProvider)
        : ref.watch(clientSearchProvider(_searchQuery));

    return SystemSafeScaffold(
      backgroundColor: ChoiceLuxTheme.jetBlack,
      appBar: LuxuryAppBar(
        title: 'Clients',
        showBackButton: true,
        onBackPressed: () => context.go('/'),
        onSignOut: () async {
          await ref.read(authProvider.notifier).signOut();
        },
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              context.go('/clients/add');
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Client'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ChoiceLuxTheme.richGold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                // Responsive Search Bar with Filter
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: _buildResponsiveSearchAndFilter(isMobile, isSmallMobile),
                ),

                SizedBox(height: spacing * 1.5),

                // Clients List
                Expanded(
                  child: clientsAsync.when(
                    data: (clients) {
                      if (clients.isEmpty) {
                        return _buildEmptyState();
                      }
                      return RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(clientsProvider);
                          if (_searchQuery.isNotEmpty) {
                            ref.invalidate(clientSearchProvider(_searchQuery));
                          }
                        },
                        color: ChoiceLuxTheme.richGold,
                        backgroundColor: ChoiceLuxTheme.charcoalGray,
                        child: _buildClientsGrid(clients),
                      );
                    },
                    loading: () =>
                        _buildMobileLoadingState(isMobile, isSmallMobile),
                    error: (error, stackTrace) =>
                        _buildErrorState(error, isMobile, isSmallMobile),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLoadingState(bool isMobile, bool isSmallMobile) {
    final screenWidth = MediaQuery.of(context).size.width;
    final spacing = ResponsiveTokens.getSpacing(screenWidth);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Loading animation
          Container(
            padding: EdgeInsets.all(
              isSmallMobile
                  ? 16
                  : isMobile
                  ? 20
                  : 24,
            ),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.charcoalGray.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              color: ChoiceLuxTheme.richGold,
              strokeWidth: isMobile ? 2.0 : 3.0,
            ),
          ),
          SizedBox(height: spacing * 2),
          // Loading text
          Text(
            'Loading clients...',
            style: TextStyle(
              fontSize: ResponsiveTokens.getFontSize(screenWidth, baseSize: 16),
              fontWeight: FontWeight.w500,
              color: ChoiceLuxTheme.softWhite,
            ),
          ),
          SizedBox(height: spacing),
          Text(
            'Please wait while we fetch client data',
            style: TextStyle(
              fontSize: ResponsiveTokens.getFontSize(screenWidth, baseSize: 13),
              color: ChoiceLuxTheme.platinumSilver,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error, bool isMobile, bool isSmallMobile) {
    final screenWidth = MediaQuery.of(context).size.width;
    final spacing = ResponsiveTokens.getSpacing(screenWidth);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(
              isSmallMobile
                  ? 20
                  : isMobile
                  ? 24
                  : 28,
            ),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.charcoalGray.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: ResponsiveTokens.getIconSize(screenWidth) * 2.5,
              color: ChoiceLuxTheme.errorColor,
            ),
          ),
          SizedBox(height: spacing * 2),
          Text(
            'Error loading clients',
            style: TextStyle(
              fontSize: ResponsiveTokens.getFontSize(screenWidth, baseSize: 18),
              fontWeight: FontWeight.w500,
              color: ChoiceLuxTheme.softWhite,
            ),
          ),
          SizedBox(height: spacing),
          Text(
            error.toString(),
            style: TextStyle(
              fontSize: isSmallMobile
                  ? 12
                  : isMobile
                  ? 13
                  : 14,
              color: ChoiceLuxTheme.platinumSilver,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: isSmallMobile
                ? 16
                : isMobile
                ? 20
                : 24,
          ),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(clientsProvider);
            },
            icon: Icon(
              Icons.refresh,
              size: isSmallMobile
                  ? 16
                  : isMobile
                  ? 18
                  : 20,
            ),
            label: Text(
              'Retry',
              style: TextStyle(
                fontSize: isSmallMobile
                    ? 14
                    : isMobile
                    ? 16
                    : 18,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: ChoiceLuxTheme.richGold,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(
                horizontal: isSmallMobile
                    ? 16
                    : isMobile
                    ? 20
                    : 24,
                vertical: isSmallMobile
                    ? 12
                    : isMobile
                    ? 14
                    : 16,
              ),
            ),
          ),
        ],
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
    final clientCards = clients
        .map((client) => _buildSwipeableClientCard(client))
        .toList();

    return ResponsiveGrid(children: clientCards);
  }

  Widget _buildSwipeableClientCard(Client client) {
    return Dismissible(
      key: Key(client.id.toString()),
      direction: DismissDirection.endToStart, // Only swipe from right to left
      confirmDismiss: (direction) async {
        // Show confirmation dialog
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: ChoiceLuxTheme.charcoalGray,
            title: Text(
              'Deactivate Client',
              style: TextStyle(
                color: ChoiceLuxTheme.softWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              'Are you sure you want to deactivate ${client.companyName}?',
              style: TextStyle(color: ChoiceLuxTheme.platinumSilver),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: ChoiceLuxTheme.platinumSilver),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ChoiceLuxTheme.richGold,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Confirm'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        ref.read(clientsProvider.notifier).deleteClient(client.id.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.archive, color: ChoiceLuxTheme.softWhite),
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
                ref
                    .read(clientsProvider.notifier)
                    .restoreClient(client.id.toString());
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
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.archive, color: Colors.orange, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Deactivate',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      child: ClientCard(
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
      ),
    );
  }

  void _showDeleteDialog(Client client) {
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
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.archive, color: Colors.orange, size: 24),
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
              style: TextStyle(color: ChoiceLuxTheme.softWhite, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.business, color: Colors.orange, size: 20),
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
              ref
                  .read(clientsProvider.notifier)
                  .deleteClient(client.id.toString());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.archive, color: ChoiceLuxTheme.softWhite),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${client.companyName} has been deactivated',
                        ),
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
                      ref
                          .read(clientsProvider.notifier)
                          .restoreClient(client.id.toString());
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${client.companyName} has been restored',
                          ),
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

  Widget _buildResponsiveSearchAndFilter(bool isMobile, bool isSmallMobile) {
    if (isMobile) {
      // Mobile: Stack search and filter vertically
      return Column(
        children: [
          // Search bar
          _buildResponsiveSearchBar(isMobile, isSmallMobile),
          SizedBox(height: isSmallMobile ? 8.0 : 12.0),
          // Filter button
          _buildMobileFilterButton(isSmallMobile),
        ],
      );
    } else {
      // Desktop: Horizontal layout
      return Row(
        children: [
          Expanded(child: _buildResponsiveSearchBar(isMobile, isSmallMobile)),
          const SizedBox(width: 12),
          _buildDesktopFilterButton(),
        ],
      );
    }
  }

  Widget _buildResponsiveSearchBar(bool isMobile, bool isSmallMobile) {
    return Container(
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: isMobile
              ? 'Search clients...'
              : 'Search clients by name, company, or email...',
          hintStyle: TextStyle(
            color: ChoiceLuxTheme.platinumSilver.withOpacity(0.6),
            fontSize: isMobile ? 14 : 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: ChoiceLuxTheme.platinumSilver.withOpacity(0.6),
            size: isMobile ? 20 : 24,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: ChoiceLuxTheme.platinumSilver.withOpacity(0.6),
                    size: isMobile ? 20 : 24,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  tooltip: 'Clear search',
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isMobile ? 14 : 16,
          ),
        ),
        style: TextStyle(
          color: ChoiceLuxTheme.softWhite,
          fontSize: isMobile ? 14 : 16,
        ),
      ),
    );
  }

  Widget _buildMobileFilterButton(bool isSmallMobile) {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showMobileFilterBottomSheet(),
        icon: Icon(Icons.filter_list, color: ChoiceLuxTheme.richGold, size: 20),
        label: Text(
          'Filter clients',
          style: TextStyle(
            color: ChoiceLuxTheme.richGold,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: ChoiceLuxTheme.richGold.withOpacity(0.1),
          foregroundColor: ChoiceLuxTheme.richGold,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          minimumSize: const Size(0, 48), // Ensure minimum 44px touch target
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: ChoiceLuxTheme.richGold.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopFilterButton() {
    return Container(
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: () => _showMobileFilterBottomSheet(),
        icon: Icon(
          Icons.filter_list,
          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.6),
          size: 24,
        ),
        tooltip: 'Filter by Status, Industry, or Date',
      ),
    );
  }

  void _showMobileFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: ChoiceLuxTheme.charcoalGray,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: ChoiceLuxTheme.richGold,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Filter Clients',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: ChoiceLuxTheme.softWhite,
                    ),
                  ),
                ],
              ),
            ),

            // Filter options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildMobileFilterOption(
                    icon: Icons.business,
                    title: 'By Industry',
                    subtitle: 'Technology, Finance, Healthcare...',
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: Implement industry filter
                    },
                  ),
                  _buildMobileFilterOption(
                    icon: Icons.location_on,
                    title: 'By Location',
                    subtitle: 'City, State, Country',
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: Implement location filter
                    },
                  ),
                  _buildMobileFilterOption(
                    icon: Icons.calendar_today,
                    title: 'By Date Added',
                    subtitle: 'This week, month, year',
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: Implement date filter
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileFilterOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            constraints: const BoxConstraints(
              minHeight: 48,
            ), // Ensure minimum 44px touch target
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: ChoiceLuxTheme.richGold, size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: ChoiceLuxTheme.softWhite,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: ChoiceLuxTheme.platinumSilver,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: ChoiceLuxTheme.platinumSilver.withOpacity(0.6),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
