import 'package:flutter/material.dart';

class LicenseStatusBadge extends StatelessWidget {
  final DateTime expiryDate;
  const LicenseStatusBadge({super.key, required this.expiryDate});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final in3Months = now.add(const Duration(days: 90));
    Color color;
    String text;
    IconData icon;

    if (expiryDate.isBefore(now)) {
      color = Colors.red;
      text = 'Expired';
      icon = Icons.error;
    } else if (expiryDate.isBefore(in3Months)) {
      color = Colors.orange;
      text = 'Expiring Soon';
      icon = Icons.warning;
    } else {
      color = Colors.green;
      text = 'Valid';
      icon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
