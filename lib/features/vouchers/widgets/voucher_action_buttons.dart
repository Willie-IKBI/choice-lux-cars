import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/voucher_data.dart';
import '../providers/voucher_controller.dart';
import '../services/voucher_sharing_service.dart';

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
  ConsumerState<VoucherActionButtons> createState() => _VoucherActionButtonsState();
}

class _VoucherActionButtonsState extends ConsumerState<VoucherActionButtons> {
  final VoucherSharingService _sharingService = VoucherSharingService();

  @override
  Widget build(BuildContext context) {
    final voucherState = ref.watch(voucherControllerProvider);
    final hasVoucher = widget.voucherPdfUrl != null && widget.voucherPdfUrl!.isNotEmpty;

    return Container(
      constraints: const BoxConstraints(maxHeight: 120), // Increased height to prevent overflow
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Voucher section header
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0), // Increased from 4.0
            child: Text(
              'Voucher',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12, // Smaller font size
              ),
            ),
          ),

          // Voucher status and actions
          if (!hasVoucher && widget.canCreateVoucher)
            _buildCreateVoucherButton(voucherState)
          else if (hasVoucher) ...[
            const SizedBox(height: 6), // Add spacing between header and content
            _buildVoucherActions(voucherState)
          ] else if (!widget.canCreateVoucher) ...[
            const SizedBox(height: 6), // Add spacing between header and content
            _buildNoPermissionMessage()
          ],

          // Loading indicator
          if (voucherState.isLoading)
            _buildLoadingIndicator(voucherState),

          // Error message
          if (voucherState.hasError)
            _buildErrorMessage(voucherState),
        ],
      ),
    );
  }

  Widget _buildCreateVoucherButton(VoucherControllerState voucherState) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: voucherState.isLoading ? null : _createVoucher,
        icon: const Icon(Icons.receipt_long, size: 16), // Increased from 14
        label: const Text('Create Voucher', style: TextStyle(fontSize: 12)), // Increased from 11
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16), // Increased padding
          minimumSize: const Size(0, 36), // Increased from 28
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Add rounded corners
          ),
        ),
      ),
    );
  }

  Widget _buildVoucherActions(VoucherControllerState voucherState) {
    return Row(
      children: [
        // Status chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                size: 14,
                color: Colors.green[700],
              ),
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
        const SizedBox(width: 12), // Increased from 6 to 12

        // Open button
        IconButton(
          onPressed: voucherState.isLoading ? null : _openVoucher,
          icon: const Icon(Icons.open_in_new, size: 14),
          tooltip: 'Open Voucher',
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            padding: const EdgeInsets.all(6), // Increased from 4
            minimumSize: const Size(28, 28), // Increased from 24x24
          ),
        ),
        const SizedBox(width: 8), // Add spacing between buttons

        // Share button
        IconButton(
          onPressed: voucherState.isLoading ? null : _showShareOptions,
          icon: const Icon(Icons.share, size: 14),
          tooltip: 'Share Voucher',
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
            padding: const EdgeInsets.all(6), // Increased from 4
            minimumSize: const Size(28, 28), // Increased from 24x24
          ),
        ),
        const SizedBox(width: 8), // Add spacing between buttons

        // Reload button (if user has permission)
        if (widget.canCreateVoucher)
          IconButton(
            onPressed: voucherState.isLoading ? null : _regenerateVoucher,
            icon: const Icon(Icons.refresh, size: 14),
            tooltip: 'Reload Voucher',
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
              padding: const EdgeInsets.all(6), // Increased from 4
              minimumSize: const Size(28, 28), // Increased from 24x24
            ),
          ),
      ],
    );
  }

  Widget _buildNoPermissionMessage() {
    return Container(
      padding: const EdgeInsets.all(8), // Reduced padding
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock,
            size: 14, // Smaller icon
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6), // Reduced spacing
          Expanded(
            child: Text(
              'Insufficient permissions to create vouchers',
              style: TextStyle(
                fontSize: 11, // Smaller font size
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(VoucherControllerState voucherState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // Reduced padding
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
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
          const SizedBox(width: 8), // Reduced spacing
          Expanded(
            child: Text(
              voucherState.loadingMessage,
              style: TextStyle(
                fontSize: 11, // Smaller font
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(VoucherControllerState voucherState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // Reduced padding
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 14, // Smaller icon
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 6), // Reduced spacing
          Expanded(
            child: Text(
              voucherState.errorMessage ?? 'An error occurred',
              style: TextStyle(
                fontSize: 11, // Smaller font
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
          TextButton(
            onPressed: _createVoucher,
            child: const Text('Retry', style: TextStyle(fontSize: 11)), // Smaller text
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Reduced padding
              minimumSize: const Size(0, 24), // Smaller minimum size
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createVoucher() async {
    try {
      await ref.read(voucherControllerProvider.notifier).createVoucher(
        jobId: widget.jobId,
      );
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voucher created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
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
    // Show confirmation dialog
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
        await ref.read(voucherControllerProvider.notifier).regenerateVoucher(
          jobId: widget.jobId,
        );
        
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
      await _sharingService.openVoucherUrl(widget.voucherPdfUrl!);
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

    showModalBottomSheet(
      context: context,
      builder: (context) => _buildShareOptionsSheet(),
    );
  }

  Widget _buildShareOptionsSheet() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Share Voucher',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
                     ListTile(
             leading: const Icon(Icons.chat, color: Colors.green),
             title: const Text('WhatsApp'),
             subtitle: Text('Share via WhatsApp'),
            onTap: () {
              Navigator.of(context).pop();
              _shareViaWhatsApp();
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('System Share'),
            subtitle: const Text('Use system share sheet'),
            onTap: () {
              Navigator.of(context).pop();
              _shareViaSystem();
            },
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Email'),
            subtitle: const Text('Share via email'),
            onTap: () {
              Navigator.of(context).pop();
              _shareViaEmail();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _shareViaWhatsApp() async {
    if (widget.voucherPdfUrl == null || widget.voucherData == null) return;

    try {
      await _sharingService.shareVoucherViaWhatsApp(
        voucherUrl: widget.voucherPdfUrl!,
        voucherData: widget.voucherData!,
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

  Future<void> _shareViaSystem() async {
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
            content: Text('Failed to share: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareViaEmail() async {
    if (widget.voucherPdfUrl == null || widget.voucherData == null) return;

    try {
      await _sharingService.shareViaEmail(
        voucherUrl: widget.voucherPdfUrl!,
        voucherData: widget.voucherData!,
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
}
