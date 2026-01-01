import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

class AddressDisplayWidget extends StatelessWidget {
  final String address;
  final String? label;
  final IconData? icon;
  final bool showLabel;
  final bool clickable;
  final VoidCallback? onTap;

  const AddressDisplayWidget({
    super.key,
    required this.address,
    this.label,
    this.icon,
    this.showLabel = true,
    this.clickable = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayAddress = address.trim().isNotEmpty
        ? address
        : 'Address not specified';
    final isAddressValid = address.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel && label != null) ...[
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: ChoiceLuxTheme.richGold),
                const SizedBox(width: 4),
              ],
              Text(
                label!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ChoiceLuxTheme.platinumSilver,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        GestureDetector(
          onTap: clickable && isAddressValid ? () => _openInMaps(context) : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: clickable && isAddressValid
                  ? ChoiceLuxTheme.richGold.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: clickable && isAddressValid
                  ? Border.all(
                      color: ChoiceLuxTheme.richGold.withValues(alpha: 0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: isAddressValid
                      ? (clickable
                            ? ChoiceLuxTheme.richGold
                            : ChoiceLuxTheme.platinumSilver)
                      : ChoiceLuxTheme.errorColor,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    displayAddress,
                    style: TextStyle(
                      fontSize: 12,
                      color: isAddressValid
                          ? (clickable
                                ? ChoiceLuxTheme.richGold
                                : ChoiceLuxTheme.platinumSilver)
                          : ChoiceLuxTheme.errorColor,
                      decoration: clickable && isAddressValid
                          ? TextDecoration.underline
                          : null,
                    ),
                  ),
                ),
                if (clickable && isAddressValid) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.open_in_new,
                    size: 12,
                    color: ChoiceLuxTheme.richGold,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSnack(BuildContext context, String msg) {
    final m = ScaffoldMessenger.maybeOf(context);
    if (m != null) m.showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openInMaps(BuildContext context) async {
    try {
      final encodedAddress = Uri.encodeComponent(address);
      final url = 'https://maps.google.com/maps?q=$encodedAddress';

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch maps');
      }
    } catch (e) {
      Log.e('Error opening maps: $e');
      // Show error message to user
      if (context.mounted) {
        _showSnack(context, 'Error opening maps: $e');
      }
    }
  }
}
