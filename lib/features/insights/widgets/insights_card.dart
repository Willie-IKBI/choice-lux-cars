import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/insights/models/insights_data.dart';
import 'package:choice_lux_cars/features/insights/providers/insights_provider.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

/// Insights card widget for administrators
class InsightsCard extends ConsumerWidget {
  final TimePeriod selectedPeriod;
  final LocationFilter selectedLocation;

  const InsightsCard({
    super.key,
    required this.selectedPeriod,
    required this.selectedLocation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('InsightsCard - Building with period: ${selectedPeriod.displayName}, location: ${selectedLocation.displayName}');
    
    // Use the new notifier provider
    final insightsState = ref.watch(insightsWithFiltersNotifierProvider);
    final insightsNotifier = ref.read(insightsWithFiltersNotifierProvider.notifier);
    
    // Trigger fetch when filters change
    ref.listen(insightsWithFiltersNotifierProvider, (previous, next) {
      if (previous?.data != next.data) {
        print('InsightsCard - State changed: loading=${next.isLoading}, hasData=${next.data != null}, error=${next.error}');
      }
    });
    
    // Fetch data when widget builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      insightsNotifier.fetchInsights(
        period: selectedPeriod,
        location: selectedLocation,
      );
    });
    
    print('InsightsCard - State: loading=${insightsState.isLoading}, hasData=${insightsState.data != null}, error=${insightsState.error}');
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1a1a1a),
            Color(0xFF2d2d2d),
          ],
        ),
        border: Border.all(color: ChoiceLuxTheme.richGold.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with period selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      color: ChoiceLuxTheme.richGold,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Insights',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    '${selectedPeriod.displayName} • ${selectedLocation.displayName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Content
            if (insightsState.isLoading)
              _buildLoadingState()
            else if (insightsState.error != null)
              _buildErrorState(insightsState.error!)
            else if (insightsState.data != null)
              _buildInsightsContent(insightsState.data!)
            else
              _buildLoadingState(),
          ],
        ),
      ),
    );
  }


  Widget _buildInsightsContent(InsightsData insights) {
    try {
      print('Building insights content with data: ${insights.jobInsights.totalJobs} jobs, ${insights.quoteInsights.totalQuotes} quotes');
      print('Insights data validation: jobs=${insights.jobInsights.totalJobs}, quotes=${insights.quoteInsights.totalQuotes}');
      
      // Validate insights data
      if (insights.jobInsights.totalJobs < 0 || insights.quoteInsights.totalQuotes < 0) {
        print('Invalid insights data: negative values detected');
        return _buildErrorState('Invalid data: negative values detected');
      }
      
      print('Building insights content sections...');
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Key Performance Indicators Section
            _buildSectionHeader('Key Performance Indicators', Icons.dashboard_outlined),
            const SizedBox(height: 16),
            _buildKeyMetricsGrid(insights),
            const SizedBox(height: 24),
            
            // Jobs Overview Section
            _buildSectionHeader('Jobs Overview', Icons.work_outline),
            const SizedBox(height: 16),
            _buildJobsOverviewCard(insights),
            const SizedBox(height: 24),
            
            // Performance Section
            _buildSectionHeader('Performance', Icons.trending_up),
            const SizedBox(height: 16),
            _buildPerformanceCards(insights),
            const SizedBox(height: 24),
            
            // Financial Summary Section
            _buildSectionHeader('Financial Summary', Icons.attach_money),
            const SizedBox(height: 16),
            _buildFinancialSummaryCard(insights),
            const SizedBox(height: 24),
            
            // Client Revenue Section
            _buildSectionHeader('Client Revenue', Icons.business),
            const SizedBox(height: 16),
            _buildClientRevenueCard(insights),
          ],
        ),
      );
    } catch (e, stackTrace) {
      Log.e('Error building insights content: $e');
      Log.e('Stack trace: $stackTrace');
      return _buildErrorState('Error displaying insights: $e');
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: ChoiceLuxTheme.richGold,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildKeyMetricsGrid(InsightsData insights) {
    return Column(
      children: [
        // First row - 2x2 grid
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Jobs',
                insights.jobInsights.totalJobs.toString(),
                Icons.work_outline,
                ChoiceLuxTheme.richGold,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Total Quotes',
                insights.quoteInsights.totalQuotes.toString(),
                Icons.description_outlined,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Second row - 2x2 grid
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Revenue',
                'R${insights.financialInsights.totalRevenue.toStringAsFixed(0)}',
                Icons.attach_money,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Completion Rate',
                '${insights.jobInsights.completionRate.toStringAsFixed(1)}%',
                Icons.check_circle_outline,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      height: 140, // Fixed height for consistency - increased to prevent overflow
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildJobsOverviewCard(InsightsData insights) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.work_outline, color: ChoiceLuxTheme.richGold, size: 20),
              SizedBox(width: 8),
              Text(
                'Job Status Breakdown',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildJobStatusCard('Open', insights.jobInsights.openJobs, Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildJobStatusCard('In Progress', insights.jobInsights.inProgressJobs, Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildJobStatusCard('Completed', insights.jobInsights.completedJobs, Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildJobStatusCard('Cancelled', insights.jobInsights.cancelledJobs, Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatRow('Average Jobs per Week', insights.jobInsights.averageJobsPerWeek.toStringAsFixed(1)),
        ],
      ),
    );
  }

  Widget _buildJobStatusCard(String status, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCards(InsightsData insights) {
    return Row(
      children: [
        Expanded(
          child: _buildTopPerformersCard(
            'Top Drivers',
            Icons.person_outline,
            insights.driverInsights.topDrivers.take(3).map((driver) => 
              '${driver.driverName}: ${driver.jobCount} jobs'
            ).toList(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTopPerformersCard(
            'Top Vehicles',
            Icons.directions_car_outlined,
            insights.vehicleInsights.topVehicles.take(3).map((vehicle) => 
              '${vehicle.vehicleName}: ${vehicle.jobCount} jobs'
            ).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialSummaryCard(InsightsData insights) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.attach_money, color: ChoiceLuxTheme.richGold, size: 20),
              SizedBox(width: 8),
              Text(
                'Financial Performance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatRow('This Week', 'R${insights.financialInsights.revenueThisWeek.toStringAsFixed(0)}'),
          _buildStatRow('This Month', 'R${insights.financialInsights.revenueThisMonth.toStringAsFixed(0)}'),
          _buildStatRow('Average Job Value', 'R${insights.financialInsights.averageJobValue.toStringAsFixed(0)}'),
          _buildStatRow('Revenue Growth', '${insights.financialInsights.revenueGrowth.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }


  Widget _buildTopPerformersCard(String title, IconData icon, List<String> performers) {
    return Container(
      height: 200, // Fixed height for consistency
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: ChoiceLuxTheme.richGold, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: performers.isEmpty 
              ? Center(
                  child: Text(
                    'No data available',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: performers.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        performers[index],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(ChoiceLuxTheme.richGold),
            ),
            SizedBox(height: 16),
            Text(
              'Loading insights...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    print('Insights error: $error');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.withValues(alpha: 0.7),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load insights',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Error: $error',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Refresh the data - this will be handled by the parent widget
                // The insightsAsync will automatically refresh when the provider is invalidated
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildClientRevenueCard(InsightsData insights) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.business,
                color: ChoiceLuxTheme.richGold,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Top Clients by Revenue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (insights.clientRevenueInsights.topClients.isEmpty)
            Center(
              child: Text(
                'No client revenue data available',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            )
          else
            Column(
              children: [
                // Summary stats
                Row(
                  children: [
                    Expanded(
                      child: _buildRevenueStatCard(
                        'Total Revenue',
                        'R${insights.clientRevenueInsights.totalRevenue.toStringAsFixed(0)}',
                        Icons.attach_money,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildRevenueStatCard(
                        'Avg per Client',
                        'R${insights.clientRevenueInsights.averageRevenuePerClient.toStringAsFixed(0)}',
                        Icons.trending_up,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Top clients list
                ...insights.clientRevenueInsights.topClients.take(5).map((client) => 
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
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
                              Text(
                                '${client.jobCount} jobs • R${client.averageJobValue.toStringAsFixed(0)} avg',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'R${client.totalRevenue.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: ChoiceLuxTheme.richGold,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRevenueStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
