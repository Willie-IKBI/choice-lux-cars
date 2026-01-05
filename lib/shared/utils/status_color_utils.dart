import 'package:flutter/material.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/jobs/models/job.dart';

/// Centralized status color utilities to eliminate duplicate functions
class StatusColorUtils {
  /// Get color for job status
  static Color getJobStatusColor(JobStatus status) {
    switch (status) {
      case JobStatus.open:
        return ChoiceLuxTheme.infoColor;
      case JobStatus.assigned:
        return ChoiceLuxTheme.orange;
      case JobStatus.started:
        return ChoiceLuxTheme.purple;
      case JobStatus.inProgress:
        return ChoiceLuxTheme.infoColor;
      case JobStatus.readyToClose:
        return ChoiceLuxTheme.warningColor;
      case JobStatus.completed:
        return ChoiceLuxTheme.successColor;
      case JobStatus.cancelled:
        return ChoiceLuxTheme.errorColor;
    }
  }

  /// Get color for general status strings
  static Color getGeneralStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
      case 'done':
        return ChoiceLuxTheme.successColor;
      case 'pending':
      case 'waiting':
        return ChoiceLuxTheme.orange;
      case 'in_progress':
      case 'active':
        return ChoiceLuxTheme.infoColor;
      case 'cancelled':
      case 'failed':
      case 'error':
        return ChoiceLuxTheme.errorColor;
      case 'urgent':
        return ChoiceLuxTheme.errorColor;
      default:
        return ChoiceLuxTheme.platinumSilver;
    }
  }

  /// Get color for trip status
  static Color getTripStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return ChoiceLuxTheme.successColor;
      case 'onboard':
        return ChoiceLuxTheme.richGold;
      case 'dropoff_arrived':
        return ChoiceLuxTheme.richGold;
      case 'pickup_arrived':
        return ChoiceLuxTheme.richGold;
      default:
        return ChoiceLuxTheme.platinumSilver;
    }
  }

  /// Get color for driver flow status
  static Color getDriverFlowColor(JobStatus status) {
    switch (status) {
      case JobStatus.assigned:
        return ChoiceLuxTheme.successColor;
      case JobStatus.started:
        return ChoiceLuxTheme.infoColor;
      case JobStatus.inProgress:
        return ChoiceLuxTheme.orange;
      case JobStatus.completed:
        return ChoiceLuxTheme.richGold;
      default:
        return ChoiceLuxTheme.platinumSilver;
    }
  }

  /// Get color for recency status
  static Color getRecencyColor(String recency) {
    switch (recency.toLowerCase()) {
      case 'recent':
        return ChoiceLuxTheme.successColor;
      case 'older':
        return ChoiceLuxTheme.orange;
      case 'old':
        return ChoiceLuxTheme.errorColor;
      default:
        return ChoiceLuxTheme.platinumSilver;
    }
  }
}
