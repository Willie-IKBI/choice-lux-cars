import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/jobs/models/job.dart';
import 'package:choice_lux_cars/features/clients/models/client.dart';
import 'package:choice_lux_cars/features/vehicles/vehicles.dart';
import 'package:choice_lux_cars/features/users/users.dart';
import 'package:choice_lux_cars/features/vouchers/vouchers.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/features/jobs/services/driver_flow_api_service.dart';
import 'package:choice_lux_cars/features/jobs/providers/jobs_provider.dart';
import 'package:choice_lux_cars/features/notifications/notifications.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';
import 'package:choice_lux_cars/shared/widgets/status_pill.dart';
import 'package:choice_lux_cars/shared/utils/driver_flow_utils.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

/// Centralized constants for JobCard widget to eliminate magic numbers
class JobCardConstants {
  // Responsive sizing multipliers
  static const double paddingMultiplier = 0.75;
  static const double spacingMultiplier = 0.75;
  static const double iconSizeMultiplier = 0.8;
  static const double baseFontSize = 12.0;

  // Card styling
  static const double cardElevationMobile = 2.0;
  static const double cardElevationDesktop = 1.0;
  static const double shadowAlpha = 0.1;
  static const double borderAlpha = 0.15;
  static const double borderWidth = 0.5;

  // Chip styling
  static const double chipHeightSmallMobile = 16.0;
  static const double chipHeightMobile = 18.0;
  static const double chipHeightDesktop = 20.0;
  static const double chipPaddingHorizontalSmallMobile = 4.0;
  static const double chipPaddingHorizontalMobile = 5.0;
  static const double chipPaddingHorizontalDesktop = 6.0;
  static const double chipFontSizeOffset = 3.0;
  static const double chipSpacingSmallMobile = 2.0;
  static const double chipSpacingMobile = 3.0;
  static const double chipSpacingDesktop = 4.0;

  // Container styling
  static const double containerBackgroundAlpha = 0.06;
  static const double containerBorderAlpha = 0.15;
  static const double containerBorderRadiusSmallMobile = 4.0;
  static const double containerBorderRadiusMobile = 5.0;
  static const double containerBorderRadiusDesktop = 6.0;
  static const double containerPaddingSmallMobile = 6.0;
  static const double containerPaddingMobile = 7.0;
  static const double containerPaddingDesktop = 8.0;
  static const double containerInnerSpacingSmallMobile = 2.0;
  static const double containerInnerSpacingMobile = 3.0;
  static const double containerInnerSpacingDesktop = 4.0;

  // Button styling
  static const double buttonPaddingVertical = 6.0;
  static const double buttonPaddingHorizontal = 8.0;
  static const double buttonBorderRadius = 4.0;
  static const double buttonIconSizeMultiplier = 0.8;
  static const double buttonFontSizeOffset = 1.0;

  // Confirmation styling
  static const double confirmationPaddingVertical = 4.0;
  static const double confirmationPaddingHorizontal = 8.0;
  static const double confirmationBorderRadius = 4.0;
  static const double confirmationIconSizeMultiplier = 0.7;
  static const double confirmationSpacing = 4.0;
  static const double confirmationBackgroundAlpha = 0.1;
  static const double confirmationBorderAlpha = 0.3;

  // Text styling
  static const double titleFontSizeOffset = 1.0;
  static const double titleLineHeight = 1.1;
  static const double detailFontSizeOffset = 1.0;
  static const double detailIconAlpha = 0.7;
  static const double detailLabelAlpha = 0.6;

  // Metric styling
  static const double metricBackgroundAlpha = 0.08;
  static const double metricBorderAlpha = 0.2;
  static const double metricBorderRadiusSmallMobile = 6.0;
  static const double metricBorderRadiusMobile = 7.0;
  static const double metricBorderRadiusDesktop = 8.0;
  static const double metricPaddingHorizontalSmallMobile = 4.0;
  static const double metricPaddingHorizontalMobile = 5.0;
  static const double metricPaddingHorizontalDesktop = 6.0;
  static const double metricPaddingVerticalSmallMobile = 2.0;
  static const double metricPaddingVerticalMobile = 3.0;
  static const double metricPaddingVerticalDesktop = 4.0;
  static const double metricIconSizeMultiplier = 0.6;
  static const double metricFontSizeOffset = 2.0;
  static const double metricTileSpacing = 6.0;
  static const double metricTileInnerSpacingSmallMobile = 1.0;
  static const double metricTileInnerSpacingMobile = 2.0;
  static const double metricTilePaddingSmallMobile = 4.0;
  static const double metricTilePaddingMobile = 5.0;
  static const double metricTilePaddingDesktop = 6.0;
  static const double metricTileBackgroundAlpha = 0.06;
  static const double metricTileBorderAlpha = 0.15;
  static const double metricTileBorderRadiusSmallMobile = 4.0;
  static const double metricTileBorderRadiusMobile = 5.0;
  static const double metricTileBorderRadiusDesktop = 6.0;
  static const double metricTileIconSizeMultiplier = 0.8;
  static const double metricTileValueAlpha = 0.7;

  // Spacing
  static const double actionButtonSpacing = 6.0;
  static const double confirmationButtonSpacing = 8.0;
  static const double footerMarginTopSmallMobile = 2.0;
  static const double footerMarginTopMobile = 3.0;
  static const double footerMarginTopDesktop = 4.0;
  static const double footerPaddingVerticalSmallMobile = 2.0;
  static const double footerPaddingVerticalMobile = 3.0;
  static const double footerPaddingVerticalDesktop = 4.0;

  // Error handling
  static const Duration snackBarDurationShort = Duration(seconds: 2);
  static const Duration snackBarDurationMedium = Duration(seconds: 3);
  static const Duration snackBarDurationLong = Duration(seconds: 4);

  // Default values
  static const String defaultPassengerName = 'Unnamed Job';
  static const String defaultClientName = 'Unknown Client';
  static const String defaultDriverName = 'Unassigned';
  static const String defaultVehicleName = 'Vehicle not assigned';
  static const String defaultJobNumberPrefix = 'Job #';
}

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
        final padding =
            ResponsiveTokens.getPadding(screenWidth) *
            JobCardConstants.paddingMultiplier;
        final spacing =
            ResponsiveTokens.getSpacing(screenWidth) *
            JobCardConstants.spacingMultiplier;
        final cornerRadius = ResponsiveTokens.getCornerRadius(screenWidth);
        final iconSize =
            ResponsiveTokens.getIconSize(screenWidth) *
            JobCardConstants.iconSizeMultiplier;
        final fontSize = ResponsiveTokens.getFontSize(
          screenWidth,
          baseSize: JobCardConstants.baseFontSize,
        );

        return Card(
          margin: EdgeInsets.all(spacing * 0.5),
          elevation: isMobile
              ? JobCardConstants.cardElevationMobile
              : JobCardConstants.cardElevationDesktop,
          shadowColor: Colors.black.withValues(
            alpha: JobCardConstants.shadowAlpha,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cornerRadius),
          ),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(cornerRadius),
              gradient: ChoiceLuxTheme.cardGradient,
              border: Border.all(
                color: ChoiceLuxTheme.richGold.withValues(
                  alpha: JobCardConstants.borderAlpha,
                ),
                width: JobCardConstants.borderWidth,
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

                  SizedBox(height: spacing * 0.5),

                  // Title row: passenger/job title
                  _buildTitleRow(isMobile, isSmallMobile, fontSize),

                  SizedBox(height: spacing * 0.5),

                  // Details block: key fields - Use Flexible instead of Expanded
                  Flexible(
                    child: _buildDetailsBlock(
                      isMobile,
                      isSmallMobile,
                      iconSize,
                      fontSize,
                    ),
                  ),

                  SizedBox(height: spacing * 0.5),

                  // Metrics row: stat tiles - More compact
                  _buildMetricsRow(isMobile, isSmallMobile, iconSize, fontSize),

                  SizedBox(height: spacing * 0.5),

                  // Progress row: show current step and progress for in-progress jobs
                  if (job.statusEnum == JobStatus.started ||
                      job.statusEnum == JobStatus.inProgress)
                    _buildProgressRow(
                      isMobile,
                      isSmallMobile,
                      iconSize,
                      fontSize,
                    ),

                  if (job.statusEnum == JobStatus.started ||
                      job.statusEnum == JobStatus.inProgress)
                    SizedBox(height: spacing * 0.5),

                  // Action row: buttons - More compact
                  _buildActionRow(
                    context,
                    ref,
                    isMobile,
                    isSmallMobile,
                    iconSize,
                    fontSize,
                  ),

                  SizedBox(height: spacing * 0.5),

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
  Widget _buildStatusRow(
    bool isMobile,
    bool isSmallMobile,
    double iconSize,
    double fontSize,
  ) {
    final chipHeight = isSmallMobile
        ? JobCardConstants.chipHeightSmallMobile
        : isMobile
        ? JobCardConstants.chipHeightMobile
        : JobCardConstants.chipHeightDesktop;
    final chipPadding = EdgeInsets.symmetric(
      horizontal: isSmallMobile
          ? JobCardConstants.chipPaddingHorizontalSmallMobile
          : isMobile
          ? JobCardConstants.chipPaddingHorizontalMobile
          : JobCardConstants.chipPaddingHorizontalDesktop,
    );
    final chipFontSize = fontSize - JobCardConstants.chipFontSizeOffset;
    final chipSpacing = isSmallMobile
        ? JobCardConstants.chipSpacingSmallMobile
        : isMobile
        ? JobCardConstants.chipSpacingMobile
        : JobCardConstants.chipSpacingDesktop;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // First line: status chips
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: chipSpacing,
                runSpacing: chipSpacing,
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
            SizedBox(width: chipSpacing),
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
          SizedBox(height: chipSpacing * 0.5),
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
        : JobCardConstants.defaultPassengerName;

    return Text(
      passenger,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: fontSize + JobCardConstants.titleFontSizeOffset,
        color: ChoiceLuxTheme.softWhite,
        height: JobCardConstants.titleLineHeight,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  // Details block: 3-4 key fields (each 1 line, ellipsis)
  Widget _buildDetailsBlock(
    bool isMobile,
    bool isSmallMobile,
    double iconSize,
    double fontSize,
  ) {
    final blockPadding = isSmallMobile
        ? JobCardConstants.containerPaddingSmallMobile
        : isMobile
        ? JobCardConstants.containerPaddingMobile
        : JobCardConstants.containerPaddingDesktop;
    final innerSpacing = isSmallMobile
        ? JobCardConstants.containerInnerSpacingSmallMobile
        : isMobile
        ? JobCardConstants.containerInnerSpacingMobile
        : JobCardConstants.containerInnerSpacingDesktop;
    final borderRadius = isSmallMobile
        ? JobCardConstants.containerBorderRadiusSmallMobile
        : isMobile
        ? JobCardConstants.containerBorderRadiusMobile
        : JobCardConstants.containerBorderRadiusDesktop;

    return Container(
      padding: EdgeInsets.all(blockPadding),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(
          alpha: JobCardConstants.containerBackgroundAlpha,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.grey.withValues(
            alpha: JobCardConstants.containerBorderAlpha,
          ),
          width: JobCardConstants.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Job Details',
            style: TextStyle(
              fontSize: fontSize - JobCardConstants.detailFontSizeOffset,
              fontWeight: FontWeight.w600,
              color: ChoiceLuxTheme.platinumSilver,
            ),
          ),
          SizedBox(height: innerSpacing),
          _buildDetailRow(
            Icons.business,
            'Client',
            client?.companyName ?? JobCardConstants.defaultClientName,
            isMobile,
            isSmallMobile,
            iconSize,
            fontSize,
          ),
          SizedBox(height: innerSpacing),
          _buildDetailRow(
            Icons.person,
            'Driver',
            driver?.displayName ?? JobCardConstants.defaultDriverName,
            isMobile,
            isSmallMobile,
            iconSize,
            fontSize,
          ),
          SizedBox(height: innerSpacing),
          _buildDetailRow(
            Icons.directions_car,
            'Vehicle',
            vehicle != null
                ? '${vehicle!.make} ${vehicle!.model}'
                : JobCardConstants.defaultVehicleName,
            isMobile,
            isSmallMobile,
            iconSize,
            fontSize,
          ),
          if (!isMobile) ...[
            SizedBox(height: innerSpacing),
            _buildDetailRow(
              Icons.tag,
              'Job Number',
              '${JobCardConstants.defaultJobNumberPrefix}${job.id}',
              isMobile,
              isSmallMobile,
              iconSize,
              fontSize,
            ),
          ],
        ],
      ),
    );
  }

  // Metrics row: two small stat tiles (Passengers/Bags)
  Widget _buildMetricsRow(
    bool isMobile,
    bool isSmallMobile,
    double iconSize,
    double fontSize,
  ) {
    // These fields are not nullable in the Job model
    final pax = job.pasCount;
    final bags = job.luggageCount;

    if (isMobile) {
      // Mobile: collapse into small pills
      return Row(
        children: [
          _buildCompactMetricPill(
            Icons.people,
            '$pax pax',
            isMobile,
            isSmallMobile,
            iconSize,
            fontSize,
          ),
          SizedBox(
            width: isSmallMobile
                ? JobCardConstants.chipSpacingSmallMobile
                : JobCardConstants.chipSpacingMobile,
          ),
          _buildCompactMetricPill(
            Icons.work,
            '$bags bags',
            isMobile,
            isSmallMobile,
            iconSize,
            fontSize,
          ),
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
              ChoiceLuxTheme.infoColor,
              isMobile,
              isSmallMobile,
              iconSize,
              fontSize,
            ),
          ),
          const SizedBox(width: JobCardConstants.metricTileSpacing),
          Expanded(
            child: _buildMetricTile(
              Icons.work,
              'Bags',
              bags,
              ChoiceLuxTheme.infoColor,
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

  // Progress row: show current step and progress percentage for in-progress jobs
  Widget _buildProgressRow(
    bool isMobile,
    bool isSmallMobile,
    double iconSize,
    double fontSize,
  ) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: DriverFlowApiService.getJobProgress(job.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.symmetric(
              vertical: JobCardConstants.metricPaddingVerticalMobile,
              horizontal: JobCardConstants.metricPaddingHorizontalMobile,
            ),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.richGold.withValues(alpha: 
                JobCardConstants.metricBackgroundAlpha,
              ),
              borderRadius: BorderRadius.circular(
                JobCardConstants.metricBorderRadiusMobile,
              ),
              border: Border.all(
                color: ChoiceLuxTheme.richGold.withValues(alpha: 
                  JobCardConstants.metricBorderAlpha,
                ),
                width: JobCardConstants.borderWidth,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: iconSize * JobCardConstants.metricIconSizeMultiplier,
                  height: iconSize * JobCardConstants.metricIconSizeMultiplier,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ChoiceLuxTheme.richGold,
                    ),
                  ),
                ),
                const SizedBox(width: JobCardConstants.metricTileInnerSpacingMobile),
                Text(
                  'Loading progress...',
                  style: TextStyle(
                    fontSize: fontSize - JobCardConstants.metricFontSizeOffset,
                    color: ChoiceLuxTheme.richGold,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final progressData = snapshot.data!;
        final currentStep =
            progressData['current_step']?.toString() ?? 'vehicle_collection';
        final progressPercentage =
            progressData['progress_percentage']?.toDouble() ?? 0.0;

        final stepTitle = DriverFlowUtils.getStepTitle(currentStep);
        final stepIcon = DriverFlowUtils.getStepIcon(currentStep);

        return Container(
          padding: const EdgeInsets.symmetric(
            vertical: JobCardConstants.metricPaddingVerticalMobile,
            horizontal: JobCardConstants.metricPaddingHorizontalMobile,
          ),
          decoration: BoxDecoration(
            color: ChoiceLuxTheme.richGold.withValues(alpha: 
              JobCardConstants.metricBackgroundAlpha,
            ),
            borderRadius: BorderRadius.circular(
              JobCardConstants.metricBorderRadiusMobile,
            ),
            border: Border.all(
              color: ChoiceLuxTheme.richGold.withValues(alpha: 
                JobCardConstants.metricBorderAlpha,
              ),
              width: JobCardConstants.borderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    stepIcon,
                    size: iconSize * JobCardConstants.metricIconSizeMultiplier,
                    color: ChoiceLuxTheme.richGold,
                  ),
                  const SizedBox(
                    width: JobCardConstants.metricTileInnerSpacingMobile,
                  ),
                  Expanded(
                    child: Text(
                      stepTitle,
                      style: TextStyle(
                        fontSize:
                            fontSize - JobCardConstants.metricFontSizeOffset,
                        color: ChoiceLuxTheme.richGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${progressPercentage.toInt()}%',
                    style: TextStyle(
                      fontSize:
                          fontSize - JobCardConstants.metricFontSizeOffset,
                      color: ChoiceLuxTheme.richGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: JobCardConstants.metricTileInnerSpacingMobile),
              LinearProgressIndicator(
                value: progressPercentage / 100.0,
                backgroundColor: ChoiceLuxTheme.richGold.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  ChoiceLuxTheme.richGold,
                ),
                minHeight: 4,
              ),
            ],
          ),
        );
      },
    );
  }

  // Action row: Primary (Start Job), secondary (View)
  Widget _buildActionRow(
    BuildContext context,
    WidgetRef ref,
    bool isMobile,
    bool isSmallMobile,
    double iconSize,
    double fontSize,
  ) {
    final isAssignedDriver = _isAssignedDriver(ref);
    final isConfirmed =
        job.isConfirmed == true || job.driverConfirmation == true;
    final needsConfirmation = isAssignedDriver && !isConfirmed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Confirmation Status - Show for assigned driver
        if (isAssignedDriver) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: JobCardConstants.confirmationPaddingVertical,
              horizontal: JobCardConstants.confirmationPaddingHorizontal,
            ),
            decoration: BoxDecoration(
              color: isConfirmed
                  ? ChoiceLuxTheme.successColor.withValues(
                      alpha: JobCardConstants.confirmationBackgroundAlpha,
                    )
                  : ChoiceLuxTheme.orange.withValues(
                      alpha: JobCardConstants.confirmationBackgroundAlpha,
                    ),
              borderRadius: BorderRadius.circular(
                JobCardConstants.confirmationBorderRadius,
              ),
              border: Border.all(
                color: isConfirmed
                    ? ChoiceLuxTheme.successColor.withValues(
                        alpha: JobCardConstants.confirmationBorderAlpha,
                      )
                    : ChoiceLuxTheme.orange.withValues(
                        alpha: JobCardConstants.confirmationBorderAlpha,
                      ),
                width: JobCardConstants.borderWidth,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isConfirmed ? Icons.check_circle : Icons.pending,
                  size:
                      iconSize *
                      JobCardConstants.confirmationIconSizeMultiplier,
                  color: isConfirmed
                      ? ChoiceLuxTheme.successColor
                      : ChoiceLuxTheme.orange,
                ),
                const SizedBox(width: JobCardConstants.confirmationSpacing),
                Text(
                  isConfirmed ? 'Job Confirmed' : 'Awaiting Confirmation',
                  style: TextStyle(
                    fontSize: fontSize - JobCardConstants.detailFontSizeOffset,
                    color: isConfirmed
                        ? ChoiceLuxTheme.successColor
                        : ChoiceLuxTheme.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: JobCardConstants.confirmationButtonSpacing),
        ],

        // Confirm Button - Show only for assigned driver who hasn't confirmed
        if (needsConfirmation) ...[
          ElevatedButton.icon(
            key: Key('confirmJobBtn_${job.id}'),
            onPressed: () => _handleDriverConfirmation(context, ref),
            icon: Icon(
              Icons.check_circle,
              size: iconSize * JobCardConstants.buttonIconSizeMultiplier,
            ),
            label: Text(
              'Confirm Job',
              style: TextStyle(
                fontSize: fontSize - JobCardConstants.buttonFontSizeOffset,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: ChoiceLuxTheme.orange.withValues(
                alpha: JobCardConstants.confirmationBackgroundAlpha,
              ),
              foregroundColor: ChoiceLuxTheme.orange,
              padding: const EdgeInsets.symmetric(
                vertical: JobCardConstants.buttonPaddingVertical,
                horizontal: JobCardConstants.buttonPaddingHorizontal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  JobCardConstants.buttonBorderRadius,
                ),
              ),
            ),
          ),
          const SizedBox(height: JobCardConstants.confirmationButtonSpacing),
        ],

        // Action buttons row
        Row(
          children: [
            // Driver Flow Button - Show only for assigned driver and when appropriate
            if (DriverFlowUtils.shouldShowDriverFlowButton(
              currentUserId: ref.read(currentUserProfileProvider)?.id,
              jobDriverId: job.driverId,
              jobStatus: job.statusEnum,
              isJobConfirmed: isConfirmed,
            )) ...[
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
                    DriverFlowUtils.getDriverFlowIcon(job.statusEnum),
                    size: iconSize * JobCardConstants.buttonIconSizeMultiplier,
                  ),
                  label: Text(
                    DriverFlowUtils.getDriverFlowText(job.statusEnum),
                    style: TextStyle(
                      fontSize:
                          fontSize - JobCardConstants.buttonFontSizeOffset,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        DriverFlowUtils.getDriverFlowColor(
                          job.statusEnum,
                        ).withValues(
                          alpha: JobCardConstants.confirmationBackgroundAlpha,
                        ),
                    foregroundColor: DriverFlowUtils.getDriverFlowColor(
                      job.statusEnum,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: JobCardConstants.buttonPaddingVertical,
                      horizontal: JobCardConstants.buttonPaddingHorizontal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        JobCardConstants.buttonBorderRadius,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: JobCardConstants.actionButtonSpacing),
            ],

            // View Button
            Expanded(
              child: TextButton.icon(
                key: Key('viewJobBtn_${job.id}'),
                onPressed: () {
                  context.go('/jobs/${job.id}/summary');
                },
                icon: Icon(
                  Icons.arrow_forward,
                  size: iconSize * JobCardConstants.buttonIconSizeMultiplier,
                ),
                label: Text(
                  _getActionText(job.statusEnum),
                  style: TextStyle(
                    fontSize: fontSize - JobCardConstants.buttonFontSizeOffset,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: job.statusEnum.color,
                  backgroundColor: job.statusEnum.color.withValues(
                    alpha: JobCardConstants.confirmationBackgroundAlpha,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: JobCardConstants.buttonPaddingVertical,
                    horizontal: JobCardConstants.buttonPaddingHorizontal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      JobCardConstants.buttonBorderRadius,
                    ),
                    side: BorderSide(
                      color: job.statusEnum.color.withValues(
                        alpha: JobCardConstants.confirmationBorderAlpha,
                      ),
                      width: JobCardConstants.borderWidth,
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
  Widget _buildVoucherFooter(
    WidgetRef ref,
    bool isMobile,
    bool isSmallMobile,
    double fontSize,
  ) {
    final hasVoucher = job.voucherPdf != null && job.voucherPdf!.isNotEmpty;
    final marginTop = isSmallMobile
        ? JobCardConstants.footerMarginTopSmallMobile
        : isMobile
        ? JobCardConstants.footerMarginTopMobile
        : JobCardConstants.footerMarginTopDesktop;
    final paddingVertical = isSmallMobile
        ? JobCardConstants.footerPaddingVerticalSmallMobile
        : isMobile
        ? JobCardConstants.footerPaddingVerticalMobile
        : JobCardConstants.footerPaddingVerticalDesktop;

    return Container(
      margin: EdgeInsets.only(top: marginTop),
      padding: EdgeInsets.symmetric(vertical: paddingVertical),
      child: VoucherActionButtons(
        jobId: job.id.toString(),
        voucherPdfUrl: hasVoucher ? job.voucherPdf : null,
        canCreateVoucher: ref.watch(canCreateVoucherProvider).value ?? false,
      ),
    );
  }

  // Helper methods
  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    bool isMobile,
    bool isSmallMobile,
    double iconSize,
    double fontSize,
  ) {
    final iconSpacing = isSmallMobile
        ? JobCardConstants.chipSpacingSmallMobile
        : isMobile
        ? JobCardConstants.chipSpacingMobile
        : JobCardConstants.chipSpacingDesktop;

    return Row(
      children: [
        Icon(
          icon,
          size: iconSize * JobCardConstants.buttonIconSizeMultiplier,
          color: ChoiceLuxTheme.platinumSilver.withValues(
            alpha: JobCardConstants.detailIconAlpha,
          ),
        ),
        SizedBox(width: iconSpacing),
        Text(
          '$label: ',
          style: TextStyle(
            color: ChoiceLuxTheme.platinumSilver.withValues(
              alpha: JobCardConstants.detailLabelAlpha,
            ),
            fontSize: fontSize - JobCardConstants.detailFontSizeOffset,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: ChoiceLuxTheme.softWhite,
              fontSize: fontSize - JobCardConstants.detailFontSizeOffset,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactMetricPill(
    IconData icon,
    String text,
    bool isMobile,
    bool isSmallMobile,
    double iconSize,
    double fontSize,
  ) {
    final paddingHorizontal = isSmallMobile
        ? JobCardConstants.metricPaddingHorizontalSmallMobile
        : isMobile
        ? JobCardConstants.metricPaddingHorizontalMobile
        : JobCardConstants.metricPaddingHorizontalDesktop;
    final paddingVertical = isSmallMobile
        ? JobCardConstants.metricPaddingVerticalSmallMobile
        : isMobile
        ? JobCardConstants.metricPaddingVerticalMobile
        : JobCardConstants.metricPaddingVerticalDesktop;
    final borderRadius = isSmallMobile
        ? JobCardConstants.metricBorderRadiusSmallMobile
        : isMobile
        ? JobCardConstants.metricBorderRadiusMobile
        : JobCardConstants.metricBorderRadiusDesktop;
    final iconSpacing = isSmallMobile
        ? JobCardConstants.chipSpacingSmallMobile
        : isMobile
        ? JobCardConstants.chipSpacingMobile
        : JobCardConstants.chipSpacingDesktop;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: paddingHorizontal,
        vertical: paddingVertical,
      ),
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.infoColor.withValues(
          alpha: JobCardConstants.metricBackgroundAlpha,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: ChoiceLuxTheme.infoColor.withValues(
            alpha: JobCardConstants.metricBorderAlpha,
          ),
          width: JobCardConstants.borderWidth,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: iconSize * JobCardConstants.metricIconSizeMultiplier,
            color: ChoiceLuxTheme.infoColor,
          ),
          SizedBox(width: iconSpacing),
          Text(
            text,
            style: TextStyle(
              color: ChoiceLuxTheme.infoColor,
              fontSize: fontSize - JobCardConstants.metricFontSizeOffset,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    IconData icon,
    String label,
    String value,
    Color color,
    bool isMobile,
    bool isSmallMobile,
    double iconSize,
    double fontSize,
  ) {
    final padding = isSmallMobile
        ? JobCardConstants.metricTilePaddingSmallMobile
        : isMobile
        ? JobCardConstants.metricTilePaddingMobile
        : JobCardConstants.metricTilePaddingDesktop;
    final borderRadius = isSmallMobile
        ? JobCardConstants.metricTileBorderRadiusSmallMobile
        : isMobile
        ? JobCardConstants.metricTileBorderRadiusMobile
        : JobCardConstants.metricTileBorderRadiusDesktop;
    final innerSpacing = isSmallMobile
        ? JobCardConstants.metricTileInnerSpacingSmallMobile
        : JobCardConstants.metricTileInnerSpacingMobile;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: JobCardConstants.metricTileBackgroundAlpha,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: color.withValues(
            alpha: JobCardConstants.metricTileBorderAlpha,
          ),
          width: JobCardConstants.borderWidth,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: iconSize * JobCardConstants.metricTileIconSizeMultiplier,
            color: color,
          ),
          SizedBox(height: innerSpacing),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(
                alpha: JobCardConstants.metricTileValueAlpha,
              ),
              fontSize: fontSize - JobCardConstants.metricFontSizeOffset,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for action text using centralized logic
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

  // Handle driver confirmation with safe integer parsing and proper error handling
  Future<void> _handleDriverConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    Log.d('=== JOB CARD: _handleDriverConfirmation() called ===');
    Log.d('Job ID: ${job.id}');
    Log.d('Job Status: ${job.status}');
    Log.d('Is Confirmed: ${job.isConfirmed}');
    Log.d('Driver Confirmation: ${job.driverConfirmation}');

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
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Confirming job...'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );

      Log.d('Calling jobsProvider.confirmJob from job card...');
      // Use the proper jobsProvider.confirmJob method
      await ref.read(jobsProvider.notifier).confirmJob(job.id.toString());
      Log.d('jobsProvider.confirmJob completed from job card');

      if (!context.mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Job confirmed successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: JobCardConstants.snackBarDurationMedium,
        ),
      );

      // Refresh notifications only (job data already updated by optimistic update)
      ref.invalidate(notificationProvider);

      // Optional: Navigate to job progress after confirmation
      // context.go('/jobs/${job.id}/progress');
    } catch (e) {
      Log.e('Error in job card _handleDriverConfirmation: $e');
      // Error handling driver confirmation
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('An error occurred: ${e.toString()}'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: JobCardConstants.snackBarDurationLong,
        ),
      );
    }
  }
}
