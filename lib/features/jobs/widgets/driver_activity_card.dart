import 'package:flutter/material.dart';

class DriverActivityCard extends StatelessWidget {
  final Map<String, dynamic> driver;
  final VoidCallback? onTap;

  const DriverActivityCard({
    Key? key,
    required this.driver,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final driverName = driver['driver_name'] ?? 'Unknown Driver';
    final driverPhone = driver['driver_phone'] ?? 'N/A';
    final driverStatus = driver['driver_status'] ?? 'unknown';
    final assignedJobs = driver['assigned_jobs'] ?? 0;
    final startedJobs = driver['started_jobs'] ?? 0;
    final activeJobs = driver['active_jobs'] ?? 0;
    final readyToCloseJobs = driver['ready_to_close_jobs'] ?? 0;
    final lastActivity = driver['last_activity'];

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
                    backgroundColor: _getStatusColor(driverStatus),
                    child: Icon(
                      _getStatusIcon(driverStatus),
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
                  _buildStatusChip(driverStatus),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Job statistics
              Row(
                children: [
                  Expanded(
                    child: _buildJobStat(
                      'Assigned',
                      assignedJobs.toString(),
                      Icons.assignment,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildJobStat(
                      'Started',
                      startedJobs.toString(),
                      Icons.play_arrow,
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildJobStat(
                      'Active',
                      activeJobs.toString(),
                      Icons.work,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildJobStat(
                      'Ready',
                      readyToCloseJobs.toString(),
                      Icons.check_circle,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Activity info
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Last activity: ${_formatTimestamp(lastActivity)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (activeJobs > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Text(
                        '$activeJobs active',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    String chipText;
    
    switch (status) {
      case 'active':
        chipColor = Colors.green;
        chipText = 'Active';
        break;
      case 'recent':
        chipColor = Colors.blue;
        chipText = 'Recent';
        break;
      case 'inactive':
        chipColor = Colors.grey;
        chipText = 'Inactive';
        break;
      default:
        chipColor = Colors.grey;
        chipText = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.3)),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'recent':
        return Colors.blue;
      case 'inactive':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'active':
        return Icons.check_circle;
      case 'recent':
        return Icons.info;
      case 'inactive':
        return Icons.person_off;
      default:
        return Icons.help;
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
}
