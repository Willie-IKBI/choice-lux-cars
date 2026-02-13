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
import 'package:choice_lux_cars/core/logging/log.dart';

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
  // Toggle for admin voucher/invoice buttons. Disabled by default to avoid
  // "Unexpected null value" cascade; enable via --dart-define=JOB_CARD_DOC_ACTIONS=true
  static const bool _enableDocumentActions = bool.fromEnvironment(
    'JOB_CARD_DOC_ACTIONS',
    defaultValue: false,
  );

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;
  bool _primaryButtonHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 220),
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
    try {
      return _buildJobCard(context);
    } catch (e, st) {
      Log.e('JobCard build error: $e', e, st);
      return _buildErrorFallback(context, widget.job);
    }
  }

  Widget _buildErrorFallback(BuildContext context, Job job) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Job #${job.id}', style: const TextStyle(color: ChoiceLuxTheme.platinumSilver)),
          Text(job.passengerName ?? 'Unknown', style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => context.go('/jobs/${job.id}/summary'),
            style: ElevatedButton.styleFrom(backgroundColor: ChoiceLuxTheme.richGold, foregroundColor: Colors.black),
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(BuildContext context) {
    // Watch jobs provider to get updated job data
    final jobsAsync = ref.watch(jobsProvider);
    
    // Get the updated job data if available, otherwise use the passed job.
    // Defensive: job may not be in provider list (e.g. paginated subset, post-refresh).
    final currentJob = jobsAsync.when(
      data: (jobs) => jobs.where((j) => j.id == widget.job.id).firstOrNull ?? widget.job,
      loading: () => widget.job,
      error: (_, __) => widget.job,
    );

    final screenWidth = MediaQuery.of(context).size.width;
    final spacing = ResponsiveTokens.getSpacing(screenWidth);

    final cardRadius = ResponsiveTokens.getJobCardRadius(screenWidth);
    final cardPadding = ResponsiveTokens.getJobCardPadding(screenWidth);
    final accentColor = StatusColorUtils.getJobCardAccentColor(currentJob.statusEnum);

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
                child: Container(
                  margin: EdgeInsets.all(spacing * 0.5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(cardRadius),
                    boxShadow: widget.isMobile
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: ResponsiveTokens.jobCardShadowOpacity,
                              ),
                              blurRadius: _isHovered
                                  ? ResponsiveTokens.jobCardShadowBlurHover
                                  : ResponsiveTokens.jobCardShadowBlur,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        final path = '/jobs/${currentJob.id}/summary';
                        final query = widget.fromRoute != null ? '?from=${Uri.encodeComponent(widget.fromRoute!)}' : '';
                        context.go('$path$query');
                      },
                      splashColor: ChoiceLuxTheme.richGold.withValues(alpha: 0.1),
                      highlightColor: ChoiceLuxTheme.richGold.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(cardRadius),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          gradient: ChoiceLuxTheme.cardGradient,
                          borderRadius: BorderRadius.circular(cardRadius),
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: _isHovered
                                  ? ResponsiveTokens.jobCardBorderOpacityHover
                                  : ResponsiveTokens.jobCardBorderOpacity,
                            ),
                            width: 1,
                          ),
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                width: ResponsiveTokens.jobCardAccentBarWidth,
                              decoration: BoxDecoration(
                                color: _isHovered
                                    ? accentColor.withValues(alpha: 0.9)
                                    : accentColor.withValues(alpha: 0.75),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.all(cardPadding),
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

                              // Metadata row: Date, Pax, Bags, Vehicle
                              _buildMetadataRow(context, currentJob, spacing, screenWidth),

                              SizedBox(
                                height: widget.isSmallMobile
                                    ? spacing * 0.5
                                    : spacing,
                              ),

                              // Actions: View Details (primary gold) + Voucher/Invoice (secondary outline)
                              _buildActionsSection(context, ref, currentJob, spacing, screenWidth),
                            ],
                                ),
                              ),
                            ),
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

  // Header: Status Badge + Job ID (premium subtle style)
  Widget _buildHeader(BuildContext context, Job job, double spacing, double screenWidth) {
    final statusColor = StatusColorUtils.getJobStatusColor(job.statusEnum);
    final statusLabel = job.statusEnum.label;
    final fontSize = ResponsiveTokens.getFontSize(screenWidth, baseSize: 11);

    return Row(
      children: [
        // Status pill - subtle, translucent
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: spacing * 0.6,
            vertical: spacing * 0.4,
          ),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: statusColor.withValues(alpha: 0.9),
              letterSpacing: 0.5,
            ),
          ),
        ),
        const Spacer(),
        // Job ID - smaller, muted
        Text(
          'Job #${job.id}',
          style: TextStyle(
            fontSize: fontSize * 0.9,
            fontWeight: FontWeight.w500,
            color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }

  // Primary Info: Passenger Name (title) + Location subline
  Widget _buildPrimaryInfo(BuildContext context, Job job, double spacing, double screenWidth) {
    final titleSize = ResponsiveTokens.getFontSize(screenWidth, baseSize: 18);
    final sublineSize = ResponsiveTokens.getFontSize(screenWidth, baseSize: 13);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          job.passengerName ?? 'No Passenger Name',
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w600,
            color: ChoiceLuxTheme.softWhite,
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: spacing * 0.25),
        Text(
          _formatLocation(job.location),
          style: TextStyle(
            fontSize: sublineSize,
            color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.75),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // Metadata row: Date | Pax | Bags | Vehicle (compact, scannable)
  Widget _buildMetadataRow(BuildContext context, Job job, double spacing, double screenWidth) {
    final iconSize = ResponsiveTokens.getIconSize(screenWidth) * 0.5;
    final fontSize = ResponsiveTokens.getFontSize(screenWidth, baseSize: 12);
    final mutedColor = ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.65);

    return Wrap(
      spacing: spacing * 0.75,
      runSpacing: spacing * 0.5,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _buildInfoChip(
          Icons.calendar_today,
          app_date_utils.DateUtils.formatDate(job.jobStartDate),
          iconSize,
          fontSize,
          spacing,
          mutedColor,
        ),
        _buildInfoChip(
          Icons.person,
          '${job.pasCount} pax',
          iconSize,
          fontSize,
          spacing,
          mutedColor,
        ),
        _buildInfoChip(
          Icons.work,
          '${job.luggageCount} bags',
          iconSize,
          fontSize,
          spacing,
          mutedColor,
        ),
        if (widget.vehicle != null && widget.vehicle!.model.isNotEmpty)
          _buildInfoChip(
            Icons.directions_car,
            widget.vehicle!.model,
            iconSize,
            fontSize,
            spacing,
            mutedColor,
          ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label, double iconSize, double fontSize, double spacing, [Color? iconColor]) {
    final color = iconColor ?? ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.7);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: color),
        SizedBox(width: spacing * 0.25),
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Actions: View Details (primary gold) + Voucher/Invoice (secondary outline) + Driver actions
  Widget _buildActionsSection(
    BuildContext context,
    WidgetRef ref,
    Job job,
    double spacing,
    double screenWidth,
  ) {
    final userProfile = ref.read(currentUserProfileProvider);
    final jobDriverId = job.driverId.isEmpty ? null : job.driverId;
    final shouldShowDriverConfirmation = DriverFlowUtils.shouldShowDriverConfirmationButton(
      currentUserId: userProfile?.id,
      jobDriverId: jobDriverId,
      jobStatus: job.statusEnum,
      isJobConfirmed: job.driverConfirmation == true,
    );
    final shouldShowDriverFlow = DriverFlowUtils.shouldShowDriverFlowButton(
      currentUserId: userProfile?.id,
      jobDriverId: jobDriverId,
      jobStatus: job.statusEnum,
      isJobConfirmed: job.driverConfirmation == true,
    );
    final fontSize = ResponsiveTokens.getFontSize(screenWidth, baseSize: 13);
    final iconSize = ResponsiveTokens.getIconSize(screenWidth) * 0.7;
    final hasSecondaryActions = _enableDocumentActions &&
        (widget.canCreateVoucher || widget.canCreateInvoice);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary CTA: View Details (gold only) with hover lift + shadow
        SizedBox(
          width: double.infinity,
          child: MouseRegion(
            onEnter: (_) {
              if (!widget.isMobile) setState(() => _primaryButtonHovered = true);
            },
            onExit: (_) => setState(() => _primaryButtonHovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              transform: Matrix4.translationValues(
                0,
                _primaryButtonHovered && !widget.isMobile ? -2 : 0,
                0,
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  final path = '/jobs/${job.id}/summary';
                  final query = widget.fromRoute != null ? '?from=${Uri.encodeComponent(widget.fromRoute!)}' : '';
                  context.go('$path$query');
                },
                icon: Icon(Icons.visibility, size: iconSize),
                label: Text('View Details', style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ChoiceLuxTheme.richGold,
                  foregroundColor: Colors.black,
                  elevation: _primaryButtonHovered && !widget.isMobile ? 8 : 4,
                  padding: EdgeInsets.symmetric(horizontal: spacing, vertical: spacing * 0.75),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
        ),
        // Secondary: Voucher + Invoice (outline, inline)
        if (hasSecondaryActions) ...[
          SizedBox(height: spacing * 0.5),
          Wrap(
            spacing: spacing * 0.5,
            runSpacing: spacing * 0.5,
            children: [
              if (widget.canCreateVoucher)
                VoucherActionButtons(
                  jobId: job.id.toString(),
                  voucherPdfUrl: job.voucherPdf,
                  voucherData: null,
                  canCreateVoucher: widget.canCreateVoucher,
                  compact: true,
                ),
              if (widget.canCreateInvoice)
                InvoiceActionButtons(
                  jobId: job.id.toString(),
                  invoicePdfUrl: job.invoicePdf,
                  invoiceData: null,
                  canCreateInvoice: widget.canCreateInvoice,
                  compact: true,
                ),
            ],
          ),
        ],
        // Driver actions (if applicable)
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
                      label: Text('Confirm Job', style: TextStyle(fontSize: fontSize)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ChoiceLuxTheme.orange,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: spacing, vertical: spacing * 0.75),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                if (shouldShowDriverFlow) ...[
                  if (shouldShowDriverConfirmation) SizedBox(height: spacing * 0.5),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleDriverFlow(context, ref, job),
                      icon: Icon(DriverFlowUtils.getDriverFlowIcon(job.statusEnum), size: 16),
                      label: Text(DriverFlowUtils.getDriverFlowText(job.statusEnum), style: TextStyle(fontSize: fontSize)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DriverFlowUtils.getDriverFlowColor(job.statusEnum),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: spacing, vertical: spacing * 0.75),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ],
            )
          else
            Wrap(
              spacing: spacing,
              runSpacing: spacing * 0.5,
              children: [
                if (shouldShowDriverConfirmation)
                  SizedBox(
                    width: widget.isTablet ? 220 : 260,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleDriverConfirmation(context, ref, job),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: Text('Confirm Job', style: TextStyle(fontSize: fontSize)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ChoiceLuxTheme.orange,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: spacing, vertical: spacing * 0.75),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                if (shouldShowDriverFlow)
                  SizedBox(
                    width: widget.isTablet ? 220 : 260,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleDriverFlow(context, ref, job),
                      icon: Icon(DriverFlowUtils.getDriverFlowIcon(job.statusEnum), size: 16),
                      label: Text(DriverFlowUtils.getDriverFlowText(job.statusEnum), style: TextStyle(fontSize: fontSize)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DriverFlowUtils.getDriverFlowColor(job.statusEnum),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: spacing, vertical: spacing * 0.75),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
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
