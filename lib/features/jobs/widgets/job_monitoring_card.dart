import 'package:flutter/material.dart';

class JobMonitoringCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback? onTap;

  const JobMonitoringCard({super.key, required this.job, this.onTap});

  @override
  Widget build(BuildContext context) {
    final driverName = job['driver_name'] ?? 'Unknown Driver';
    final driverPhone = job['driver_phone'] ?? 'N/A';
    final currentStep = job['current_step'] ?? 'Unknown';
    final progressPercentage = job['progress_percentage'] ?? 0;
    final lastActivity = job['last_activity_at'];
    final activityRecency = job['activity_recency'] ?? 'unknown';
    final estimatedCompletion = job['estimated_completion'];

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with driver info and status
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getStatusColor(activityRecency),
                    child: Icon(
                      _getStatusIcon(activityRecency),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driverName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          driverPhone,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(activityRecency),
                ],
              ),

              const SizedBox(height: 16),

              // Progress section
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Step',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatStepName(currentStep),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Progress',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$progressPercentage%',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: _getProgressColor(progressPercentage),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Progress bar
              LinearProgressIndicator(
                value: progressPercentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(progressPercentage),
                ),
                minHeight: 6,
              ),

              const SizedBox(height: 12),

              // Activity info
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Last activity: ${_formatTimestamp(lastActivity)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const Spacer(),
                  if (estimatedCompletion != null) ...[
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'ETA: ${_formatEstimatedCompletion(estimatedCompletion)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String recency) {
    Color chipColor;
    String chipText;

    switch (recency) {
      case 'very_recent':
        chipColor = Colors.green;
        chipText = 'Active';
        break;
      case 'recent':
        chipColor = Colors.blue;
        chipText = 'Recent';
        break;
      case 'stale':
        chipColor = Colors.orange;
        chipText = 'Stale';
        break;
      default:
        chipColor = Colors.grey;
        chipText = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        chipText,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getStatusColor(String recency) {
    switch (recency) {
      case 'very_recent':
        return Colors.green;
      case 'recent':
        return Colors.blue;
      case 'stale':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String recency) {
    switch (recency) {
      case 'very_recent':
        return Icons.check_circle;
      case 'recent':
        return Icons.info;
      case 'stale':
        return Icons.warning;
      default:
        return Icons.help;
    }
  }

  Color _getProgressColor(int progress) {
    if (progress >= 80) return Colors.green;
    if (progress >= 60) return Colors.blue;
    if (progress >= 40) return Colors.orange;
    if (progress >= 20) return Colors.yellow[700]!;
    return Colors.red;
  }

  String _formatStepName(String step) {
    switch (step) {
      case 'vehicle_collection':
        return 'Vehicle Collection';
      case 'pickup_arrival':
        return 'Arrive at Pickup';
      case 'passenger_onboard':
        return 'Passenger Onboard';
      case 'dropoff_arrival':
        return 'Arrive at Dropoff';
      case 'trip_complete':
        return 'Trip Complete';
      case 'vehicle_return':
        return 'Vehicle Return';
      default:
        return step.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Unknown';

    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  String _formatEstimatedCompletion(String? estimatedCompletion) {
    if (estimatedCompletion == null) return 'N/A';

    try {
      final dateTime = DateTime.parse(estimatedCompletion);
      final now = DateTime.now();
      final difference = dateTime.difference(now);

      if (difference.isNegative) {
        return 'Overdue';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h';
      } else {
        return '${difference.inDays}d';
      }
    } catch (e) {
      return 'N/A';
    }
  }
}
