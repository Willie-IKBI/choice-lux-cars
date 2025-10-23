import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:choice_lux_cars/features/vouchers/models/voucher_data.dart';
import 'package:choice_lux_cars/features/vouchers/providers/voucher_controller.dart';
import 'package:choice_lux_cars/features/vouchers/services/voucher_sharing_service.dart';
import 'package:choice_lux_cars/features/jobs/providers/jobs_provider.dart';

class VoucherActionButtons extends ConsumerStatefulWidget {
  final String jobId;
  final String? voucherPdfUrl;
  final VoucherData? voucherData;
  final bool canCreateVoucher;

  const VoucherActionButtons({
    super.key,
    required this.jobId,
    this.voucherPdfUrl,
    this.voucherData,
    required this.canCreateVoucher,
  });

  @override
  ConsumerState<VoucherActionButtons> createState() =>
      _VoucherActionButtonsState();
}

class _VoucherActionButtonsState extends ConsumerState<VoucherActionButtons> {
  final VoucherSharingService _sharingService = VoucherSharingService();
  bool _isCreatingVoucher = false;

  @override
  Widget build(BuildContext context) {
    final voucherState = ref.watch(voucherControllerProvider);
    
    // Watch jobs provider to get the most up-to-date job data
    final jobsAsync = ref.watch(jobsProvider);
    final currentJob = jobsAsync.when(
      data: (jobs) {
        try {
          return jobs.firstWhere(
            (job) => job.id.toString() == widget.jobId,
          );
        } catch (e) {
          // Job not found in current data, return null
          return null;
        }
      },
      loading: () => null,
      error: (_, __) => null,
    );

    // Use the most up-to-date voucher PDF URL from the job data
    final currentVoucherPdfUrl = currentJob?.voucherPdf ?? widget.voucherPdfUrl;

    return VoucherActionBar(
      jobId: widget.jobId,
      voucherPdfUrl: currentVoucherPdfUrl,
      voucherData: widget.voucherData,
      canCreateVoucher: widget.canCreateVoucher,
      voucherState: voucherState,
      isCreatingVoucher: _isCreatingVoucher,
      onCreateVoucher: _createVoucher,
      onRegenerateVoucher: _regenerateVoucher,
      onOpenVoucher: _openVoucher,
      onShowShareOptions: _showShareOptions,
    );
  }

  Future<void> _createVoucher() async {
    setState(() {
      _isCreatingVoucher = true;
    });

    try {
      await ref
          .read(voucherControllerProvider.notifier)
          .createVoucher(jobId: widget.jobId);

      // Note: refreshJobs() is already called inside the voucher controller
      // No need for additional refresh calls here

      if (mounted) {
        setState(() {
          _isCreatingVoucher = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voucher created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreatingVoucher = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create voucher: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _regenerateVoucher() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reload Voucher'),
        content: const Text(
          'This will replace the existing voucher with updated information. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reload'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(voucherControllerProvider.notifier)
            .regenerateVoucher(jobId: widget.jobId);

        // Note: refreshJobs() is already called inside the voucher controller
        // No need for additional refresh calls here

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Voucher reloaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reload voucher: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _openVoucher() async {
    if (widget.voucherPdfUrl == null) return;

    try {
      await _sharingService.openVoucherUrl(
        widget.voucherPdfUrl!, 
        context,
        voucherData: {
          'id': widget.jobId,
          'title': 'Voucher #${widget.jobId}',
          'recipientEmail': widget.voucherData?.agentContact,
          'phoneNumber': widget.voucherData?.preferredPhoneNumber,
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open voucher: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showShareOptions() async {
    if (widget.voucherPdfUrl == null || widget.voucherData == null) return;

    try {
      await _sharingService.shareViaSystemShareSheet(
        voucherUrl: widget.voucherPdfUrl!,
        voucherData: widget.voucherData!,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share voucher: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

}

/// Responsive voucher action bar that prevents overflow on narrow cards
class VoucherActionBar extends StatefulWidget {
  final String jobId;
  final String? voucherPdfUrl;
  final VoucherData? voucherData;
  final bool canCreateVoucher;
  final VoucherControllerState voucherState;
  final bool isCreatingVoucher;
  final VoidCallback onCreateVoucher;
  final VoidCallback onRegenerateVoucher;
  final VoidCallback onOpenVoucher;
  final VoidCallback onShowShareOptions;

  const VoucherActionBar({
    super.key,
    required this.jobId,
    this.voucherPdfUrl,
    this.voucherData,
    required this.canCreateVoucher,
    required this.voucherState,
    required this.isCreatingVoucher,
    required this.onCreateVoucher,
    required this.onRegenerateVoucher,
    required this.onOpenVoucher,
    required this.onShowShareOptions,
  });

  @override
  State<VoucherActionBar> createState() => _VoucherActionBarState();
}

class _VoucherActionBarState extends State<VoucherActionBar> {
  @override
  Widget build(BuildContext context) {
    final hasVoucher = widget.voucherPdfUrl != null && widget.voucherPdfUrl!.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTight =
            constraints.maxWidth < 320; // Breakpoint for tight layouts
        final horizontalGap = isTight ? 6.0 : 8.0;
        final verticalGap = isTight ? 6.0 : 8.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Voucher section header
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Voucher',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                ),
              ),
            ),

            // Progressive voucher button flow
            if (!widget.canCreateVoucher) ...[
              const SizedBox(height: 6),
              _buildNoPermissionMessage(context),
            ] else
              _buildProgressiveVoucherFlow(
                context,
                isTight,
                horizontalGap,
                verticalGap,
                constraints.maxWidth,
                hasVoucher,
              ),

            // Loading indicator
            if (widget.voucherState.isLoading) _buildLoadingIndicator(context),

            // Error message
            if (widget.voucherState.hasError) _buildErrorMessage(context),
          ],
        );
      },
    );
  }

  Widget _buildProgressiveVoucherFlow(
    BuildContext context,
    bool isTight,
    double horizontalGap,
    double verticalGap,
    double maxWidth,
    bool hasVoucher,
  ) {
    // State 1: No voucher - Show Create Voucher button
    if (!hasVoucher && !widget.isCreatingVoucher) {
      return _buildCreateVoucherButton(context, isTight, maxWidth);
    }
    
    // State 2: Creating voucher - Show creating button
    if (widget.isCreatingVoucher) {
      return _buildCreatingVoucherButton(context, isTight, maxWidth);
    }
    
    // State 3: Voucher created - Show status and action buttons
    if (hasVoucher) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status button
          _buildVoucherCreatedButton(context, isTight, maxWidth),
          const SizedBox(height: 8),
          // Action buttons
          _buildVoucherActionButtons(
            context,
            isTight,
            horizontalGap,
            verticalGap,
            maxWidth,
          ),
        ],
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildCreateVoucherButton(
    BuildContext context,
    bool isTight,
    double maxWidth,
  ) {
    // Ensure constraints are valid - minWidth cannot exceed maxWidth
    final availableWidth = maxWidth;
    final minWidth = isTight ? 120.0 : 140.0; // Reduced minimum width
    final effectiveMinWidth = minWidth < availableWidth
        ? minWidth
        : availableWidth * 0.8;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: effectiveMinWidth,
        maxWidth: availableWidth,
      ),
      child: SizedBox(
        width: double.infinity, // Always use full available width
        child: ElevatedButton.icon(
                        onPressed: widget.voucherState.isLoading ? null : widget.onCreateVoucher,
          icon: const Icon(Icons.receipt_long, size: 16),
          label: const Text('Create Voucher', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreatingVoucherButton(
    BuildContext context,
    bool isTight,
    double maxWidth,
  ) {
    final availableWidth = maxWidth;
    final minWidth = isTight ? 120.0 : 140.0;
    final effectiveMinWidth = minWidth < availableWidth
        ? minWidth
        : availableWidth * 0.8;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: effectiveMinWidth,
        maxWidth: availableWidth,
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: null, // Disabled during creation
          icon: const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          label: const Text('Creating Voucher...', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoucherCreatedButton(
    BuildContext context,
    bool isTight,
    double maxWidth,
  ) {
    final availableWidth = maxWidth;
    final minWidth = isTight ? 120.0 : 140.0;
    final effectiveMinWidth = minWidth < availableWidth
        ? minWidth
        : availableWidth * 0.8;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: effectiveMinWidth,
        maxWidth: availableWidth,
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: null, // Status button, not clickable
          icon: const Icon(Icons.check_circle, size: 16),
          label: const Text('Voucher Created', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoucherActionButtons(
    BuildContext context,
    bool isTight,
    double horizontalGap,
    double verticalGap,
    double maxWidth,
  ) {
    return Wrap(
      spacing: horizontalGap,
      runSpacing: verticalGap,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // View Voucher button
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: isTight ? 100 : 120,
            maxWidth: maxWidth * 0.6,
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.voucherState.isLoading ? null : widget.onOpenVoucher,
              icon: const Icon(Icons.open_in_new, size: 14),
              label: const Text('View Voucher', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ),

        // Reload Voucher button
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: isTight ? 100 : 120,
            maxWidth: maxWidth * 0.6,
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.voucherState.isLoading ? null : widget.onRegenerateVoucher,
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Reload Voucher', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ),

        // Share icon action
        _iconAction(
          context,
          Icons.share,
          'Share Voucher',
          onTap: widget.voucherState.isLoading ? null : widget.onShowShareOptions,
        ),
      ],
    );
  }

  Widget _buildVoucherActions(
    BuildContext context,
    bool isTight,
    double horizontalGap,
    double verticalGap,
    double maxWidth,
  ) {
    return Wrap(
      spacing: horizontalGap,
      runSpacing: verticalGap,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Status chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 14, color: Colors.green[700]),
              const SizedBox(width: 3),
              Text(
                'Voucher Created',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        ),

        // Primary action button
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: isTight ? 100 : 120, // Reduced minimum width
            maxWidth: maxWidth,
          ),
          child: SizedBox(
            width: double.infinity, // Always use full available width
            child: ElevatedButton.icon(
              onPressed: widget.voucherState.isLoading ? null : widget.onOpenVoucher,
              icon: const Icon(Icons.open_in_new, size: 14),
              label: const Text('Open Voucher', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                foregroundColor: Theme.of(
                  context,
                ).colorScheme.onPrimaryContainer,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ),

        // Secondary icon actions
        _iconAction(
          context,
          Icons.share,
          'Share Voucher',
          onTap: widget.voucherState.isLoading ? null : widget.onShowShareOptions,
        ),

        // Reload button (if user has permission)
        if (widget.canCreateVoucher)
          _iconAction(
            context,
            Icons.refresh,
            'Reload Voucher',
            onTap: widget.voucherState.isLoading ? null : widget.onRegenerateVoucher,
          ),
      ],
    );
  }

  Widget _iconAction(
    BuildContext context,
    IconData icon,
    String tooltip, {
    VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.secondaryContainer.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.onSecondaryContainer.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: onTap == null
                ? Colors.grey
                : Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _buildNoPermissionMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock,
            size: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Insufficient permissions to create vouchers',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.voucherState.loadingMessage,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 14,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              widget.voucherState.errorMessage ?? 'An error occurred',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
          TextButton(
            onPressed: widget.onCreateVoucher,
            child: const Text('Retry', style: TextStyle(fontSize: 11)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(0, 24),
            ),
          ),
        ],
      ),
    );
  }
}
