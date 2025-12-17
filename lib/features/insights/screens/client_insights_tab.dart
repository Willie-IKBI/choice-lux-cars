import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/insights/models/insights_data.dart';
import 'package:choice_lux_cars/features/insights/providers/client_insights_provider.dart';
import 'package:choice_lux_cars/app/theme.dart';

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
    final clientInsightsAsync = ref.watch(clientInsightsProvider((
      selectedPeriod,
      selectedLocation,
      customStartDate,
      customEndDate,
    )));

    return Container(
      padding: const EdgeInsets.all(16),
      child: clientInsightsAsync.when(
        data: (insights) => _buildClientContent(insights),
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildClientContent(ClientInsights insights) {
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
              border: Border.all(color: ChoiceLuxTheme.richGold.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.business_outlined,
                  color: ChoiceLuxTheme.richGold,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Client Analytics',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${insights.totalClients} clients • ${insights.activeClients} active • ${insights.vipClients} VIP',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Client Overview Metrics
          _buildSectionHeader('Client Overview'),
          const SizedBox(height: 16),
          _buildOverviewMetrics(insights),

          const SizedBox(height: 32),

          // Client Status Breakdown
          if (insights.clientsByStatus.isNotEmpty) ...[
            _buildSectionHeader('Client Status Breakdown'),
            const SizedBox(height: 16),
            _buildStatusBreakdown(insights),
            const SizedBox(height: 32),
          ],

          // Client Value Metrics
          _buildSectionHeader('Client Value Metrics'),
          const SizedBox(height: 16),
          _buildValueMetrics(insights),

          const SizedBox(height: 32),

          // Quote Conversion
          if (insights.quoteToJobConversionRate > 0) ...[
            _buildSectionHeader('Quote Conversion'),
            const SizedBox(height: 16),
            Builder(
              builder: (context) => _buildQuoteConversion(insights, context),
            ),
            const SizedBox(height: 32),
          ],

          // Top Clients by Different Metrics
          if (insights.topClients.isNotEmpty) ...[
            _buildSectionHeader('Top Clients by Total Value'),
            const SizedBox(height: 16),
            _buildTopClientsList(insights.topClients, 'Total Value'),
            const SizedBox(height: 32),
          ],

          if (insights.topClientsByJobs.isNotEmpty) ...[
            _buildSectionHeader('Top Clients by Job Count'),
            const SizedBox(height: 16),
            _buildTopClientsList(insights.topClientsByJobs, 'Jobs'),
            const SizedBox(height: 32),
          ],

          if (insights.topClientsByRevenue.isNotEmpty) ...[
            _buildSectionHeader('Top Clients by Revenue'),
            const SizedBox(height: 16),
            _buildTopClientsList(insights.topClientsByRevenue, 'Revenue'),
            const SizedBox(height: 32),
          ],

          if (insights.topClientsByQuotes.isNotEmpty) ...[
            _buildSectionHeader('Top Clients by Quote Value'),
            const SizedBox(height: 16),
            _buildTopClientsList(insights.topClientsByQuotes, 'Quotes'),
            const SizedBox(height: 32),
          ],

          // Client Engagement
          if (insights.atRiskClientsList.isNotEmpty || insights.newClientsList.isNotEmpty) ...[
            _buildSectionHeader('Client Engagement'),
            const SizedBox(height: 16),
            if (insights.atRiskClientsList.isNotEmpty) ...[
              _buildAtRiskClients(insights.atRiskClientsList),
              const SizedBox(height: 16),
            ],
            if (insights.newClientsList.isNotEmpty) ...[
              _buildNewClients(insights.newClientsList),
              const SizedBox(height: 32),
            ],
          ],

          // Agent Performance
          if (insights.topAgents.isNotEmpty) ...[
            _buildSectionHeader('Top Agents by Client Value'),
            const SizedBox(height: 16),
            _buildTopAgentsList(insights.topAgents),
            const SizedBox(height: 32),
          ],

          // Client Tier Comparison
          if (insights.clientsByTier.isNotEmpty) ...[
            _buildSectionHeader('Client Tier Comparison'),
            const SizedBox(height: 16),
            _buildTierComparison(insights),
            const SizedBox(height: 32),
          ],

          // Job Status Breakdown
          if (insights.jobsByStatus.isNotEmpty) ...[
            _buildSectionHeader('Job Status Breakdown'),
            const SizedBox(height: 16),
            _buildJobStatusBreakdown(insights.jobsByStatus),
            const SizedBox(height: 32),
          ],

          // Quote Status Breakdown
          if (insights.quotesByStatus.isNotEmpty) ...[
            _buildSectionHeader('Quote Status Breakdown'),
            const SizedBox(height: 16),
            _buildQuoteStatusBreakdown(insights.quotesByStatus),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewMetrics(ClientInsights insights) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isLargeDesktop = screenWidth >= 1200;
        final isDesktop = screenWidth >= 600;
        
        final crossAxisCount = isLargeDesktop ? 5 : (isDesktop ? 3 : 2);
        final childAspectRatio = isDesktop ? 1.0 : 1.5;
        final spacing = isDesktop ? 12.0 : 16.0;
        
        final gridView = GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          children: [
            _buildMetricCard(
              'Total Clients',
              insights.totalClients.toString(),
              Icons.business_outlined,
              ChoiceLuxTheme.richGold,
              context: context,
            ),
            _buildMetricCard(
              'Active Clients',
              insights.activeClients.toString(),
              Icons.business,
              Colors.green,
              context: context,
            ),
            _buildMetricCard(
              'VIP Clients',
              insights.vipClients.toString(),
              Icons.star,
              Colors.amber,
              context: context,
            ),
            _buildMetricCard(
              'New Clients',
              insights.newClients.toString(),
              Icons.person_add,
              Colors.blue,
              context: context,
            ),
            _buildMetricCard(
              'At-Risk Clients',
              insights.atRiskClients.toString(),
              Icons.warning,
              Colors.orange,
              context: context,
            ),
          ],
        );
        
        if (isDesktop) {
          final maxWidth = isLargeDesktop ? 1000.0 : 700.0;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: gridView,
            ),
          );
        }
        
        return gridView;
      },
    );
  }

  Widget _buildStatusBreakdown(ClientInsights insights) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: insights.clientsByStatus.entries.map((entry) {
          final status = entry.key;
          final count = entry.value;
          final revenue = insights.revenueByStatus[status] ?? 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '$count clients',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'R${revenue.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildValueMetrics(ClientInsights insights) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isLargeDesktop = screenWidth >= 1200;
        final isDesktop = screenWidth >= 600;
        
        final crossAxisCount = isLargeDesktop ? 4 : (isDesktop ? 2 : 1);
        final childAspectRatio = isDesktop ? 1.0 : 1.5;
        final spacing = isDesktop ? 12.0 : 16.0;
        
        final gridView = GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          children: [
            _buildMetricCard(
              'Avg Jobs/Client',
              insights.averageJobsPerClient.toStringAsFixed(1),
              Icons.work_outline,
              Colors.blue,
              context: context,
            ),
            _buildMetricCard(
              'Avg Revenue/Client',
              'R${insights.averageRevenuePerClient.toStringAsFixed(0)}',
              Icons.attach_money,
              Colors.orange,
              context: context,
            ),
            _buildMetricCard(
              'Avg Job Value',
              'R${insights.averageJobValuePerClient.toStringAsFixed(0)}',
              Icons.receipt,
              Colors.green,
              context: context,
            ),
            _buildMetricCard(
              'Avg Quote Value',
              'R${insights.averageQuoteValuePerClient.toStringAsFixed(0)}',
              Icons.description,
              Colors.purple,
              context: context,
            ),
            if (insights.averageQuotesPerClient > 0)
              _buildMetricCard(
                'Avg Quotes/Client',
                insights.averageQuotesPerClient.toStringAsFixed(1),
                Icons.description_outlined,
                Colors.teal,
                context: context,
              ),
            if (insights.averageAgentsPerClient > 0)
              _buildMetricCard(
                'Avg Agents/Client',
                insights.averageAgentsPerClient.toStringAsFixed(1),
                Icons.people,
                Colors.indigo,
                context: context,
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
    );
  }

  Widget _buildQuoteConversion(ClientInsights insights, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildMetricCard(
            'Quote-to-Job Conversion Rate',
            '${insights.quoteToJobConversionRate.toStringAsFixed(1)}%',
            Icons.trending_up,
            Colors.green,
            context: context,
          ),
        ],
      ),
    );
  }

  Widget _buildTopClientsList(List<TopClient> clients, String metricType) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: clients.length,
        itemBuilder: (context, index) {
          final client = clients[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: index < clients.length - 1
                  ? Border(
                      bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ChoiceLuxTheme.richGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: ChoiceLuxTheme.richGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.clientName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (client.clientStatus != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          client.clientStatus!.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(client.clientStatus!),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatChip('Jobs: ${client.jobCount}', Colors.blue),
                          const SizedBox(width: 8),
                          _buildStatChip('Quotes: ${client.quoteCount}', Colors.purple),
                          if (client.agentCount != null) ...[
                            const SizedBox(width: 8),
                            _buildStatChip('Agents: ${client.agentCount}', Colors.indigo),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'R${_getMetricValue(client, metricType).toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (client.conversionRate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${client.conversionRate!.toStringAsFixed(1)}% conv.',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAtRiskClients(List<AtRiskClient> clients) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              const Text(
                'At-Risk Clients (No activity in 30+ days)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...clients.take(5).map((client) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client.clientName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${client.daysSinceLastActivity} days since last activity',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'R${client.lifetimeValue.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildNewClients(List<NewClient> clients) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_add, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'New Clients (First activity in period)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...clients.take(5).map((client) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client.clientName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${client.jobCount} jobs • ${client.quoteCount} quotes',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'R${client.revenue.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTopAgentsList(List<TopAgent> agents) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: agents.length,
        itemBuilder: (context, index) {
          final agent = agents[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: index < agents.length - 1
                  ? Border(
                      bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(Icons.person, color: Colors.indigo, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agent.agentName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        agent.clientName,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'R${agent.totalValue.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${agent.jobCount} jobs • ${agent.quoteCount} quotes',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTierComparison(ClientInsights insights) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'VIP Clients',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${insights.clientsByTier['VIP'] ?? 0}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'R${(insights.revenueByTier['VIP'] ?? 0.0).toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.white.withOpacity(0.2),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Regular Clients',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${insights.clientsByTier['Regular'] ?? 0}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'R${(insights.revenueByTier['Regular'] ?? 0.0).toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobStatusBreakdown(Map<String, int> jobsByStatus) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: jobsByStatus.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key.toUpperCase().replaceAll('_', ' '),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                Text(
                  entry.value.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuoteStatusBreakdown(Map<String, int> quotesByStatus) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: quotesByStatus.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                Text(
                  entry.value.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  double _getMetricValue(TopClient client, String metricType) {
    switch (metricType) {
      case 'Total Value':
        return client.totalValue;
      case 'Jobs':
        return client.jobCount.toDouble();
      case 'Revenue':
        return client.jobRevenue;
      case 'Quotes':
        return client.quoteValue;
      default:
        return client.totalValue;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'vip':
        return Colors.amber;
      case 'pending':
        return Colors.orange;
      case 'inactive':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
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
