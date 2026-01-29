import 'package:flutter/material.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';

/// Compact KPI tile for Operations Dashboard: icon in circle, value, label.
/// [isProblem] applies subtle red tint border/gradient for the Problem tile.
class OpsKpiTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool isProblem;

  const OpsKpiTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.isProblem = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final spacing = ResponsiveTokens.getSpacing(width);
    final radius = ResponsiveTokens.getCornerRadius(width);
    final padding = ResponsiveTokens.getPadding(width);

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: isProblem
            ? ChoiceLuxTheme.errorColor.withOpacity(0.08)
            : ChoiceLuxTheme.charcoalGray.withOpacity(0.8),
        borderRadius: BorderRadius.circular(radius),
        border: isProblem
            ? Border.all(
                color: ChoiceLuxTheme.errorColor.withOpacity(0.4),
                width: 1,
              )
            : Border.all(
                color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
                width: 1,
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(spacing),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(radius * 0.75),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  color: ChoiceLuxTheme.softWhite,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing),
          Text(
            label,
            style: TextStyle(
              color: ChoiceLuxTheme.platinumSilver.withOpacity(0.9),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
