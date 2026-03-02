import 'package:flutter/material.dart';
import 'package:choice_lux_cars/app/theme.dart';

/// Base action bar layout shared by Invoice and Voucher action buttons.
/// Subclass or use directly by providing document-specific labels.
class DocumentActionBar extends StatelessWidget {
  final String documentType;
  final bool hasDocument;
  final bool compact;
  final bool isLoading;
  final bool isCreating;
  final bool hasError;
  final bool canCreate;
  final String? errorMessage;
  final VoidCallback onCreate;
  final VoidCallback onRegenerate;
  final VoidCallback onOpen;
  final VoidCallback onShare;

  const DocumentActionBar({
    super.key,
    required this.documentType,
    required this.hasDocument,
    this.compact = false,
    required this.isLoading,
    required this.isCreating,
    required this.hasError,
    required this.canCreate,
    this.errorMessage,
    required this.onCreate,
    required this.onRegenerate,
    required this.onOpen,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 400.0;
        final isTight = maxWidth < 200;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!compact)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  documentType,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                  ),
                ),
              ),
            if (!canCreate) ...[
              const SizedBox(height: 6),
              _buildNoPermission(context),
            ] else
              _buildFlow(context, isTight, maxWidth),
            if (isLoading) _buildLoading(context),
            if (hasError)
              compact ? _buildCompactError(context) : _buildError(context),
          ],
        );
      },
    );
  }

  Widget _buildFlow(BuildContext context, bool isTight, double maxWidth) {
    if (!hasDocument && !isCreating) {
      return _buildCreateButton(context, isTight, maxWidth);
    }
    if (isCreating) {
      return _buildCreatingButton(context, isTight, maxWidth);
    }
    if (hasDocument) {
      if (compact) return _buildCompactViewButton(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCreatedStatus(context, isTight, maxWidth),
          const SizedBox(height: 8),
          _buildActions(context),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildCompactViewButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isLoading ? null : onOpen,
      icon: const Icon(Icons.description, size: 14),
      label: Text('View $documentType', style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: ChoiceLuxTheme.platinumSilver,
        side: BorderSide(color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        minimumSize: const Size(0, 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildCreateButton(BuildContext context, bool isTight, double maxWidth) {
    if (compact) {
      return OutlinedButton.icon(
        onPressed: isLoading ? null : onCreate,
        icon: const Icon(Icons.receipt_long, size: 14),
        label: Text('Create $documentType', style: const TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          foregroundColor: ChoiceLuxTheme.platinumSilver,
          side: BorderSide(color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          minimumSize: const Size(0, 44),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onCreate,
        icon: const Icon(Icons.receipt_long, size: 16),
        label: Text('Create $documentType', style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: ChoiceLuxTheme.richGold,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildCreatingButton(BuildContext context, bool isTight, double maxWidth) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: null,
        icon: const SizedBox(
          width: 16, height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        label: Text('Creating $documentType...', style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildCreatedStatus(BuildContext context, bool isTight, double maxWidth) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.access_time, size: 16),
        label: Text('$documentType Created', style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: ChoiceLuxTheme.charcoalGray.withValues(alpha: 0.8),
          foregroundColor: ChoiceLuxTheme.platinumSilver,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : onOpen,
            icon: const Icon(Icons.description, size: 14),
            label: Text('View $documentType', style: const TextStyle(fontSize: 11)),
            style: ElevatedButton.styleFrom(
              backgroundColor: ChoiceLuxTheme.richGold,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onRegenerate,
                icon: const Icon(Icons.refresh, size: 14),
                label: Text('Reload $documentType', style: const TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ChoiceLuxTheme.charcoalGray,
                  foregroundColor: Colors.white,
                  side: BorderSide(color: ChoiceLuxTheme.richGold.withValues(alpha: 0.4), width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Share $documentType',
              child: InkWell(
                onTap: isLoading ? null : onShare,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onSecondaryContainer.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    Icons.share, size: 16,
                    color: isLoading ? Colors.grey : Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoPermission(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.lock, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Insufficient permissions to create ${documentType.toLowerCase()}s',
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14, height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Creating ${documentType.toLowerCase()}...',
            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactError(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 12, color: Colors.red[700]),
            const SizedBox(width: 6),
            Text(
              '$documentType action failed',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: Colors.red[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
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
          mainAxisSize: MainAxisSize.max,
          children: [
            Icon(Icons.error, size: 12, color: Colors.red[700]),
            const SizedBox(width: 4),
            Flexible(
              fit: FlexFit.loose,
              child: Text(
                errorMessage ?? 'Failed to create ${documentType.toLowerCase()}',
                style: TextStyle(fontSize: 10, color: Colors.red[700]),
                maxLines: 2, overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
