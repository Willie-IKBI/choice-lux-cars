import 'package:flutter/material.dart';
import 'package:choice_lux_cars/app/theme.dart';

/// Displays a 0-5 star rating. Uses [ChoiceLuxTheme.richGold] for filled stars.
class StarRatingBar extends StatelessWidget {
  /// Rating value 0-5 (can be null for "no rating")
  final double? rating;
  /// Size of each star
  final double size;
  /// Color for filled/half stars
  final Color? activeColor;
  /// Color for empty stars
  final Color? inactiveColor;

  const StarRatingBar({
    super.key,
    required this.rating,
    this.size = 16.0,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final active = activeColor ?? ChoiceLuxTheme.richGold;
    final inactive = inactiveColor ?? ChoiceLuxTheme.platinumSilver.withOpacity(0.5);
    final value = rating == null ? 0.0 : rating!.clamp(0.0, 5.0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final starValue = value - i;
        if (starValue >= 1.0) {
          return Icon(Icons.star, size: size, color: active);
        }
        if (starValue > 0.0) {
          return Icon(Icons.star_half, size: size, color: active);
        }
        return Icon(Icons.star_border, size: size, color: inactive);
      }),
    );
  }
}
