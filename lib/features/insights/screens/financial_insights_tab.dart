import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/insights/models/insights_data.dart';
import 'package:choice_lux_cars/features/insights/providers/financial_insights_provider.dart';
import 'package:choice_lux_cars/app/theme.dart';

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
    final financialInsightsAsync = ref.watch(financialInsightsProvider((
      selectedPeriod,
      selectedLocation,
      customStartDate,
      customEndDate,
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
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1a1a1a),
                  Color(0xFF2d2d2d),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ChoiceLuxTheme.richGold.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.attach_money,
                  color: ChoiceLuxTheme.richGold,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Financial Analytics',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'R${insights.totalRevenue.toStringAsFixed(0)} total revenue',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
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
              final isLargeDesktop = screenWidth >= 1200;
              final isDesktop = screenWidth >= 600;
              
              // 4 columns on large desktop (all cards in one row), 2 columns on medium desktop/tablet
              final crossAxisCount = isLargeDesktop ? 4 : 2;
              final childAspectRatio = isDesktop ? 1.0 : 1.5; // Square cards on desktop, taller on mobile
              final spacing = isDesktop ? 12.0 : 16.0; // Match dashboard spacing on desktop
              
              final gridView = GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                children: [
                  _buildMetricCard(
                    'Total Revenue',
                    'R${insights.totalRevenue.toStringAsFixed(0)}',
                    Icons.attach_money,
                    Colors.green,
                    context: context,
                  ),
                  _buildMetricCard(
                    'Avg Job Value',
                    'R${insights.averageJobValue.toStringAsFixed(0)}',
                    Icons.trending_up,
                    Colors.blue,
                    context: context,
                  ),
                  _buildMetricCard(
                    'This Week',
                    'R${insights.revenueThisWeek.toStringAsFixed(0)}',
                    Icons.calendar_today,
                    Colors.blue,
                    context: context,
                  ),
                  _buildMetricCard(
                    'This Month',
                    'R${insights.revenueThisMonth.toStringAsFixed(0)}',
                    Icons.calendar_month,
                    Colors.purple,
                    context: context,
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
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, {required BuildContext context}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 600;
    
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
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(iconContainerPadding),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(borderRadius * 0.8),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
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
              color: Colors.white.withValues(alpha: 0.8),
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
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load financial insights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
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
