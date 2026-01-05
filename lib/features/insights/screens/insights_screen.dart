import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/insights/screens/jobs_insights_tab.dart';
import 'package:choice_lux_cars/features/insights/screens/financial_insights_tab.dart';
import 'package:choice_lux_cars/features/insights/screens/driver_insights_tab.dart';
import 'package:choice_lux_cars/features/insights/screens/vehicle_insights_tab.dart';
import 'package:choice_lux_cars/features/insights/screens/client_insights_tab.dart';
import 'package:choice_lux_cars/features/insights/models/insights_data.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_drawer.dart';
import 'package:choice_lux_cars/shared/widgets/system_safe_scaffold.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:go_router/go_router.dart';

/// Tabbed insights screen for administrators
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> with SingleTickerProviderStateMixin {
  TimePeriod _selectedPeriod = TimePeriod.thisMonth;
  LocationFilter _selectedLocation = LocationFilter.all;
  late TabController _tabController;
  bool _showFilters = false; // Filters hidden by default

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final userProfile = ref.watch(currentUserProfileProvider);
    
    // Check if user is administrator or super_admin
    final userRole = userProfile?.role?.toLowerCase();
    final isAdmin = userRole == 'administrator' || userRole == 'super_admin';
    
    print('InsightsScreen - User role: $userRole, isAdmin: $isAdmin');
    
    if (!isAdmin) {
      return SystemSafeScaffold(
        backgroundColor: Colors.transparent,
        appBar: LuxuryAppBar(
          title: 'Insights',
          onSignOut: () async {
            await ref.read(authProvider.notifier).signOut();
          },
        ),
        body: const Center(
          child: Text(
            'Access Denied: You do not have permission to view this page.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(screenWidth);
    final padding = ResponsiveTokens.getPadding(screenWidth);
    final spacing = ResponsiveTokens.getSpacing(screenWidth);

    return SystemSafeScaffold(
      appBar: LuxuryAppBar(
        title: 'Business Insights',
        showBackButton: true,
        onBackPressed: () => context.go('/'),
        onSignOut: () async {
          await ref.read(authProvider.notifier).signOut();
        },
      ),
      drawer: isMobile ? null : const LuxuryDrawer(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            children: [
              // Filter Toggle Button + Collapsible Filter Bar
              Container(
                margin: EdgeInsets.only(
                  left: padding,
                  right: padding,
                  top: isMobile ? 4 : 8,
                  bottom: 2,
                ),
                child: Column(
                  children: [
                    // Filter Toggle Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showFilters = !_showFilters;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 10 : 12,
                              vertical: isMobile ? 6 : 8,
                            ),
                            decoration: BoxDecoration(
                              color: _showFilters 
                                  ? ChoiceLuxTheme.richGold.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _showFilters
                                    ? ChoiceLuxTheme.richGold.withOpacity(0.5)
                                    : Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.filter_list,
                                  size: isMobile ? 16 : 18,
                                  color: _showFilters
                                      ? ChoiceLuxTheme.richGold
                                      : ChoiceLuxTheme.platinumSilver,
                                ),
                                SizedBox(width: isMobile ? 4 : 6),
                                Text(
                                  'Filters',
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 13,
                                    fontWeight: FontWeight.w600,
                                    color: _showFilters
                                        ? ChoiceLuxTheme.richGold
                                        : ChoiceLuxTheme.platinumSilver,
                                  ),
                                ),
                                SizedBox(width: isMobile ? 4 : 6),
                                Icon(
                                  _showFilters ? Icons.expand_less : Icons.expand_more,
                                  size: isMobile ? 16 : 18,
                                  color: _showFilters
                                      ? ChoiceLuxTheme.richGold
                                      : ChoiceLuxTheme.platinumSilver,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Collapsible Filter Bar
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: _showFilters
                          ? Container(
                              margin: EdgeInsets.only(top: isMobile ? 6 : 8),
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 10 : 12,
                                vertical: isMobile ? 8 : 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: _buildCompactFilterBar(isMobile, isSmallMobile),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              
              // Ultra-Compact Tab bar - Icon-only on mobile
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: padding,
                  vertical: isMobile ? 2 : 4,
                ),
                decoration: BoxDecoration(
                  color: ChoiceLuxTheme.charcoalGray,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 2 : 4),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicator: BoxDecoration(
                      color: ChoiceLuxTheme.richGold,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    indicatorPadding: EdgeInsets.all(2),
                    dividerColor: Colors.transparent,
                    labelColor: Colors.black,
                    unselectedLabelColor: ChoiceLuxTheme.platinumSilver,
                    labelStyle: TextStyle(
                      fontSize: isMobile ? 11 : 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontSize: isMobile ? 11 : 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                    labelPadding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 8 : 14,
                      vertical: isMobile ? 6 : 8,
                    ),
                    tabAlignment: TabAlignment.start,
                    tabs: [
                      _buildTab(Icons.work, 'Jobs', isMobile),
                      _buildTab(Icons.attach_money, 'Financial', isMobile),
                      _buildTab(Icons.person, 'Drivers', isMobile),
                      _buildTab(Icons.directions_car, 'Vehicles', isMobile),
                      _buildTab(Icons.business, 'Clients', isMobile),
                    ],
                  ),
                ),
              ),
          
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    JobsInsightsTab(
                      selectedPeriod: _selectedPeriod,
                      selectedLocation: _selectedLocation,
                    ),
                    FinancialInsightsTab(
                      selectedPeriod: _selectedPeriod,
                      selectedLocation: _selectedLocation,
                    ),
                    DriverInsightsTab(
                      selectedPeriod: _selectedPeriod,
                      selectedLocation: _selectedLocation,
                    ),
                    VehicleInsightsTab(
                      selectedPeriod: _selectedPeriod,
                      selectedLocation: _selectedLocation,
                    ),
                    ClientInsightsTab(
                      selectedPeriod: _selectedPeriod,
                      selectedLocation: _selectedLocation,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(IconData icon, String text, bool isMobile) {
    return Tab(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 2 : 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isMobile ? 18 : 20,
            ),
            // Show text only on desktop, icon-only on mobile
            if (!isMobile) ...[
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactFilterBar(bool isMobile, bool isSmallMobile) {
    return Row(
      children: [
        // Time Period Filter - Ultra-compact
        Expanded(
          child: GestureDetector(
            onTap: () => _showTimePeriodPicker(context),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 10,
                vertical: isMobile ? 8 : 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: isMobile ? 16 : 18,
                    color: ChoiceLuxTheme.richGold.withOpacity(0.9),
                  ),
                  SizedBox(width: isMobile ? 6 : 8),
                  Expanded(
                    child: Text(
                      _selectedPeriod.displayName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 12 : 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    size: isMobile ? 18 : 20,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        SizedBox(width: isMobile ? 6 : 8),
        
        // Location Filter - Ultra-compact
        Expanded(
          child: GestureDetector(
            onTap: () => _showLocationPicker(context),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 10,
                vertical: isMobile ? 8 : 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: isMobile ? 16 : 18,
                    color: ChoiceLuxTheme.richGold.withOpacity(0.9),
                  ),
                  SizedBox(width: isMobile ? 6 : 8),
                  Expanded(
                    child: Text(
                      _selectedLocation.displayName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 12 : 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    size: isMobile ? 18 : 20,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showTimePeriodPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a1a),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Time Period',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            ...TimePeriod.values.map((period) => ListTile(
              title: Text(
                period.displayName,
                style: TextStyle(
                  color: _selectedPeriod == period ? ChoiceLuxTheme.richGold : Colors.white,
                  fontWeight: _selectedPeriod == period ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                });
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showLocationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a1a),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Location',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            ...LocationFilter.values.map((location) => ListTile(
              title: Text(
                location.displayName,
                style: TextStyle(
                  color: _selectedLocation == location ? ChoiceLuxTheme.richGold : Colors.white,
                  fontWeight: _selectedLocation == location ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              onTap: () {
                setState(() {
                  _selectedLocation = location;
                });
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }
}