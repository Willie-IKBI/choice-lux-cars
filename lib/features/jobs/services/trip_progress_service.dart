import 'package:choice_lux_cars/core/errors/app_exception.dart';

/// Service layer for trip progress business logic
/// 
/// Provides helper methods for status transitions and error mapping.
/// The database trigger is the source of truth for validation rules.
class TripProgressService {
  /// Get the next valid action for a given status
  /// 
  /// Returns the next status and user-friendly label, or null if trip is completed.
  /// Status transitions (enforced by DB trigger):
  /// - pending -> pickup_arrived
  /// - pickup_arrived -> passenger_onboard
  /// - passenger_onboard -> dropoff_arrived
  /// - dropoff_arrived -> completed
  static TripProgressAction? getNextAction(String currentStatus) {
    switch (currentStatus) {
      case 'pending':
        return const TripProgressAction(
          nextStatus: 'pickup_arrived',
          label: 'Arrived at pickup',
        );
      case 'pickup_arrived':
        return const TripProgressAction(
          nextStatus: 'passenger_onboard',
          label: 'Passenger onboard',
        );
      case 'passenger_onboard':
        return const TripProgressAction(
          nextStatus: 'dropoff_arrived',
          label: 'Arrived at dropoff',
        );
      case 'dropoff_arrived':
        return const TripProgressAction(
          nextStatus: 'completed',
          label: 'Complete trip',
        );
      case 'completed':
        return null; // No next action
      default:
        return null;
    }
  }

  /// Map Supabase/PostgreSQL errors to user-friendly messages
  /// 
  /// Handles trigger exceptions and RLS policy violations.
  static String mapErrorToMessage(AppException error) {
    final message = error.message.toLowerCase();

    // Invalid status transition
    if (message.contains('invalid status transition')) {
      return 'Cannot change trip status. Please follow the correct sequence.';
    }

    // Timestamp immutability
    if (message.contains('cannot change') && message.contains('timestamp')) {
      return 'This timestamp cannot be modified once set.';
    }

    // Immutability violations
    if (message.contains('immutable')) {
      if (message.contains('job_id')) {
        return 'Job ID cannot be changed.';
      }
      if (message.contains('trip_index')) {
        return 'Trip index cannot be changed.';
      }
      return 'This field cannot be modified.';
    }

    // Missing prerequisite timestamp
    if (message.contains('timestamp is missing') || 
        message.contains('must be set before advancing')) {
      return 'Previous step timestamp is missing. Please contact support.';
    }

    // RLS/Auth errors
    if (message.contains('unauthorized') || 
        message.contains('forbidden') ||
        message.contains('permission denied')) {
      return 'You do not have permission to perform this action.';
    }

    // Network errors
    if (message.contains('network') || 
        message.contains('timeout') ||
        message.contains('connection')) {
      return 'Network error. Please check your connection and try again.';
    }

    // Generic validation error
    if (error is ValidationException) {
      // Extract the meaningful part of the error
      if (message.contains('invalid status transition')) {
        final match = RegExp(r'from (\w+) to (\w+)').firstMatch(error.message);
        if (match != null) {
          return 'Cannot change status from ${match.group(1)} to ${match.group(2)}.';
        }
      }
      return error.message;
    }

    // Default fallback
    return 'An error occurred. Please try again.';
  }
}

/// Represents a valid trip progress action
class TripProgressAction {
  final String nextStatus;
  final String label;

  const TripProgressAction({
    required this.nextStatus,
    required this.label,
  });
}

