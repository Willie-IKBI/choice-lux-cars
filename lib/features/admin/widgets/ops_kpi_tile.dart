import 'package:flutter/material.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/widgets/metric_help_icon.dart';

/// KPI tile for Operations Dashboard and Insights: label, value, icon, optional tap and problem styling.
class OpsKpiTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool isProblem;
  final VoidCallback? onTap;
  final String? helpText;

  const OpsKpiTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.isProblem = false,
    this.onTap,
    this.helpText,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isProblem
        ? ChoiceLuxTheme.errorColor.withOpacity(0.4)
        : ChoiceLuxTheme.platinumSilver.withOpacity(0.12);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: ChoiceLuxTheme.charcoalGray.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (helpText != null)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                color: ChoiceLuxTheme.softWhite.withOpacity(0.8),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          MetricHelpIcon(explanation: helpText!),
                        ],
                      )
                    else
                      Text(
                        label,
                        style: TextStyle(
                          color: ChoiceLuxTheme.softWhite.withOpacity(0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: TextStyle(
                          color: ChoiceLuxTheme.softWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
