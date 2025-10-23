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
    
    // Check if user is administrator
    final userRole = userProfile?.role?.toLowerCase();
    final isAdmin = userRole == 'administrator';
    
    print('InsightsScreen - User role: $userRole, isAdmin: $isAdmin');
    
    if (!isAdmin) {
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
              controller: _tabController,
              isScrollable: true,
              indicatorColor: ChoiceLuxTheme.richGold,
              labelColor: ChoiceLuxTheme.richGold,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
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
              ],
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
                              _selectedPeriod.displayName,
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