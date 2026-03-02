import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/insights/models/insights_data.dart';
import 'package:choice_lux_cars/features/insights/providers/driver_insights_provider.dart';
import 'package:choice_lux_cars/features/insights/widgets/star_rating_bar.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/widgets/insights_metric_card.dart';
import 'package:choice_lux_cars/shared/widgets/section_header.dart';
import 'package:choice_lux_cars/shared/widgets/common_states.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/shared/utils/snackbar_utils.dart';
import 'package:choice_lux_cars/core/utils.dart';

class DriverInsightsTab extends ConsumerWidget {
  final TimePeriod selectedPeriod;
  final LocationFilter selectedLocation;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final GlobalKey _driversListKey = GlobalKey();

  DriverInsightsTab({
    super.key,
    required this.selectedPeriod,
    required this.selectedLocation,
    this.customStartDate,
    this.customEndDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerKey = (selectedPeriod, selectedLocation, customStartDate, customEndDate);
    final driverInsightsAsync = ref.watch(driverInsightsProvider(providerKey));

    return Container(
      padding: const EdgeInsets.all(16),
      child: driverInsightsAsync.when(
        data: (insights) => _buildDriverContent(context, insights),
        loading: () => const LoadingStateWidget(message: 'Loading driver insights...'),
        error: (error, stack) => ErrorStateWidget(
          message: 'Failed to load driver insights: ${error.toString()}',
          onRetry: () => ref.invalidate(driverInsightsProvider(providerKey)),
        ),
      ),
    );
  }

  Widget _buildDriverContent(BuildContext context, DriverInsights insights) {
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
                            'Driver Analytics',
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
                  '${insights.totalDrivers} drivers • ${insights.activeDrivers} active',
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
          SectionHeader(title: 'Driver Performance'),
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
                    label: 'Total Drivers',
                    value: insights.totalDrivers.toString(),
                    icon: Icons.people_outline,
                    iconColor: ChoiceLuxTheme.richGold,
                    progressValue: 1.0,
                    helpText: 'Total number of drivers in the selected period and location.',
                    onTap: () {
                      final keyContext = _driversListKey.currentContext;
                      if (keyContext != null) {
                        Scrollable.ensureVisible(keyContext, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                      }
                    },
                  ),
                  InsightsMetricCard(
                    label: 'Active Drivers',
                    value: insights.activeDrivers.toString(),
                    icon: Icons.person_outline,
                    iconColor: Colors.green,
                    progressValue: insights.totalDrivers > 0 
                        ? (insights.activeDrivers / insights.totalDrivers).clamp(0.0, 1.0)
                        : 0.0,
                    helpText: 'Drivers who have completed at least one job in the period. Indicates engaged workforce size.',
                  ),
                  InsightsMetricCard(
                    label: 'Avg Jobs/Driver',
                    value: insights.averageJobsPerDriver.toStringAsFixed(1),
                    icon: Icons.work_outline,
                    iconColor: Colors.blue,
                    progressValue: insights.averageJobsPerDriver > 0 ? 1.0 : 0.0,
                    helpText: 'Average number of jobs completed per active driver. Used to compare workload and productivity.',
                  ),
                  InsightsMetricCard(
                    label: 'Avg Revenue/Driver',
                    value: CurrencyUtils.formatCompact(insights.averageRevenuePerDriver),
                    icon: Icons.attach_money,
                    iconColor: Colors.orange,
                    progressValue: insights.averageRevenuePerDriver > 0 ? 1.0 : 0.0,
                    helpText: 'Average revenue generated per active driver in the period. Helps assess driver contribution.',
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

          // Sprint 1: New Driver Metrics
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
                    label: 'Driver Utilization',
                    value: '${insights.driverUtilizationRate.toStringAsFixed(1)}%',
                    icon: Icons.people,
                    iconColor: Colors.blue,
                    progressValue: insights.driverUtilizationRate / 100,
                    helpText: 'Percentage of drivers who completed at least one job in the period. Measures how much of the fleet is actively used.',
                  ),
                  InsightsMetricCard(
                    label: 'Unassigned Jobs',
                    value: insights.unassignedJobsCount.toString(),
                    icon: Icons.person_off,
                    iconColor: Colors.orange,
                    progressValue: insights.unassignedJobsCount > 0 ? 1.0 : 0.0,
                    helpText: 'Number of jobs without a driver assigned. High values may indicate staffing or scheduling gaps.',
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

          // Phase 2: Performance Metrics
          SectionHeader(title: 'Performance Metrics'),
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
                    label: 'Avg Completion Time',
                    value: insights.averageJobCompletionTime > 0
                        ? '${insights.averageJobCompletionTime.toStringAsFixed(1)}h'
                        : 'N/A',
                    icon: Icons.timer,
                    iconColor: Colors.blue,
                    progressValue: insights.averageJobCompletionTime > 0 ? 1.0 : 0.0,
                    helpText: 'Average hours from job start to completion. Used to monitor delivery speed.',
                  ),
                  InsightsMetricCard(
                    label: 'Avg Time to Pickup',
                    value: insights.averageTimeToPickup > 0
                        ? '${CurrencyUtils.formatWithSpaces(insights.averageTimeToPickup)}m'
                        : 'N/A',
                    icon: Icons.access_time,
                    iconColor: Colors.green,
                    progressValue: insights.averageTimeToPickup > 0 ? 1.0 : 0.0,
                    helpText: 'Average minutes from job assignment to driver pickup. Tracks responsiveness.',
                  ),
                  InsightsMetricCard(
                    label: 'On-Time Pickup Rate',
                    value: insights.onTimePickupRate > 0
                        ? '${insights.onTimePickupRate.toStringAsFixed(1)}%'
                        : 'N/A',
                    icon: Icons.check_circle_outline,
                    iconColor: Colors.green,
                    progressValue: insights.onTimePickupRate / 100,
                    helpText: 'Percentage of jobs where the driver arrived at pickup within the allowed window. Monitors service reliability.',
                  ),
                  InsightsMetricCard(
                    label: 'Payment Collection',
                    value: insights.paymentCollectionRate > 0
                        ? '${insights.paymentCollectionRate.toStringAsFixed(1)}%'
                        : 'N/A',
                    icon: Icons.payment,
                    iconColor: Colors.purple,
                    progressValue: insights.paymentCollectionRate / 100,
                    helpText: 'Percentage of jobs where payment was collected. Used to track revenue capture.',
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

          // Phase 2: Activity Metrics
          SectionHeader(title: 'Activity Metrics'),
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
                    label: 'Jobs This Week',
                    value: insights.jobsCompletedThisWeek.toString(),
                    icon: Icons.calendar_today,
                    iconColor: Colors.blue,
                    progressValue: insights.jobsCompletedThisWeek > 0 ? 1.0 : 0.0,
                    helpText: 'Number of jobs completed in the current calendar week. Weekly activity snapshot.',
                  ),
                  InsightsMetricCard(
                    label: 'Jobs This Month',
                    value: insights.jobsCompletedThisMonth.toString(),
                    icon: Icons.calendar_month,
                    iconColor: Colors.purple,
                    progressValue: insights.jobsCompletedThisMonth > 0 ? 1.0 : 0.0,
                    helpText: 'Number of jobs completed in the current calendar month. Monthly delivery volume.',
                  ),
                  InsightsMetricCard(
                    label: 'Active Jobs Now',
                    value: insights.activeJobsNow.toString(),
                    icon: Icons.work,
                    iconColor: Colors.orange,
                    progressValue: insights.activeJobsNow > 0 ? 1.0 : 0.0,
                    helpText: 'Jobs currently in progress (started but not yet completed). Current workload indicator.',
                  ),
                  InsightsMetricCard(
                    label: 'Started Today',
                    value: insights.jobsStartedToday.toString(),
                    icon: Icons.play_arrow,
                    iconColor: Colors.green,
                    progressValue: insights.jobsStartedToday > 0 ? 1.0 : 0.0,
                    helpText: 'Jobs that were started today. Daily activity measure.',
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

          // All drivers (sorted by rating)
          if (insights.allDrivers.isNotEmpty) ...[
            Container(key: _driversListKey, child: SectionHeader(title: 'All drivers')),
            const SizedBox(height: 4),
            Text(
              'Sorted by rating (highest to lowest)',
              style: TextStyle(
                fontSize: 14,
                color: ChoiceLuxTheme.platinumSilver,
              ),
            ),
            const SizedBox(height: 16),
            _buildTopDriversCard(context, insights.allDrivers),
          ],
        ],
      ),
    );
  }

  Widget _buildTopDriversCard(BuildContext context, List<TopDriver> topDrivers) {
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
                'Drivers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ChoiceLuxTheme.softWhite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topDrivers.map((driver) => _buildDriverItem(context, driver)),
        ],
      ),
    );
  }

  Widget _buildDriverItem(BuildContext context, TopDriver driver) {
    return GestureDetector(
      onTap: () {
        context.push(
          '/insights/driver?id=${Uri.encodeComponent(driver.driverId)}&name=${Uri.encodeComponent(driver.driverName)}',
        );
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
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
          CircleAvatar(
            backgroundColor: ChoiceLuxTheme.richGold.withOpacity(0.2),
            child: Text(
              driver.driverName.isNotEmpty ? driver.driverName[0].toUpperCase() : 'D',
              style: TextStyle(
                color: ChoiceLuxTheme.richGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.driverName.isNotEmpty ? driver.driverName : 'Unknown Driver',
                  style: TextStyle(
                    color: ChoiceLuxTheme.softWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${driver.jobCount} jobs',
                  style: TextStyle(
                    color: ChoiceLuxTheme.platinumSilver,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StarRatingBar(rating: driver.averageRating, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      driver.ratingTripCount > 0
                          ? '(${driver.ratingTripCount} trip${driver.ratingTripCount == 1 ? '' : 's'})'
                          : 'No rating yet',
                      style: TextStyle(
                        color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            CurrencyUtils.formatCompact(driver.revenue),
            style: TextStyle(
              color: ChoiceLuxTheme.richGold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      ),
    ),
    );
  }

}
