import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/jobs/models/job.dart';
import 'package:choice_lux_cars/features/clients/models/client.dart';
import 'package:choice_lux_cars/features/vehicles/models/vehicle.dart';
import 'package:choice_lux_cars/features/users/models/user.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';
import 'package:choice_lux_cars/shared/utils/status_color_utils.dart';
import 'package:choice_lux_cars/shared/utils/date_utils.dart' as app_date_utils;
import 'package:choice_lux_cars/shared/utils/driver_flow_utils.dart';
import 'package:choice_lux_cars/features/jobs/providers/jobs_provider.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/features/vouchers/widgets/voucher_action_buttons.dart';
import 'package:choice_lux_cars/features/invoices/widgets/invoice_action_buttons.dart';

class JobCard extends ConsumerStatefulWidget {
  final Job job;
  final Client? client;
  final Vehicle? vehicle;
  final User? driver;
  final bool isSmallMobile;
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;
  final bool canCreateVoucher;
  final bool canCreateInvoice;
  /// When set (e.g. 'operations'), job summary back button goes to that route.
  final String? fromRoute;

  const JobCard({
    super.key,
    required this.job,
    this.client,
    this.vehicle,
    this.driver,
    required this.isSmallMobile,
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
    this.canCreateVoucher = false,
    this.canCreateInvoice = false,
    this.fromRoute,
  });

  @override
  ConsumerState<JobCard> createState() => _JobCardState();
}

class _JobCardState extends ConsumerState<JobCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    if (widget.isMobile) return; // No hover on mobile
    setState(() {
      _isHovered = isHovered;
    });
    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch jobs provider to get updated job data
    final jobsAsync = ref.watch(jobsProvider);
    
    // Get the updated job data if available, otherwise use the passed job
    final currentJob = jobsAsync.when(
      data: (jobs) => jobs.firstWhere(
        (j) => j.id == widget.job.id,
        orElse: () => widget.job,
      ),
      loading: () => widget.job,
      error: (_, __) => widget.job,
    );

    final screenWidth = MediaQuery.of(context).size.width;
    final spacing = ResponsiveTokens.getSpacing(screenWidth);
    final padding = ResponsiveTokens.getPadding(screenWidth);
    final cornerRadius = ResponsiveTokens.getCornerRadius(screenWidth);

    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          onEnter: (_) => _onHover(true),
          onExit: (_) => _onHover(false),
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.isMobile ? 1.0 : _scaleAnimation.value,
                child: Card(
                  margin: EdgeInsets.all(spacing * 0.5),
                  elevation: _isHovered ? 8 : 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(cornerRadius),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    decoration: BoxDecoration(
                      color: ChoiceLuxTheme.charcoalGray,
                      borderRadius: BorderRadius.circular(cornerRadius),
                      border: Border.all(
                        color: _isHovered
                            ? ChoiceLuxTheme.platinumSilver.withOpacity(0.08)
                            : ChoiceLuxTheme.platinumSilver.withOpacity(0.05),
                        width: 1,
                      ),
                      boxShadow: widget.isMobile
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(cornerRadius),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          final path = '/jobs/${currentJob.id}/summary';
                          final query = widget.fromRoute != null ? '?from=${Uri.encodeComponent(widget.fromRoute!)}' : '';
                          context.go('$path$query');
                        },
                        splashColor: ChoiceLuxTheme.richGold.withOpacity(0.1),
                        highlightColor: ChoiceLuxTheme.richGold.withOpacity(
                          0.05,
                        ),
                        borderRadius: BorderRadius.circular(cornerRadius),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            widget.isSmallMobile
                                ? padding * 0.5
                                : widget.isMobile
                                ? padding * 0.75
                                : padding,
                            widget.isSmallMobile
                                ? padding * 0.5
                                : widget.isMobile
                                ? padding * 0.75
                                : padding,
                            widget.isSmallMobile
                                ? padding * 0.5
                                : widget.isMobile
                                ? padding * 0.75
                                : padding,
                            widget.isSmallMobile
                                ? padding * 0.4
                                : widget.isMobile
                                ? padding * 0.6
                                : padding * 0.8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Header: Status badge + Job ID
                              _buildHeader(context, currentJob, spacing, screenWidth),
                              
                              SizedBox(
                                height: widget.isSmallMobile
                                    ? spacing * 0.5
                                    : spacing,
                              ),

                              // Primary Info: Passenger Name
                              _buildPrimaryInfo(context, currentJob, spacing, screenWidth),

                              SizedBox(
                                height: widget.isSmallMobile
                                    ? spacing * 0.25
                                    : spacing * 0.5,
                              ),

                              // Secondary Info: Location, Date
                              _buildSecondaryInfo(context, currentJob, spacing, screenWidth),

                              SizedBox(
                                height: widget.isSmallMobile
                                    ? spacing * 0.25
                                    : spacing * 0.5,
                              ),

                              // Tertiary Info: Pax, Luggage, Vehicle
                              _buildTertiaryInfo(context, currentJob, spacing, screenWidth),

                              SizedBox(
                                height: widget.isSmallMobile
                                    ? spacing * 0.5
                                    : spacing,
                              ),

                              // PDF Actions (Voucher & Invoice)
                              if (widget.canCreateVoucher || widget.canCreateInvoice)
                                _buildPdfActions(context, ref, currentJob, spacing, screenWidth),

                              SizedBox(
                                height: widget.isSmallMobile
                                    ? spacing * 0.5
                                    : spacing,
                              ),

                              // Action Buttons
                              _buildActionButtons(context, ref, currentJob, spacing, screenWidth),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Header: Status Badge + Job ID
  Widget _buildHeader(BuildContext context, Job job, double spacing, double screenWidth) {
    final statusColor = StatusColorUtils.getJobStatusColor(job.statusEnum);
    final statusLabel = job.statusEnum.label;
    final fontSize = ResponsiveTokens.getFontSize(screenWidth, baseSize: 12);

    return Row(
      children: [
        // Status Badge
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: spacing * 0.75,
            vertical: spacing * 0.5,
          ),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: statusColor.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: spacing * 0.5),
              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Job ID
        Text(
          'Job #${job.id}',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: ChoiceLuxTheme.platinumSilver.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  // Primary Info: Passenger Name
  Widget _buildPrimaryInfo(BuildContext context, Job job, double spacing, double screenWidth) {
    final fontSize = ResponsiveTokens.getFontSize(screenWidth, baseSize: 18);

    return Text(
      job.passengerName ?? 'No Passenger Name',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: ChoiceLuxTheme.softWhite,
        height: 1.2,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  // Secondary Info: Location, Date
  Widget _buildSecondaryInfo(BuildContext context, Job job, double spacing, double screenWidth) {
    final iconSize = ResponsiveTokens.getIconSize(screenWidth) * 0.6;
    final fontSize = ResponsiveTokens.getFontSize(screenWidth, baseSize: 13);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location
        Row(
          children: [
            Icon(
              Icons.location_on,
              size: iconSize,
              color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7),
            ),
            SizedBox(width: spacing * 0.25),
            Expanded(
              child: Text(
                _formatLocation(job.location),
                style: TextStyle(
                  fontSize: fontSize,
                  color: ChoiceLuxTheme.platinumSilver.withOpacity(0.8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: spacing * 0.25),
        // Date
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: iconSize * 0.85,
              color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7),
            ),
            SizedBox(width: spacing * 0.25),
            Text(
              app_date_utils.DateUtils.formatDate(job.jobStartDate),
              style: TextStyle(
                fontSize: fontSize * 0.9,
                color: ChoiceLuxTheme.platinumSilver.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Tertiary Info: Pax, Luggage, Vehicle
  Widget _buildTertiaryInfo(BuildContext context, Job job, double spacing, double screenWidth) {
    final iconSize = ResponsiveTokens.getIconSize(screenWidth) * 0.5;
    final fontSize = ResponsiveTokens.getFontSize(screenWidth, baseSize: 12);

    return Wrap(
      spacing: spacing * 0.75,
      runSpacing: spacing * 0.5,
      children: [
        _buildInfoChip(
          Icons.person,
          '${job.pasCount} pax',
          iconSize,
          fontSize,
          spacing,
        ),
        _buildInfoChip(
          Icons.work,
          '${job.luggageCount} bags',
          iconSize,
          fontSize,
          spacing,
        ),
        if (widget.vehicle?.model != null)
          _buildInfoChip(
            Icons.directions_car,
            widget.vehicle!.model,
            iconSize,
            fontSize,
            spacing,
          ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label, double iconSize, double fontSize, double spacing) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: iconSize,
          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7),
        ),
        SizedBox(width: spacing * 0.25),
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            color: ChoiceLuxTheme.platinumSilver.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // PDF Actions (Voucher & Invoice)
  Widget _buildPdfActions(
    BuildContext context,
    WidgetRef ref,
    Job job,
    double spacing,
    double screenWidth,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.canCreateVoucher) ...[
          VoucherActionButtons(
            jobId: job.id.toString(),
            voucherPdfUrl: job.voucherPdf,
            voucherData: null,
            canCreateVoucher: widget.canCreateVoucher,
          ),
          if (widget.canCreateInvoice) SizedBox(height: spacing),
        ],
        if (widget.canCreateInvoice)
          InvoiceActionButtons(
            jobId: job.id.toString(),
            invoicePdfUrl: job.invoicePdf,
            invoiceData: null,
            canCreateInvoice: widget.canCreateInvoice,
          ),
      ],
    );
  }

  // Action Buttons
  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    Job job,
    double spacing,
    double screenWidth,
  ) {
    final userProfile = ref.read(currentUserProfileProvider);
    final shouldShowDriverConfirmation = DriverFlowUtils.shouldShowDriverConfirmationButton(
      currentUserId: userProfile?.id,
      jobDriverId: job.driverId,
      jobStatus: job.statusEnum,
      isJobConfirmed: job.driverConfirmation == true,
    );
    final shouldShowDriverFlow = DriverFlowUtils.shouldShowDriverFlowButton(
      currentUserId: userProfile?.id,
      jobDriverId: job.driverId,
      jobStatus: job.statusEnum,
      isJobConfirmed: job.driverConfirmation == true,
    );

    final fontSize = ResponsiveTokens.getFontSize(screenWidth, baseSize: 13);
    final iconSize = ResponsiveTokens.getIconSize(screenWidth) * 0.7;

    return Column(
      children: [
        // Primary Action: View Details
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.go('/jobs/${job.id}/summary'),
            icon: Icon(
              Icons.visibility,
              size: iconSize,
            ),
            label: Text(
              'View Details',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
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

        // Driver Actions (if applicable)
        if (shouldShowDriverConfirmation || shouldShowDriverFlow) ...[
          SizedBox(height: spacing * 0.5),
          if (widget.isSmallMobile || widget.isMobile)
            Column(
              children: [
                if (shouldShowDriverConfirmation)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleDriverConfirmation(context, ref, job),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: Text(
                        'Confirm Job',
                        style: TextStyle(fontSize: fontSize),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ChoiceLuxTheme.orange,
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
                if (shouldShowDriverFlow) ...[
                  if (shouldShowDriverConfirmation) SizedBox(height: spacing * 0.5),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleDriverFlow(context, ref, job),
                      icon: Icon(
                        DriverFlowUtils.getDriverFlowIcon(job.statusEnum),
                        size: 16,
                      ),
                      label: Text(
                        DriverFlowUtils.getDriverFlowText(job.statusEnum),
                        style: TextStyle(fontSize: fontSize),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DriverFlowUtils.getDriverFlowColor(job.statusEnum),
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
                ],
              ],
            )
          else
            Row(
              children: [
                if (shouldShowDriverConfirmation)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleDriverConfirmation(context, ref, job),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: Text(
                        'Confirm Job',
                        style: TextStyle(fontSize: fontSize),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ChoiceLuxTheme.orange,
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
                if (shouldShowDriverFlow) ...[
                  if (shouldShowDriverConfirmation) SizedBox(width: spacing),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleDriverFlow(context, ref, job),
                      icon: Icon(
                        DriverFlowUtils.getDriverFlowIcon(job.statusEnum),
                        size: 16,
                      ),
                      label: Text(
                        DriverFlowUtils.getDriverFlowText(job.statusEnum),
                        style: TextStyle(fontSize: fontSize),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DriverFlowUtils.getDriverFlowColor(job.statusEnum),
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
                ],
              ],
            ),
        ],
      ],
    );
  }

  // Helper Methods
  String _formatLocation(String? location) {
    if (location == null || location.isEmpty) {
      return 'Location not specified';
    }
    
    switch (location.toUpperCase()) {
      case 'JHB':
        return 'Johannesburg';
      case 'CPT':
        return 'Cape Town';
      case 'DBN':
        return 'Durban';
      case 'PTA':
        return 'Pretoria';
      default:
        return location;
    }
  }

  Future<void> _handleDriverFlow(BuildContext context, WidgetRef ref, Job job) async {
    try {
      final route = DriverFlowUtils.getDriverFlowRoute(
        int.parse(job.id.toString()),
        job.statusEnum,
      );

      if (context.mounted) {
        context.go(route);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to navigate to driver flow: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDriverConfirmation(BuildContext context, WidgetRef ref, Job job) async {
    try {
      await ref.read(jobsProvider.notifier).confirmJob(job.id.toString());
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job confirmed successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to confirm job: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
