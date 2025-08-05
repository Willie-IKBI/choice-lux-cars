import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/jobs/models/job.dart';
import 'package:choice_lux_cars/shared/widgets/dashboard_card.dart';

class JobCard extends StatelessWidget {
  final Job job;

  const JobCard({
    super.key,
    required this.job,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // Navigation will be handled by parent
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E1E1E),
                Color(0xFF2A2A2A),
              ],
            ),
            border: Border.all(
              color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                // Header with title and status badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        job.passengerName ?? 'Unnamed Job',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: ChoiceLuxTheme.softWhite,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(),
                  ],
                ),
                
                                                 const SizedBox(height: 6),
                
                // Time status badge
                _buildTimeStatusBadge(),
                
                const SizedBox(height: 6),
                
                // Job metadata
                _buildMetadataRow(),
                
                const SizedBox(height: 4),
                
                // Payment info if applicable
                if (job.collectPayment && job.paymentAmount != null)
                  _buildPaymentInfo(),
                
                const SizedBox(height: 6),
                
                // Footer with action
                _buildFooter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: 12,
            color: _getStatusColor(),
          ),
          const SizedBox(width: 4),
          Text(
            _getStatusText(),
            style: TextStyle(
              color: _getStatusColor(),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeStatusBadge() {
    final daysUntilStart = job.daysUntilStart;
    final isStarted = daysUntilStart < 0;
    final isToday = daysUntilStart == 0;
    final isSoon = daysUntilStart <= 3 && daysUntilStart > 0;
    
    String text;
    IconData icon;
    Color color;
    
    if (isStarted) {
      text = 'Started ${daysUntilStart.abs()} day${daysUntilStart.abs() == 1 ? '' : 's'} ago';
      icon = Icons.calendar_today;
      color = ChoiceLuxTheme.platinumSilver;
    } else if (isToday) {
      text = 'Starts today';
      icon = Icons.access_time;
      color = Colors.orange;
    } else if (isSoon) {
      text = 'Starts in $daysUntilStart day${daysUntilStart == 1 ? '' : 's'}';
      icon = Icons.warning;
      color = Colors.red;
    } else {
      text = 'Starts in $daysUntilStart day${daysUntilStart == 1 ? '' : 's'}';
      icon = Icons.schedule;
      color = Colors.green;
    }
    
         return Container(
       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
       decoration: BoxDecoration(
         color: color.withOpacity(0.15),
         borderRadius: BorderRadius.circular(6),
         border: Border.all(
           color: color.withOpacity(0.3),
           width: 1,
         ),
       ),
       child: Row(
         mainAxisSize: MainAxisSize.min,
         children: [
           Icon(
             icon,
             size: 10,
             color: color,
           ),
           const SizedBox(width: 3),
           Text(
             text,
             style: TextStyle(
               color: color,
               fontSize: 9,
               fontWeight: FontWeight.w500,
             ),
           ),
         ],
       ),
     );
  }

    Widget _buildMetadataRow() {
    return Row(
      children: [
        // Job ID
        Expanded(
          child: Row(
            children: [
              Icon(
                Icons.tag,
                size: 12,
                color: ChoiceLuxTheme.platinumSilver,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Job #${job.id.length > 8 ? job.id.substring(0, 8) + '...' : job.id}',
                  style: TextStyle(
                    color: ChoiceLuxTheme.platinumSilver,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Passenger and luggage count
        Row(
          children: [
            Icon(
              Icons.people,
              size: 12,
              color: ChoiceLuxTheme.platinumSilver,
            ),
            const SizedBox(width: 4),
            Text(
              '${job.pasCount} pax',
              style: TextStyle(
                color: ChoiceLuxTheme.platinumSilver,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.work,
              size: 12,
              color: ChoiceLuxTheme.platinumSilver,
            ),
            const SizedBox(width: 4),
            Text(
              '${job.luggageCount} bag${job.luggageCount == 1 ? '' : 's'}',
              style: TextStyle(
                color: ChoiceLuxTheme.platinumSilver,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.richGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ChoiceLuxTheme.richGold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.payment,
            size: 14,
            color: ChoiceLuxTheme.richGold,
          ),
          const SizedBox(width: 6),
          Text(
            'Collect R${job.paymentAmount!.toStringAsFixed(2)}',
            style: TextStyle(
              color: ChoiceLuxTheme.richGold,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Warning indicator if incomplete details
        if (!job.hasCompletePassengerDetails)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: ChoiceLuxTheme.errorColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: ChoiceLuxTheme.errorColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning,
                    size: 10,
                    color: ChoiceLuxTheme.errorColor,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'Incomplete',
                    style: TextStyle(
                      color: ChoiceLuxTheme.errorColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Action button - right aligned
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            InkWell(
              onTap: () {
                // Navigate to job details/summary screen
                context.go('/jobs/${job.id}/summary');
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getStatusColor().withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getActionText(),
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 10,
                      color: _getStatusColor(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (job.status) {
      case 'open':
        return ChoiceLuxTheme.richGold;
      case 'in_progress':
        return Colors.blue;
      case 'closed':
      case 'completed':
        return ChoiceLuxTheme.successColor;
      default:
        return ChoiceLuxTheme.platinumSilver;
    }
  }

  IconData _getStatusIcon() {
    switch (job.status) {
      case 'open':
        return Icons.folder_open;
      case 'in_progress':
        return Icons.sync;
      case 'closed':
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  String _getStatusText() {
    switch (job.status) {
      case 'open':
        return 'OPEN';
      case 'in_progress':
        return 'IN PROGRESS';
      case 'closed':
        return 'CLOSED';
      case 'completed':
        return 'COMPLETED';
      default:
        return job.status.toUpperCase();
    }
  }

  String _getActionText() {
    switch (job.status) {
      case 'open':
        return 'VIEW';
      case 'in_progress':
        return 'TRACK';
      case 'closed':
      case 'completed':
        return 'DETAILS';
      default:
        return 'VIEW';
    }
  }
}