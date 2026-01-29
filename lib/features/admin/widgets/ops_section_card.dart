import 'package:flutter/material.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';

/// Section container for Operations Dashboard: title, optional count badge, optional filter chips, content.
/// Uses consistent card padding (16–20px) and elevation.
class OpsSectionCard extends StatelessWidget {
  final String title;
  final int? count;
  final List<String>? filterChipLabels;
  final String? selectedFilterLabel;
  final ValueChanged<String?>? onFilterChanged;
  final Widget child;

  const OpsSectionCard({
    super.key,
    required this.title,
    this.count,
    this.filterChipLabels,
    this.selectedFilterLabel,
    this.onFilterChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final padding = ResponsiveTokens.getPadding(width);
    final spacing = ResponsiveTokens.getSpacing(width);
    final radius = ResponsiveTokens.getCornerRadius(width);
    final cardPadding = (padding + 4).clamp(16.0, 20.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray.withOpacity(0.6),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: ChoiceLuxTheme.softWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (count != null) ...[
                SizedBox(width: spacing),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ChoiceLuxTheme.richGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '($count)',
                    style: TextStyle(
                      color: ChoiceLuxTheme.richGold,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (filterChipLabels != null && filterChipLabels!.isNotEmpty) ...[
            SizedBox(height: spacing),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filterChipLabels!
                    .map((label) => Padding(
                          padding: EdgeInsets.only(right: spacing),
                          child: FilterChip(
                            label: Text(label, style: TextStyle(fontSize: 12, color: ChoiceLuxTheme.softWhite)),
                            selected: selectedFilterLabel == label,
                            onSelected: onFilterChanged != null
                                ? (_) => onFilterChanged!(label)
                                : null,
                            selectedColor: ChoiceLuxTheme.richGold.withOpacity(0.25),
                            checkmarkColor: ChoiceLuxTheme.richGold,
                            backgroundColor: ChoiceLuxTheme.jetBlack.withOpacity(0.5),
                            side: BorderSide(
                              color: selectedFilterLabel == label
                                  ? ChoiceLuxTheme.richGold.withOpacity(0.5)
                                  : ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            SizedBox(height: spacing),
          ],
          child,
        ],
      ),
    );
  }
}
