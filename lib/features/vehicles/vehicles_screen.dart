import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/features/vehicles/providers/vehicles_provider.dart';
import 'package:choice_lux_cars/features/vehicles/widgets/vehicle_card.dart';
import 'package:choice_lux_cars/features/vehicles/models/vehicle.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/widgets/system_safe_scaffold.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';

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
    final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(screenWidth);
    final isTablet = ResponsiveBreakpoints.isTablet(screenWidth);
    final isDesktop = ResponsiveBreakpoints.isDesktop(screenWidth);
    final isLargeDesktop = ResponsiveBreakpoints.isLargeDesktop(screenWidth);

    return SystemSafeScaffold(
      backgroundColor: ChoiceLuxTheme.jetBlack,
      appBar: LuxuryAppBar(
        title: 'Vehicles',
        subtitle: 'OVERVIEW & STATISTICS',
        showBackButton: true,
        onBackPressed: () => context.go('/'),
        onSignOut: () async {
          await ref.read(authProvider.notifier).signOut();
        },
        actions: [
          ElevatedButton.icon(
            onPressed: () => context.push('/vehicles/edit'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Vehicle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ChoiceLuxTheme.richGold,
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
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
    // Get screen width for responsive tokens
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive grid configuration - using maxCrossAxisExtent for better flexibility
    double maxCrossAxisExtent;
    double spacing;
    double childAspectRatio;

    if (isLargeDesktop) {
      maxCrossAxisExtent = 320.0;
      spacing = ResponsiveTokens.getSpacing(screenWidth);
      childAspectRatio = 0.75;
    } else if (isDesktop) {
      maxCrossAxisExtent = 350.0;
      spacing = ResponsiveTokens.getSpacing(screenWidth);
      childAspectRatio = 0.75;
    } else if (isTablet) {
      maxCrossAxisExtent = 400.0;
      spacing = ResponsiveTokens.getSpacing(screenWidth);
      childAspectRatio = 0.78;
    } else if (isMobile) {
      // Mobile: Single column with full width minus padding
      maxCrossAxisExtent = screenWidth - (isSmallMobile ? 24.0 : 32.0);
      spacing = ResponsiveTokens.getSpacing(screenWidth);
      // Calculate aspect ratio based on actual content: image (120px) + padding (24px) + text (~50px) = ~194px
      // For width ~328px: aspectRatio = 328/194 ≈ 1.7
      childAspectRatio = 1.7;
    } else {
      // Small mobile: Single column with full width minus padding
      maxCrossAxisExtent = screenWidth - 24.0;
      spacing = ResponsiveTokens.getSpacing(screenWidth);
      // Calculate aspect ratio based on actual content: image (100px) + padding (20px) + text (~45px) = ~165px
      // For width ~336px: aspectRatio = 336/165 ≈ 2.0
      childAspectRatio = 2.0;
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(vehiclesProvider.notifier).refresh(),
      color: ChoiceLuxTheme.richGold,
      backgroundColor: ChoiceLuxTheme.charcoalGray,
      child: GridView.builder(
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: maxCrossAxisExtent,
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


  Widget _buildLoadingState() {
    return SystemSafeScaffold(
      backgroundColor: Colors.transparent,
      appBar: LuxuryAppBar(
        title: 'Vehicles',
        showBackButton: true,
        onBackPressed: () => context.go('/'),
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState(Object error) {
    return SystemSafeScaffold(
      backgroundColor: Colors.transparent,
      appBar: LuxuryAppBar(
        title: 'Vehicles',
        showBackButton: true,
        onBackPressed: () => context.go('/'),
      ),
      body: Center(child: Text('Error: $error')),
    );
  }
}
