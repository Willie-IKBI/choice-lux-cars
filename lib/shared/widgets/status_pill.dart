import 'package:flutter/material.dart';

/// A reusable status pill widget for displaying status information consistently
class StatusPill extends StatelessWidget {
  final IconData? icon;
  final Color color;
  final String text;
  final double height;
  final EdgeInsets padding;
  final bool showDot;
  final double? fontSize;

  const StatusPill({
    super.key,
    this.icon,
    required this.color,
    required this.text,
    this.height = 24,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
    this.showDot = true,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveFontSize = fontSize ?? (height * 0.4);
    final dotSize = height * 0.25;
    final iconSize = height * 0.6;

    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: color),
            SizedBox(width: height * 0.25),
          ] else if (showDot) ...[
            Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            SizedBox(width: height * 0.25),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: effectiveFontSize,
            ),
          ),
        ],
      ),
    );
  }
}

/// A specialized status pill for job statuses
class JobStatusPill extends StatelessWidget {
  final String status;
  final double height;
  final EdgeInsets padding;
  final double? fontSize;

  const JobStatusPill({
    super.key,
    required this.status,
    this.height = 24,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    // Import the JobStatus enum and extension
    // This would need to be imported from the job model
    // For now, we'll use a simple mapping
    final (color, label) = _getStatusInfo(status);

    return StatusPill(
      color: color,
      text: label,
      height: height,
      padding: padding,
      fontSize: fontSize,
      showDot: true,
    );
  }

  (Color, String) _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return (const Color(0xFFD4AF37), 'ASSIGNED'); // richGold
      case 'started':
        return (const Color(0xFFF59E0B), 'STARTED'); // orange
      case 'in_progress':
        return (const Color(0xFF3B82F6), 'IN PROGRESS'); // infoColor
      case 'ready_to_close':
        return (const Color(0xFF8B5CF6), 'READY TO CLOSE'); // purple
      case 'completed':
        return (const Color(0xFF059669), 'COMPLETED'); // successColor
      case 'cancelled':
        return (const Color(0xFFDC2626), 'CANCELLED'); // errorColor
      default:
        return (const Color(0xFFC0C0C0), 'OPEN'); // platinumSilver
    }
  }
}

/// A specialized status pill for driver confirmation status
class DriverConfirmationPill extends StatelessWidget {
  final bool? isConfirmed;
  final double height;
  final EdgeInsets padding;
  final double? fontSize;

  const DriverConfirmationPill({
    super.key,
    required this.isConfirmed,
    this.height = 24,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final (color, text) = _getConfirmationInfo(isConfirmed);

    return StatusPill(
      color: color,
      text: text,
      height: height,
      padding: padding,
      fontSize: fontSize,
      showDot: true,
    );
  }

  (Color, String) _getConfirmationInfo(bool? isConfirmed) {
    if (isConfirmed == null) {
      return (Colors.grey, 'Pending');
    } else if (isConfirmed == true) {
      return (Colors.green, 'Confirmed');
    } else {
      return (Colors.red, 'Not Confirmed');
    }
  }
}

/// A specialized status pill for time-based status
class TimeStatusPill extends StatelessWidget {
  final int? daysUntilStart;
  final double height;
  final EdgeInsets padding;
  final double? fontSize;
  final bool isSmallScreen;

  const TimeStatusPill({
    super.key,
    required this.daysUntilStart,
    this.height = 24,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
    this.fontSize,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final (color, text, icon) = _getTimeInfo(daysUntilStart, isSmallScreen);

    return StatusPill(
      color: color,
      text: text,
      icon: icon,
      height: height,
      padding: padding,
      fontSize: fontSize,
      showDot: false,
    );
  }

  (Color, String, IconData) _getTimeInfo(
    int? daysUntilStart,
    bool isSmallScreen,
  ) {
    if (daysUntilStart == null) {
      return (Colors.grey, 'Unknown', Icons.schedule);
    }

    final isStarted = daysUntilStart < 0;
    final isToday = daysUntilStart == 0;
    final isSoon = daysUntilStart <= 3 && daysUntilStart > 0;

    if (isStarted) {
      final text = isSmallScreen
          ? '${daysUntilStart.abs()}d ago'
          : 'Started ${daysUntilStart.abs()}d ago';
      return (Colors.grey, text, Icons.schedule);
    } else if (isToday) {
      return (Colors.orange, 'TODAY', Icons.today);
    } else if (isSoon) {
      final text = isSmallScreen
          ? '${daysUntilStart}d'
          : 'URGENT ${daysUntilStart}d';
      return (Colors.red, text, Icons.warning);
    } else {
      final text = isSmallScreen
          ? '${daysUntilStart}d'
          : 'In ${daysUntilStart}d';
      return (Colors.green, text, Icons.calendar_today);
    }
  }
}
