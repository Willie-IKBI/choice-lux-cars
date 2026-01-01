import 'package:flutter/material.dart';
import 'package:choice_lux_cars/app/theme_tokens.dart';
import 'package:choice_lux_cars/features/jobs/jobs.dart';

/// Centralized status color utilities using Stealth Luxury theme tokens
///
/// This utility provides status-to-color mapping using semantic tokens from
/// AppTokens ThemeExtension. All colors match THEME_SPEC.md values.
///
/// Migration note: Old static methods are deprecated but maintained for
/// backward compatibility. New code should use methods that accept BuildContext.
class StatusColorUtils {
  // Private constructor to prevent instantiation
  StatusColorUtils._();

  // Fallback colors for compatibility layer (matches old behavior)
  // These are only used when BuildContext is not available
  @Deprecated('Use getJobStatusColor with BuildContext instead')
  static const Color _fallbackOpen = Color(0xFF3B82F6); // infoColor
  @Deprecated('Use getJobStatusColor with BuildContext instead')
  static const Color _fallbackAssigned = Color(0xFFF59E0B); // primary (amber)
  @Deprecated('Use getJobStatusColor with BuildContext instead')
  static const Color _fallbackStarted = Color(0xFF3B82F6); // infoColor
  @Deprecated('Use getJobStatusColor with BuildContext instead')
  static const Color _fallbackInProgress = Color(0xFF3B82F6); // infoColor
  @Deprecated('Use getJobStatusColor with BuildContext instead')
  static const Color _fallbackReadyToClose = Color(0xFFF59E0B); // primary (amber)
  @Deprecated('Use getJobStatusColor with BuildContext instead')
  static const Color _fallbackCompleted = Color(0xFF10B981); // successColor
  @Deprecated('Use getJobStatusColor with BuildContext instead')
  static const Color _fallbackCancelled = Color(0xFFF43F5E); // warningColor
  @Deprecated('Use getJobStatusColor with BuildContext instead')
  static const Color _fallbackPending = Color(0xFFF59E0B); // primary (amber)
  @Deprecated('Use getJobStatusColor with BuildContext instead')
  static const Color _fallbackUrgent = Color(0xFFF43F5E); // warningColor
  @Deprecated('Use getJobStatusColor with BuildContext instead')
  static const Color _fallbackDefault = Color(0xFFA1A1AA); // textBody

  /// Get color for job status using theme tokens
  ///
  /// Maps job statuses to semantic tokens:
  /// - completed -> successColor (#10b981)
  /// - inProgress -> infoColor (#3b82f6)
  /// - cancelled -> warningColor (#f43f5e)
  /// - assigned, readyToClose -> primary (#f59e0b)
  /// - open, started -> infoColor (#3b82f6)
  static Color getJobStatusColorWithContext(JobStatus status, BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;

    switch (status) {
      case JobStatus.open:
        return tokens.infoColor; // info/progress
      case JobStatus.assigned:
        return colorScheme.primary; // primary (amber)
      case JobStatus.started:
        return tokens.infoColor; // info/progress
      case JobStatus.inProgress:
        return tokens.infoColor; // info/progress
      case JobStatus.readyToClose:
        return colorScheme.primary; // primary (amber)
      case JobStatus.completed:
        return tokens.successColor; // success (#10b981)
      case JobStatus.cancelled:
        return tokens.warningColor; // warning/error (#f43f5e)
    }
  }

  /// Get color for job status (deprecated compatibility layer)
  ///
  /// @Deprecated Use getJobStatusColor(JobStatus, BuildContext) instead.
  /// This method uses fallback colors and does not respect theme tokens.
  @Deprecated('Use getJobStatusColor(JobStatus, BuildContext) instead. '
      'This method will be removed in a future version.')
  static Color getJobStatusColorLegacy(JobStatus status) {
    switch (status) {
      case JobStatus.open:
        return _fallbackOpen;
      case JobStatus.assigned:
        return _fallbackAssigned;
      case JobStatus.started:
        return _fallbackStarted;
      case JobStatus.inProgress:
        return _fallbackInProgress;
      case JobStatus.readyToClose:
        return _fallbackReadyToClose;
      case JobStatus.completed:
        return _fallbackCompleted;
      case JobStatus.cancelled:
        return _fallbackCancelled;
    }
  }

  /// Get color for general status strings using theme tokens
  ///
  /// Maps status strings to semantic tokens:
  /// - completed/success/done -> successColor (#10b981)
  /// - in_progress/active -> infoColor (#3b82f6)
  /// - cancelled/failed/error/urgent -> warningColor (#f43f5e)
  /// - pending/waiting -> primary (#f59e0b)
  /// - default -> textBody (#a1a1aa)
  static Color getGeneralStatusColorWithContext(String status, BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;

    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
      case 'done':
        return tokens.successColor; // success (#10b981)
      case 'pending':
      case 'waiting':
        return colorScheme.primary; // primary (amber)
      case 'in_progress':
      case 'active':
        return tokens.infoColor; // info/progress (#3b82f6)
      case 'cancelled':
      case 'failed':
      case 'error':
        return tokens.warningColor; // warning/error (#f43f5e)
      case 'urgent':
        return tokens.warningColor; // warning/urgent (#f43f5e)
      default:
        return tokens.textBody; // textBody (#a1a1aa)
    }
  }

  /// Get color for general status strings (deprecated compatibility layer)
  ///
  /// @Deprecated Use getGeneralStatusColor(String, BuildContext) instead.
  /// This method uses fallback colors and does not respect theme tokens.
  @Deprecated('Use getGeneralStatusColor(String, BuildContext) instead. '
      'This method will be removed in a future version.')
  static Color getGeneralStatusColorLegacy(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
      case 'done':
        return _fallbackCompleted;
      case 'pending':
      case 'waiting':
        return _fallbackPending;
      case 'in_progress':
      case 'active':
        return _fallbackInProgress;
      case 'cancelled':
      case 'failed':
      case 'error':
        return _fallbackCancelled;
      case 'urgent':
        return _fallbackUrgent;
      default:
        return _fallbackDefault;
    }
  }

  /// Get color for trip status using theme tokens
  ///
  /// Maps trip statuses to semantic tokens:
  /// - completed -> successColor (#10b981)
  /// - onboard, dropoff_arrived, pickup_arrived -> primary (#f59e0b)
  /// - default -> textBody (#a1a1aa)
  static Color getTripStatusColorWithContext(String? status, BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;

    switch (status) {
      case 'completed':
        return tokens.successColor; // success (#10b981)
      case 'onboard':
      case 'dropoff_arrived':
      case 'pickup_arrived':
        return colorScheme.primary; // primary (amber)
      default:
        return tokens.textBody; // textBody (#a1a1aa)
    }
  }

  /// Get color for trip status (deprecated compatibility layer)
  ///
  /// @Deprecated Use getTripStatusColor(String?, BuildContext) instead.
  /// This method uses fallback colors and does not respect theme tokens.
  @Deprecated('Use getTripStatusColor(String?, BuildContext) instead. '
      'This method will be removed in a future version.')
  static Color getTripStatusColorLegacy(String? status) {
    switch (status) {
      case 'completed':
        return _fallbackCompleted;
      case 'onboard':
      case 'dropoff_arrived':
      case 'pickup_arrived':
        return _fallbackAssigned; // primary (amber)
      default:
        return _fallbackDefault;
    }
  }

  /// Get color for driver flow status using theme tokens
  ///
  /// Maps driver flow statuses to semantic tokens:
  /// - assigned -> successColor (#10b981)
  /// - started, inProgress -> infoColor (#3b82f6)
  /// - completed -> primary (#f59e0b)
  /// - default -> textBody (#a1a1aa)
  static Color getDriverFlowColorWithContext(JobStatus status, BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;

    switch (status) {
      case JobStatus.assigned:
        return tokens.successColor; // success (#10b981)
      case JobStatus.started:
        return tokens.infoColor; // info/progress (#3b82f6)
      case JobStatus.inProgress:
        return tokens.infoColor; // info/progress (#3b82f6)
      case JobStatus.completed:
        return colorScheme.primary; // primary (amber)
      default:
        return tokens.textBody; // textBody (#a1a1aa)
    }
  }

  /// Get color for driver flow status (deprecated compatibility layer)
  ///
  /// @Deprecated Use getDriverFlowColor(JobStatus, BuildContext) instead.
  /// This method uses fallback colors and does not respect theme tokens.
  @Deprecated('Use getDriverFlowColor(JobStatus, BuildContext) instead. '
      'This method will be removed in a future version.')
  static Color getDriverFlowColorLegacy(JobStatus status) {
    switch (status) {
      case JobStatus.assigned:
        return _fallbackCompleted;
      case JobStatus.started:
        return _fallbackInProgress;
      case JobStatus.inProgress:
        return _fallbackInProgress;
      case JobStatus.completed:
        return _fallbackAssigned; // primary (amber)
      default:
        return _fallbackDefault;
    }
  }

  /// Get color for recency status using theme tokens
  ///
  /// Maps recency statuses to semantic tokens:
  /// - recent -> successColor (#10b981)
  /// - older -> primary (#f59e0b)
  /// - old -> warningColor (#f43f5e)
  /// - default -> textBody (#a1a1aa)
  static Color getRecencyColorWithContext(String recency, BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final colorScheme = Theme.of(context).colorScheme;

    switch (recency.toLowerCase()) {
      case 'recent':
        return tokens.successColor; // success (#10b981)
      case 'older':
        return colorScheme.primary; // primary (amber)
      case 'old':
        return tokens.warningColor; // warning/error (#f43f5e)
      default:
        return tokens.textBody; // textBody (#a1a1aa)
    }
  }

  /// Get color for recency status (deprecated compatibility layer)
  ///
  /// @Deprecated Use getRecencyColor(String, BuildContext) instead.
  /// This method uses fallback colors and does not respect theme tokens.
  @Deprecated('Use getRecencyColor(String, BuildContext) instead. '
      'This method will be removed in a future version.')
  static Color getRecencyColorLegacy(String recency) {
    switch (recency.toLowerCase()) {
      case 'recent':
        return _fallbackCompleted;
      case 'older':
        return _fallbackPending;
      case 'old':
        return _fallbackCancelled;
      default:
        return _fallbackDefault;
    }
  }

  // Compatibility layer: Keep old method names that delegate to legacy methods
  // This ensures existing call sites continue to work without modification

  /// @Deprecated Use getJobStatusColor(JobStatus, BuildContext) instead.
  @Deprecated('Use getJobStatusColor(JobStatus, BuildContext) instead. '
      'This method will be removed in a future version.')
  static Color getJobStatusColor(JobStatus status) {
    return getJobStatusColorLegacy(status);
  }

  /// @Deprecated Use getGeneralStatusColor(String, BuildContext) instead.
  @Deprecated('Use getGeneralStatusColor(String, BuildContext) instead. '
      'This method will be removed in a future version.')
  static Color getGeneralStatusColor(String status) {
    return getGeneralStatusColorLegacy(status);
  }

  /// @Deprecated Use getTripStatusColor(String?, BuildContext) instead.
  @Deprecated('Use getTripStatusColor(String?, BuildContext) instead. '
      'This method will be removed in a future version.')
  static Color getTripStatusColor(String? status) {
    return getTripStatusColorLegacy(status);
  }

  /// @Deprecated Use getDriverFlowColor(JobStatus, BuildContext) instead.
  @Deprecated('Use getDriverFlowColor(JobStatus, BuildContext) instead. '
      'This method will be removed in a future version.')
  static Color getDriverFlowColor(JobStatus status) {
    return getDriverFlowColorLegacy(status);
  }

  /// @Deprecated Use getRecencyColor(String, BuildContext) instead.
  @Deprecated('Use getRecencyColor(String, BuildContext) instead. '
      'This method will be removed in a future version.')
  static Color getRecencyColor(String recency) {
    return getRecencyColorLegacy(recency);
  }
}
