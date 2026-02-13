import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/features/insights/models/insights_data.dart';
import 'package:choice_lux_cars/features/insights/providers/jobs_insights_provider.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';
import 'package:choice_lux_cars/features/admin/widgets/ops_kpi_tile.dart';
import 'package:choice_lux_cars/features/admin/widgets/ops_section_card.dart';

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

    final screenWidth = MediaQuery.of(context).size.width;
    final padding = ResponsiveTokens.getPadding(screenWidth);
    
    return Container(
      padding: EdgeInsets.all(padding),
      child: jobsInsightsAsync.when(
        data: (insights) => _buildJobsContent(context, insights),
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildJobsContent(BuildContext context, JobInsights insights) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = ResponsiveBreakpoints.isDesktop(screenWidth);
    final padding = ResponsiveTokens.getPadding(screenWidth);
    final spacing = ResponsiveTokens.getSpacing(screenWidth);
    final sectionSpacing = 24.0; // Match Operations Dashboard
    
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? padding * 2 : padding,
        vertical: padding,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200), // Match Operations Dashboard
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header - Match Operations Dashboard style
              _buildPageHeader(context, insights, screenWidth, padding, spacing, isDesktop),
              SizedBox(height: sectionSpacing),

              // Key Metrics - Using OpsKpiTile to match Operations Dashboard
              _buildKpiSection(context, insights, screenWidth, padding, spacing),
              SizedBox(height: sectionSpacing),

              // Job Status Breakdown - Using OpsSectionCard
              _buildJobStatusSection(insights, screenWidth, padding, spacing),
              SizedBox(height: sectionSpacing),
          
              // Additional Metrics Section
              _buildAdditionalMetricsSection(insights, screenWidth, padding, spacing),
              SizedBox(height: sectionSpacing),
              
              // Time-Based Metrics Section
              _buildTimeBasedMetricsSection(insights, screenWidth, padding, spacing),
              SizedBox(height: sectionSpacing),
              
              // Operational Metrics Section
              _buildOperationalMetricsSection(insights, screenWidth, padding, spacing),
            ],
          ),
        ),
      ),
    );
  }

  // Page Header - Match Operations Dashboard style
  Widget _buildPageHeader(
    BuildContext context,
    JobInsights insights,
    double width,
    double padding,
    double spacing,
    bool isDesktop,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jobs Analytics',
                    style: TextStyle(
                      color: ChoiceLuxTheme.softWhite,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: spacing * 0.5),
                  Text(
                    '${insights.totalJobs} total jobs • ${insights.completedJobs} completed',
                    style: TextStyle(
                      color: ChoiceLuxTheme.platinumSilver.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isDesktop) ...[
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
          ],
        ),
      ],
    );
  }

  // KPI Section - Match Operations Dashboard
  Widget _buildKpiSection(
    BuildContext context,
    JobInsights insights,
    double width,
    double padding,
    double spacing,
  ) {
    final isMobile = ResponsiveBreakpoints.isMobile(width);
    final isTablet = ResponsiveBreakpoints.isTablet(width);
    final crossAxisCount = isMobile ? 2 : (isTablet ? 3 : 4);
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      childAspectRatio: ResponsiveBreakpoints.isDesktop(width) ? 1.0 : 1.2,
      children: [
        OpsKpiTile(
          label: 'Total Jobs',
          value: insights.totalJobs.toString(),
          icon: Icons.work_outlined,
          iconColor: ChoiceLuxTheme.infoColor,
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
        OpsKpiTile(
          label: 'Completed',
          value: insights.completedJobs.toString(),
          icon: Icons.check_circle_outline,
          iconColor: ChoiceLuxTheme.successColor,
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
        OpsKpiTile(
          label: 'Open Jobs',
          value: insights.openJobs.toString(),
          icon: Icons.hourglass_empty,
          iconColor: ChoiceLuxTheme.orange,
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
        OpsKpiTile(
          label: 'Completion Rate',
          value: '${(insights.completionRate * 100).toStringAsFixed(0)}%',
          icon: Icons.trending_up,
          iconColor: ChoiceLuxTheme.richGold,
        ),
      ],
    );
  }

  // Job Status Section - Using OpsSectionCard
  Widget _buildJobStatusSection(
    JobInsights insights,
    double width,
    double padding,
    double spacing,
  ) {
    return OpsSectionCard(
      title: 'Job Status Breakdown',
      child: _buildJobStatusContent(insights, spacing),
    );
  }

  Widget _buildJobStatusContent(JobInsights insights, double spacing) {
    final completedPercentage = insights.totalJobs > 0
        ? (insights.completedJobs / insights.totalJobs * 100)
        : 0.0;
    final openPercentage = insights.totalJobs > 0
        ? ((insights.openJobs + insights.inProgressJobs) / insights.totalJobs * 100)
        : 0.0;
    final openJobsTotal = insights.openJobs + insights.inProgressJobs;

    return Padding(
      padding: EdgeInsets.only(top: spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusBar(
            'Completed',
            insights.completedJobs,
            completedPercentage,
            Colors.green,
          ),
          SizedBox(height: spacing),
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

  // Additional Metrics Section
  Widget _buildAdditionalMetricsSection(
    JobInsights insights,
    double width,
    double padding,
    double spacing,
  ) {
    return OpsSectionCard(
      title: 'Performance Metrics',
      child: Padding(
        padding: EdgeInsets.only(top: spacing),
        child: Row(
          children: [
            Expanded(
              child: OpsKpiTile(
                label: 'Avg. Completion Time',
                value: insights.completedJobs > 0
                    ? '${insights.averageCompletionDays.toStringAsFixed(1)}d'
                    : 'N/A',
                icon: Icons.schedule,
                iconColor: ChoiceLuxTheme.infoColor,
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: OpsKpiTile(
                label: 'On-Time Rate',
                value: insights.completedJobs > 0
                    ? '${insights.onTimeRate.toStringAsFixed(0)}%'
                    : 'N/A',
                icon: Icons.timer,
                iconColor: ChoiceLuxTheme.successColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Time-Based Metrics Section
  Widget _buildTimeBasedMetricsSection(
    JobInsights insights,
    double width,
    double padding,
    double spacing,
  ) {
    final isMobile = ResponsiveBreakpoints.isMobile(width);
    final isTablet = ResponsiveBreakpoints.isTablet(width);
    final crossAxisCount = isMobile ? 2 : (isTablet ? 3 : 4);
    
    return OpsSectionCard(
      title: 'Time-Based Metrics',
      child: Padding(
        padding: EdgeInsets.only(top: spacing),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: ResponsiveBreakpoints.isDesktop(width) ? 1.0 : 1.2,
          children: [
            OpsKpiTile(
              label: 'Avg. Time to Start',
              value: '${insights.averageTimeToStart.toStringAsFixed(1)}d',
              icon: Icons.play_arrow,
              iconColor: ChoiceLuxTheme.infoColor,
            ),
            OpsKpiTile(
              label: 'Starting Today',
              value: insights.jobsStartingToday.toString(),
              icon: Icons.today,
              iconColor: Colors.blue,
            ),
            OpsKpiTile(
              label: 'Starting Tomorrow',
              value: insights.jobsStartingTomorrow.toString(),
              icon: Icons.calendar_today,
              iconColor: Colors.purple,
            ),
            OpsKpiTile(
              label: 'Overdue Jobs',
              value: insights.overdueJobs.toString(),
              icon: Icons.warning_amber_outlined,
              iconColor: ChoiceLuxTheme.errorColor,
              isProblem: insights.overdueJobs > 0,
            ),
          ],
        ),
      ),
    );
  }

  // Operational Metrics Section
  Widget _buildOperationalMetricsSection(
    JobInsights insights,
    double width,
    double padding,
    double spacing,
  ) {
    return OpsSectionCard(
      title: 'Operational Metrics',
      child: Padding(
        padding: EdgeInsets.only(top: spacing),
        child: OpsKpiTile(
          label: 'Unassigned Jobs',
          value: insights.unassignedJobs.toString(),
          icon: Icons.person_off,
          iconColor: ChoiceLuxTheme.orange,
          isProblem: insights.unassignedJobs > 0,
        ),
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
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: ChoiceLuxTheme.softWhite,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
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
