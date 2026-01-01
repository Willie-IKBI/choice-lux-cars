import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:choice_lux_cars/features/invoices/models/invoice_data.dart';
import 'package:choice_lux_cars/features/invoices/providers/invoice_controller.dart';
import 'package:choice_lux_cars/features/invoices/services/invoice_sharing_service.dart';
import 'package:choice_lux_cars/shared/services/pdf_viewer_service.dart';
import 'package:choice_lux_cars/core/providers/job_invoice_provider.dart';
import 'package:choice_lux_cars/app/theme_helpers.dart';

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
    
    // Watch job invoice PDF provider to get the most up-to-date invoice PDF URL
    final invoicePdfAsync = ref.watch(jobInvoicePdfProvider(widget.jobId));
    final currentInvoicePdfUrl = invoicePdfAsync.when(
      data: (invoicePdf) => invoicePdf ?? widget.invoicePdfUrl,
      loading: () => widget.invoicePdfUrl,
      error: (_, __) => widget.invoicePdfUrl,
    );

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

      // Refresh job invoice PDF URL to show updated invoice status
      ref.invalidate(jobInvoicePdfProvider(widget.jobId));
      
      // Add a small delay to ensure the database update has propagated
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _isCreatingInvoice = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invoice created successfully!'),
            backgroundColor: context.tokens.successColor,
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
            backgroundColor: context.tokens.warningColor,
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

        // Refresh job invoice PDF URL to show updated invoice status
        ref.invalidate(jobInvoicePdfProvider(widget.jobId));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Invoice regenerated successfully!'),
              backgroundColor: context.tokens.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to regenerate invoice: ${e.toString()}'),
              backgroundColor: context.tokens.warningColor,
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
            backgroundColor: context.tokens.warningColor,
          ),
        );
      }
    }
  }

  Future<void> _showShareOptions() async {
    // Get the most current invoice PDF URL
    final invoicePdfAsync = ref.read(jobInvoicePdfProvider(widget.jobId));
    final currentInvoicePdfUrl = invoicePdfAsync.when(
      data: (invoicePdf) => invoicePdf ?? widget.invoicePdfUrl,
      loading: () => widget.invoicePdfUrl,
      error: (_, __) => widget.invoicePdfUrl,
    );
    
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
            backgroundColor: context.tokens.warningColor,
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
        const verticalGap = 4.0;

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
          icon: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                context.colorScheme.onPrimary,
              ),
            ),
          ),
          label: const Text('Creating Invoice...', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: context.colorScheme.primary,
            foregroundColor: context.colorScheme.onPrimary,
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
            backgroundColor: context.tokens.successColor,
            foregroundColor: context.tokens.onSuccess,
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
                ? context.tokens.textSubtle
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
          color: context.tokens.warningColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: context.tokens.warningColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error,
              size: 12,
              color: context.tokens.warningColor,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.invoiceState.errorMessage ?? 'Failed to create invoice',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.tokens.warningColor,
                  fontSize: 10,
                ),
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
