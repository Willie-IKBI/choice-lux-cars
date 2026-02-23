import 'package:flutter/material.dart';
import 'package:choice_lux_cars/app/theme.dart';

/// Small help icon for KPIs/metrics. On tap shows a dialog with [explanation].
class MetricHelpIcon extends StatelessWidget {
  final String explanation;

  const MetricHelpIcon({
    super.key,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('About this metric'),
            content: Text(explanation),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
      icon: Icon(
        Icons.help_outline,
        size: 20,
        color: ChoiceLuxTheme.platinumSilver.withOpacity(0.9),
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
