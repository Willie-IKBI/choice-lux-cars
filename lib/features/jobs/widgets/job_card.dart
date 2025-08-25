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
import 'package:choice_lux_cars/features/notifications/providers/notification_provider.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';
import 'package:choice_lux_cars/shared/widgets/status_pill.dart';

class JobCard extends ConsumerWidget {
  final Job job;
  final Client? client;
  final Vehicle? vehicle;
  final User? driver;

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
        // Use centralized responsive system
        final screenWidth = constraints.maxWidth;
        final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(screenWidth);
        final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
        
        // Get responsive design tokens - use smaller values to prevent overflow
        final padding = ResponsiveTokens.getPadding(screenWidth) * 0.75; // Reduce padding
        final spacing = ResponsiveTokens.getSpacing(screenWidth) * 0.75; // Reduce spacing
        final cornerRadius = ResponsiveTokens.getCornerRadius(screenWidth);
        final iconSize = ResponsiveTokens.getIconSize(screenWidth) * 0.8; // Smaller icons
        final fontSize = ResponsiveTokens.getFontSize(screenWidth, baseSize: 12.0); // Smaller base font
        
        return Card(
          margin: EdgeInsets.all(spacing * 0.5), // Reduce margin
          elevation: isMobile ? 2 : 1, // Reduce elevation
          shadowColor: Colors.black.withValues(alpha: 0.1), // Reduce shadow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cornerRadius),
          ),
          child: Container(
            width: double.infinity,
            // Removed height: double.infinity to prevent overflow issues
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(cornerRadius),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E1E1E),
                  Color(0xFF2A2A2A),
                ],
              ),
              border: Border.all(
                color: ChoiceLuxTheme.richGold.withValues(alpha: 0.15), // Reduce border opacity
                width: 0.5, // Thinner border
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status row: chips + date badge - More compact
                  _buildStatusRow(isMobile, isSmallMobile, iconSize, fontSize),
                  
                  SizedBox(height: spacing * 0.5), // Reduce spacing
                  
                  // Title row: passenger/job title
                  _buildTitleRow(isMobile, isSmallMobile, fontSize),
                  
                  SizedBox(height: spacing * 0.5), // Reduce spacing
                  
                  // Details block: key fields - Use Flexible instead of Expanded
                  Flexible(
                    child: _buildDetailsBlock(isMobile, isSmallMobile, iconSize, fontSize),
                  ),
                  
                  SizedBox(height: spacing * 0.5), // Reduce spacing
                  
                  // Metrics row: stat tiles - More compact
                  _buildMetricsRow(isMobile, isSmallMobile, iconSize, fontSize),
                  
                  SizedBox(height: spacing * 0.5), // Reduce spacing
                  
                  // Action row: buttons - More compact
                  _buildActionRow(context, ref, isMobile, isSmallMobile, iconSize, fontSize),
                  
                  SizedBox(height: spacing * 0.5), // Reduce spacing
                  
                  // Footer row: voucher state - More compact
                  _buildVoucherFooter(ref, isMobile, isSmallMobile, fontSize),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Status row: chips + date badge
  Widget _buildStatusRow(bool isMobile, bool isSmallMobile, double iconSize, double fontSize) {
    final chipHeight = isSmallMobile ? 16.0 : isMobile ? 18.0 : 20.0; // Smaller chip heights
    final chipPadding = EdgeInsets.symmetric(
      horizontal: isSmallMobile ? 4.0 : isMobile ? 5.0 : 6.0, // Reduced padding
    );
    final chipFontSize = fontSize - 3; // Smaller font size
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // First line: status chips
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: isSmallMobile ? 2 : isMobile ? 3 : 4, // Reduced spacing
                runSpacing: isSmallMobile ? 2 : isMobile ? 3 : 4, // Reduced run spacing
                children: [
                  // Use JobStatus enum for status chip
                  StatusPill(
                    color: job.statusEnum.color,
                    text: job.statusEnum.label,
                    height: chipHeight,
                    padding: chipPadding,
                    fontSize: chipFontSize,
                    showDot: true,
                  ),
                  if (!isMobile) 
                    DriverConfirmationPill(
                      isConfirmed: job.driverConfirmation,
                      height: chipHeight,
                      padding: chipPadding,
                      fontSize: chipFontSize,
                    ),
                ],
              ),
            ),
            SizedBox(width: isSmallMobile ? 4 : isMobile ? 5 : 6), // Reduced spacing
            // Use TimeStatusPill for time chip
            TimeStatusPill(
              daysUntilStart: job.daysUntilStart,
              height: chipHeight,
              padding: chipPadding,
              fontSize: chipFontSize,
              isSmallScreen: isSmallMobile,
            ),
          ],
        ),
        // Second line: additional chips for mobile mode
        if (isMobile) ...[
          SizedBox(height: isSmallMobile ? 2 : 3), // Reduced spacing
          DriverConfirmationPill(
            isConfirmed: job.driverConfirmation,
            height: chipHeight,
            padding: chipPadding,
            fontSize: chipFontSize,
          ),
        ],
      ],
    );
  }

  // Title row: passenger/job title (1 line, ellipsis)
  Widget _buildTitleRow(bool isMobile, bool isSmallMobile, double fontSize) {
    // Add null safety for passenger name
    final passenger = job.passengerName?.trim().isNotEmpty == true 
      ? job.passengerName! 
      : 'Unnamed Job';
      
    return Text(
      passenger,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: fontSize + 1, // Smaller title font
        color: ChoiceLuxTheme.softWhite,
        height: 1.1, // Tighter line height
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  // Details block: 3-4 key fields (each 1 line, ellipsis)
  Widget _buildDetailsBlock(bool isMobile, bool isSmallMobile, double iconSize, double fontSize) {
    final blockPadding = isSmallMobile ? 6.0 : isMobile ? 7.0 : 8.0; // Reduced padding
    final innerSpacing = isSmallMobile ? 2.0 : isMobile ? 3.0 : 4.0; // Reduced spacing
    
    return Container(
      padding: EdgeInsets.all(blockPadding),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.06), // Lighter background
        borderRadius: BorderRadius.circular(isSmallMobile ? 4 : isMobile ? 5 : 6), // Smaller radius
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.15), // Lighter border
          width: 0.5, // Thinner border
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Job Details',
            style: TextStyle(
              fontSize: fontSize - 1, // Smaller heading font
              fontWeight: FontWeight.w600,
              color: ChoiceLuxTheme.platinumSilver,
            ),
          ),
          SizedBox(height: innerSpacing),
          _buildDetailRow(Icons.business, 'Client', client?.companyName ?? 'Unknown Client', isMobile, isSmallMobile, iconSize, fontSize),
          SizedBox(height: innerSpacing),
          _buildDetailRow(Icons.person, 'Driver', driver?.displayName ?? 'Unassigned', isMobile, isSmallMobile, iconSize, fontSize),
          SizedBox(height: innerSpacing),
          _buildDetailRow(Icons.directions_car, 'Vehicle', 
            vehicle != null ? '${vehicle!.make} ${vehicle!.model}' : 'Vehicle not assigned', isMobile, isSmallMobile, iconSize, fontSize),
          if (!isMobile) ...[
            SizedBox(height: innerSpacing),
            _buildDetailRow(Icons.tag, 'Job Number', 'Job #${job.id}', isMobile, isSmallMobile, iconSize, fontSize),
          ],
        ],
      ),
    );
  }

  // Metrics row: two small stat tiles (Passengers/Bags)
  Widget _buildMetricsRow(bool isMobile, bool isSmallMobile, double iconSize, double fontSize) {
    // These fields are not nullable in the Job model
    final pax = job.pasCount;
    final bags = job.luggageCount;
    
    if (isMobile) {
      // Mobile: collapse into small pills
      return Row(
        children: [
          _buildCompactMetricPill(Icons.people, '$pax pax', isMobile, isSmallMobile, iconSize, fontSize),
          SizedBox(width: isSmallMobile ? 4 : 5), // Reduced spacing
          _buildCompactMetricPill(Icons.work, '$bags bags', isMobile, isSmallMobile, iconSize, fontSize),
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
              pax.toString(),
              ChoiceLuxTheme.infoColor, // Use theme color instead of raw blue
              isMobile,
              isSmallMobile,
              iconSize,
              fontSize,
            ),
          ),
          const SizedBox(width: 6), // Reduced spacing
          Expanded(
            child: _buildMetricTile(
              Icons.work,
              'Bags',
              bags,
              ChoiceLuxTheme.infoColor, // Use theme color instead of raw blue
              isMobile,
              isSmallMobile,
              iconSize,
              fontSize,
            ),
          ),
        ],
      );
    }
  }

  // Action row: Primary (Start Job), secondary (View)
  Widget _buildActionRow(BuildContext context, WidgetRef ref, bool isMobile, bool isSmallMobile, double iconSize, double fontSize) {
    final isAssignedDriver = _isAssignedDriver(ref);
    final isConfirmed = job.isConfirmed == true || job.driverConfirmation == true;
    final needsConfirmation = isAssignedDriver && !isConfirmed;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Confirmation Status - Show for assigned driver
        if (isAssignedDriver) ...[
          Container(
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: isConfirmed 
                  ? ChoiceLuxTheme.successColor.withValues(alpha: 0.1)
                  : ChoiceLuxTheme.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isConfirmed 
                    ? ChoiceLuxTheme.successColor.withValues(alpha: 0.3)
                    : ChoiceLuxTheme.orange.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isConfirmed ? Icons.check_circle : Icons.pending,
                  size: iconSize * 0.7,
                  color: isConfirmed ? ChoiceLuxTheme.successColor : ChoiceLuxTheme.orange,
                ),
                SizedBox(width: 4),
                Text(
                  isConfirmed ? 'Job Confirmed' : 'Awaiting Confirmation',
                  style: TextStyle(
                    fontSize: fontSize - 1,
                    color: isConfirmed ? ChoiceLuxTheme.successColor : ChoiceLuxTheme.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
        ],
        
        // Confirm Button - Show only for assigned driver who hasn't confirmed
        if (needsConfirmation) ...[
          ElevatedButton.icon(
            key: Key('confirmJobBtn_${job.id}'),
            onPressed: () => _handleDriverConfirmation(context, ref),
            icon: Icon(Icons.check_circle, size: iconSize * 0.8), // Smaller icon
            label: Text('Confirm Job', style: TextStyle(fontSize: fontSize - 1)), // Smaller text
            style: ElevatedButton.styleFrom(
              backgroundColor: ChoiceLuxTheme.orange.withValues(alpha: 0.15), // Use theme color
              foregroundColor: ChoiceLuxTheme.orange,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8), // Reduced padding
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4), // Smaller radius
              ),
            ),
          ),
          SizedBox(height: 8), // Reduced spacing
        ],
        
        // Action buttons row
        Row(
          children: [
            // Driver Flow Button - Show only for assigned driver
            if (isAssignedDriver) ...[
              Expanded(
                child: ElevatedButton.icon(
                  key: Key('driverFlowBtn_${job.id}'),
                  onPressed: () {
                    // Simplified route logic using JobStatus enum
                    final route = switch (job.statusEnum) {
                      JobStatus.completed => '/jobs/${job.id}/summary',
                      _ => '/jobs/${job.id}/progress',
                    };
                    context.go(route);
                  },
                  icon: Icon(
                    _getDriverFlowIcon(job.statusEnum),
                    size: iconSize * 0.8, // Smaller icon
                  ),
                  label: Text(_getDriverFlowText(job.statusEnum), style: TextStyle(fontSize: fontSize - 1)), // Smaller text
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getDriverFlowColor(job.statusEnum).withValues(alpha: 0.15),
                    foregroundColor: _getDriverFlowColor(job.statusEnum),
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8), // Reduced padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4), // Smaller radius
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6), // Reduced spacing
            ],
            
            // View Button
            Expanded(
              child: TextButton.icon(
                key: Key('viewJobBtn_${job.id}'),
                onPressed: () {
                  context.go('/jobs/${job.id}/summary');
                },
                icon: Icon(Icons.arrow_forward, size: iconSize * 0.8), // Smaller icon
                label: Text(_getActionText(job.statusEnum), style: TextStyle(fontSize: fontSize - 1)), // Smaller text
                style: TextButton.styleFrom(
                  foregroundColor: job.statusEnum.color,
                  backgroundColor: job.statusEnum.color.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8), // Reduced padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4), // Smaller radius
                    side: BorderSide(
                      color: job.statusEnum.color.withValues(alpha: 0.3),
                      width: 0.5, // Thinner border
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
  Widget _buildVoucherFooter(WidgetRef ref, bool isMobile, bool isSmallMobile, double fontSize) {
    final hasVoucher = job.voucherPdf != null && job.voucherPdf!.isNotEmpty;
    
    return Container(
      margin: EdgeInsets.only(top: isSmallMobile ? 2 : isMobile ? 3 : 4), // Reduced margin
      padding: EdgeInsets.symmetric(vertical: isSmallMobile ? 2 : isMobile ? 3 : 4), // Reduced padding
      child: VoucherActionButtons(
        jobId: job.id,
        voucherPdfUrl: hasVoucher ? job.voucherPdf : null,
        canCreateVoucher: ref.watch(canCreateVoucherProvider).value ?? false,
      ),
    );
  }

  // Helper methods
  Widget _buildDetailRow(IconData icon, String label, String value, bool isMobile, bool isSmallMobile, double iconSize, double fontSize) {
    return Row(
      children: [
        Icon(
          icon,
          size: iconSize * 0.8, // Smaller icon
          color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.7), // Lighter color
        ),
        SizedBox(width: isSmallMobile ? 3 : isMobile ? 4 : 5), // Reduced spacing
        Text(
          '$label: ',
          style: TextStyle(
            color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.6), // Lighter color
            fontSize: fontSize - 1, // Smaller font
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: ChoiceLuxTheme.softWhite,
              fontSize: fontSize - 1, // Smaller font
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactMetricPill(IconData icon, String text, bool isMobile, bool isSmallMobile, double iconSize, double fontSize) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallMobile ? 4 : isMobile ? 5 : 6, // Reduced padding
        vertical: isSmallMobile ? 2 : isMobile ? 3 : 4, // Reduced padding
      ),
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.infoColor.withValues(alpha: 0.08), // Lighter background
        borderRadius: BorderRadius.circular(isSmallMobile ? 6 : isMobile ? 7 : 8), // Smaller radius
        border: Border.all(
          color: ChoiceLuxTheme.infoColor.withValues(alpha: 0.2), // Lighter border
          width: 0.5, // Thinner border
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon, 
            size: iconSize * 0.6, // Smaller icon
            color: ChoiceLuxTheme.infoColor // Use theme color
          ),
          SizedBox(width: isSmallMobile ? 2 : isMobile ? 3 : 4), // Reduced spacing
          Text(
            text,
            style: TextStyle(
              color: ChoiceLuxTheme.infoColor, // Use theme color
              fontSize: fontSize - 2, // Smaller font
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(IconData icon, String label, String value, Color color, bool isMobile, bool isSmallMobile, double iconSize, double fontSize) {
    return Container(
      padding: EdgeInsets.all(isSmallMobile ? 4 : isMobile ? 5 : 6), // Reduced padding
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06), // Lighter background
        borderRadius: BorderRadius.circular(isSmallMobile ? 4 : isMobile ? 5 : 6), // Smaller radius
        border: Border.all(
          color: color.withValues(alpha: 0.15), // Lighter border
          width: 0.5, // Thinner border
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon, 
            size: iconSize * 0.8, // Smaller icon
            color: color
          ),
          SizedBox(height: isSmallMobile ? 1 : 2), // Reduced spacing
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: fontSize, // Smaller font
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.7), // Lighter color
              fontSize: fontSize - 2, // Smaller font
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for driver flow actions using JobStatus enum
  IconData _getDriverFlowIcon(JobStatus status) {
    return switch (status) {
      JobStatus.completed => Icons.summarize,
      JobStatus.inProgress || JobStatus.started => Icons.sync,
      _ => Icons.play_arrow,
    };
  }

  String _getDriverFlowText(JobStatus status) {
    return switch (status) {
      JobStatus.completed => 'Job Overview',
      JobStatus.inProgress || JobStatus.started => 'Resume Job',
      _ => 'Start Job',
    };
  }

  Color _getDriverFlowColor(JobStatus status) {
    return switch (status) {
      JobStatus.completed => ChoiceLuxTheme.richGold,
      _ => ChoiceLuxTheme.successColor,
    };
  }

  String _getActionText(JobStatus status) {
    return switch (status) {
      JobStatus.open => 'VIEW',
      JobStatus.inProgress => 'TRACK',
      JobStatus.completed => 'OVERVIEW',
      _ => 'VIEW',
    };
  }

  // Check if current user is the assigned driver
  bool _isAssignedDriver(WidgetRef ref) {
    final currentUser = ref.read(currentUserProfileProvider);
    return currentUser?.id == job.driverId;
  }

  // Handle driver confirmation with safe integer parsing
  Future<void> _handleDriverConfirmation(BuildContext context, WidgetRef ref) async {
    print('=== JOB CARD: _handleDriverConfirmation() called ===');
    print('Job ID: ${job.id}');
    print('Job Status: ${job.status}');
    print('Is Confirmed: ${job.isConfirmed}');
    print('Driver Confirmation: ${job.driverConfirmation}');
    
    final jobId = int.tryParse(job.id);
    if (jobId == null) {
      print('Invalid job ID: ${job.id}');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid job ID'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    try {
      // Show loading state
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              ),
              SizedBox(width: 12),
              Text('Confirming job...'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
      
      print('Calling jobsProvider.confirmJob from job card...');
      // Use the proper jobsProvider.confirmJob method
      await ref.read(jobsProvider.notifier).confirmJob(job.id, ref: ref);
      print('jobsProvider.confirmJob completed from job card');
      
      if (!context.mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Job confirmed successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      
      // Refresh job data and notifications
      await ref.read(jobsProvider.notifier).refreshJob(job.id);
      ref.invalidate(notificationProvider);
      
      // Optional: Navigate to job progress after confirmation
      // context.go('/jobs/${job.id}/progress');
    } catch (e) {
      print('Error in job card _handleDriverConfirmation: $e');
      // Error handling driver confirmation
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('An error occurred: ${e.toString()}'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }
}