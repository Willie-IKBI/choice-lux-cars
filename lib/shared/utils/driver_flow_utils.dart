import 'package:flutter/material.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/jobs/models/job.dart';
import 'package:choice_lux_cars/shared/utils/status_color_utils.dart';

/// Centralized driver flow utilities to eliminate duplicate functions
class DriverFlowUtils {
  /// Get icon for driver flow based on job status
  static IconData getDriverFlowIcon(JobStatus status) {
    switch (status) {
      case JobStatus.assigned:
        return Icons.play_arrow;
      case JobStatus.started:
        return Icons.sync;
      case JobStatus.inProgress:
        return Icons.sync;
      case JobStatus.completed:
        return Icons.summarize;
      default:
        return Icons.info;
    }
  }

  /// Get text for driver flow button based on job status
  static String getDriverFlowText(JobStatus status) {
    switch (status) {
      case JobStatus.assigned:
        return 'Start Job';
      case JobStatus.started:
        return 'Resume Job';
      case JobStatus.inProgress:
        return 'Continue Job';
      case JobStatus.completed:
        return 'Job Overview';
      default:
        return 'View Job';
    }
  }

  /// Get color for driver flow button based on job status
  static Color getDriverFlowColor(JobStatus status) {
    return StatusColorUtils.getDriverFlowColor(status);
  }

  /// Get icon for trip status
  static IconData getTripStatusIcon(String? status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle_rounded;
      case 'onboard':
        return Icons.person_rounded;
      case 'dropoff_arrived':
        return Icons.location_on_rounded;
      case 'pickup_arrived':
        return Icons.location_on_rounded;
      default:
        return Icons.pending_rounded;
    }
  }

  /// Get color for trip status
  static Color getTripStatusColor(String? status) {
    return StatusColorUtils.getTripStatusColor(status);
  }

  /// Check if driver flow button should be shown
  static bool shouldShowDriverFlowButton({
    required String? currentUserId,
    required String? jobDriverId,
    required JobStatus jobStatus,
  }) {
    // Check if current user is the assigned driver
    final isAssignedDriver = currentUserId == jobDriverId;
    
    // Only show button if user is assigned driver and job status allows it
    return isAssignedDriver && (
      jobStatus == JobStatus.assigned || 
      jobStatus == JobStatus.started ||
      jobStatus == JobStatus.inProgress
    );
  }

  /// Get route for driver flow based on job status
  static String getDriverFlowRoute(int jobId, JobStatus status) {
    switch (status) {
      case JobStatus.completed:
        return '/jobs/$jobId/summary';
      default:
        return '/jobs/$jobId/progress';
    }
  }

  /// Get step description for driver flow
  static String getStepDescription(String stepId) {
    switch (stepId) {
      case 'vehicle_collection':
        return 'Collect vehicle and record odometer';
      case 'pickup_arrival':
        return 'Arrive at passenger pickup location';
      case 'passenger_onboard':
        return 'Passenger has boarded the vehicle';
      case 'dropoff_arrival':
        return 'Arrive at passenger dropoff location';
      case 'trip_complete':
        return 'Trip has been completed';
      case 'vehicle_return':
        return 'Return vehicle and record final odometer';
      default:
        return 'Unknown step';
    }
  }

  /// Get step title for driver flow
  static String getStepTitle(String stepId) {
    switch (stepId) {
      case 'vehicle_collection':
        return 'Vehicle Collection';
      case 'pickup_arrival':
        return 'Arrive at Pickup';
      case 'passenger_onboard':
        return 'Passenger Onboard';
      case 'dropoff_arrival':
        return 'Arrive at Dropoff';
      case 'trip_complete':
        return 'Trip Complete';
      case 'vehicle_return':
        return 'Vehicle Return';
      default:
        return 'Unknown Step';
    }
  }

  /// Get step icon for driver flow
  static IconData getStepIcon(String stepId) {
    switch (stepId) {
      case 'vehicle_collection':
        return Icons.directions_car;
      case 'pickup_arrival':
        return Icons.location_on;
      case 'passenger_onboard':
        return Icons.person_add;
      case 'dropoff_arrival':
        return Icons.location_on;
      case 'trip_complete':
        return Icons.check_circle;
      case 'vehicle_return':
        return Icons.home;
      default:
        return Icons.info;
    }
  }
}
