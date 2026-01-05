import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/features/insights/models/insights_data.dart';
import 'package:choice_lux_cars/features/insights/providers/client_insights_provider.dart';
import 'package:choice_lux_cars/features/insights/screens/client_statement_screen.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';

class ClientInsightsTab extends ConsumerWidget {
  final TimePeriod selectedPeriod;
  final LocationFilter selectedLocation;

  const ClientInsightsTab({
    super.key,
    required this.selectedPeriod,
    required this.selectedLocation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientInsightsAsync = ref.watch(clientInsightsProvider((
      selectedPeriod,
      selectedLocation,
    )));

    return Container(
      padding: const EdgeInsets.all(16),
      child: clientInsightsAsync.when(
        data: (insights) => _buildClientContent(context, insights),
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildClientContent(BuildContext context, ClientInsights insights) {
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
                            'Client Analytics',
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
                  '${insights.totalClients} clients • ${insights.activeClients} active',
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
          _buildSectionHeader('Client Overview'),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isLargeDesktop = ResponsiveBreakpoints.isLargeDesktop(screenWidth);
              final isDesktop = ResponsiveBreakpoints.isDesktop(screenWidth);
              final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
              final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(screenWidth);
              final spacing = ResponsiveTokens.getSpacing(screenWidth);
              
              // 4 columns on large desktop (all cards in one row), 2 columns on medium desktop/tablet
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
                    label: 'Total Clients',
                    value: insights.totalClients.toString(),
                    icon: Icons.business_outlined,
                    iconColor: ChoiceLuxTheme.richGold,
                    progressValue: 1.0,
                  ),
                  _buildNewMetricCard(
                    context: context,
                    label: 'Active Clients',
                    value: insights.activeClients.toString(),
                    icon: Icons.business,
                    iconColor: Colors.green,
                    progressValue: insights.totalClients > 0 ? insights.activeClients / insights.totalClients : 0.0,
                  ),
                  _buildNewMetricCard(
                    context: context,
                    label: 'Avg Jobs/Client',
                    value: insights.averageJobsPerClient.toStringAsFixed(1),
                    icon: Icons.work_outline,
                    iconColor: Colors.blue,
                    progressValue: 1.0,
                  ),
                  _buildNewMetricCard(
                    context: context,
                    label: 'Avg Revenue/Client',
                    value: 'R${insights.averageRevenuePerClient.toStringAsFixed(0)}',
                    icon: Icons.attach_money,
                    iconColor: Colors.orange,
                    progressValue: 1.0,
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

          // Client Retention Rate
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final spacing = ResponsiveTokens.getSpacing(screenWidth);
              
              return Row(
                children: [
                  Expanded(
                    child: _buildNewMetricCard(
                      context: context,
                      label: 'Client Retention Rate',
                      value: '${insights.clientRetentionRate.toStringAsFixed(1)}%',
                      icon: Icons.repeat,
                      iconColor: Colors.green,
                      progressValue: insights.clientRetentionRate / 100,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Sprint 1: Top Clients by Revenue
          if (insights.topClientsByRevenue.isNotEmpty) ...[
            _buildSectionHeader('Top Clients by Revenue'),
            const SizedBox(height: 16),
            _buildTopClientsCard(context, insights.topClientsByRevenue),
          ],
        ],
      ),
    );
  }

  Widget _buildTopClientsCard(BuildContext context, List<TopClient> topClients) {
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
                'Top Clients',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ChoiceLuxTheme.softWhite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topClients.take(5).map((client) => InkWell(
            onTap: () {
              // Navigate to client statement screen
              context.push(
                '/insights/client-statement',
                extra: {
                  'clientId': client.clientId,
                  'clientName': client.clientName,
                },
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
                        client.clientName.isNotEmpty ? client.clientName[0].toUpperCase() : 'C',
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
                            client.clientName.isNotEmpty ? client.clientName : 'Unknown Client',
                            style: TextStyle(
                              color: ChoiceLuxTheme.softWhite,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${client.jobCount} jobs',
                            style: TextStyle(
                              color: ChoiceLuxTheme.platinumSilver,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'R${client.totalValue.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: ChoiceLuxTheme.richGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: ChoiceLuxTheme.platinumSilver,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )),
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
            'Loading client insights...',
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
            'Failed to load client insights',
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
