import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/jobs/models/job.dart';
import 'package:choice_lux_cars/features/clients/models/client.dart';
import 'package:choice_lux_cars/features/vehicles/models/vehicle.dart';
import 'package:choice_lux_cars/features/users/models/user.dart';
import 'package:choice_lux_cars/features/vouchers/widgets/voucher_action_buttons.dart';
import 'package:choice_lux_cars/shared/widgets/status_pill.dart';
import 'package:choice_lux_cars/features/jobs/services/driver_flow_api_service.dart';
import 'package:intl/intl.dart';

class JobListCard extends StatelessWidget {
  final Job job;
  final Client? client;
  final Vehicle? vehicle;
  final User? driver;
  final bool isSmallMobile;
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;

  const JobListCard({
    super.key,
    required this.job,
    this.client,
    this.vehicle,
    this.driver,
    required this.isSmallMobile,
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final padding = isSmallMobile ? 12.0 : isMobile ? 16.0 : 20.0;
    final spacing = isSmallMobile ? 8.0 : isMobile ? 12.0 : 16.0;
    final cornerRadius = isSmallMobile ? 8.0 : isMobile ? 12.0 : 16.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cornerRadius),
      ),
      child: Container(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Status, Job ID, Time
            _buildHeaderRow(context, spacing),
            
            SizedBox(height: spacing),
            
            // Main Content: Passenger and Location Info
            _buildMainContent(context, spacing),
            
            SizedBox(height: spacing),
            
            // Metrics Row: Pax, Luggage, Vehicle
            _buildMetricsRow(context, spacing),
            
            SizedBox(height: spacing),
            
            // Actions Row: View, Voucher, Driver Flow
            _buildActionsRow(context, spacing),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context, double spacing) {
    return Row(
      children: [
        // Status Pill
        JobStatusPill(status: job.status),
        
        SizedBox(width: spacing),
        
        // Job ID
        Expanded(
          child: Text(
            'Job #${job.id}',
            style: TextStyle(
              fontSize: isSmallMobile ? 14 : isMobile ? 16 : 18,
              fontWeight: FontWeight.w600,
              color: ChoiceLuxTheme.jetBlack,
            ),
          ),
        ),
        
        // Time Status
        TimeStatusPill(
          daysUntilStart: job.daysUntilStart,
          isSmallScreen: isSmallMobile,
        ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context, double spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Passenger Name
        Text(
          job.passengerName ?? 'No Passenger Name',
          style: TextStyle(
            fontSize: isSmallMobile ? 16 : isMobile ? 18 : 20,
            fontWeight: FontWeight.bold,
            color: ChoiceLuxTheme.jetBlack,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        SizedBox(height: spacing * 0.5),
        
        // Location Info
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location
            Expanded(
              child: _buildLocationInfo(
                context,
                'Location',
                job.location ?? 'No location specified',
                Icons.location_on,
                ChoiceLuxTheme.infoColor,
                spacing,
              ),
            ),
          ],
        ),
        
        SizedBox(height: spacing * 0.5),
        
        // Date and Time
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: isSmallMobile ? 14 : 16,
              color: ChoiceLuxTheme.infoColor,
            ),
            SizedBox(width: spacing * 0.5),
            Expanded(
              child: Text(
                _formatDate(job.jobStartDate),
                style: TextStyle(
                  fontSize: isSmallMobile ? 12 : 14,
                  color: ChoiceLuxTheme.infoColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationInfo(
    BuildContext context,
    String label,
    String location,
    IconData icon,
    Color color,
    double spacing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: isSmallMobile ? 12 : 14,
              color: color,
            ),
            SizedBox(width: spacing * 0.25),
            Text(
              label,
              style: TextStyle(
                fontSize: isSmallMobile ? 10 : 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: spacing * 0.25),
        Text(
          location,
          style: TextStyle(
            fontSize: isSmallMobile ? 12 : 14,
            color: ChoiceLuxTheme.jetBlack,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMetricsRow(BuildContext context, double spacing) {
    return Row(
      children: [
        // Passenger Count
        _buildMetricChip(
          context,
          Icons.person,
          '${job.pasCount} pax',
          ChoiceLuxTheme.infoColor,
          spacing,
        ),
        
        SizedBox(width: spacing),
        
        // Luggage Count
        _buildMetricChip(
          context,
          Icons.work,
          '${job.luggageCount} bags',
          ChoiceLuxTheme.infoColor,
          spacing,
        ),
        
        SizedBox(width: spacing),
        
        // Vehicle Info
        if (vehicle?.model != null)
          _buildMetricChip(
            context,
            Icons.directions_car,
            vehicle!.model,
            ChoiceLuxTheme.infoColor,
            spacing,
          ),
        
        const Spacer(),
        
        // Driver Confirmation
        DriverConfirmationPill(
          isConfirmed: job.driverConfirmation ?? false,
        ),
      ],
    );
  }

  Widget _buildMetricChip(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    double spacing,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing * 0.75,
        vertical: spacing * 0.5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isSmallMobile ? 12 : 14,
            color: color,
          ),
          SizedBox(width: spacing * 0.25),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallMobile ? 10 : 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsRow(BuildContext context, double spacing) {
    return Row(
      children: [
        // View Button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.go('/jobs/${job.id}'),
            icon: const Icon(Icons.visibility, size: 16),
            label: Text(
              'View Details',
              style: TextStyle(fontSize: isSmallMobile ? 12 : 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: ChoiceLuxTheme.richGold,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(
                horizontal: spacing,
                vertical: spacing * 0.75,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        
        SizedBox(width: spacing),
        
        // Driver Flow Button (if applicable)
        if (_shouldShowDriverFlowButton())
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _handleDriverFlow(context),
              icon: Icon(_getDriverFlowIcon(), size: 16),
              label: Text(
                _getDriverFlowText(),
                style: TextStyle(fontSize: isSmallMobile ? 12 : 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getDriverFlowColor(),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: spacing,
                  vertical: spacing * 0.75,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        
        // Voucher Actions
        if (job.statusEnum == JobStatus.completed)
          Expanded(
            child: VoucherActionButtons(
              jobId: job.id,
              voucherPdfUrl: job.voucherPdf,
              voucherData: null, // You'll need to pass actual voucher data
              canCreateVoucher: true, // You'll need to determine this
            ),
          ),
      ],
    );
  }

  bool _shouldShowDriverFlowButton() {
    return job.statusEnum == JobStatus.assigned || 
           job.statusEnum == JobStatus.started ||
           job.statusEnum == JobStatus.inProgress;
  }

  IconData _getDriverFlowIcon() {
    switch (job.statusEnum) {
      case JobStatus.assigned:
        return Icons.play_arrow;
      case JobStatus.started:
        return Icons.directions_car;
      case JobStatus.inProgress:
        return Icons.timeline;
      default:
        return Icons.info;
    }
  }

  String _getDriverFlowText() {
    switch (job.statusEnum) {
      case JobStatus.assigned:
        return 'Start Trip';
      case JobStatus.started:
        return 'In Transit';
      case JobStatus.inProgress:
        return 'Update';
      default:
        return 'Details';
    }
  }

  Color _getDriverFlowColor() {
    switch (job.statusEnum) {
      case JobStatus.assigned:
        return Colors.green;
      case JobStatus.started:
        return Colors.blue;
      case JobStatus.inProgress:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _handleDriverFlow(BuildContext context) async {
    try {
      final jobId = int.tryParse(job.id);
      if (jobId != null) {
        await DriverFlowApiService.confirmDriverAwareness(jobId);
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Driver flow updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update driver flow: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }
}
