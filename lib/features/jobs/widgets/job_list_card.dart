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
import 'package:choice_lux_cars/features/jobs/providers/jobs_provider.dart';
import 'package:choice_lux_cars/shared/utils/status_color_utils.dart';
import 'package:choice_lux_cars/shared/utils/date_utils.dart' as app_date_utils;
import 'package:choice_lux_cars/shared/utils/driver_flow_utils.dart';
import 'package:choice_lux_cars/features/clients/data/clients_repository.dart';
import 'package:choice_lux_cars/features/clients/models/client_branch.dart';
import 'package:choice_lux_cars/features/branches/providers/branches_provider.dart';

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
    // Watch jobs provider to get updated job data
    final jobsAsync = ref.watch(jobsProvider);
    
    // Get the updated job data if available, otherwise use the passed job
    final currentJob = jobsAsync.when(
      data: (jobs) => jobs.firstWhere(
        (j) => j.id == job.id,
        orElse: () => job,
      ),
      loading: () => job,
      error: (_, __) => job,
    );

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
            _buildTopBar(context, spacing, currentJob),

            SizedBox(height: spacing),

            // 2. Client Details (Primary)
            _buildClientDetails(context, ref, spacing, currentJob),

            SizedBox(height: spacing),

            // 3. Travel Details (Secondary)
            _buildTravelDetails(context, spacing, currentJob),

            SizedBox(height: spacing),

            // 4. Confirmation State
            _buildConfirmationState(context, spacing, currentJob),

            SizedBox(height: spacing),

            // 5. Action Buttons
            _buildActionButtons(context, ref, spacing, currentJob),
          ],
        ),
      ),
    );
  }

  // 1. Top Bar: Status + Urgency
  Widget _buildTopBar(BuildContext context, double spacing, Job currentJob) {
    final isUrgent = currentJob.daysUntilStart != null && currentJob.daysUntilStart! <= 3;
    final statusColor = StatusColorUtils.getJobStatusColor(currentJob.statusEnum);

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
                  '${currentJob.statusEnum.label.toUpperCase()} • Job #${currentJob.id}',
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
                'URGENT (${currentJob.daysUntilStart}d)',
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
  Widget _buildClientDetails(BuildContext context, WidgetRef ref, double spacing, Job currentJob) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Client Name (Primary)
        Text(
          currentJob.passengerName ?? 'No Passenger Name',
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

        // Location (Secondary) - Show branch location with better formatting
        if (currentJob.branchId != null)
          Consumer(
            builder: (context, ref, child) {
              final branchesAsync = ref.watch(branchesProvider);
              return branchesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (branches) {
                  final branch = branches.where((b) => b.id == currentJob.branchId).firstOrNull;
                  if (branch == null) return const SizedBox.shrink();
                  
                  return Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: isSmallMobile ? 14 : 16,
                        color: ChoiceLuxTheme.platinumSilver,
                      ),
                      SizedBox(width: spacing * 0.25),
                      Expanded(
                        child: Text(
                          branch.name,
                          style: TextStyle(
                            fontSize: isSmallMobile ? 12 : 14,
                            color: ChoiceLuxTheme.platinumSilver,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),

        SizedBox(height: spacing * 0.25),

        // Branch Name (if exists)
        if (currentJob.branchId != null)
          FutureBuilder<ClientBranch?>(
            future: ref.read(clientsRepositoryProvider).fetchBranchById(currentJob.branchId!).then((result) => result.data),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink(); // Don't show anything while loading
              }
              
              if (snapshot.hasData && snapshot.data != null) {
                return Padding(
                  padding: EdgeInsets.only(bottom: spacing * 0.25),
                  child: Row(
                    children: [
                      Icon(
                        Icons.business,
                        size: isSmallMobile ? 12 : 14,
                        color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.7),
                      ),
                      SizedBox(width: spacing * 0.25),
                      Text(
                        snapshot.data!.branchName,
                        style: TextStyle(
                          fontSize: isSmallMobile ? 11 : 12,
                          color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }
              
              return const SizedBox.shrink();
            },
          ),

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
              app_date_utils.DateUtils.formatDate(currentJob.jobStartDate),
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
  Widget _buildTravelDetails(BuildContext context, double spacing, Job currentJob) {
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
      child: Wrap(
        spacing: spacing * 0.5,
        runSpacing: spacing * 0.25,
        children: [
          _buildTravelChip(context, Icons.person, '${currentJob.pasCount} pax', spacing),
          _buildTravelChip(context, Icons.work, '${currentJob.luggageCount} bags', spacing),
          if (vehicle?.model != null)
            _buildTravelChip(context, Icons.directions_car, vehicle!.model, spacing),
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

  // 4. Dual Status Display: Driver Confirmation + Current Step
  Widget _buildConfirmationState(BuildContext context, double spacing, Job currentJob) {
    // Driver confirmation status
    final isConfirmed = currentJob.driverConfirmation == true;
    final confirmationColor = isConfirmed ? Colors.green : Colors.orange;
    final confirmationText = isConfirmed ? 'Driver Confirmed' : 'Awaiting Confirmation';
    final confirmationIcon = isConfirmed ? Icons.check_circle : Icons.pending;

    // Current job step
    final currentStep = DriverFlowUtils.getCurrentJobStep(currentJob);
    final stepText = DriverFlowUtils.getCurrentStepDisplayText(currentStep);
    final stepColor = DriverFlowUtils.getCurrentStepColor(currentStep);

    return Column(
      children: [
        // Driver Confirmation Status
        Container(
          width: double.infinity,
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
                confirmationText,
                style: TextStyle(
                  fontSize: isSmallMobile ? 12 : 14,
                  fontWeight: FontWeight.w500,
                  color: confirmationColor,
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: spacing * 0.5),
        
        // Current Job Step Status
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: spacing * 0.75,
            vertical: spacing * 0.5,
          ),
          decoration: BoxDecoration(
            color: stepColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: stepColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.timeline,
                size: isSmallMobile ? 14 : 16,
                color: stepColor,
              ),
              SizedBox(width: spacing * 0.5),
              Text(
                stepText,
                style: TextStyle(
                  fontSize: isSmallMobile ? 12 : 14,
                  fontWeight: FontWeight.w500,
                  color: stepColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 5. Action Buttons
  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    double spacing,
    Job currentJob,
  ) {
    final isTiny = isSmallMobile; // stack on very small devices

    return Column(
      children: [
        // Primary Action: View Details
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.go('/jobs/${currentJob.id}/summary'),
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

        // Secondary Actions responsive
        if (isTiny)
          Column(
            children: [
              if (DriverFlowUtils.shouldShowDriverConfirmationButton(
                currentUserId: ref.read(currentUserProfileProvider)?.id,
                jobDriverId: currentJob.driverId,
                jobStatus: currentJob.statusEnum,
                isJobConfirmed: currentJob.driverConfirmation == true,
              ))
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleDriverConfirmation(context, ref, currentJob),
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: Text('Confirm Job', style: TextStyle(fontSize: isSmallMobile ? 12 : 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ChoiceLuxTheme.orange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: spacing, vertical: spacing * 0.75),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              if (DriverFlowUtils.shouldShowDriverFlowButton(
                currentUserId: ref.read(currentUserProfileProvider)?.id,
                jobDriverId: currentJob.driverId,
                jobStatus: currentJob.statusEnum,
                isJobConfirmed: currentJob.driverConfirmation == true,
              ))
                Padding(
                  padding: EdgeInsets.only(top: spacing),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleDriverFlow(context, ref, currentJob),
                      icon: Icon(DriverFlowUtils.getDriverFlowIcon(currentJob.statusEnum), size: 16),
                      label: Text(DriverFlowUtils.getDriverFlowText(currentJob.statusEnum), style: TextStyle(fontSize: isSmallMobile ? 12 : 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DriverFlowUtils.getDriverFlowColor(currentJob.statusEnum),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: spacing, vertical: spacing * 0.75),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ),
              if (canCreateVoucher)
                Padding(
                  padding: EdgeInsets.only(top: spacing),
                  child: _buildVoucherSection(context, spacing, currentJob),
                ),
              if (canCreateInvoice)
                Padding(
                  padding: EdgeInsets.only(top: spacing),
                  child: _buildInvoiceSection(context, spacing, currentJob),
                ),
            ],
          )
        else
          Row(
            children: [
            // Driver Confirmation Button (if applicable)
            if (DriverFlowUtils.shouldShowDriverConfirmationButton(
              currentUserId: ref.read(currentUserProfileProvider)?.id,
              jobDriverId: currentJob.driverId,
              jobStatus: currentJob.statusEnum,
              isJobConfirmed: currentJob.driverConfirmation == true,
            ))
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleDriverConfirmation(context, ref, currentJob),
                  icon: const Icon(Icons.check_circle, size: 16),
                  label: Text(
                    'Confirm Job',
                    style: TextStyle(fontSize: isSmallMobile ? 12 : 14),
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

            // Driver Flow Button (if applicable)
            if (DriverFlowUtils.shouldShowDriverFlowButton(
              currentUserId: ref.read(currentUserProfileProvider)?.id,
              jobDriverId: currentJob.driverId,
              jobStatus: currentJob.statusEnum,
              isJobConfirmed: currentJob.driverConfirmation == true,
            ))
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleDriverFlow(context, ref, currentJob),
                  icon: Icon(
                    DriverFlowUtils.getDriverFlowIcon(currentJob.statusEnum),
                    size: 16,
                  ),
                  label: Text(
                    DriverFlowUtils.getDriverFlowText(currentJob.statusEnum),
                    style: TextStyle(fontSize: isSmallMobile ? 12 : 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DriverFlowUtils.getDriverFlowColor(
                      currentJob.statusEnum,
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
                if (DriverFlowUtils.shouldShowDriverConfirmationButton(
                    currentUserId: ref.read(currentUserProfileProvider)?.id,
                    jobDriverId: currentJob.driverId,
                    jobStatus: currentJob.statusEnum,
                    isJobConfirmed: currentJob.driverConfirmation == true,
                    ) ||
                    DriverFlowUtils.shouldShowDriverFlowButton(
                    currentUserId: ref.read(currentUserProfileProvider)?.id,
                    jobDriverId: currentJob.driverId,
                    jobStatus: currentJob.statusEnum,
                    isJobConfirmed: currentJob.driverConfirmation == true,
                    ))
                  SizedBox(width: spacing),
                Expanded(child: _buildVoucherSection(context, spacing, currentJob)),
              ],

              // Invoice Actions
              if (canCreateInvoice) ...[
                if (DriverFlowUtils.shouldShowDriverConfirmationButton(
                    currentUserId: ref.read(currentUserProfileProvider)?.id,
                    jobDriverId: currentJob.driverId,
                    jobStatus: currentJob.statusEnum,
                    isJobConfirmed: currentJob.driverConfirmation == true,
                    ) ||
                    DriverFlowUtils.shouldShowDriverFlowButton(
                    currentUserId: ref.read(currentUserProfileProvider)?.id,
                    jobDriverId: currentJob.driverId,
                    jobStatus: currentJob.statusEnum,
                    isJobConfirmed: currentJob.driverConfirmation == true,
                    ) ||
                    canCreateVoucher)
                  SizedBox(width: spacing),
                Expanded(child: _buildInvoiceSection(context, spacing, currentJob)),
              ],
            ],
          ),
      ],
    );
  }

  // Voucher Section
  Widget _buildVoucherSection(BuildContext context, double spacing, Job currentJob) {
    final hasVoucher = currentJob.voucherPdf != null && currentJob.voucherPdf!.isNotEmpty;

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
            jobId: currentJob.id.toString(),
            voucherPdfUrl: currentJob.voucherPdf,
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
  Widget _buildInvoiceSection(BuildContext context, double spacing, Job currentJob) {
    final hasInvoice = currentJob.invoicePdf != null && currentJob.invoicePdf!.isNotEmpty;

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
            jobId: currentJob.id.toString(),
            invoicePdfUrl: currentJob.invoicePdf,
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

  // Removed _formatLocation - now using branchId with branches provider

  Future<void> _handleDriverFlow(BuildContext context, WidgetRef ref, Job currentJob) async {
    try {
      // Navigate to the appropriate screen based on job status
      final route = DriverFlowUtils.getDriverFlowRoute(
        int.parse(currentJob.id.toString()),
        currentJob.statusEnum,
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

  Future<void> _handleDriverConfirmation(BuildContext context, WidgetRef ref, Job currentJob) async {
    try {
      // Call the jobs provider to confirm the job
      await ref.read(jobsProvider.notifier).confirmJob(currentJob.id.toString());
      
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
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
