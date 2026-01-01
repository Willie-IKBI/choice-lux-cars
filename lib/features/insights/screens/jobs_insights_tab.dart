import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/features/insights/models/insights_data.dart';
import 'package:choice_lux_cars/features/insights/providers/jobs_insights_provider.dart';
import 'package:choice_lux_cars/app/theme.dart';

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
    final jobsInsightsAsync = ref.watch(jobsInsightsProvider((
      selectedPeriod,
      selectedLocation,
      customStartDate,
      customEndDate,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 600;
    final bottomPadding = isDesktop ? 24.0 : 16.0;
    
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
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
                  Icons.work_outline,
                  color: ChoiceLuxTheme.richGold,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jobs Analytics',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${insights.totalJobs} total jobs • ${insights.completedJobs} completed',
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
          _buildSectionHeader('Key Metrics'),
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
                    'Total Jobs',
                    insights.totalJobs.toString(),
                    Icons.work_outline,
                    ChoiceLuxTheme.richGold,
                    status: 'all',
                    context: context,
                  ),
                  _buildMetricCard(
                    'Completed',
                    insights.completedJobs.toString(),
                    Icons.check_circle_outline,
                    Colors.green,
                    status: 'completed',
                    context: context,
                  ),
                  _buildMetricCard(
                    'Open Jobs',
                    insights.openJobs.toString(),
                    Icons.pending_outlined,
                    Colors.orange,
                    status: 'open',
                    context: context,
                  ),
                  _buildMetricCard(
                    'Completion Rate',
                    '${(insights.completionRate * 100).toStringAsFixed(1)}%',
                    Icons.trending_up,
                    Colors.blue,
                    context: context,
                  ),
                ],
              );
              
              // Center the grid on desktop with max width constraint
              Widget mainGridView;
              if (isDesktop) {
                // Calculate max width: for 4 columns, cap at ~800px; for 2 columns, cap at ~600px
                final maxWidth = isLargeDesktop ? 800.0 : 600.0;
                mainGridView = Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: gridView,
                  ),
                );
              } else {
                mainGridView = gridView;
              }
              
              // Add completed jobs metrics if there are completed jobs
              if (insights.completedJobs > 0) {
                final completedCrossAxisCount = isLargeDesktop ? 2 : 1;
                final completedChildAspectRatio = isDesktop ? 2.0 : 1.5;
                final completedSpacing = isDesktop ? 12.0 : 16.0;
                
                final completedMetricsGrid = GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: completedCrossAxisCount,
                  childAspectRatio: completedChildAspectRatio,
                  crossAxisSpacing: completedSpacing,
                  mainAxisSpacing: completedSpacing,
                  children: [
                    _buildMetricCard(
                      'Avg Km per Job',
                      '${insights.averageKmPerCompletedJob.toStringAsFixed(1)} km',
                      Icons.straighten,
                      Colors.teal,
                      context: context,
                      onTap: () {
                        final uri = Uri(
                          path: '/insights/completed-jobs-details',
                          queryParameters: {
                            'timePeriod': selectedPeriod.toString().split('.').last,
                            'location': selectedLocation.toString().split('.').last,
                            'metricType': 'km',
                          },
                        );
                        context.go(uri.toString());
                      },
                    ),
                    _buildMetricCard(
                      'Avg Time per Job',
                      _formatDuration(insights.averageTimePerCompletedJob),
                      Icons.access_time,
                      Colors.purple,
                      context: context,
                      onTap: () {
                        final uri = Uri(
                          path: '/insights/completed-jobs-details',
                          queryParameters: {
                            'timePeriod': selectedPeriod.toString().split('.').last,
                            'location': selectedLocation.toString().split('.').last,
                            'metricType': 'time',
                          },
                        );
                        context.go(uri.toString());
                      },
                    ),
                  ],
                );
                
                Widget completedGridView = completedMetricsGrid;
                if (isDesktop) {
                  final maxWidth = isLargeDesktop ? 600.0 : 400.0;
                  completedGridView = Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: completedMetricsGrid,
                    ),
                  );
                }
                
                return Column(
                  children: [
                    mainGridView,
                    SizedBox(height: isDesktop ? 24.0 : 32.0),
                    _buildSectionHeader('Completed Jobs Metrics'),
                    SizedBox(height: isDesktop ? 16.0 : 20.0),
                    completedGridView,
                  ],
                );
              }
              
              return mainGridView;
            },
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isDesktop = screenWidth >= 600;
              final topSpacing = isDesktop ? 24.0 : 32.0; // More spacing on mobile
              final headerSpacing = isDesktop ? 16.0 : 26.0; // More spacing after header on mobile
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: topSpacing),
                  // Job Status Breakdown
                  _buildSectionHeader('Job Status Breakdown'),
                  SizedBox(height: headerSpacing),
                  _buildJobStatusCard(insights),
                ],
              );
            },
          ),
          ],
        ),
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

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? status,
    required BuildContext context,
    VoidCallback? onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 600;
    
    // Smaller, more compact cards for desktop
    final iconSize = isDesktop ? 20.0 : 32.0;
    final iconContainerPadding = isDesktop ? 6.0 : 12.0;
    final cardPadding = isDesktop 
        ? const EdgeInsets.all(6.0) 
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 20); // More vertical padding on mobile
    final valueFontSize = isDesktop ? 16.0 : 24.0;
    final titleFontSize = isDesktop ? 12.0 : 14.0;
    final titleSpacing = isDesktop ? 4.0 : 15.0; // Increased spacing on mobile
    final valueSpacing = isDesktop ? 3.0 : 12.0; // Increased spacing between icon and value on mobile
    final borderRadius = isDesktop ? 16.0 : 12.0;
    
    return GestureDetector(
      onTap: onTap ?? (status != null
          ? () {
              // Navigate to filtered jobs list
              final uri = Uri(
                path: '/insights/jobs',
                queryParameters: {
                  'timePeriod': selectedPeriod.toString().split('.').last,
                  'location': selectedLocation.toString().split('.').last,
                  'status': status,
                },
              );
              context.go(uri.toString());
            }
          : null),
      child: MouseRegion(
        cursor: (status != null || onTap != null) ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Container(
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
        ),
      ),
    );
  }

  Widget _buildJobStatusCard(JobInsights insights) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktop = screenWidth >= 600;
        
        // Responsive padding: smaller on mobile, larger on desktop
        final cardPadding = isDesktop 
            ? const EdgeInsets.all(20) 
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 16);
        final iconSize = isDesktop ? 24.0 : 20.0;
        final titleFontSize = isDesktop ? 18.0 : 16.0;
        final spacingBetweenItems = isDesktop ? 16.0 : 12.0;
        final headerSpacing = isDesktop ? 20.0 : 16.0;
        
        return Container(
          padding: cardPadding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.pie_chart_outline,
                    color: ChoiceLuxTheme.richGold,
                    size: iconSize,
                  ),
                  SizedBox(width: isDesktop ? 12 : 8),
                  Text(
                    'Job Distribution',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: headerSpacing),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusItem(
                      'Completed',
                      insights.completedJobs,
                      insights.totalJobs,
                      Colors.green,
                      isDesktop: isDesktop,
                    ),
                  ),
                  SizedBox(width: spacingBetweenItems),
                  Expanded(
                    child: _buildStatusItem(
                      'Open',
                      insights.openJobs,
                      insights.totalJobs,
                      Colors.orange,
                      isDesktop: isDesktop,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusItem(String label, int count, int total, Color color, {bool isDesktop = false}) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;
    
    // Responsive padding and font sizes
    final itemPadding = isDesktop 
        ? const EdgeInsets.all(16) 
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 12);
    final countFontSize = isDesktop ? 24.0 : 20.0;
    final labelFontSize = isDesktop ? 14.0 : 13.0;
    final percentageFontSize = isDesktop ? 12.0 : 11.0;
    final spacing = isDesktop ? 4.0 : 3.0;
    
    return Container(
      padding: itemPadding,
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
              fontSize: countFontSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: spacing),
          Text(
            label,
            style: TextStyle(
              fontSize: labelFontSize,
              color: Colors.white,
            ),
          ),
          SizedBox(height: spacing),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: percentageFontSize,
              color: Colors.white.withValues(alpha: 0.8),
            ),
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
            'Loading jobs insights...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _formatDuration(double hours) {
    if (hours < 0) return '0 min';
    
    final totalMinutes = (hours * 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    
    if (h > 0 && m > 0) {
      return '$h ${h == 1 ? 'hr' : 'hrs'} ${m}min';
    } else if (h > 0) {
      return '$h ${h == 1 ? 'hour' : 'hours'}';
    } else if (m > 0) {
      return '$m min';
    } else {
      return '< 1 min';
    }
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
            'Failed to load jobs insights',
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
