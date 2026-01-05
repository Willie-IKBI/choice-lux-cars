import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/features/insights/models/insights_data.dart';
import 'package:choice_lux_cars/features/insights/providers/jobs_insights_provider.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';

class JobsInsightsTab extends ConsumerWidget {
  final TimePeriod selectedPeriod;
  final LocationFilter selectedLocation;

  const JobsInsightsTab({
    super.key,
    required this.selectedPeriod,
    required this.selectedLocation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsInsightsAsync = ref.watch(jobsInsightsProvider((
      selectedPeriod,
      selectedLocation,
    )));

    return Container(
      padding: const EdgeInsets.all(16),
      child: jobsInsightsAsync.when(
        data: (insights) => _buildJobsContent(context, insights),
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildJobsContent(BuildContext context, JobInsights insights) {
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
                            'Jobs Analytics',
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
                  '${insights.totalJobs} total jobs • ${insights.completedJobs} completed',
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
                    label: 'Total Jobs',
                    value: insights.totalJobs.toString(),
                    icon: Icons.work,
                    iconColor: ChoiceLuxTheme.richGold,
                    progressValue: 1.0,
                    trendIndicator: '+10%',
                    onTap: () {
                      final uri = Uri(
                        path: '/insights/jobs',
                        queryParameters: {
                          'timePeriod': selectedPeriod.toString().split('.').last,
                          'location': selectedLocation.toString().split('.').last,
                          'status': 'all',
                        },
                      );
                      context.go(uri.toString());
                    },
                  ),
                  _buildNewMetricCard(
                    context: context,
                    label: 'Completed',
                    value: insights.completedJobs.toString(),
                    icon: Icons.check_circle,
                    iconColor: Colors.green,
                    progressValue: insights.totalJobs > 0 ? insights.completedJobs / insights.totalJobs : 0.0,
                    onTap: () {
                      final uri = Uri(
                        path: '/insights/jobs',
                        queryParameters: {
                          'timePeriod': selectedPeriod.toString().split('.').last,
                          'location': selectedLocation.toString().split('.').last,
                          'status': 'completed',
                        },
                      );
                      context.go(uri.toString());
                    },
                  ),
                  _buildNewMetricCard(
                    context: context,
                    label: 'Open Jobs',
                    value: insights.openJobs.toString(),
                    icon: Icons.schedule,
                    iconColor: Colors.orange,
                    progressValue: insights.totalJobs > 0 ? insights.openJobs / insights.totalJobs : 0.0,
                    onTap: () {
                      final uri = Uri(
                        path: '/insights/jobs',
                        queryParameters: {
                          'timePeriod': selectedPeriod.toString().split('.').last,
                          'location': selectedLocation.toString().split('.').last,
                          'status': 'open',
                        },
                      );
                      context.go(uri.toString());
                    },
                  ),
                  _buildNewMetricCard(
                    context: context,
                    label: 'Completion Rate',
                    value: '${(insights.completionRate * 100).toStringAsFixed(0)}%',
                    icon: Icons.trending_down,
                    iconColor: Colors.blue,
                    progressValue: insights.completionRate,
                    trendIndicator: '-2.3%',
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

          // Job Status Breakdown
          _buildSectionHeader('Job Status Breakdown'),
          const SizedBox(height: 16),
          _buildJobStatusCard(insights),
          const SizedBox(height: 24),
          
          // Additional Metrics
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final spacing = ResponsiveTokens.getSpacing(screenWidth);
              
              return Row(
                children: [
                  Expanded(
                    child: _buildAdditionalMetricCard(
                      context: context,
                      label: 'AVG. COMPLETION TIME',
                      value: insights.completedJobs > 0
                          ? '${insights.averageCompletionDays.toStringAsFixed(1)} days'
                          : 'N/A',
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: _buildAdditionalMetricCard(
                      context: context,
                      label: 'ON-TIME RATE',
                      value: insights.completedJobs > 0
                          ? '${insights.onTimeRate.toStringAsFixed(1)}%'
                          : 'N/A',
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Sprint 1: Time-Based Metrics
          _buildSectionHeader('Time-Based Metrics'),
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
                  _buildAdditionalMetricCard(
                    context: context,
                    label: 'AVG. TIME TO START',
                    value: '${insights.averageTimeToStart.toStringAsFixed(1)} days',
                  ),
                  _buildNewMetricCard(
                    context: context,
                    label: 'Starting Today',
                    value: insights.jobsStartingToday.toString(),
                    icon: Icons.today,
                    iconColor: Colors.blue,
                    progressValue: 1.0,
                  ),
                  _buildNewMetricCard(
                    context: context,
                    label: 'Starting Tomorrow',
                    value: insights.jobsStartingTomorrow.toString(),
                    icon: Icons.calendar_today,
                    iconColor: Colors.purple,
                    progressValue: 1.0,
                  ),
                  _buildNewMetricCard(
                    context: context,
                    label: 'Overdue Jobs',
                    value: insights.overdueJobs.toString(),
                    icon: Icons.warning,
                    iconColor: Colors.red,
                    progressValue: insights.overdueJobs > 0 ? 1.0 : 0.0,
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

          // Sprint 1: Operational Metrics
          _buildSectionHeader('Operational Metrics'),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final spacing = ResponsiveTokens.getSpacing(screenWidth);
              
              return Row(
                children: [
                  Expanded(
                    child: _buildNewMetricCard(
                      context: context,
                      label: 'Unassigned Jobs',
                      value: insights.unassignedJobs.toString(),
                      icon: Icons.person_off,
                      iconColor: Colors.orange,
                      progressValue: insights.unassignedJobs > 0 ? 1.0 : 0.0,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalMetricCard({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(screenWidth);
    
    // Match padding from _buildNewMetricCard
    final cardPadding = isSmallMobile ? 10.0 : (isMobile ? 12.0 : 16.0);
    final valueFontSize = isSmallMobile ? 20.0 : (isMobile ? 22.0 : 28.0);
    final labelFontSize = isSmallMobile ? 11.0 : (isMobile ? 12.0 : 14.0);
    
    // Match spacing from _buildNewMetricCard
    final iconSpacing = isSmallMobile ? 6.0 : (isMobile ? 8.0 : 12.0);
    final valueSpacing = isSmallMobile ? 3.0 : (isMobile ? 4.0 : 6.0);
    final labelSpacing = isSmallMobile ? 6.0 : (isMobile ? 8.0 : 12.0);

    return Container(
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
          // Add spacing at top to match main cards structure
          SizedBox(height: iconSpacing),
          // Value (moved up to match main cards layout)
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
          // Add a thin spacer bar at bottom to match visual weight
          Container(
            height: 2,
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
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

  Widget _buildJobStatusCard(JobInsights insights) {
    final completedPercentage = insights.totalJobs > 0
        ? (insights.completedJobs / insights.totalJobs * 100)
        : 0.0;
    final openPercentage = insights.totalJobs > 0
        ? ((insights.openJobs + insights.inProgressJobs) / insights.totalJobs * 100)
        : 0.0;
    final openJobsTotal = insights.openJobs + insights.inProgressJobs;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Job Status Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ChoiceLuxTheme.softWhite,
            ),
          ),
          const SizedBox(height: 20),
          // Completed status bar
          _buildStatusBar(
            'Completed',
            insights.completedJobs,
            completedPercentage,
            Colors.green,
          ),
          const SizedBox(height: 16),
          // Open/In Progress status bar
          _buildStatusBar(
            'Open / In Progress',
            openJobsTotal,
            openPercentage,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(String label, int count, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '•',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: ChoiceLuxTheme.softWhite,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              '$count (${percentage.toStringAsFixed(0)}%)',
              style: TextStyle(
                fontSize: 14,
                color: ChoiceLuxTheme.platinumSilver,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            widthFactor: (percentage / 100).clamp(0.0, 1.0),
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
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
            'Loading jobs insights...',
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
            'Failed to load jobs insights',
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
