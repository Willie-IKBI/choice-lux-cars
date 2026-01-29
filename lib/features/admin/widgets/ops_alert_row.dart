import 'package:flutter/material.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/admin/models/ops_today_summary.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';

/// Single alert list card: icon + job id | reason + secondary | actions (Assign, Close, View).
/// Row tap (content area) navigates to job summary; action buttons do not trigger row tap.
/// On mobile, actions can collapse into overflow menu.
class OpsAlertRow extends StatelessWidget {
  final OpsAlertItem item;
  final bool isAdmin;
  final bool useOverflowMenu;
  final bool assigning;
  final bool closing;
  final VoidCallback onAssign;
  final VoidCallback? onClose;
  final VoidCallback onView;

  const OpsAlertRow({
    super.key,
    required this.item,
    required this.isAdmin,
    required this.useOverflowMenu,
    required this.assigning,
    required this.closing,
    required this.onAssign,
    this.onClose,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final spacing = ResponsiveTokens.getSpacing(width);
    final radius = ResponsiveTokens.getCornerRadius(width);
    final durationText = item.ageMinutes >= 60
        ? '${item.ageMinutes ~/ 60}h ${item.ageMinutes % 60}m ago'
        : '${item.ageMinutes}m ago';

    final leftContent = Padding(
      padding: EdgeInsets.symmetric(vertical: spacing * 1.25, horizontal: spacing * 1.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_outlined, color: ChoiceLuxTheme.errorColor, size: 24),
          SizedBox(width: spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Job #${item.jobId}',
                  style: TextStyle(
                    color: ChoiceLuxTheme.softWhite,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: spacing * 0.25),
                Text(
                  item.reason,
                  style: TextStyle(
                    color: ChoiceLuxTheme.platinumSilver,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: spacing * 0.25),
                Text(
                  '${item.currentStep.isNotEmpty ? item.currentStep : '—'} · $durationText',
                  style: TextStyle(color: ChoiceLuxTheme.grey, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: EdgeInsets.only(bottom: spacing),
        decoration: BoxDecoration(
          color: ChoiceLuxTheme.charcoalGray.withOpacity(0.5),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onView,
                borderRadius: BorderRadius.circular(radius),
                child: leftContent,
              ),
            ),
            if (useOverflowMenu) _buildOverflowButton(context, spacing, isAdmin && item.requiresClose) else _buildActions(context, spacing, isAdmin && item.requiresClose),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, double spacing, bool showClose) {
    return Padding(
      padding: EdgeInsets.only(right: spacing),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAdmin)
            SizedBox(
              height: 32,
              child: TextButton(
                onPressed: assigning ? null : onAssign,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: assigning
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: ChoiceLuxTheme.richGold),
                      )
                    : Text('Assign', style: TextStyle(fontSize: 13, color: ChoiceLuxTheme.richGold)),
              ),
            ),
          if (item.reason == 'Missing agent assignment') ...[
            SizedBox(width: spacing * 0.5),
            SizedBox(
              height: 32,
              child: TextButton(
                onPressed: onView,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('Open job', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
          if (showClose && onClose != null) ...[
            SizedBox(width: spacing * 0.5),
            SizedBox(
              height: 32,
              child: TextButton(
                onPressed: closing ? null : onClose,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: closing
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: ChoiceLuxTheme.richGold),
                      )
                    : Text('Close', style: TextStyle(fontSize: 13, color: ChoiceLuxTheme.errorColor)),
              ),
            ),
          ],
          SizedBox(width: spacing * 0.5),
          IconButton(
            icon: Icon(Icons.arrow_forward_ios, size: 14, color: ChoiceLuxTheme.platinumSilver),
            onPressed: onView,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
            style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          ),
        ],
      ),
    );
  }

  Widget _buildOverflowButton(BuildContext context, double spacing, bool showClose) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: ChoiceLuxTheme.platinumSilver, size: 20),
      padding: EdgeInsets.zero,
      onSelected: (value) {
        if (value == 'assign') onAssign();
        if (value == 'close' && onClose != null) onClose!();
        if (value == 'view') onView();
      },
      itemBuilder: (context) => [
        if (isAdmin) const PopupMenuItem(value: 'assign', child: Text('Assign')),
        if (showClose && onClose != null) const PopupMenuItem(value: 'close', child: Text('Close')),
        const PopupMenuItem(value: 'view', child: Text('View job')),
      ],
    );
  }
}
