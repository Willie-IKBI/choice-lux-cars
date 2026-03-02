import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/insights/models/insights_data.dart';
import 'package:choice_lux_cars/features/insights/providers/vehicle_insights_provider.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';
import 'package:choice_lux_cars/shared/widgets/insights_metric_card.dart';
import 'package:choice_lux_cars/shared/widgets/section_header.dart';
import 'package:choice_lux_cars/shared/widgets/common_states.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/shared/utils/snackbar_utils.dart';
import 'package:choice_lux_cars/core/utils.dart';

class VehicleInsightsTab extends ConsumerWidget {
  final TimePeriod selectedPeriod;
  final LocationFilter selectedLocation;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const VehicleInsightsTab({
    super.key,
    required this.selectedPeriod,
    required this.selectedLocation,
    this.customStartDate,
    this.customEndDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerKey = (selectedPeriod, selectedLocation, customStartDate, customEndDate);
    final vehicleInsightsAsync = ref.watch(vehicleInsightsProvider(providerKey));

    return Container(
      padding: const EdgeInsets.all(16),
      child: vehicleInsightsAsync.when(
        data: (insights) => _buildVehicleContent(context, insights),
        loading: () => const LoadingStateWidget(message: 'Loading vehicle insights...'),
        error: (error, stack) => ErrorStateWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(vehicleInsightsProvider(providerKey)),
        ),
      ),
    );
  }

  Widget _buildVehicleContent(BuildContext context, VehicleInsights insights) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.charcoalGray,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            'Vehicle Analytics',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: ChoiceLuxTheme.softWhite,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Live Data',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade300,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        SnackBarUtils.showInfo(context, 'Export Report coming soon');
                      },
                      child: Text(
                        'Export Report',
                        style: TextStyle(
                          color: ChoiceLuxTheme.richGold,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${insights.totalVehicles} vehicles • ${insights.activeVehicles} active',
                  style: TextStyle(
                    fontSize: 16,
                    color: ChoiceLuxTheme.platinumSilver,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Key Metrics
          SectionHeader(title: 'Vehicle Performance'),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isLargeDesktop = ResponsiveBreakpoints.isLargeDesktop(screenWidth);
              final isDesktop = ResponsiveBreakpoints.isDesktop(screenWidth);
              final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
              final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(screenWidth);
              final spacing = ResponsiveTokens.getSpacing(screenWidth);
              
              // 4 columns on large desktop (all cards in one row), 2 columns on medium desktop/tablet/mobile
              final crossAxisCount = isLargeDesktop ? 4 : 2;
              final childAspectRatio = isSmallMobile ? 1.4 : (isMobile ? 1.6 : (isDesktop ? 1.8 : 2.0));
              
              final gridView = GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                children: [
                  InsightsMetricCard(
                    label: 'Total Vehicles',
                    value: insights.totalVehicles.toString(),
                    icon: Icons.directions_car_outlined,
                    iconColor: ChoiceLuxTheme.richGold,
                    progressValue: 1.0,
                    helpText: 'Total number of vehicles in the selected period and location.',
                  ),
                  InsightsMetricCard(
                    label: 'Active Vehicles',
                    value: insights.activeVehicles.toString(),
                    icon: Icons.directions_car,
                    iconColor: Colors.green,
                    progressValue: insights.totalVehicles > 0
                        ? (insights.activeVehicles / insights.totalVehicles).clamp(0.0, 1.0)
                        : 0.0,
                    helpText: 'Vehicles that completed at least one job in the period. Indicates fleet usage.',
                  ),
                  InsightsMetricCard(
                    label: 'Avg Jobs/Vehicle',
                    value: insights.averageJobsPerVehicle.toStringAsFixed(1),
                    icon: Icons.work_outline,
                    iconColor: Colors.blue,
                    progressValue: insights.averageJobsPerVehicle > 0 ? 1.0 : 0.0,
                    helpText: 'Average number of jobs completed per active vehicle. Measures vehicle productivity.',
                  ),
                  InsightsMetricCard(
                    label: 'Avg Revenue/Vehicle',
                    value: CurrencyUtils.formatCompact(insights.averageIncomePerVehicle),
                    icon: Icons.attach_money,
                    iconColor: Colors.orange,
                    progressValue: insights.averageIncomePerVehicle > 0 ? 1.0 : 0.0,
                    helpText: 'Average revenue generated per active vehicle in the period.',
                  ),
                ],
              );
              
              // Center the grid on desktop with max width constraint
              if (isDesktop) {
                // Calculate max width: for 4 columns, cap at ~800px; for 2 columns, cap at ~600px
                final maxWidth = isLargeDesktop ? 800.0 : 600.0;
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: gridView,
                  ),
                );
              }
              
              return gridView;
            },
          ),
          const SizedBox(height: 24),

          // Sprint 1: Vehicle Metrics
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isLargeDesktop = ResponsiveBreakpoints.isLargeDesktop(screenWidth);
              final isDesktop = ResponsiveBreakpoints.isDesktop(screenWidth);
              final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
              final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(screenWidth);
              final spacing = ResponsiveTokens.getSpacing(screenWidth);
              
              final crossAxisCount = isLargeDesktop ? 3 : 2;
              final childAspectRatio = isSmallMobile ? 1.4 : (isMobile ? 1.6 : (isDesktop ? 1.8 : 2.0));
              
              final gridView = GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                children: [
                  InsightsMetricCard(
                    label: 'Vehicle Utilization',
                    value: '${insights.vehicleUtilizationRate.toStringAsFixed(1)}%',
                    icon: Icons.directions_car,
                    iconColor: Colors.blue,
                    progressValue: insights.vehicleUtilizationRate / 100,
                    helpText: 'Percentage of vehicles that completed at least one job in the period. Fleet utilization.',
                  ),
                  InsightsMetricCard(
                    label: 'Unassigned Jobs',
                    value: insights.unassignedJobsCount.toString(),
                    icon: Icons.warning,
                    iconColor: Colors.orange,
                    progressValue: insights.unassignedJobsCount > 0 ? 1.0 : 0.0,
                    helpText: 'Number of jobs without a vehicle/driver assigned. Indicates scheduling or capacity gaps.',
                  ),
                ],
              );
              
              if (isDesktop) {
                final maxWidth = isLargeDesktop ? 800.0 : 600.0;
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: gridView,
                  ),
                );
              }
              
              return gridView;
            },
          ),
          const SizedBox(height: 24),

          // Phase 2: Distance Metrics
          SectionHeader(title: 'Distance Metrics'),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isLargeDesktop = ResponsiveBreakpoints.isLargeDesktop(screenWidth);
              final isDesktop = ResponsiveBreakpoints.isDesktop(screenWidth);
              final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
              final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(screenWidth);
              final spacing = ResponsiveTokens.getSpacing(screenWidth);
              
              final crossAxisCount = isLargeDesktop ? 4 : 2;
              final childAspectRatio = isSmallMobile ? 1.4 : (isMobile ? 1.6 : (isDesktop ? 1.8 : 2.0));
              
              final gridView = GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                children: [
                  InsightsMetricCard(
                    label: 'Total Distance',
                    value: insights.totalDistanceTraveled > 0
                        ? '${CurrencyUtils.formatWithSpaces(insights.totalDistanceTraveled)} km'
                        : 'N/A',
                    icon: Icons.straighten,
                    iconColor: Colors.blue,
                    progressValue: insights.totalDistanceTraveled > 0 ? 1.0 : 0.0,
                    helpText: 'Total distance traveled by all vehicles in the period. Fleet mileage overview.',
                  ),
                  InsightsMetricCard(
                    label: 'Avg Distance/Vehicle',
                    value: insights.averageDistancePerVehicle > 0
                        ? '${CurrencyUtils.formatWithSpaces(insights.averageDistancePerVehicle)} km'
                        : 'N/A',
                    icon: Icons.speed,
                    iconColor: Colors.green,
                    progressValue: insights.averageDistancePerVehicle > 0 ? 1.0 : 0.0,
                    helpText: 'Average distance per active vehicle in the period. Per-vehicle usage.',
                  ),
                  InsightsMetricCard(
                    label: 'Avg Distance/Job',
                    value: insights.averageDistancePerJob > 0
                        ? '${CurrencyUtils.formatWithSpaces(insights.averageDistancePerJob)} km'
                        : 'N/A',
                    icon: Icons.route,
                    iconColor: Colors.purple,
                    progressValue: insights.averageDistancePerJob > 0 ? 1.0 : 0.0,
                    helpText: 'Average distance per completed job. Helps assess trip length and routing.',
                  ),
                  InsightsMetricCard(
                    label: 'Revenue per Km',
                    value: insights.revenuePerKm > 0
                        ? 'R${insights.revenuePerKm.toStringAsFixed(2)}/km'
                        : 'N/A',
                    icon: Icons.attach_money,
                    iconColor: Colors.orange,
                    progressValue: insights.revenuePerKm > 0 ? 1.0 : 0.0,
                    helpText: 'Revenue divided by total distance. Efficiency of revenue per kilometer traveled.',
                  ),
                ],
              );
              
              if (isDesktop) {
                final maxWidth = isLargeDesktop ? 800.0 : 600.0;
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: gridView,
                  ),
                );
              }
              
              return gridView;
            },
          ),
          const SizedBox(height: 24),

          // Efficiency Metrics
          SectionHeader(title: 'Efficiency Metrics'),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isLargeDesktop = ResponsiveBreakpoints.isLargeDesktop(screenWidth);
              final isDesktop = ResponsiveBreakpoints.isDesktop(screenWidth);
              final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
              final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(screenWidth);
              final spacing = ResponsiveTokens.getSpacing(screenWidth);
              
              final crossAxisCount = isLargeDesktop ? 3 : 2;
              final childAspectRatio = isSmallMobile ? 1.4 : (isMobile ? 1.6 : (isDesktop ? 1.8 : 2.0));
              
              final gridView = GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                children: [
                  InsightsMetricCard(
                    label: 'Efficiency Score',
                    value: '${CurrencyUtils.formatWithSpaces(insights.vehicleEfficiencyScore)}/100',
                    icon: Icons.star,
                    iconColor: Colors.amber,
                    progressValue: insights.vehicleEfficiencyScore / 100,
                    helpText: 'Composite score (0–100) based on utilization, revenue, and distance. Higher means better fleet efficiency.',
                  ),
                  InsightsMetricCard(
                    label: insights.vehicleWithHighestOdometer != null
                        ? 'Highest Odo – ${insights.vehicleWithHighestOdometer}'
                        : 'Highest Odometer',
                    value: insights.highestOdometerReading > 0
                        ? '${CurrencyUtils.formatWithSpaces(insights.highestOdometerReading)} km'
                        : '0 km',
                    icon: Icons.dashboard,
                    iconColor: Colors.red,
                    progressValue: insights.highestOdometerReading > 0 ? 1.0 : 0.0,
                    helpText: 'Highest odometer reading recorded among all vehicles. Useful for maintenance planning.',
                  ),
                  InsightsMetricCard(
                    label: 'Avg Km/Day',
                    value: insights.averageKmPerDay > 0
                        ? '${CurrencyUtils.formatWithSpaces(insights.averageKmPerDay)} km'
                        : '0 km',
                    icon: Icons.today,
                    iconColor: Colors.cyan,
                    progressValue: insights.averageKmPerDay > 0 ? 1.0 : 0.0,
                    helpText: 'Average kilometers traveled per day in the period. Daily fleet usage.',
                  ),
                ],
              );
              
              if (isDesktop) {
                final maxWidth = isLargeDesktop ? 800.0 : 600.0;
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: gridView,
                  ),
                );
              }
              
              return gridView;
            },
          ),
          const SizedBox(height: 24),

          // Phase 2: Top Vehicles
          if (insights.topVehicles.isNotEmpty) ...[
            SectionHeader(title: 'Top Vehicles'),
            const SizedBox(height: 16),
            _buildTopVehiclesCard(context, insights.topVehicles),
            const SizedBox(height: 24),
          ],

          // Sprint 1: Least Used Vehicles
          if (insights.leastUsedVehicles.isNotEmpty) ...[
            SectionHeader(title: 'Least Used Vehicles'),
            const SizedBox(height: 16),
            _buildLeastUsedVehiclesCard(context, insights.leastUsedVehicles),
          ],
        ],
      ),
    );
  }

  Widget _buildTopVehiclesCard(BuildContext context, List<TopVehicle> vehicles) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events_outlined,
                color: ChoiceLuxTheme.richGold,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Most Used Vehicles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ChoiceLuxTheme.softWhite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...vehicles.take(5).map((vehicle) => InkWell(
            onTap: () => context.go('/vehicles'),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ChoiceLuxTheme.charcoalGray.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.directions_car,
                    color: ChoiceLuxTheme.richGold,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.vehicleName,
                          style: TextStyle(
                            color: ChoiceLuxTheme.softWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          vehicle.registration,
                          style: TextStyle(
                            color: ChoiceLuxTheme.platinumSilver,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${vehicle.jobCount} jobs',
                        style: TextStyle(
                          color: ChoiceLuxTheme.richGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        CurrencyUtils.formatCompact(vehicle.revenue),
                        style: TextStyle(
                          color: ChoiceLuxTheme.platinumSilver,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildLeastUsedVehiclesCard(BuildContext context, List<TopVehicle> vehicles) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Underutilized Vehicles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ChoiceLuxTheme.softWhite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...vehicles.take(5).map((vehicle) => InkWell(
            onTap: () => context.go('/vehicles'),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ChoiceLuxTheme.charcoalGray.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.directions_car_outlined,
                    color: Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.vehicleName,
                          style: TextStyle(
                            color: ChoiceLuxTheme.softWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          vehicle.registration,
                          style: TextStyle(
                            color: ChoiceLuxTheme.platinumSilver,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${vehicle.jobCount} jobs',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

}
