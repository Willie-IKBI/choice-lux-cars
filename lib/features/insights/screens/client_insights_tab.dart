import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/features/insights/models/insights_data.dart';
import 'package:choice_lux_cars/features/insights/providers/client_insights_provider.dart';
import 'package:choice_lux_cars/features/insights/screens/client_statement_screen.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/widgets/insights_metric_card.dart';
import 'package:choice_lux_cars/shared/widgets/section_header.dart';
import 'package:choice_lux_cars/shared/widgets/common_states.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';
import 'package:choice_lux_cars/shared/utils/snackbar_utils.dart';
import 'package:choice_lux_cars/core/utils.dart';

class ClientInsightsTab extends ConsumerWidget {
  final TimePeriod selectedPeriod;
  final LocationFilter selectedLocation;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const ClientInsightsTab({
    super.key,
    required this.selectedPeriod,
    required this.selectedLocation,
    this.customStartDate,
    this.customEndDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerKey = (selectedPeriod, selectedLocation, customStartDate, customEndDate);
    final clientInsightsAsync = ref.watch(clientInsightsProvider(providerKey));

    return Container(
      padding: const EdgeInsets.all(16),
      child: clientInsightsAsync.when(
        data: (insights) => _buildClientContent(context, insights),
        loading: () => const LoadingStateWidget(message: 'Loading client insights...'),
        error: (error, stack) => ErrorStateWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(clientInsightsProvider(providerKey)),
        ),
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
          SectionHeader(title: 'Client Overview'),
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
                  InsightsMetricCard(
                    label: 'Total Clients',
                    value: insights.totalClients.toString(),
                    icon: Icons.business_outlined,
                    iconColor: ChoiceLuxTheme.richGold,
                    progressValue: 1.0,
                    helpText: 'Total number of clients in the selected period and location.',
                    onTap: () => context.go('/clients'),
                  ),
                  InsightsMetricCard(
                    label: 'Active Clients',
                    value: insights.activeClients.toString(),
                    icon: Icons.business,
                    iconColor: Colors.green,
                    progressValue: insights.totalClients > 0 ? insights.activeClients / insights.totalClients : 0.0,
                    helpText: 'Clients who had at least one job in the period. Indicates engaged client base.',
                  ),
                  InsightsMetricCard(
                    label: 'Avg Jobs/Client',
                    value: insights.averageJobsPerClient.toStringAsFixed(1),
                    icon: Icons.work_outline,
                    iconColor: Colors.blue,
                    progressValue: 1.0,
                    helpText: 'Average number of jobs per active client. Measures client usage and loyalty.',
                  ),
                  InsightsMetricCard(
                    label: 'Avg Revenue/Client',
                    value: CurrencyUtils.formatCompact(insights.averageRevenuePerClient),
                    icon: Icons.attach_money,
                    iconColor: Colors.orange,
                    progressValue: 1.0,
                    helpText: 'Average revenue generated per active client in the period. Client value indicator.',
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
              return Row(
                children: [
                  Expanded(
                    child: InsightsMetricCard(
                      label: 'Client Retention Rate',
                      value: '${insights.clientRetentionRate.toStringAsFixed(1)}%',
                      icon: Icons.repeat,
                      iconColor: Colors.green,
                      progressValue: insights.clientRetentionRate / 100,
                      helpText: 'Percentage of clients who had jobs in both the current and previous period. Measures client loyalty and repeat business.',
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Sprint 1: Top Clients by Revenue
          if (insights.topClientsByRevenue.isNotEmpty) ...[
            SectionHeader(title: 'Top Clients by Revenue'),
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
                    const SizedBox(width: 8),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              CurrencyUtils.formatCompact(client.totalValue),
                              style: TextStyle(
                                color: ChoiceLuxTheme.richGold,
                                fontWeight: FontWeight.bold,
                              ),
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

}
