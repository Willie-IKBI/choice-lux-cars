import 'package:flutter/material.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/app/theme_helpers.dart';

/// Shared luxury button widget to eliminate duplicate button building functions
class LuxuryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool isPrimary;
  final bool isLoading;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const LuxuryButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.isPrimary = false,
    this.isLoading = false,
    this.width,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.brandGold,
              context.brandGold.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(context.radiusMd),
          boxShadow: [
            BoxShadow(
              color: context.brandGold.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : Icon(icon, color: Colors.black, size: 20),
          label: Text(
            isLoading ? 'Processing...' : label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding:
                padding ??
                EdgeInsets.symmetric(
                  horizontal: context.spacing,
                  vertical: context.spacing * 0.75,
                ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.radiusMd),
            ),
          ),
        ),
      );
    } else {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: ChoiceLuxTheme.charcoalGray,
          borderRadius: BorderRadius.circular(context.radiusMd),
          border: Border.all(
            color: context.brandGold.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      context.brandGold,
                    ),
                  ),
                )
              : Icon(icon, color: context.brandGold, size: 20),
          label: Text(
            isLoading ? 'Processing...' : label,
            style: TextStyle(
              color: context.brandGold,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding:
                padding ??
                EdgeInsets.symmetric(
                  horizontal: context.spacing,
                  vertical: context.spacing * 0.75,
                ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.radiusMd),
            ),
          ),
        ),
      );
    }
  }
}
