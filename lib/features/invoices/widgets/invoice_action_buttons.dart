import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/invoice_data.dart';
import '../providers/invoice_controller.dart';
import '../services/invoice_sharing_service.dart';
import '../../jobs/providers/jobs_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final invoiceState = ref.watch(invoiceControllerProvider);

    return InvoiceActionBar(
      jobId: widget.jobId,
      invoicePdfUrl: widget.invoicePdfUrl,
      invoiceData: widget.invoiceData,
      canCreateInvoice: widget.canCreateInvoice,
      invoiceState: invoiceState,
      onCreateInvoice: _createInvoice,
      onRegenerateInvoice: _regenerateInvoice,
      onOpenInvoice: _openInvoice,
      onShowShareOptions: _showShareOptions,
    );
  }

  Future<void> _createInvoice() async {
    try {
      await ref
          .read(invoiceControllerProvider.notifier)
          .createInvoice(jobId: widget.jobId);

      // Refresh jobs data to show updated invoice status
      await ref.read(jobsProvider.notifier).refreshJobs();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
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

        // Refresh jobs data to show updated invoice status
        await ref.read(jobsProvider.notifier).refreshJobs();

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
      await _sharingService.openInvoiceUrl(widget.invoicePdfUrl!);
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
    if (widget.invoicePdfUrl == null || widget.invoiceData == null) return;

    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share Invoice',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.green),
              title: const Text('WhatsApp'),
              onTap: () => Navigator.of(context).pop('whatsapp'),
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: const Text('Email'),
              onTap: () => Navigator.of(context).pop('email'),
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.grey),
              title: const Text('Copy Link'),
              onTap: () => Navigator.of(context).pop('copy'),
            ),
          ],
        ),
      ),
    );

    if (result == 'whatsapp') {
      await _shareViaWhatsApp();
    } else if (result == 'email') {
      await _shareViaEmail();
    } else if (result == 'copy') {
      await _copyLink();
    }
  }

  Future<void> _shareViaWhatsApp() async {
    if (widget.invoicePdfUrl == null || widget.invoiceData == null) return;

    try {
      await _sharingService.shareInvoiceViaWhatsApp(
        invoiceUrl: widget.invoicePdfUrl!,
        invoiceData: widget.invoiceData!,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share via WhatsApp: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareViaEmail() async {
    if (widget.invoicePdfUrl == null || widget.invoiceData == null) return;

    try {
      await _sharingService.shareInvoiceViaEmail(
        invoiceUrl: widget.invoicePdfUrl!,
        invoiceData: widget.invoiceData!,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share via email: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _copyLink() async {
    if (widget.invoicePdfUrl == null || widget.invoiceData == null) return;

    try {
      await _sharingService.copyInvoiceLink(
        invoiceUrl: widget.invoicePdfUrl!,
        invoiceData: widget.invoiceData!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice link copied to clipboard!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy link: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Responsive invoice action bar that prevents overflow on narrow cards
class InvoiceActionBar extends StatelessWidget {
  final String jobId;
  final String? invoicePdfUrl;
  final InvoiceData? invoiceData;
  final bool canCreateInvoice;
  final InvoiceControllerState invoiceState;
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
    required this.onCreateInvoice,
    required this.onRegenerateInvoice,
    required this.onOpenInvoice,
    required this.onShowShareOptions,
  });

  @override
  Widget build(BuildContext context) {
    final hasInvoice = invoicePdfUrl != null && invoicePdfUrl!.isNotEmpty;

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

            // Invoice status and actions
            if (!hasInvoice && canCreateInvoice)
              _buildCreateInvoiceButton(context, isTight, constraints.maxWidth)
            else if (hasInvoice) ...[
              const SizedBox(height: 6),
              _buildInvoiceActions(
                context,
                isTight,
                horizontalGap,
                verticalGap,
                constraints.maxWidth,
              ),
            ] else if (!canCreateInvoice) ...[
              const SizedBox(height: 6),
              _buildNoPermissionMessage(context),
            ],

            // Loading indicator
            if (invoiceState.isLoading) _buildLoadingIndicator(context),

            // Error message
            if (invoiceState.hasError) _buildErrorMessage(context),
          ],
        );
      },
    );
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
          onPressed: invoiceState.isLoading ? null : onCreateInvoice,
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
              onPressed: invoiceState.isLoading ? null : onOpenInvoice,
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
          onTap: invoiceState.isLoading ? null : onShowShareOptions,
        ),

        // Reload button (if user has permission)
        if (canCreateInvoice)
          _iconAction(
            context,
            Icons.refresh,
            'Reload Invoice',
            onTap: invoiceState.isLoading ? null : onRegenerateInvoice,
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
                invoiceState.errorMessage ?? 'Failed to create invoice',
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
