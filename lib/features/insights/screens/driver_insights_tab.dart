import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/insights/models/insights_data.dart';
import 'package:choice_lux_cars/features/insights/providers/driver_insights_provider.dart';
import 'package:choice_lux_cars/features/insights/widgets/star_rating_bar.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/widgets/compact_metric_tile.dart';
import 'package:choice_lux_cars/shared/widgets/metric_help_icon.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';
import 'package:go_router/go_router.dart';

class DriverInsightsTab extends ConsumerWidget {
  final TimePeriod selectedPeriod;
  final LocationFilter selectedLocation;

  const DriverInsightsTab({
    super.key,
    required this.selectedPeriod,
    required this.selectedLocation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverInsightsAsync = ref.watch(driverInsightsProvider((
      selectedPeriod,
      selectedLocation,
    )));

    return Container(
      padding: const EdgeInsets.all(16),
      child: driverInsightsAsync.when(
        data: (insights) => _buildDriverContent(context, insights),
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error.toString()),
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
                        // TODO: Implement export report functionality
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
          _buildSectionHeader('Driver Performance'),
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
                  _buildNewMetricCard(
                    context: context,
                    label: 'Total Drivers',
                    value: insights.totalDrivers.toString(),
                    icon: Icons.people_outline,
                    iconColor: ChoiceLuxTheme.richGold,
                    progressValue: 1.0,
                    helpText: 'Total number of drivers in the selected period and location.',
                  ),
                  _buildNewMetricCard(
                    context: context,
                    label: 'Active Drivers',
                    value: insights.activeDrivers.toString(),
                    icon: Icons.person_outline,
                    iconColor: Colors.green,
                    progressValue: insights.totalDrivers > 0 
                        ? (insights.activeDrivers / insights.totalDrivers).clamp(0.0, 1.0)
                        : 0.0,
                    helpText: 'Drivers who have completed at least one job in the period. Indicates engaged workforce size.',
                  ),
                  _buildNewMetricCard(
                    context: context,
                    label: 'Avg Jobs/Driver',
                    value: insights.averageJobsPerDriver.toStringAsFixed(1),
                    icon: Icons.work_outline,
                    iconColor: Colors.blue,
                    progressValue: insights.averageJobsPerDriver > 0 ? 1.0 : 0.0,
                    helpText: 'Average number of jobs completed per active driver. Used to compare workload and productivity.',
                  ),
                  _buildNewMetricCard(
                    context: context,
                    label: 'Avg Revenue/Driver',
                    value: 'R${insights.averageRevenuePerDriver.toStringAsFixed(0)}',
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
                  _buildNewMetricCard(
                    context: context,
                    label: 'Driver Utilization',
                    value: '${insights.driverUtilizationRate.toStringAsFixed(1)}%',
                    icon: Icons.people,
                    iconColor: Colors.blue,
                    progressValue: insights.driverUtilizationRate / 100,
                    helpText: 'Percentage of drivers who completed at least one job in the period. Measures how much of the fleet is actively used.',
                  ),
                  _buildNewMetricCard(
                    context: context,
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
          _buildSectionHeader('Performance Metrics'),
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
                  _buildNewMetricCard(
                    context: context,
                    label: 'Avg Completion Time',
                    value: insights.averageJobCompletionTime > 0
                        ? '${insights.averageJobCompletionTime.toStringAsFixed(1)}h'
                        : 'N/A',
                    icon: Icons.timer,
                    iconColor: Colors.blue,
                    progressValue: insights.averageJobCompletionTime > 0 ? 1.0 : 0.0,
                    helpText: 'Average hours from job start to completion. Used to monitor delivery speed.',
                  ),
                  _buildNewMetricCard(
                    context: context,
                    label: 'Avg Time to Pickup',
                    value: insights.averageTimeToPickup > 0
                        ? '${insights.averageTimeToPickup.toStringAsFixed(0)}m'
                        : 'N/A',
                    icon: Icons.access_time,
                    iconColor: Colors.green,
                    progressValue: insights.averageTimeToPickup > 0 ? 1.0 : 0.0,
                    helpText: 'Average minutes from job assignment to driver pickup. Tracks responsiveness.',
                  ),
                  _buildNewMetricCard(
                    context: context,
                    label: 'On-Time Pickup Rate',
                    value: insights.onTimePickupRate > 0
                        ? '${insights.onTimePickupRate.toStringAsFixed(1)}%'
                        : 'N/A',
                    icon: Icons.check_circle_outline,
                    iconColor: Colors.green,
                    progressValue: insights.onTimePickupRate / 100,
                    helpText: 'Percentage of jobs where the driver arrived at pickup within the allowed window. Monitors service reliability.',
                  ),
                  _buildNewMetricCard(
                    context: context,
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
          _buildSectionHeader('Activity Metrics'),
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
                  _buildNewMetricCard(
                    context: context,
                    label: 'Jobs This Week',
                    value: insights.jobsCompletedThisWeek.toString(),
                    icon: Icons.calendar_today,
                    iconColor: Colors.blue,
                    progressValue: insights.jobsCompletedThisWeek > 0 ? 1.0 : 0.0,
                    helpText: 'Number of jobs completed in the current calendar week. Weekly activity snapshot.',
                  ),
                  _buildNewMetricCard(
                    context: context,
                    label: 'Jobs This Month',
                    value: insights.jobsCompletedThisMonth.toString(),
                    icon: Icons.calendar_month,
                    iconColor: Colors.purple,
                    progressValue: insights.jobsCompletedThisMonth > 0 ? 1.0 : 0.0,
                    helpText: 'Number of jobs completed in the current calendar month. Monthly delivery volume.',
                  ),
                  _buildNewMetricCard(
                    context: context,
                    label: 'Active Jobs Now',
                    value: insights.activeJobsNow.toString(),
                    icon: Icons.work,
                    iconColor: Colors.orange,
                    progressValue: insights.activeJobsNow > 0 ? 1.0 : 0.0,
                    helpText: 'Jobs currently in progress (started but not yet completed). Current workload indicator.',
                  ),
                  _buildNewMetricCard(
                    context: context,
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
            _buildSectionHeader('All drivers'),
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: ChoiceLuxTheme.softWhite,
      ),
    );
  }

  Widget _buildNewMetricCard({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required double progressValue,
    String? trendIndicator,
    String? helpText,
    VoidCallback? onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(screenWidth);
    final cardPadding = isSmallMobile ? 10.0 : (isMobile ? 12.0 : 16.0);
    final iconSize = isSmallMobile ? 32.0 : (isMobile ? 36.0 : 40.0);
    final iconIconSize = isSmallMobile ? 18.0 : (isMobile ? 20.0 : 22.0);
    final valueFontSize = isSmallMobile ? 20.0 : (isMobile ? 22.0 : 28.0);
    final labelFontSize = isSmallMobile ? 11.0 : (isMobile ? 12.0 : 14.0);
    final iconSpacing = isSmallMobile ? 6.0 : (isMobile ? 8.0 : 12.0);
    final valueSpacing = isSmallMobile ? 3.0 : (isMobile ? 4.0 : 6.0);
    final labelSpacing = isSmallMobile ? 6.0 : (isMobile ? 8.0 : 12.0);

    Widget card = Container(
      padding: EdgeInsets.all(cardPadding),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon in rounded square container
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: iconIconSize,
                ),
              ),
            // Trend indicator (optional, top-right)
            if (trendIndicator != null)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallMobile ? 4 : 6,
                  vertical: isSmallMobile ? 1 : 2,
                ),
                decoration: BoxDecoration(
                  color: trendIndicator.startsWith('-')
                      ? Colors.red.withOpacity(0.2)
                      : Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  trendIndicator,
                  style: TextStyle(
                    fontSize: isSmallMobile ? 9 : 10,
                    fontWeight: FontWeight.w600,
                    color: trendIndicator.startsWith('-')
                        ? Colors.red.shade300
                        : Colors.green.shade300,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: iconSpacing),
          // Value
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: valueFontSize,
                fontWeight: FontWeight.w700,
                color: ChoiceLuxTheme.softWhite,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: valueSpacing),
          // Label
          if (helpText != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: labelFontSize,
                      color: ChoiceLuxTheme.platinumSilver,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                MetricHelpIcon(explanation: helpText!),
              ],
            )
          else
            Text(
              label,
              style: TextStyle(
                fontSize: labelFontSize,
                color: ChoiceLuxTheme.platinumSilver,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          SizedBox(height: labelSpacing),
          // Progress bar at bottom
          Container(
            height: 2,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(1),
            ),
            child: FractionallySizedBox(
              widthFactor: progressValue.clamp(0.0, 1.0),
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: card,
        ),
      );
    }

    return card;
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, {required BuildContext context}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = ResponsiveBreakpoints.isDesktop(screenWidth);
    
    // Smaller, more compact cards for desktop
    final iconSize = isDesktop ? 20.0 : 32.0;
    final iconContainerPadding = isDesktop ? 6.0 : 12.0;
    final cardPadding = isDesktop ? const EdgeInsets.all(6.0) : const EdgeInsets.all(16.0);
    final valueFontSize = isDesktop ? 16.0 : 24.0;
    final titleFontSize = isDesktop ? 12.0 : 14.0;
    final titleSpacing = isDesktop ? 4.0 : 8.0;
    final valueSpacing = isDesktop ? 3.0 : 8.0;
    final borderRadius = isDesktop ? 16.0 : 12.0;
    
    return Container(
      padding: cardPadding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(iconContainerPadding),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(borderRadius * 0.8),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
          SizedBox(height: valueSpacing),
          Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: titleSpacing),
          Text(
            title,
            style: TextStyle(
              fontSize: titleFontSize,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
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
            'R${driver.revenue.toStringAsFixed(0)}',
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

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ChoiceLuxTheme.richGold),
          ),
          SizedBox(height: 16),
          Text(
            'Loading driver insights...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load driver insights',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Refresh logic would go here
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ChoiceLuxTheme.richGold,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
