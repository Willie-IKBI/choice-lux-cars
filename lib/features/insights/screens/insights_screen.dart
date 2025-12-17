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
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:go_router/go_router.dart';

/// Tabbed insights screen for administrators and managers
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> with SingleTickerProviderStateMixin {
  TimePeriod _selectedPeriod = TimePeriod.today;
  LocationFilter _selectedLocation = LocationFilter.all;
  TabController? _tabController;
  int? _previousTabCount;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final userProfile = ref.watch(currentUserProfileProvider);
    
    // Check if user is administrator, super_admin, or manager
    final userRole = userProfile?.role?.toLowerCase();
    final isAdmin = userProfile?.isAdmin ?? false;
    final isManager = userProfile?.role?.toLowerCase() == 'manager';
    final hasAccess = isAdmin || isManager;
    
    print('InsightsScreen - User role: $userRole, isAdmin: $isAdmin, isManager: $isManager');
    
    if (!hasAccess) {
      return Scaffold(
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

    // Determine number of tabs based on role
    final tabCount = isAdmin ? 5 : 1;
    
    // Initialize or update tab controller if length changed
    if (_tabController == null || _previousTabCount != tabCount) {
      _tabController?.dispose();
      _tabController = TabController(length: tabCount, vsync: this);
      _previousTabCount = tabCount;
    }

    final isMobile = MediaQuery.of(context).size.width < 600;

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
      body: Column(
        children: [
          // Filter bar
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: _buildFilterBar(),
          ),
          
          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: TabBar(
              controller: _tabController!,
              isScrollable: true,
              indicatorColor: ChoiceLuxTheme.richGold,
              labelColor: ChoiceLuxTheme.richGold,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: isAdmin
                  ? const [
                      Tab(
                        icon: Icon(Icons.work_outline),
                        text: 'Jobs',
                      ),
                      Tab(
                        icon: Icon(Icons.attach_money),
                        text: 'Financial',
                      ),
                      Tab(
                        icon: Icon(Icons.person_outline),
                        text: 'Drivers',
                      ),
                      Tab(
                        icon: Icon(Icons.directions_car_outlined),
                        text: 'Vehicles',
                      ),
                      Tab(
                        icon: Icon(Icons.business_outlined),
                        text: 'Clients',
                      ),
                    ]
                  : const [
                      Tab(
                        icon: Icon(Icons.work_outline),
                        text: 'Jobs',
                      ),
                    ],
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController!,
              children: isAdmin
                  ? [
                      JobsInsightsTab(
                        selectedPeriod: _selectedPeriod,
                        selectedLocation: _selectedLocation,
                        customStartDate: _customStartDate,
                        customEndDate: _customEndDate,
                      ),
                      FinancialInsightsTab(
                        selectedPeriod: _selectedPeriod,
                        selectedLocation: _selectedLocation,
                        customStartDate: _customStartDate,
                        customEndDate: _customEndDate,
                      ),
                      DriverInsightsTab(
                        selectedPeriod: _selectedPeriod,
                        selectedLocation: _selectedLocation,
                        customStartDate: _customStartDate,
                        customEndDate: _customEndDate,
                      ),
                      VehicleInsightsTab(
                        selectedPeriod: _selectedPeriod,
                        selectedLocation: _selectedLocation,
                        customStartDate: _customStartDate,
                        customEndDate: _customEndDate,
                      ),
                      ClientInsightsTab(
                        selectedPeriod: _selectedPeriod,
                        selectedLocation: _selectedLocation,
                        customStartDate: _customStartDate,
                        customEndDate: _customEndDate,
                      ),
                    ]
                  : [
                      JobsInsightsTab(
                        selectedPeriod: _selectedPeriod,
                        selectedLocation: _selectedLocation,
                        customStartDate: _customStartDate,
                        customEndDate: _customEndDate,
                      ),
                    ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.filter_list,
              color: ChoiceLuxTheme.richGold,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Filters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Time Period',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showTimePeriodPicker(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                              Expanded(
                            child: Text(
                              _selectedPeriod == TimePeriod.custom && _customStartDate != null && _customEndDate != null
                                  ? '${_formatDate(_customStartDate!)} - ${_formatDate(_customEndDate!)}'
                                  : _selectedPeriod.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showLocationPicker(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedLocation.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showTimePeriodPicker(BuildContext context) {
    // Separate periods into historical and planning
    final historicalPeriods = [
      TimePeriod.today,
      TimePeriod.yesterday,
      TimePeriod.last3Days,
      TimePeriod.thisWeek,
      TimePeriod.thisMonth,
      TimePeriod.thisQuarter,
      TimePeriod.thisYear,
      TimePeriod.custom,
    ];
    final planningPeriods = [
      TimePeriod.tomorrow,
      TimePeriod.next3Days,
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a1a),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // Get safe area insets to account for system navigation bar
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        final safeBottomPadding = bottomPadding > 0 ? bottomPadding + 20 : 32.0; // Extra padding for system bar
        
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: safeBottomPadding,
          ),
          child: SingleChildScrollView(
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
              // Historical section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Text(
                      'Historical',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              ...historicalPeriods.map((period) {
                final isCustom = period == TimePeriod.custom;
                final hasCustomDates = _customStartDate != null && _customEndDate != null;
                
                return ListTile(
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          period.displayName,
                          style: TextStyle(
                            color: _selectedPeriod == period ? ChoiceLuxTheme.richGold : Colors.white,
                            fontWeight: _selectedPeriod == period ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isCustom && hasCustomDates)
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: ChoiceLuxTheme.richGold.withOpacity(0.7),
                        ),
                    ],
                  ),
                  subtitle: isCustom && hasCustomDates
                      ? Text(
                          '${_formatDate(_customStartDate!)} - ${_formatDate(_customEndDate!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        )
                      : null,
                  trailing: isCustom
                      ? IconButton(
                          icon: Icon(
                            Icons.date_range,
                            color: ChoiceLuxTheme.richGold,
                            size: 20,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _showCustomDateRangePicker(context);
                          },
                        )
                      : null,
                  onTap: () {
                    if (isCustom) {
                      Navigator.pop(context);
                      _showCustomDateRangePicker(context);
                    } else {
                      setState(() {
                        _selectedPeriod = period;
                        // Clear custom dates when selecting a non-custom period
                        _customStartDate = null;
                        _customEndDate = null;
                      });
                      Navigator.pop(context);
                    }
                  },
                );
              }),
              // Divider
              Divider(
                color: Colors.white.withOpacity(0.2),
                thickness: 1,
                height: 32,
              ),
              // Planning section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Text(
                      'Planning',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              ...planningPeriods.map((period) => ListTile(
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
      },
    );
  }

  void _showCustomDateRangePicker(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 7)),
              end: DateTime.now(),
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: ChoiceLuxTheme.richGold,
              onPrimary: Colors.black,
              surface: ChoiceLuxTheme.charcoalGray,
              onSurface: ChoiceLuxTheme.softWhite,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedPeriod = TimePeriod.custom;
        _customStartDate = DateTime(picked.start.year, picked.start.month, picked.start.day);
        _customEndDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showLocationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a1a),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // Get safe area insets to account for system navigation bar
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        final safeBottomPadding = bottomPadding > 0 ? bottomPadding + 20 : 32.0; // Extra padding for system bar
        
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: safeBottomPadding,
          ),
          child: SingleChildScrollView(
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
      },
    );
  }
}