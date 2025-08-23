import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../vehicles/providers/vehicles_provider.dart';
import '../vehicles/widgets/vehicle_card.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/luxury_app_bar.dart';
import '../../app/theme.dart';
import '../auth/providers/auth_provider.dart';

class VehicleListScreen extends ConsumerStatefulWidget {
  const VehicleListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends ConsumerState<VehicleListScreen> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(vehiclesProvider.notifier).fetchVehicles());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vehiclesProvider);
    final vehicles = state.vehicles.where((v) => v.make.toLowerCase().contains(_search.toLowerCase())).toList();
    
    // Responsive breakpoints - consistent with our design system
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 400;
    final isTablet = screenWidth >= 600 && screenWidth < 800;
    final isDesktop = screenWidth >= 800;
    final isLargeDesktop = screenWidth >= 1200;
    
    return Scaffold(
      appBar: LuxuryAppBar(
        title: 'Vehicles',
        subtitle: 'Manage your fleet',
        showBackButton: true,
        onBackPressed: () => context.go('/'),
        onSignOut: () async {
          await ref.read(authProvider.notifier).signOut();
        },
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: ChoiceLuxTheme.richGold.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: ChoiceLuxTheme.richGold,
                size: 20,
              ),
            ),
            onPressed: () => ref.read(vehiclesProvider.notifier).fetchVehicles(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: ChoiceLuxTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(isSmallMobile ? 12.0 : isMobile ? 16.0 : 24.0),
            child: Column(
              children: [
                // Responsive search bar
                _buildResponsiveSearchBar(isMobile, isSmallMobile),
                SizedBox(height: isSmallMobile ? 12.0 : isMobile ? 16.0 : 20.0),
                if (state.isLoading)
                  Expanded(child: _buildMobileLoadingState(isMobile, isSmallMobile)),
                if (state.error != null)
                  Expanded(child: Center(child: Text(state.error!, style: const TextStyle(color: Colors.red)))),
                if (!state.isLoading && state.error == null)
                  Expanded(
                    child: _buildResponsiveVehicleGrid(
                      vehicles, 
                      isMobile, 
                      isSmallMobile, 
                      isTablet, 
                      isDesktop, 
                      isLargeDesktop
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildMobileOptimizedFAB(),
    );
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
        onChanged: (val) => setState(() => _search = val),
        decoration: InputDecoration(
          hintText: isMobile ? 'Search vehicles...' : 'Search vehicles by make, model, or plate...',
          hintStyle: TextStyle(
            color: ChoiceLuxTheme.platinumSilver.withOpacity(0.6),
            fontSize: isMobile ? 14 : 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: ChoiceLuxTheme.platinumSilver.withOpacity(0.6),
            size: isMobile ? 20 : 24,
          ),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: ChoiceLuxTheme.platinumSilver.withOpacity(0.6),
                    size: isMobile ? 20 : 24,
                  ),
                  onPressed: () => setState(() => _search = ''),
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

  Widget _buildResponsiveVehicleGrid(
    List vehicles, 
    bool isMobile, 
    bool isSmallMobile, 
    bool isTablet, 
    bool isDesktop, 
    bool isLargeDesktop
  ) {
    // Responsive grid configuration
    int crossAxisCount;
    double spacing;
    double childAspectRatio;
    EdgeInsets padding;

    if (isLargeDesktop) {
      crossAxisCount = 4;
      spacing = 20.0;
      childAspectRatio = 1.4;
      padding = const EdgeInsets.all(24.0);
    } else if (isDesktop) {
      crossAxisCount = 3;
      spacing = 18.0;
      childAspectRatio = 1.5;
      padding = const EdgeInsets.all(20.0);
    } else if (isTablet) {
      crossAxisCount = 2;
      spacing = 16.0;
      childAspectRatio = 1.6;
      padding = const EdgeInsets.all(16.0);
    } else if (isMobile) {
      crossAxisCount = 2;
      spacing = 12.0;
      childAspectRatio = 1.6;
      padding = const EdgeInsets.all(12.0);
    } else {
      // Small mobile
      crossAxisCount = 1;
      spacing = 12.0;
      childAspectRatio = 1.8;
      padding = const EdgeInsets.all(12.0);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(vehiclesProvider.notifier).fetchVehicles(),
      color: ChoiceLuxTheme.richGold,
      backgroundColor: ChoiceLuxTheme.charcoalGray,
      child: GridView.builder(
        padding: padding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: vehicles.length,
        itemBuilder: (context, i) => VehicleCard(
          vehicle: vehicles[i],
          onTap: () {
            context.push('/vehicles/edit', extra: vehicles[i]);
          },
        ),
      ),
    );
  }

  Widget _buildMobileLoadingState(bool isMobile, bool isSmallMobile) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Loading animation
          Container(
            padding: EdgeInsets.all(isSmallMobile ? 16 : isMobile ? 20 : 24),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.charcoalGray.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              color: ChoiceLuxTheme.richGold,
              strokeWidth: isMobile ? 2.0 : 3.0,
            ),
          ),
          SizedBox(height: isSmallMobile ? 16 : isMobile ? 20 : 24),
          // Loading text
          Text(
            'Loading vehicles...',
            style: TextStyle(
              fontSize: isSmallMobile ? 14 : isMobile ? 16 : 18,
              fontWeight: FontWeight.w500,
              color: ChoiceLuxTheme.softWhite,
            ),
          ),
          SizedBox(height: isSmallMobile ? 8 : isMobile ? 10 : 12),
          Text(
            'Please wait while we fetch your fleet',
            style: TextStyle(
              fontSize: isSmallMobile ? 12 : isMobile ? 13 : 14,
              color: ChoiceLuxTheme.platinumSilver,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileOptimizedFAB() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      // Mobile: Compact FAB with icon only
      return FloatingActionButton(
        onPressed: () => context.push('/vehicles/edit'),
        backgroundColor: ChoiceLuxTheme.richGold,
        foregroundColor: Colors.black,
        elevation: 6,
        child: const Icon(Icons.add, size: 24),
        tooltip: 'Add Vehicle',
      );
    } else {
      // Desktop: Extended FAB with label
      return FloatingActionButton.extended(
        onPressed: () => context.push('/vehicles/edit'),
        backgroundColor: ChoiceLuxTheme.richGold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
        elevation: 6,
      );
    }
  }
} 