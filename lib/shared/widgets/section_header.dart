import 'package:flutter/material.dart';
import 'package:choice_lux_cars/app/theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? iconColor;

  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return Row(
        children: [
          Icon(icon, color: iconColor ?? ChoiceLuxTheme.richGold, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ChoiceLuxTheme.softWhite,
            ),
          ),
        ],
      );
    }

    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: ChoiceLuxTheme.softWhite,
      ),
    );
  }
}
