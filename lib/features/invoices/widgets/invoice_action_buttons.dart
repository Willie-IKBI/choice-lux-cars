import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:choice_lux_cars/features/invoices/models/invoice_data.dart';
import 'package:choice_lux_cars/features/invoices/providers/invoice_controller.dart';
import 'package:choice_lux_cars/features/invoices/services/invoice_sharing_service.dart';
import 'package:choice_lux_cars/shared/services/pdf_viewer_service.dart';
import 'package:choice_lux_cars/features/jobs/jobs.dart';

class InvoiceActionButtons extends ConsumerStatefulWidget {
  final String jobId;
  final String? invoicePdfUrl;
  final InvoiceData? invoiceData;
  final bool canCreateInvoice;

  const InvoiceActionButtons({
    super.key,
    required this.jobId,
    this.invoicePdfUrl,
    this.invoiceData,
    required this.canCreateInvoice,
  });

  @override
  ConsumerState<InvoiceActionButtons> createState() =>
      _InvoiceActionButtonsState();
}

class _InvoiceActionButtonsState extends ConsumerState<InvoiceActionButtons> {
  final InvoiceSharingService _sharingService = InvoiceSharingService();
  bool _isCreatingInvoice = false;

  @override
  Widget build(BuildContext context) {
    final invoiceState = ref.watch(invoiceControllerProvider);
    
    // Watch jobs provider to get the most up-to-date job data
    final jobsAsync = ref.watch(jobsProvider);
    final currentJob = jobsAsync.when(
      data: (jobs) {
        try {
          final job = jobs.firstWhere(
            (job) => job.id.toString() == widget.jobId,
          );
          // Debug: Print job data to see if invoice PDF is updated
          print('Job ${widget.jobId} invoice PDF: ${job.invoicePdf}');
          return job;
        } catch (e) {
          // Job not found in current data, return null
          print('Job ${widget.jobId} not found in jobs list');
          return null;
        }
      },
      loading: () => null,
      error: (_, __) => null,
    );

    // Use the most up-to-date invoice PDF URL from the job data
    final currentInvoicePdfUrl = currentJob?.invoicePdf ?? widget.invoicePdfUrl;
    print('Current invoice PDF URL for job ${widget.jobId}: $currentInvoicePdfUrl');

    return InvoiceActionBar(
      jobId: widget.jobId,
      invoicePdfUrl: currentInvoicePdfUrl,
      invoiceData: widget.invoiceData,
      canCreateInvoice: widget.canCreateInvoice,
      invoiceState: invoiceState,
      isCreatingInvoice: _isCreatingInvoice,
      onCreateInvoice: _createInvoice,
      onRegenerateInvoice: _regenerateInvoice,
      onOpenInvoice: _openInvoice,
      onShowShareOptions: _showShareOptions,
    );
  }

  Future<void> _createInvoice() async {
    setState(() {
      _isCreatingInvoice = true;
    });

    try {
      await ref
          .read(invoiceControllerProvider.notifier)
          .createInvoice(jobId: widget.jobId);

      // Force refresh jobs data to show updated invoice status
      print('Invoice created - refreshing jobs data...');
      await ref.read(jobsProvider.notifier).refreshJobs();
      
      // Force widget rebuild by invalidating the jobs provider
      ref.invalidate(jobsProvider);
      
      // Add a small delay to ensure the database update has propagated
      await Future.delayed(const Duration(milliseconds: 500));
      
      print('Invoice refresh completed for job ${widget.jobId}');

      if (mounted) {
        setState(() {
          _isCreatingInvoice = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreatingInvoice = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create invoice: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _regenerateInvoice() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate Invoice'),
        content: const Text(
          'This will replace the existing invoice with updated information. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(invoiceControllerProvider.notifier)
            .regenerateInvoice(jobId: widget.jobId);

        // Force refresh jobs data to show updated invoice status
        await ref.read(jobsProvider.notifier).refreshJobs();
        
        // Force widget rebuild by invalidating the jobs provider
        ref.invalidate(jobsProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invoice regenerated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to regenerate invoice: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _openInvoice() async {
    if (widget.invoicePdfUrl == null) return;

    try {
      await PdfViewerService.openPdf(
        context: context,
        pdfUrl: widget.invoicePdfUrl!,
        title: 'Invoice #${widget.jobId}',
        documentType: 'invoice',
        documentData: {
          'id': widget.jobId,
          'title': 'Invoice #${widget.jobId}',
          'recipientEmail': widget.invoiceData?.clientContactEmail,
          'phoneNumber': widget.invoiceData?.clientContactNumber,
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open invoice: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showShareOptions() async {
    // Get the most current job data
    final jobsAsync = ref.read(jobsProvider);
    final currentJob = jobsAsync.when(
      data: (jobs) {
        try {
          return jobs.firstWhere(
            (job) => job.id.toString() == widget.jobId,
          );
        } catch (e) {
          return null;
        }
      },
      loading: () => null,
      error: (_, __) => null,
    );
    
    final currentInvoicePdfUrl = currentJob?.invoicePdf ?? widget.invoicePdfUrl;
    
    if (currentInvoicePdfUrl == null || widget.invoiceData == null) return;

    try {
      await _sharingService.shareInvoiceViaSystemShareSheet(
        invoiceUrl: currentInvoicePdfUrl,
        invoiceData: widget.invoiceData!,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share invoice: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



}

/// Responsive invoice action bar that prevents overflow on narrow cards
class InvoiceActionBar extends StatefulWidget {
  final String jobId;
  final String? invoicePdfUrl;
  final InvoiceData? invoiceData;
  final bool canCreateInvoice;
  final InvoiceControllerState invoiceState;
  final bool isCreatingInvoice;
  final VoidCallback onCreateInvoice;
  final VoidCallback onRegenerateInvoice;
  final VoidCallback onOpenInvoice;
  final VoidCallback onShowShareOptions;

  const InvoiceActionBar({
    super.key,
    required this.jobId,
    this.invoicePdfUrl,
    this.invoiceData,
    required this.canCreateInvoice,
    required this.invoiceState,
    required this.isCreatingInvoice,
    required this.onCreateInvoice,
    required this.onRegenerateInvoice,
    required this.onOpenInvoice,
    required this.onShowShareOptions,
  });

  @override
  State<InvoiceActionBar> createState() => _InvoiceActionBarState();
}

class _InvoiceActionBarState extends State<InvoiceActionBar> {
  @override
  Widget build(BuildContext context) {
    final hasInvoice = widget.invoicePdfUrl != null && widget.invoicePdfUrl!.isNotEmpty;
    print('InvoiceActionBar - Job ${widget.jobId} - hasInvoice: $hasInvoice - invoicePdfUrl: ${widget.invoicePdfUrl}');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTight = constraints.maxWidth < 200;
        final horizontalGap = isTight ? 4.0 : 8.0;
        final verticalGap = 4.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Invoice section header
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Invoice',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                ),
              ),
            ),

            // Progressive invoice button flow
            if (!widget.canCreateInvoice) ...[
              const SizedBox(height: 6),
              _buildNoPermissionMessage(context),
            ] else
              _buildProgressiveInvoiceFlow(
                context,
                isTight,
                horizontalGap,
                verticalGap,
                constraints.maxWidth,
                hasInvoice,
              ),

            // Loading indicator
            if (widget.invoiceState.isLoading) _buildLoadingIndicator(context),

            // Error message
            if (widget.invoiceState.hasError) _buildErrorMessage(context),
          ],
        );
      },
    );
  }

  Widget _buildProgressiveInvoiceFlow(
    BuildContext context,
    bool isTight,
    double horizontalGap,
    double verticalGap,
    double maxWidth,
    bool hasInvoice,
  ) {
    print('_buildProgressiveInvoiceFlow - Job ${widget.jobId} - hasInvoice: $hasInvoice - isCreatingInvoice: ${widget.isCreatingInvoice}');
    
    // State 1: No invoice - Show Create Invoice button
    if (!hasInvoice && !widget.isCreatingInvoice) {
      print('Showing Create Invoice button for job ${widget.jobId}');
      return _buildCreateInvoiceButton(context, isTight, maxWidth);
    }
    
    // State 2: Creating invoice - Show creating button
    if (widget.isCreatingInvoice) {
      print('Showing Creating Invoice button for job ${widget.jobId}');
      return _buildCreatingInvoiceButton(context, isTight, maxWidth);
    }
    
    // State 3: Invoice created - Show status and action buttons
    if (hasInvoice) {
      print('Showing Invoice Created state for job ${widget.jobId}');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status button
          _buildInvoiceCreatedButton(context, isTight, maxWidth),
          const SizedBox(height: 8),
          // Action buttons
          _buildInvoiceActionButtons(
            context,
            isTight,
            horizontalGap,
            verticalGap,
            maxWidth,
          ),
        ],
      );
    }
    
    print('Returning empty widget for job ${widget.jobId}');
    return const SizedBox.shrink();
  }

  Widget _buildCreateInvoiceButton(
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
                        onPressed: widget.invoiceState.isLoading ? null : widget.onCreateInvoice,
          icon: const Icon(Icons.receipt_long, size: 16),
          label: const Text('Create Invoice', style: TextStyle(fontSize: 12)),
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

  Widget _buildCreatingInvoiceButton(
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
          label: const Text('Creating Invoice...', style: TextStyle(fontSize: 12)),
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

  Widget _buildInvoiceCreatedButton(
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
          label: const Text('Invoice Created', style: TextStyle(fontSize: 12)),
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

  Widget _buildInvoiceActionButtons(
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
        // View Invoice button
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: isTight ? 100 : 120,
            maxWidth: maxWidth * 0.6,
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.invoiceState.isLoading ? null : widget.onOpenInvoice,
              icon: const Icon(Icons.open_in_new, size: 14),
              label: const Text('View Invoice', style: TextStyle(fontSize: 11)),
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

        // Reload Invoice button
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: isTight ? 100 : 120,
            maxWidth: maxWidth * 0.6,
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.invoiceState.isLoading ? null : widget.onRegenerateInvoice,
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Reload Invoice', style: TextStyle(fontSize: 11)),
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
          'Share Invoice',
          onTap: widget.invoiceState.isLoading ? null : widget.onShowShareOptions,
        ),
      ],
    );
  }

  Widget _buildInvoiceActions(
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
                'Invoice Created',
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
              onPressed: widget.invoiceState.isLoading ? null : widget.onOpenInvoice,
              icon: const Icon(Icons.open_in_new, size: 14),
              label: const Text('Open Invoice', style: TextStyle(fontSize: 11)),
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
          'Share Invoice',
          onTap: widget.invoiceState.isLoading ? null : widget.onShowShareOptions,
        ),

        // Reload button (if user has permission)
        if (widget.canCreateInvoice)
          _iconAction(
            context,
            Icons.refresh,
            'Reload Invoice',
            onTap: widget.invoiceState.isLoading ? null : widget.onRegenerateInvoice,
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
              'Insufficient permissions to create invoices',
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
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Creating invoice...',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error, size: 12, color: Colors.red[700]),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.invoiceState.errorMessage ?? 'Failed to create invoice',
                style: TextStyle(fontSize: 10, color: Colors.red[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
