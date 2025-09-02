import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/jobs/models/job.dart';
import 'package:choice_lux_cars/features/clients/models/client.dart';
import 'package:choice_lux_cars/features/vehicles/models/vehicle.dart';
import 'package:choice_lux_cars/features/users/models/user.dart';
import 'package:choice_lux_cars/features/vouchers/widgets/voucher_action_buttons.dart';
import 'package:choice_lux_cars/features/invoices/widgets/invoice_action_buttons.dart';

import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/shared/utils/status_color_utils.dart';
import 'package:choice_lux_cars/shared/utils/date_utils.dart' as app_date_utils;
import 'package:choice_lux_cars/shared/utils/driver_flow_utils.dart';

class JobListCard extends ConsumerWidget {
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
    this.canCreateVoucher = false,
    this.canCreateInvoice = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final padding = isSmallMobile
        ? 12.0
        : isMobile
        ? 16.0
        : 20.0;
    final spacing = isSmallMobile
        ? 8.0
        : isMobile
        ? 12.0
        : 16.0;
    final cornerRadius = isSmallMobile
        ? 8.0
        : isMobile
        ? 12.0
        : 16.0;

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
            // 1. Top Bar: Status + Urgency
            _buildTopBar(context, spacing),

            SizedBox(height: spacing),

            // 2. Client Details (Primary)
            _buildClientDetails(context, spacing),

            SizedBox(height: spacing),

            // 3. Travel Details (Secondary)
            _buildTravelDetails(context, spacing),

            SizedBox(height: spacing),

            // 4. Confirmation State
            _buildConfirmationState(context, spacing),

            SizedBox(height: spacing),

            // 5. Action Buttons
            _buildActionButtons(context, ref, spacing),
          ],
        ),
      ),
    );
  }

  // 1. Top Bar: Status + Urgency
  Widget _buildTopBar(BuildContext context, double spacing) {
    final isUrgent = job.daysUntilStart != null && job.daysUntilStart! <= 3;
    final statusColor = StatusColorUtils.getJobStatusColor(job.statusEnum);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing * 0.75,
        vertical: spacing * 0.5,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.1),
            statusColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: statusColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          // Left: Status + Job ID
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: spacing * 0.5),
                Text(
                  '${job.statusEnum.label.toUpperCase()} • Job #${job.id}',
                  style: TextStyle(
                    fontSize: isSmallMobile ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),

          // Right: Urgency Indicator
          if (isUrgent)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: spacing * 0.5,
                vertical: spacing * 0.25,
              ),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'URGENT (${job.daysUntilStart}d)',
                style: TextStyle(
                  fontSize: isSmallMobile ? 10 : 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 2. Client Details (Primary)
  Widget _buildClientDetails(BuildContext context, double spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Client Name (Primary)
        Text(
          job.passengerName ?? 'No Passenger Name',
          style: TextStyle(
            fontSize: isSmallMobile
                ? 16
                : isMobile
                ? 18
                : 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        SizedBox(height: spacing * 0.5),

        // Location (Secondary)
        Row(
          children: [
            Icon(
              Icons.location_on,
              size: isSmallMobile ? 14 : 16,
              color: ChoiceLuxTheme.platinumSilver,
            ),
            SizedBox(width: spacing * 0.25),
            Expanded(
              child: Text(
                job.location ?? 'No location specified',
                style: TextStyle(
                  fontSize: isSmallMobile ? 12 : 14,
                  color: ChoiceLuxTheme.platinumSilver,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        SizedBox(height: spacing * 0.25),

        // Date (Tertiary)
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: isSmallMobile ? 12 : 14,
              color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.7),
            ),
            SizedBox(width: spacing * 0.25),
            Text(
              app_date_utils.DateUtils.formatDate(job.jobStartDate),
              style: TextStyle(
                fontSize: isSmallMobile ? 11 : 12,
                color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 3. Travel Details (Secondary)
  Widget _buildTravelDetails(BuildContext context, double spacing) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing * 0.75,
        vertical: spacing * 0.5,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
      ),
      child: Row(
        children: [
          // Passenger Count
          _buildTravelChip(
            context,
            Icons.person,
            '${job.pasCount} pax',
            spacing,
          ),

          SizedBox(width: spacing * 0.5),

          // Luggage Count
          _buildTravelChip(
            context,
            Icons.work,
            '${job.luggageCount} bags',
            spacing,
          ),

          if (vehicle?.model != null) ...[
            SizedBox(width: spacing * 0.5),

            // Vehicle Info
            _buildTravelChip(
              context,
              Icons.directions_car,
              vehicle!.model,
              spacing,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTravelChip(
    BuildContext context,
    IconData icon,
    String label,
    double spacing,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: isSmallMobile ? 12 : 14,
          color: ChoiceLuxTheme.platinumSilver,
        ),
        SizedBox(width: spacing * 0.25),
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallMobile ? 11 : 12,
            color: ChoiceLuxTheme.platinumSilver,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // 4. Confirmation State
  Widget _buildConfirmationState(BuildContext context, double spacing) {
    final isConfirmed =
        job.isConfirmed == true || job.driverConfirmation == true;
    final confirmationColor = isConfirmed ? Colors.green : Colors.orange;
    final confirmationText = isConfirmed ? 'Confirmed' : 'Not Confirmed';
    final confirmationIcon = isConfirmed ? Icons.check_circle : Icons.pending;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing * 0.75,
        vertical: spacing * 0.5,
      ),
      decoration: BoxDecoration(
        color: confirmationColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: confirmationColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            confirmationIcon,
            size: isSmallMobile ? 14 : 16,
            color: confirmationColor,
          ),
          SizedBox(width: spacing * 0.5),
          Text(
            'Driver $confirmationText',
            style: TextStyle(
              fontSize: isSmallMobile ? 12 : 14,
              fontWeight: FontWeight.w500,
              color: confirmationColor,
            ),
          ),
        ],
      ),
    );
  }

  // 5. Action Buttons
  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    double spacing,
  ) {
    return Column(
      children: [
        // Primary Action: View Details
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.go('/jobs/${job.id}/summary'),
            icon: const Icon(Icons.visibility, size: 16),
            label: Text(
              'View Details',
              style: TextStyle(
                fontSize: isSmallMobile ? 12 : 14,
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

        SizedBox(height: spacing),

        // Secondary Actions Row
        Row(
          children: [
            // Driver Flow Button (if applicable)
            if (DriverFlowUtils.shouldShowDriverFlowButton(
              currentUserId: ref.read(currentUserProfileProvider)?.id,
              jobDriverId: job.driverId,
              jobStatus: job.statusEnum,
              isJobConfirmed:
                  job.isConfirmed == true || job.driverConfirmation == true,
            ))
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleDriverFlow(context, ref),
                  icon: Icon(
                    DriverFlowUtils.getDriverFlowIcon(job.statusEnum),
                    size: 16,
                  ),
                  label: Text(
                    DriverFlowUtils.getDriverFlowText(job.statusEnum),
                    style: TextStyle(fontSize: isSmallMobile ? 12 : 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DriverFlowUtils.getDriverFlowColor(
                      job.statusEnum,
                    ),
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
            if (canCreateVoucher) ...[
              if (DriverFlowUtils.shouldShowDriverFlowButton(
                currentUserId: ref.read(currentUserProfileProvider)?.id,
                jobDriverId: job.driverId,
                jobStatus: job.statusEnum,
                isJobConfirmed:
                    job.isConfirmed == true || job.driverConfirmation == true,
              ))
                SizedBox(width: spacing),
              Expanded(child: _buildVoucherSection(context, spacing)),
            ],

            // Invoice Actions
            if (canCreateInvoice) ...[
              if (DriverFlowUtils.shouldShowDriverFlowButton(
                    currentUserId: ref.read(currentUserProfileProvider)?.id,
                    jobDriverId: job.driverId,
                    jobStatus: job.statusEnum,
                    isJobConfirmed:
                        job.isConfirmed == true ||
                        job.driverConfirmation == true,
                  ) ||
                  canCreateVoucher)
                SizedBox(width: spacing),
              Expanded(child: _buildInvoiceSection(context, spacing)),
            ],
          ],
        ),
      ],
    );
  }

  // Voucher Section
  Widget _buildVoucherSection(BuildContext context, double spacing) {
    final hasVoucher = job.voucherPdf != null && job.voucherPdf!.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(spacing * 0.75),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Voucher Actions
          VoucherActionButtons(
            jobId: job.id.toString(),
            voucherPdfUrl: job.voucherPdf,
            voucherData: null,
            canCreateVoucher: canCreateVoucher,
          ),

          // Status Text
          if (hasVoucher)
            Padding(
              padding: EdgeInsets.only(top: spacing * 0.25),
              child: Text(
                'Created',
                style: TextStyle(
                  fontSize: isSmallMobile ? 10 : 11,
                  color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.7),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Invoice Section
  Widget _buildInvoiceSection(BuildContext context, double spacing) {
    final hasInvoice = job.invoicePdf != null && job.invoicePdf!.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(spacing * 0.75),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Invoice Actions
          InvoiceActionButtons(
            jobId: job.id.toString(),
            invoicePdfUrl: job.invoicePdf,
            invoiceData: null,
            canCreateInvoice: canCreateInvoice,
          ),

          // Status Text
          if (hasInvoice)
            Padding(
              padding: EdgeInsets.only(top: spacing * 0.25),
              child: Text(
                'Created',
                style: TextStyle(
                  fontSize: isSmallMobile ? 10 : 11,
                  color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.7),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper Methods

  Future<void> _handleDriverFlow(BuildContext context, WidgetRef ref) async {
    try {
      // Navigate to the appropriate screen based on job status
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
}
