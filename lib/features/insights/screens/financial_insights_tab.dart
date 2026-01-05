import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/insights/models/insights_data.dart';
import 'package:choice_lux_cars/features/insights/providers/financial_insights_provider.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/widgets/compact_metric_tile.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';
import 'package:go_router/go_router.dart';

class FinancialInsightsTab extends ConsumerWidget {
  final TimePeriod selectedPeriod;
  final LocationFilter selectedLocation;

  const FinancialInsightsTab({
    super.key,
    required this.selectedPeriod,
    required this.selectedLocation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financialInsightsAsync = ref.watch(financialInsightsProvider((
      selectedPeriod,
      selectedLocation,
    )));

    return Container(
      padding: const EdgeInsets.all(16),
      child: financialInsightsAsync.when(
        data: (insights) => _buildFinancialContent(insights),
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildFinancialContent(FinancialInsights insights) {
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
                  'R${insights.totalRevenue.toStringAsFixed(0)} total revenue',
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
          _buildSectionHeader('Financial Overview'),
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
                    label: 'Total Revenue',
                    value: 'R${insights.totalRevenue.toStringAsFixed(0)}',
                    icon: Icons.attach_money,
                    iconColor: Colors.green,
                    progressValue: 1.0,
                  ),
                  _buildNewMetricCard(
                    context: context,
                    label: 'Avg Job Value',
                    value: insights.averageJobValue > 0
                        ? 'R${insights.averageJobValue.toStringAsFixed(0)}'
                        : 'N/A',
                    icon: Icons.trending_up,
                    iconColor: Colors.blue,
                    progressValue: insights.averageJobValue > 0 ? 1.0 : 0.0,
                  ),
                  _buildNewMetricCard(
                    context: context,
                    label: 'This Week',
                    value: insights.revenueThisWeek > 0
                        ? 'R${insights.revenueThisWeek.toStringAsFixed(0)}'
                        : 'R0',
                    icon: Icons.calendar_today,
                    iconColor: Colors.blue,
                    progressValue: insights.totalRevenue > 0 
                        ? (insights.revenueThisWeek / insights.totalRevenue).clamp(0.0, 1.0)
                        : 0.0,
                  ),
                  _buildNewMetricCard(
                    context: context,
                    label: 'This Month',
                    value: 'R${insights.revenueThisMonth.toStringAsFixed(0)}',
                    icon: Icons.calendar_month,
                    iconColor: Colors.purple,
                    progressValue: insights.totalRevenue > 0
                        ? (insights.revenueThisMonth / insights.totalRevenue).clamp(0.0, 1.0)
                        : 0.0,
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

          // Sprint 1: Payment Metrics
          _buildSectionHeader('Payment Analytics'),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isLargeDesktop = ResponsiveBreakpoints.isLargeDesktop(screenWidth);
              final isDesktop = ResponsiveBreakpoints.isDesktop(screenWidth);
              final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
              final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(screenWidth);
              final spacing = ResponsiveTokens.getSpacing(screenWidth);
              
              // Adjust grid to show 6 cards properly (3 columns on large desktop, 2 on smaller screens)
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
                  CompactMetricTile(
                    label: 'Payment Collection Rate',
                    value: insights.paymentCollectionRate != null
                        ? '${insights.paymentCollectionRate!.toStringAsFixed(1)}%'
                        : 'N/A',
                    icon: Icons.payment,
                    iconColor: Colors.green,
                  ),
                  CompactMetricTile(
                    label: 'Outstanding Payments',
                    value: 'R${insights.outstandingPayments.toStringAsFixed(0)}',
                    icon: Icons.warning,
                    iconColor: Colors.orange,
                  ),
                  CompactMetricTile(
                    label: 'Total Collected',
                    value: 'R${insights.totalCollected.toStringAsFixed(0)}',
                    icon: Icons.check_circle,
                    iconColor: Colors.green,
                  ),
                  CompactMetricTile(
                    label: 'Total Uncollected',
                    value: 'R${insights.totalUncollected.toStringAsFixed(0)}',
                    icon: Icons.cancel,
                    iconColor: Colors.red,
                  ),
                  CompactMetricTile(
                    label: 'Avg Payment Amount',
                    value: insights.averagePaymentAmount > 0
                        ? 'R${insights.averagePaymentAmount.toStringAsFixed(0)}'
                        : 'N/A',
                    icon: Icons.attach_money,
                    iconColor: Colors.blue,
                  ),
                  CompactMetricTile(
                    label: 'Jobs Requiring Payment',
                    value: insights.jobsRequiringPaymentCollection.toString(),
                    icon: Icons.receipt,
                    iconColor: Colors.purple,
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

          // Revenue Growth Metrics
          _buildSectionHeader('Revenue Growth'),
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
                  ),
                  CompactMetricTile(
                    label: 'Month-over-Month Growth',
                    value: '${insights.revenueGrowthMonthOverMonth >= 0 ? '+' : ''}${insights.revenueGrowthMonthOverMonth.toStringAsFixed(1)}%',
                    icon: Icons.trending_up,
                    iconColor: insights.revenueGrowthMonthOverMonth >= 0 ? Colors.green : Colors.red,
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
          _buildSectionHeader('Revenue by Location'),
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
                      Text(
                        location,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'R${revenue.toStringAsFixed(0)} (${percentage.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          color: ChoiceLuxTheme.richGold,
                          fontWeight: FontWeight.bold,
                        ),
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
            'Loading financial insights...',
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
            'Failed to load financial insights',
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
