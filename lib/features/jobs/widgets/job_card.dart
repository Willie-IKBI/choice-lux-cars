import 'package:flutter/material.dart';
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
    return DashboardCard(
      title: _buildTitle(),
      subtitle: _buildSubtitle(),
      icon: Icons.work,
      color: _getStatusColor(),
      badge: _buildBadge(),
      onTap: () {
        // Navigation will be handled by parent
      },
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Expanded(
          child: Text(
            job.passengerName ?? 'Unnamed Job',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!job.hasCompletePassengerDetails)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.errorColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubtitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Days until start
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getDaysUntilStartColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            job.daysUntilStartText,
            style: TextStyle(
              color: _getDaysUntilStartColor(),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Branch and status
        Row(
          children: [
            Icon(
              _getBranchIcon(),
              size: 14,
              color: ChoiceLuxTheme.platinumSilver,
            ),
            const SizedBox(width: 4),
            Text(
              job.branch,
              style: TextStyle(
                color: ChoiceLuxTheme.platinumSilver,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getStatusText(),
                style: TextStyle(
                  color: _getStatusColor(),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Passenger count and luggage
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
              '${job.luggageCount} bags',
              style: TextStyle(
                color: ChoiceLuxTheme.platinumSilver,
                fontSize: 11,
              ),
            ),
          ],
        ),
        // Payment collection indicator
        if (job.collectPayment && job.paymentAmount != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.payment,
                size: 12,
                color: ChoiceLuxTheme.richGold,
              ),
              const SizedBox(width: 4),
              Text(
                'Collect R${job.paymentAmount!.toStringAsFixed(2)}',
                style: TextStyle(
                  color: ChoiceLuxTheme.richGold,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget? _buildBadge() {
    if (!job.hasCompletePassengerDetails) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: ChoiceLuxTheme.errorColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          '!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return null;
  }

  Color _getStatusColor() {
    switch (job.status) {
      case 'open':
        return ChoiceLuxTheme.richGold;
      case 'in_progress':
        return Colors.blue;
      case 'closed':
        return Colors.grey;
      default:
        return ChoiceLuxTheme.platinumSilver;
    }
  }

  Color _getDaysUntilStartColor() {
    if (job.daysUntilStart < 0) {
      return Colors.grey; // Started
    } else if (job.daysUntilStart == 0) {
      return Colors.orange; // Starts today
    } else if (job.daysUntilStart <= 3) {
      return Colors.red; // Starts soon
    } else if (job.daysUntilStart <= 7) {
      return Colors.orange; // Starts this week
    } else {
      return Colors.green; // Starts later
    }
  }

  IconData _getBranchIcon() {
    switch (job.branch) {
      case 'Jhb':
        return Icons.location_city;
      case 'Cpt':
        return Icons.beach_access;
      case 'Dbn':
        return Icons.water;
      default:
        return Icons.location_on;
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
      default:
        return job.status.toUpperCase();
    }
  }
} 