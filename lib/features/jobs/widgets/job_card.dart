import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/jobs/models/job.dart';
import 'package:choice_lux_cars/features/clients/models/client.dart';
import 'package:choice_lux_cars/features/vehicles/models/vehicle.dart';
import 'package:choice_lux_cars/features/users/models/user.dart';
import 'package:choice_lux_cars/features/vouchers/widgets/voucher_action_buttons.dart';
import 'package:choice_lux_cars/features/vouchers/providers/voucher_controller.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/features/jobs/services/driver_flow_api_service.dart';
import 'package:choice_lux_cars/features/jobs/providers/jobs_provider.dart';

class JobCard extends ConsumerWidget {
  final Job job;
  final Client? client;
  final Vehicle? vehicle;
  final User? driver;

  // Design tokens for consistent sizing
  static const double cardWidth = 380.0; // Target width
  static const double cardPadding = 16.0; // Consistent padding
  static const double railSpacing = 12.0; // Vertical rhythm
  static const double cornerRadius = 12.0; // Modern feel
  static const double buttonHeight = 44.0; // Touch target
  static const double chipHeight = 28.0; // Status chips
  static const double iconSize = 18.0; // Fixed icon size

  const JobCard({
    super.key,
    required this.job,
    this.client,
    this.vehicle,
    this.driver,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Enhanced responsive breakpoints for mobile optimization
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 600;
        final isSmallMobile = screenWidth < 400;
        final isTablet = screenWidth >= 600 && screenWidth < 800;
        final isDesktop = screenWidth >= 800;
        
        // Responsive design tokens
        final responsivePadding = isSmallMobile ? 12.0 : isMobile ? 14.0 : cardPadding;
        final responsiveSpacing = isSmallMobile ? 8.0 : isMobile ? 10.0 : railSpacing;
        final responsiveCornerRadius = isSmallMobile ? 8.0 : isMobile ? 10.0 : cornerRadius;
        final responsiveMargin = isSmallMobile ? 4.0 : isMobile ? 6.0 : 8.0;
        
        return Card(
          margin: EdgeInsets.all(responsiveMargin),
          elevation: isMobile ? 3 : 2,
          shadowColor: Colors.black.withOpacity(0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsiveCornerRadius),
          ),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(responsiveCornerRadius),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E1E1E),
                  Color(0xFF2A2A2A),
                ],
              ),
              border: Border.all(
                color: ChoiceLuxTheme.richGold.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(responsivePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status row: chips + date badge
                  _buildStatusRow(isMobile, isSmallMobile),
                  
                  SizedBox(height: responsiveSpacing),
                  
                  // Title row: passenger/job title
                  _buildTitleRow(isMobile, isSmallMobile),
                  
                  SizedBox(height: responsiveSpacing),
                  
                  // Details block: key fields
                  _buildDetailsBlock(isMobile, isSmallMobile),
                  
                  SizedBox(height: responsiveSpacing),
                  
                  // Metrics row: stat tiles
                  _buildMetricsRow(isMobile, isSmallMobile),
                  
                  SizedBox(height: responsiveSpacing),
                  
                  // Action row: buttons
                  _buildActionRow(context, ref, isMobile, isSmallMobile),
                  
                  SizedBox(height: responsiveSpacing),
                  
                  // Footer row: voucher state with better spacing
                  SizedBox(height: isSmallMobile ? 6 : isMobile ? 8 : 8),
                  _buildVoucherFooter(ref, isMobile, isSmallMobile),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Status row: chips + date badge
  Widget _buildStatusRow(bool isMobile, bool isSmallMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // First line: status chips
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: isSmallMobile ? 4 : isMobile ? 6 : 8,
                runSpacing: isSmallMobile ? 3 : isMobile ? 4 : 6,
                children: [
                  _buildStatusChip(isMobile, isSmallMobile),
                  if (!isMobile) _buildDriverConfirmationChip(isMobile, isSmallMobile),
                ],
              ),
            ),
            SizedBox(width: isSmallMobile ? 6 : isMobile ? 8 : 12),
            _buildTimeChip(isMobile, isSmallMobile),
          ],
        ),
        // Second line: additional chips for mobile mode
        if (isMobile) ...[
          SizedBox(height: isSmallMobile ? 3 : 4),
          _buildDriverConfirmationChip(isMobile, isSmallMobile),
        ],
      ],
    );
  }

  // Title row: passenger/job title (1 line, ellipsis)
  Widget _buildTitleRow(bool isMobile, bool isSmallMobile) {
    return Text(
      job.passengerName ?? 'Unnamed Job',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: isSmallMobile ? 14 : isMobile ? 15 : 16,
        color: ChoiceLuxTheme.softWhite,
        height: 1.2,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  // Details block: 3-4 key fields (each 1 line, ellipsis)
  Widget _buildDetailsBlock(bool isMobile, bool isSmallMobile) {
    return Container(
      padding: EdgeInsets.all(isSmallMobile ? 10 : isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(isSmallMobile ? 6 : isMobile ? 8 : 10),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Job Details',
            style: TextStyle(
              fontSize: isSmallMobile ? 11 : isMobile ? 12 : 14,
              fontWeight: FontWeight.w600,
              color: ChoiceLuxTheme.platinumSilver,
            ),
          ),
          SizedBox(height: isSmallMobile ? 6 : isMobile ? 8 : 10),
          _buildDetailRow(Icons.business, 'Client', client?.companyName ?? 'Unknown Client', isMobile, isSmallMobile),
          SizedBox(height: isSmallMobile ? 4 : isMobile ? 6 : 8),
          _buildDetailRow(Icons.person, 'Driver', driver?.displayName ?? 'Unassigned', isMobile, isSmallMobile),
          SizedBox(height: isSmallMobile ? 4 : isMobile ? 6 : 8),
          _buildDetailRow(Icons.directions_car, 'Vehicle', 
            vehicle != null ? '${vehicle!.make} ${vehicle!.model}' : 'Vehicle not assigned', isMobile, isSmallMobile),
          if (!isMobile) ...[
            SizedBox(height: isSmallMobile ? 4 : isMobile ? 6 : 8),
            _buildDetailRow(Icons.tag, 'Job Number', 'Job #${job.id}', isMobile, isSmallMobile),
          ],
        ],
      ),
    );
  }

  // Metrics row: two small stat tiles (Passengers/Bags)
  Widget _buildMetricsRow(bool isMobile, bool isSmallMobile) {
    if (isMobile) {
      // Mobile: collapse into small pills
      return Row(
        children: [
          _buildCompactMetricPill(Icons.people, '${job.pasCount} pax', isMobile, isSmallMobile),
          SizedBox(width: isSmallMobile ? 6 : 8),
          _buildCompactMetricPill(Icons.work, '${job.luggageCount} bags', isMobile, isSmallMobile),
        ],
      );
    } else {
      // Desktop: separate metric tiles
      return Row(
        children: [
          Expanded(
            child: _buildMetricTile(
              Icons.people,
              'Passengers',
              '${job.pasCount}',
              Colors.blue,
              isMobile,
              isSmallMobile,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricTile(
              Icons.work,
              'Bags',
              '${job.luggageCount}',
              Colors.blue,
              isMobile,
              isSmallMobile,
            ),
          ),
        ],
      );
    }
  }

  // Action row: Primary (Start Job), secondary (View)
  Widget _buildActionRow(BuildContext context, WidgetRef ref, bool isMobile, bool isSmallMobile) {
    final isAssignedDriver = _isAssignedDriver(ref);
    final needsConfirmation = isAssignedDriver && job.driverConfirmation != true;
    
    // Debug logging
    print('Action row debug:');
    print('  Is assigned driver: $isAssignedDriver');
    print('  Needs confirmation: $needsConfirmation');
    print('  Driver confirmation: ${job.driverConfirmation}');
    print('  Is confirmed: ${job.isConfirmed}');
    print('  Job ID: ${job.id}');
    print('  Job driver ID: ${job.driverId}');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Confirm Button - Show only for assigned driver who hasn't confirmed
        if (needsConfirmation) ...[
          ElevatedButton.icon(
            onPressed: () => _handleDriverConfirmation(context, ref),
            icon: Icon(Icons.check_circle, size: iconSize),
            label: Text('Confirm Job'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.withOpacity(0.15),
              foregroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          SizedBox(height: railSpacing),
        ],
        
        // Action buttons row
        Row(
          children: [
            // Driver Flow Button - Show only for assigned driver
            if (isAssignedDriver) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (job.status == 'completed') {
                      // Navigate to job summary for completed jobs
                      context.go('/jobs/${job.id}/summary');
                    } else if (job.status == 'in_progress' || job.status == 'started') {
                      // Resume existing job
                      context.go('/jobs/${job.id}/progress');
                    } else {
                      // Start new job
                      context.go('/jobs/${job.id}/progress');
                    }
                  },
                  icon: Icon(
                    job.status == 'completed'
                      ? Icons.summarize
                      : job.status == 'in_progress' || job.status == 'started' 
                        ? Icons.sync 
                        : Icons.play_arrow,
                    size: iconSize,
                  ),
                  label: Text(
                    job.status == 'completed' 
                      ? 'Job Overview'
                      : job.status == 'in_progress' || job.status == 'started' 
                        ? 'Resume Job' 
                        : 'Start Job'
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: job.status == 'completed'
                      ? ChoiceLuxTheme.richGold.withOpacity(0.15)
                      : Colors.green.withOpacity(0.15),
                    foregroundColor: job.status == 'completed'
                      ? ChoiceLuxTheme.richGold
                      : Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            
            // View Button
            Expanded(
              child: TextButton.icon(
                onPressed: () {
                  context.go('/jobs/${job.id}/summary');
                },
                icon: Icon(Icons.arrow_forward, size: iconSize),
                label: Text(_getActionText()),
                style: TextButton.styleFrom(
                  foregroundColor: _getStatusColor(),
                  backgroundColor: _getStatusColor().withOpacity(0.1), // Add subtle background
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), // Add horizontal padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: BorderSide(
                      color: _getStatusColor().withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Footer row: Voucher state chip
  Widget _buildVoucherFooter(WidgetRef ref, bool isMobile, bool isSmallMobile) {
    final hasVoucher = job.voucherPdf != null && job.voucherPdf!.isNotEmpty;
    
    return Container(
      margin: EdgeInsets.only(top: isSmallMobile ? 6 : isMobile ? 8 : 10),
      padding: EdgeInsets.symmetric(vertical: isSmallMobile ? 6 : isMobile ? 8 : 10),
      child: VoucherActionButtons(
        jobId: job.id,
        voucherPdfUrl: hasVoucher ? job.voucherPdf : null,
        canCreateVoucher: ref.watch(canCreateVoucherProvider).value ?? false,
      ),
    );
  }

  // Helper methods
  Widget _buildDetailRow(IconData icon, String label, String value, bool isMobile, bool isSmallMobile) {
    return Row(
      children: [
        Icon(
          icon,
          size: isSmallMobile ? 14 : isMobile ? 16 : 18,
          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.8),
        ),
        SizedBox(width: isSmallMobile ? 4 : isMobile ? 6 : 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7),
            fontSize: isSmallMobile ? 11 : isMobile ? 12 : 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: ChoiceLuxTheme.softWhite,
              fontSize: isSmallMobile ? 11 : isMobile ? 12 : 14,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactMetricPill(IconData icon, String text, bool isMobile, bool isSmallMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallMobile ? 6 : isMobile ? 8 : 10,
        vertical: isSmallMobile ? 3 : isMobile ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isSmallMobile ? 8 : isMobile ? 10 : 12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon, 
            size: isSmallMobile ? 12 : isMobile ? 14 : 16, 
            color: Colors.blue
          ),
          SizedBox(width: isSmallMobile ? 3 : isMobile ? 4 : 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.blue,
              fontSize: isSmallMobile ? 10 : isMobile ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(IconData icon, String label, String value, Color color, bool isMobile, bool isSmallMobile) {
    return Container(
      padding: EdgeInsets.all(isSmallMobile ? 6 : isMobile ? 8 : 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(isSmallMobile ? 6 : isMobile ? 8 : 10),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon, 
            size: isSmallMobile ? 14 : isMobile ? 16 : 18, 
            color: color
          ),
          SizedBox(height: isSmallMobile ? 1 : isMobile ? 2 : 3),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: isSmallMobile ? 12 : isMobile ? 14 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: isSmallMobile ? 9 : isMobile ? 10 : 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool isMobile, bool isSmallMobile) {
    final responsiveChipHeight = isSmallMobile ? 20.0 : isMobile ? 24.0 : chipHeight;
    final responsivePadding = isSmallMobile ? 6.0 : isMobile ? 8.0 : 10.0;
    final responsiveFontSize = isSmallMobile ? 10.0 : isMobile ? 11.0 : 12.0;
    final responsiveDotSize = isSmallMobile ? 4.0 : isMobile ? 5.0 : 6.0;
    
    return Container(
      height: responsiveChipHeight,
      padding: EdgeInsets.symmetric(horizontal: responsivePadding),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.15),
        borderRadius: BorderRadius.circular(responsiveChipHeight / 2),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: responsiveDotSize,
            height: responsiveDotSize,
            decoration: BoxDecoration(
              color: _getStatusColor(),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: isSmallMobile ? 3 : isMobile ? 4 : 6),
          Text(
            _getStatusText(),
            style: TextStyle(
              color: _getStatusColor(),
              fontSize: responsiveFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverConfirmationChip(bool isMobile, bool isSmallMobile) {
    Color color;
    String text;
    
    if (job.driverConfirmation == null) {
      color = Colors.grey;
      text = 'Pending';
    } else if (job.driverConfirmation == true) {
      color = Colors.green;
      text = 'Confirmed';
    } else {
      color = Colors.red;
      text = 'Not Confirmed';
    }
    
    final responsiveChipHeight = isSmallMobile ? 20.0 : isMobile ? 24.0 : chipHeight;
    final responsivePadding = isSmallMobile ? 6.0 : isMobile ? 8.0 : 10.0;
    final responsiveFontSize = isSmallMobile ? 10.0 : isMobile ? 11.0 : 12.0;
    final responsiveDotSize = isSmallMobile ? 4.0 : isMobile ? 5.0 : 6.0;
    
    return Container(
      height: responsiveChipHeight,
      padding: EdgeInsets.symmetric(horizontal: responsivePadding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(responsiveChipHeight / 2),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: responsiveDotSize,
            height: responsiveDotSize,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: isSmallMobile ? 3 : isMobile ? 4 : 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: responsiveFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeChip(bool isMobile, bool isSmallMobile) {
    final daysUntilStart = job.daysUntilStart;
    final isStarted = daysUntilStart < 0;
    final isToday = daysUntilStart == 0;
    final isSoon = daysUntilStart <= 3 && daysUntilStart > 0;
    
    String text;
    Color color;
    IconData icon;
    
    if (isStarted) {
      text = isSmallMobile ? '${daysUntilStart.abs()}d ago' : 'Started ${daysUntilStart.abs()}d ago';
      color = Colors.grey;
      icon = Icons.schedule;
    } else if (isToday) {
      text = 'TODAY';
      color = Colors.orange;
      icon = Icons.today;
    } else if (isSoon) {
      text = isSmallMobile ? '${daysUntilStart}d' : 'URGENT ${daysUntilStart}d';
      color = Colors.red;
      icon = Icons.warning;
    } else {
      text = isSmallMobile ? '${daysUntilStart}d' : 'In ${daysUntilStart}d';
      color = Colors.green;
      icon = Icons.calendar_today;
    }
    
    final responsiveChipHeight = isSmallMobile ? 20.0 : isMobile ? 24.0 : chipHeight;
    final responsivePadding = isSmallMobile ? 6.0 : isMobile ? 8.0 : 10.0;
    final responsiveFontSize = isSmallMobile ? 10.0 : isMobile ? 11.0 : 12.0;
    final responsiveIconSize = isSmallMobile ? 12.0 : isMobile ? 14.0 : 16.0;
    
    return Container(
      height: responsiveChipHeight,
      padding: EdgeInsets.symmetric(horizontal: responsivePadding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(responsiveChipHeight / 2),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: responsiveIconSize, color: color),
          SizedBox(width: isSmallMobile ? 3 : isMobile ? 4 : 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: responsiveFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (job.status) {
      case 'assigned':
        return ChoiceLuxTheme.richGold;
      case 'started':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'ready_to_close':
        return Colors.purple;
      case 'completed':
        return ChoiceLuxTheme.successColor;
      case 'cancelled':
        return ChoiceLuxTheme.errorColor;
      default:
        return ChoiceLuxTheme.platinumSilver;
    }
  }

  String _getStatusText() {
    switch (job.status) {
      case 'assigned':
        return 'ASSIGNED';
      case 'started':
        return 'STARTED';
      case 'in_progress':
        return 'IN PROGRESS';
      case 'ready_to_close':
        return 'READY TO CLOSE';
      case 'completed':
        return 'COMPLETED';
      case 'cancelled':
        return 'CANCELLED';
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
        return 'OVERVIEW';
      default:
        return 'VIEW';
    }
  }

  // Check if current user is the assigned driver
  bool _isAssignedDriver(WidgetRef ref) {
    final currentUser = ref.read(currentUserProfileProvider);
    final isAssigned = currentUser?.id == job.driverId;
    
    // Debug logging
    print('Driver assignment check:');
    print('  Current user ID: ${currentUser?.id}');
    print('  Job driver ID: ${job.driverId}');
    print('  Is assigned: $isAssigned');
    print('  Driver confirmation: ${job.driverConfirmation}');
    print('  Is confirmed: ${job.isConfirmed}');
    
    return isAssigned;
  }

  // Handle driver confirmation
  Future<void> _handleDriverConfirmation(BuildContext context, WidgetRef ref) async {
    try {
      final success = await DriverFlowApiService.confirmDriverAwareness(int.parse(job.id));
      
      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Job confirmed successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Refresh the jobs list to update the UI
        ref.invalidate(jobsProvider);
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to confirm job. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error handling driver confirmation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}