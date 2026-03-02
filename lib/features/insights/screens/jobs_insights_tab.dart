import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/features/insights/models/insights_data.dart';
import 'package:choice_lux_cars/features/insights/providers/jobs_insights_provider.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/widgets/common_states.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';
import 'package:choice_lux_cars/features/admin/widgets/ops_kpi_tile.dart';
import 'package:choice_lux_cars/features/admin/widgets/ops_section_card.dart';
import 'package:choice_lux_cars/shared/utils/snackbar_utils.dart';
import 'package:choice_lux_cars/core/utils.dart';

class JobsInsightsTab extends ConsumerWidget {
  final TimePeriod selectedPeriod;
  final LocationFilter selectedLocation;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const JobsInsightsTab({
    super.key,
    required this.selectedPeriod,
    required this.selectedLocation,
    this.customStartDate,
    this.customEndDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerKey = (selectedPeriod, selectedLocation, customStartDate, customEndDate);
    final jobsInsightsAsync = ref.watch(jobsInsightsProvider(providerKey));

    final screenWidth = MediaQuery.of(context).size.width;
    final padding = ResponsiveTokens.getPadding(screenWidth);
    
    return Container(
      padding: EdgeInsets.all(padding),
      child: jobsInsightsAsync.when(
        data: (insights) => _buildJobsContent(context, insights),
        loading: () => const LoadingStateWidget(message: 'Loading job insights...'),
        error: (error, stack) => ErrorStateWidget(
          message: 'Failed to load jobs insights.\n\n${error.toString()}',
          onRetry: () => ref.invalidate(jobsInsightsProvider(providerKey)),
        ),
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
              _buildTimeBasedMetricsSection(context, insights, screenWidth, padding, spacing),
              SizedBox(height: sectionSpacing),
              
              // Operational Metrics Section
              _buildOperationalMetricsSection(context, insights, screenWidth, padding, spacing),
              SizedBox(height: sectionSpacing),

              // Expense Overview Section
              _buildExpenseOverviewSection(context, insights, screenWidth, padding, spacing),
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
            if (width >= ResponsiveBreakpoints.tablet) ...[
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
          helpText: 'Total number of jobs in the selected period and location filters.',
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
          helpText: 'Number of jobs that have been completed in the selected period. Used to track delivery volume.',
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
          helpText: 'Number of jobs not yet completed (open or in progress). Helps monitor current workload.',
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
          helpText: 'Percentage of jobs completed out of total jobs in the period. Used to track delivery performance.',
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
        ? (insights.openJobs / insights.totalJobs * 100)
        : 0.0;
    final openJobsTotal = insights.openJobs;

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
                helpText: 'Average number of days from job start to completion. Helps assess how quickly jobs are delivered.',
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
                helpText: 'Percentage of completed jobs that were delivered on or before the due date. Used to monitor service reliability.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Time-Based Metrics Section
  Widget _buildTimeBasedMetricsSection(
    BuildContext context,
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
              helpText: 'Average number of days from job creation to when work started. Helps spot scheduling delays.',
            ),
            OpsKpiTile(
              label: 'Starting Today',
              value: insights.jobsStartingToday.toString(),
              icon: Icons.today,
              iconColor: Colors.blue,
              helpText: 'Count of jobs scheduled to start today. Useful for daily capacity planning.',
              onTap: () {
                final uri = Uri(
                  path: '/insights/jobs',
                  queryParameters: {
                    'timePeriod': selectedPeriod.toString().split('.').last,
                    'location': selectedLocation.toString().split('.').last,
                    'timeFilter': 'starting_today',
                  },
                );
                context.go(uri.toString());
              },
            ),
            OpsKpiTile(
              label: 'Starting Tomorrow',
              value: insights.jobsStartingTomorrow.toString(),
              icon: Icons.calendar_today,
              iconColor: Colors.purple,
              helpText: 'Count of jobs scheduled to start tomorrow. Helps plan ahead for resource allocation.',
              onTap: () {
                final uri = Uri(
                  path: '/insights/jobs',
                  queryParameters: {
                    'timePeriod': selectedPeriod.toString().split('.').last,
                    'location': selectedLocation.toString().split('.').last,
                    'timeFilter': 'starting_tomorrow',
                  },
                );
                context.go(uri.toString());
              },
            ),
            OpsKpiTile(
              label: 'Overdue Jobs',
              value: insights.overdueJobs.toString(),
              icon: Icons.warning_amber_outlined,
              iconColor: ChoiceLuxTheme.errorColor,
              isProblem: insights.overdueJobs > 0,
              helpText: 'Number of jobs past their due date and not yet completed. Requires attention to avoid client impact.',
              onTap: () {
                final uri = Uri(
                  path: '/insights/jobs',
                  queryParameters: {
                    'timePeriod': selectedPeriod.toString().split('.').last,
                    'location': selectedLocation.toString().split('.').last,
                    'timeFilter': 'overdue',
                  },
                );
                context.go(uri.toString());
              },
            ),
          ],
        ),
      ),
    );
  }

  // Operational Metrics Section
  Widget _buildOperationalMetricsSection(
    BuildContext context,
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
          helpText: 'Number of jobs that do not yet have a driver or resource assigned. High numbers may indicate staffing or scheduling gaps.',
          onTap: () {
            final uri = Uri(
              path: '/insights/jobs',
              queryParameters: {
                'timePeriod': selectedPeriod.toString().split('.').last,
                'location': selectedLocation.toString().split('.').last,
                'status': 'unassigned',
              },
            );
            context.go(uri.toString());
          },
        ),
      ),
    );
  }


  Widget _buildExpenseOverviewSection(
    BuildContext context,
    JobInsights insights,
    double width,
    double padding,
    double spacing,
  ) {
    if (insights.totalExpenses == 0) {
      return OpsSectionCard(
        title: 'Expense Overview',
        child: Padding(
          padding: EdgeInsets.all(spacing),
          child: Center(
            child: Text(
              'No expenses recorded for this period',
              style: TextStyle(
                color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    final isMobile = width < 600;
    final crossAxisCount = isMobile ? 2 : 4;

    return OpsSectionCard(
      title: 'Expense Overview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: spacing),
          GridView.count(
            crossAxisCount: crossAxisCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: isMobile ? 2.2 : 2.5,
            children: [
              OpsKpiTile(
                label: 'Total Expenses',
                value: insights.totalExpenses.toString(),
                icon: Icons.receipt_long,
                iconColor: Colors.blue,
                helpText: 'Total number of expense entries across all jobs in this period.',
              ),
              OpsKpiTile(
                label: 'Total Amount',
                value: CurrencyUtils.formatCompact(insights.totalExpenseAmount),
                icon: Icons.account_balance_wallet,
                iconColor: ChoiceLuxTheme.richGold,
                helpText: 'Sum of all expense amounts for this period.',
              ),
              OpsKpiTile(
                label: 'Avg per Job',
                value: CurrencyUtils.formatCompact(insights.averageExpensePerJob),
                icon: Icons.trending_flat,
                iconColor: Colors.green,
                helpText: 'Average expense amount per job that has expenses.',
              ),
              OpsKpiTile(
                label: 'Jobs with Expenses',
                value: _jobsWithExpensesCount(insights),
                icon: Icons.work,
                iconColor: Colors.purple,
                helpText: 'Number of jobs that have at least one expense entry.',
              ),
            ],
          ),
          SizedBox(height: spacing),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing / 2),
            child: Text(
              'Breakdown by Type',
              style: TextStyle(
                color: ChoiceLuxTheme.platinumSilver,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing / 2),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (insights.fuelExpenseAmount > 0)
                  _buildExpenseTypeChip('Fuel', insights.fuelExpenseAmount, Colors.orange),
                if (insights.parkingExpenseAmount > 0)
                  _buildExpenseTypeChip('Parking', insights.parkingExpenseAmount, Colors.blue),
                if (insights.tollExpenseAmount > 0)
                  _buildExpenseTypeChip('Tolls', insights.tollExpenseAmount, Colors.purple),
                if (insights.otherExpenseAmount > 0)
                  _buildExpenseTypeChip('Other', insights.otherExpenseAmount, Colors.grey),
              ],
            ),
          ),
          SizedBox(height: spacing),
        ],
      ),
    );
  }

  String _jobsWithExpensesCount(JobInsights insights) {
    if (insights.totalExpenses == 0 || insights.averageExpensePerJob == 0) return '0';
    return (insights.totalExpenseAmount / insights.averageExpensePerJob).round().toString();
  }

  Widget _buildExpenseTypeChip(String type, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            type,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            CurrencyUtils.formatCompact(amount),
            style: TextStyle(
              color: ChoiceLuxTheme.softWhite,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
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
            Flexible(
              child: Text(
                '$count (${percentage.toStringAsFixed(0)}%)',
                style: TextStyle(
                  fontSize: 14,
                  color: ChoiceLuxTheme.platinumSilver,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
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

}
