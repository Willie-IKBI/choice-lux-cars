import 'package:flutter/material.dart';

class ActiveJobsSummary extends StatelessWidget {
  final Map<String, dynamic> summary;

  const ActiveJobsSummary({
    Key? key,
    required this.summary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalActiveJobs = summary['total_active_jobs'] ?? 0;
    final veryRecentJobs = summary['very_recent_jobs'] ?? 0;
    final recentJobs = summary['recent_jobs'] ?? 0;
    final staleJobs = summary['stale_jobs'] ?? 0;
    final activeDrivers = summary['active_drivers'] ?? 0;
    final totalDrivers = summary['total_drivers'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dashboard, color: Colors.blue[700], size: 24),
                const SizedBox(width: 8),
                Text(
                  'System Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Jobs Overview
            Row(
              children: [
                Expanded(
                  child: _buildOverviewCard(
                    'Active Jobs',
                    totalActiveJobs.toString(),
                    Icons.work,
                    Colors.blue,
                    [
                      _buildStatusRow('Very Recent', veryRecentJobs, Colors.green),
                      _buildStatusRow('Recent', recentJobs, Colors.orange),
                      _buildStatusRow('Stale', staleJobs, Colors.red),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildOverviewCard(
                    'Driver Status',
                    '$activeDrivers/$totalDrivers',
                    Icons.people,
                    Colors.green,
                    [
                      _buildStatusRow('Active', activeDrivers, Colors.green),
                      _buildStatusRow('Recent', summary['recent_drivers'] ?? 0, Colors.blue),
                      _buildStatusRow('Inactive', summary['inactive_drivers'] ?? 0, Colors.grey),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // System Health Indicator
            _buildSystemHealthIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(
    String title,
    String mainValue,
    IconData icon,
    Color color,
    List<Widget> statusRows,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            mainValue,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          ...statusRows,
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemHealthIndicator() {
    final totalActiveJobs = summary['total_active_jobs'] ?? 0;
    final staleJobs = summary['stale_jobs'] ?? 0;
    final totalDrivers = summary['total_drivers'] ?? 0;
    final activeDrivers = summary['active_drivers'] ?? 0;

    // Calculate system health score (0-100)
    double healthScore = 100.0;
    
    // Deduct points for stale jobs
    if (totalActiveJobs > 0) {
      healthScore -= (staleJobs / totalActiveJobs) * 30;
    }
    
    // Deduct points for inactive drivers
    if (totalDrivers > 0) {
      final inactiveRatio = (totalDrivers - activeDrivers) / totalDrivers;
      healthScore -= inactiveRatio * 20;
    }

    healthScore = healthScore.clamp(0.0, 100.0);
    
    Color healthColor;
    String healthStatus;
    IconData healthIcon;
    
    if (healthScore >= 80) {
      healthColor = Colors.green;
      healthStatus = 'Excellent';
      healthIcon = Icons.check_circle;
    } else if (healthScore >= 60) {
      healthColor = Colors.blue;
      healthStatus = 'Good';
      healthIcon = Icons.info;
    } else if (healthScore >= 40) {
      healthColor = Colors.orange;
      healthStatus = 'Fair';
      healthIcon = Icons.warning;
    } else {
      healthColor = Colors.red;
      healthStatus = 'Poor';
      healthIcon = Icons.error;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: healthColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: healthColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(healthIcon, color: healthColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Health',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: healthColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  healthStatus,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: healthColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${healthScore.round()}%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: healthColor,
                ),
              ),
              Text(
                'Health Score',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
