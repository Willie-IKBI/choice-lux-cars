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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Voucher section header
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Voucher',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),

        // Voucher status and actions
        if (!hasVoucher && widget.canCreateVoucher)
          _buildCreateVoucherButton(voucherState)
        else if (hasVoucher)
          _buildVoucherActions(voucherState)
        else if (!widget.canCreateVoucher)
          _buildNoPermissionMessage(),

        // Loading indicator
        if (voucherState.isLoading)
          _buildLoadingIndicator(voucherState),

        // Error message
        if (voucherState.hasError)
          _buildErrorMessage(voucherState),
      ],
    );
  }

  Widget _buildCreateVoucherButton(VoucherControllerState voucherState) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: voucherState.isLoading ? null : _createVoucher,
        icon: const Icon(Icons.receipt_long, size: 18),
        label: const Text('Create Voucher'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildVoucherActions(VoucherControllerState voucherState) {
    return Row(
      children: [
        // Status chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                size: 16,
                color: Colors.green[700],
              ),
              const SizedBox(width: 4),
              Text(
                'Voucher Created',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Open button
        IconButton(
          onPressed: voucherState.isLoading ? null : _openVoucher,
          icon: const Icon(Icons.open_in_new, size: 20),
          tooltip: 'Open Voucher',
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),

        // Share button
        IconButton(
          onPressed: voucherState.isLoading ? null : _showShareOptions,
          icon: const Icon(Icons.share, size: 20),
          tooltip: 'Share Voucher',
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),

        // Regenerate button (if user has permission)
        if (widget.canCreateVoucher)
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'regenerate') {
                _regenerateVoucher();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'regenerate',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 18),
                    SizedBox(width: 8),
                    Text('Regenerate Voucher'),
                  ],
                ),
              ),
            ],
            child: IconButton(
              onPressed: voucherState.isLoading ? null : null,
              icon: const Icon(Icons.more_vert, size: 20),
              tooltip: 'More Options',
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNoPermissionMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            'Insufficient permissions to create vouchers',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(VoucherControllerState voucherState) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              voucherState.loadingMessage,
              style: TextStyle(
                fontSize: 12,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 16,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              voucherState.errorMessage ?? 'An error occurred',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
          TextButton(
            onPressed: _createVoucher,
            child: const Text('Retry'),
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
        title: const Text('Regenerate Voucher'),
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
            child: const Text('Regenerate'),
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
              content: Text('Voucher regenerated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to regenerate voucher: ${e.toString()}'),
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
