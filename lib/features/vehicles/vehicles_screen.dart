import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/features/vehicles/providers/vehicles_provider.dart';
import 'package:choice_lux_cars/features/vehicles/widgets/vehicle_card.dart';
import 'package:choice_lux_cars/features/vehicles/models/vehicle.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/shared/utils/background_pattern_utils.dart';

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
    // Removed Future.microtask call that was causing LateInitializationError
    // The provider will automatically load data when accessed
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vehiclesProvider);

    return state.when(
      loading: () => _buildLoadingState(),
      error: (error, stackTrace) => _buildErrorState(error),
      data: (vehicles) => _buildContent(vehicles),
    );
  }

  Widget _buildContent(List<Vehicle> vehicles) {
    final filteredVehicles = vehicles
        .where((v) => v.make.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    // Responsive breakpoints - consistent with our design system
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 400;
    final isTablet = screenWidth >= 600 && screenWidth < 800;
    final isDesktop = screenWidth >= 800;
    final isLargeDesktop = screenWidth >= 1200;

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
                onPressed: () => ref.read(vehiclesProvider.notifier).refresh(),
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(
                isSmallMobile
                    ? 12.0
                    : isMobile
                    ? 16.0
                    : 24.0,
              ),
              child: Column(
                children: [
                  // Responsive search bar
                  _buildResponsiveSearchBar(isMobile, isSmallMobile),
                  SizedBox(
                    height: isSmallMobile
                        ? 12.0
                        : isMobile
                        ? 16.0
                        : 20.0,
                  ),
                  Expanded(
                    child: _buildResponsiveVehicleGrid(
                      filteredVehicles,
                      isMobile,
                      isSmallMobile,
                      isTablet,
                      isDesktop,
                      isLargeDesktop,
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: _buildMobileOptimizedFAB(),
        ),
      ],
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
          hintText: isMobile
              ? 'Search vehicles...'
              : 'Search vehicles by make, model, or plate...',
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
    List<Vehicle> vehicles,
    bool isMobile,
    bool isSmallMobile,
    bool isTablet,
    bool isDesktop,
    bool isLargeDesktop,
  ) {
    // Responsive grid configuration - using maxCrossAxisExtent for better flexibility
    double maxCrossAxisExtent;
    double spacing;
    EdgeInsets padding;

    if (isLargeDesktop) {
      maxCrossAxisExtent = 320.0;
      spacing = 20.0;
      padding = const EdgeInsets.all(24.0);
    } else if (isDesktop) {
      maxCrossAxisExtent = 350.0;
      spacing = 18.0;
      padding = const EdgeInsets.all(20.0);
    } else if (isTablet) {
      maxCrossAxisExtent = 400.0;
      spacing = 16.0;
      padding = const EdgeInsets.all(16.0);
    } else if (isMobile) {
      maxCrossAxisExtent = 450.0;
      spacing = 12.0;
      padding = const EdgeInsets.all(12.0);
    } else {
      // Small mobile
      maxCrossAxisExtent = double.infinity;
      spacing = 12.0;
      padding = const EdgeInsets.all(12.0);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(vehiclesProvider.notifier).refresh(),
      color: ChoiceLuxTheme.richGold,
      backgroundColor: ChoiceLuxTheme.charcoalGray,
      child: GridView.builder(
        padding: padding,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: maxCrossAxisExtent,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          // Removed childAspectRatio to allow natural content-based sizing
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
          SizedBox(
            height: isSmallMobile
                ? 16
                : isMobile
                ? 20
                : 24,
          ),
          // Loading text
          Text(
            'Loading vehicles...',
            style: TextStyle(
              fontSize: isSmallMobile
                  ? 14
                  : isMobile
                  ? 16
                  : 18,
              fontWeight: FontWeight.w500,
              color: ChoiceLuxTheme.softWhite,
            ),
          ),
          SizedBox(
            height: isSmallMobile
                ? 8
                : isMobile
                ? 10
                : 12,
          ),
          Text(
            'Please wait while we fetch your fleet',
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

  Widget _buildLoadingState() {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  Widget _buildErrorState(Object error) {
    return Scaffold(body: Center(child: Text('Error: $error')));
  }
}
