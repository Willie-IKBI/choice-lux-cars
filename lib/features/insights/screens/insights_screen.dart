import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/insights/screens/jobs_insights_tab.dart';
import 'package:choice_lux_cars/features/insights/screens/financial_insights_tab.dart';
import 'package:choice_lux_cars/features/insights/screens/driver_insights_tab.dart';
import 'package:choice_lux_cars/features/insights/screens/vehicle_insights_tab.dart';
import 'package:choice_lux_cars/features/insights/screens/client_insights_tab.dart';
import 'package:choice_lux_cars/features/insights/models/insights_data.dart';
import 'package:choice_lux_cars/features/insights/presentation/widgets/premium_command_tabs.dart';
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

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  TimePeriod _selectedPeriod = TimePeriod.thisMonth;
  LocationFilter _selectedLocation = LocationFilter.all;
  int _selectedTabIndex = 0;
  bool _showFilters = false; // Filters hidden by default

  // Premium tab items
  static const List<PremiumTabItem> _tabItems = [
    PremiumTabItem(
      label: 'Jobs',
      iconOutlined: Icons.work_outlined,
      iconFilled: Icons.work,
      semanticLabel: 'Jobs insights tab',
    ),
    PremiumTabItem(
      label: 'Financial',
      iconOutlined: Icons.attach_money_outlined,
      iconFilled: Icons.attach_money,
      semanticLabel: 'Financial insights tab',
    ),
    PremiumTabItem(
      label: 'Drivers',
      iconOutlined: Icons.person_outline,
      iconFilled: Icons.person,
      semanticLabel: 'Drivers insights tab',
    ),
    PremiumTabItem(
      label: 'Vehicles',
      iconOutlined: Icons.directions_car_outlined,
      iconFilled: Icons.directions_car,
      semanticLabel: 'Vehicles insights tab',
    ),
    PremiumTabItem(
      label: 'Clients',
      iconOutlined: Icons.business_outlined,
      iconFilled: Icons.business,
      semanticLabel: 'Clients insights tab',
    ),
  ];

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
              // Premium Command Tabs Navigation with integrated Filters
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: padding,
                  vertical: isMobile ? 8 : 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tabs - takes available space
                    Expanded(
                      child: PremiumCommandTabs(
                        items: _tabItems,
                        selectedIndex: _selectedTabIndex,
                        onChanged: (index) {
                          setState(() {
                            _selectedTabIndex = index;
                          });
                        },
                        scrollableOnMobile: true,
                        maxWidth: null, // Let it expand within the Row
                      ),
                    ),
                    // Filters Button - aligned to the right, same height as tabs
                    SizedBox(width: isMobile ? 8 : 12),
                    _buildFiltersButton(context, screenWidth, isMobile, isSmallMobile),
                  ],
                ),
              ),
              
              // Collapsible Filter Bar - below tabs and filters
              Padding(
                padding: EdgeInsets.symmetric(horizontal: padding),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: _showFilters
                      ? Container(
                          margin: EdgeInsets.only(
                            top: isMobile ? 8 : 12,
                            bottom: isMobile ? 8 : 12,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 16,
                            vertical: isMobile ? 10 : 12,
                          ),
                          decoration: BoxDecoration(
                            color: ChoiceLuxTheme.charcoalGray.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(ResponsiveTokens.getCornerRadius(screenWidth)),
                            border: Border.all(
                              color: ChoiceLuxTheme.platinumSilver.withOpacity(0.12),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _buildCompactFilterBar(isMobile, isSmallMobile),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
          
              // Tab content - Using IndexedStack for better performance
              Expanded(
                child: IndexedStack(
                  index: _selectedTabIndex,
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


  Widget _buildFiltersButton(
    BuildContext context,
    double screenWidth,
    bool isMobile,
    bool isSmallMobile,
  ) {
    final radius = ResponsiveTokens.getCornerRadius(screenWidth);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _showFilters = !_showFilters;
          });
        },
        borderRadius: BorderRadius.circular(radius * 0.75),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: isMobile ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: _showFilters 
                ? ChoiceLuxTheme.richGold.withOpacity(0.15)
                : ChoiceLuxTheme.charcoalGray.withOpacity(0.6),
            borderRadius: BorderRadius.circular(radius * 1.5), // Match tabs container
            border: Border.all(
              color: _showFilters
                  ? ChoiceLuxTheme.richGold.withOpacity(0.4)
                  : ChoiceLuxTheme.platinumSilver.withOpacity(0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              if (_showFilters)
                BoxShadow(
                  color: ChoiceLuxTheme.richGold.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_list_outlined,
                size: isMobile ? 20 : 22,
                color: _showFilters
                    ? ChoiceLuxTheme.richGold
                    : ChoiceLuxTheme.platinumSilver,
              ),
              SizedBox(width: isMobile ? 6 : 8),
              Text(
                'Filters',
                style: TextStyle(
                  fontSize: isMobile ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: _showFilters
                      ? ChoiceLuxTheme.richGold
                      : ChoiceLuxTheme.platinumSilver,
                ),
              ),
              SizedBox(width: isMobile ? 6 : 8),
              Icon(
                _showFilters ? Icons.expand_less : Icons.expand_more,
                size: isMobile ? 18 : 20,
                color: _showFilters
                    ? ChoiceLuxTheme.richGold
                    : ChoiceLuxTheme.platinumSilver,
              ),
            ],
          ),
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