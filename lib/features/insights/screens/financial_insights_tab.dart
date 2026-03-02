import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/insights/models/insights_data.dart';
import 'package:choice_lux_cars/features/insights/providers/financial_insights_provider.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/widgets/compact_metric_tile.dart';
import 'package:choice_lux_cars/shared/widgets/insights_metric_card.dart';
import 'package:choice_lux_cars/shared/widgets/section_header.dart';
import 'package:choice_lux_cars/shared/widgets/common_states.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';
import 'package:choice_lux_cars/shared/utils/snackbar_utils.dart';
import 'package:choice_lux_cars/core/utils.dart';

class FinancialInsightsTab extends ConsumerWidget {
  final TimePeriod selectedPeriod;
  final LocationFilter selectedLocation;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const FinancialInsightsTab({
    super.key,
    required this.selectedPeriod,
    required this.selectedLocation,
    this.customStartDate,
    this.customEndDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerKey = (selectedPeriod, selectedLocation, customStartDate, customEndDate);
    final financialInsightsAsync = ref.watch(financialInsightsProvider(providerKey));

    return Container(
      padding: const EdgeInsets.all(16),
      child: financialInsightsAsync.when(
        data: (insights) => _buildFinancialContent(context, insights),
        loading: () => const LoadingStateWidget(message: 'Loading financial insights...'),
        error: (error, stack) => ErrorStateWidget(
          message: 'Failed to load financial insights.\n\n${error.toString()}',
          onRetry: () => ref.invalidate(financialInsightsProvider(providerKey)),
        ),
      ),
    );
  }

  Widget _buildFinancialContent(BuildContext context, FinancialInsights insights) {
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
                            'Financial Analytics',
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
                  '${CurrencyUtils.formatCompact(insights.totalRevenue)} total revenue',
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
          SectionHeader(title: 'Financial Overview'),
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
                    label: 'Total Revenue',
                    value: CurrencyUtils.formatCompact(insights.totalRevenue),
                    icon: Icons.attach_money,
                    iconColor: Colors.green,
                    progressValue: 1.0,
                    helpText: 'Sum of all revenue from completed jobs in the selected period and location.',
                  ),
                  InsightsMetricCard(
                    label: 'Avg Job Value',
                    value: insights.averageJobValue > 0
                        ? CurrencyUtils.formatCompact(insights.averageJobValue)
                        : 'N/A',
                    icon: Icons.trending_up,
                    iconColor: Colors.blue,
                    progressValue: insights.averageJobValue > 0 ? 1.0 : 0.0,
                    helpText: 'Average revenue per completed job. Used to understand typical job value.',
                  ),
                  InsightsMetricCard(
                    label: 'This Week',
                    value: insights.revenueThisWeek > 0
                        ? CurrencyUtils.formatCompact(insights.revenueThisWeek)
                        : 'R0',
                    icon: Icons.calendar_today,
                    iconColor: Colors.blue,
                    progressValue: insights.totalRevenue > 0 
                        ? (insights.revenueThisWeek / insights.totalRevenue).clamp(0.0, 1.0)
                        : 0.0,
                    helpText: 'Revenue from jobs completed in the current calendar week.',
                  ),
                  InsightsMetricCard(
                    label: 'This Month',
                    value: CurrencyUtils.formatCompact(insights.revenueThisMonth),
                    icon: Icons.calendar_month,
                    iconColor: Colors.purple,
                    progressValue: insights.totalRevenue > 0
                        ? (insights.revenueThisMonth / insights.totalRevenue).clamp(0.0, 1.0)
                        : 0.0,
                    helpText: 'Revenue from jobs completed in the current calendar month.',
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

          // Revenue Growth Metrics
          SectionHeader(title: 'Revenue Growth'),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isLargeDesktop = ResponsiveBreakpoints.isLargeDesktop(screenWidth);
              final isDesktop = ResponsiveBreakpoints.isDesktop(screenWidth);
              final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
              final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(screenWidth);
              final spacing = ResponsiveTokens.getSpacing(screenWidth);
              
              final crossAxisCount = isLargeDesktop ? 2 : 2;
              final childAspectRatio = isSmallMobile ? 1.4 : (isMobile ? 1.6 : (isDesktop ? 1.8 : 2.0));
              
              final gridView = GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                children: [
                  CompactMetricTile(
                    label: 'Week-over-Week Growth',
                    value: '${insights.revenueGrowthWeekOverWeek >= 0 ? '+' : ''}${insights.revenueGrowthWeekOverWeek.toStringAsFixed(1)}%',
                    icon: Icons.trending_up,
                    iconColor: insights.revenueGrowthWeekOverWeek >= 0 ? Colors.green : Colors.red,
                    helpText: 'Percentage change in revenue compared to the previous week. Short-term trend.',
                  ),
                  CompactMetricTile(
                    label: 'Month-over-Month Growth',
                    value: '${insights.revenueGrowthMonthOverMonth >= 0 ? '+' : ''}${insights.revenueGrowthMonthOverMonth.toStringAsFixed(1)}%',
                    icon: Icons.trending_up,
                    iconColor: insights.revenueGrowthMonthOverMonth >= 0 ? Colors.green : Colors.red,
                    helpText: 'Percentage change in revenue compared to the previous month. Medium-term trend.',
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

          // Sprint 1: Revenue by Location
          SectionHeader(title: 'Revenue by Location'),
          const SizedBox(height: 16),
          _buildRevenueByLocationCard(insights),
        ],
      ),
    );
  }

  Widget _buildRevenueByLocationCard(FinancialInsights insights) {
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
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: ChoiceLuxTheme.richGold,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Location Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...insights.revenueByLocation.entries.map((entry) {
            final location = entry.key;
            final revenue = entry.value;
            final totalRevenue = insights.revenueByLocation.values.fold<double>(0.0, (sum, val) => sum + val);
            final percentage = totalRevenue > 0 ? (revenue / totalRevenue) * 100 : 0.0;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${CurrencyUtils.formatCompact(revenue)} (${percentage.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          color: ChoiceLuxTheme.richGold,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(ChoiceLuxTheme.richGold),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

}
