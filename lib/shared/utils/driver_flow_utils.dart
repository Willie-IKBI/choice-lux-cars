import 'package:flutter/material.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/jobs/models/job.dart';
import 'package:choice_lux_cars/shared/utils/status_color_utils.dart';

/// Centralized driver flow utilities to eliminate duplicate functions
class DriverFlowUtils {
  /// Get icon for driver flow based on job status
  static IconData getDriverFlowIcon(JobStatus status) {
    switch (status) {
      case JobStatus.open:
        return Icons.play_arrow;
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
      case JobStatus.open:
        return 'Start Job';
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

  /// Get current job step from job data
  /// Note: This is a simplified version. For accurate step tracking, 
  /// the job progress screen fetches detailed data from driver_flow table
  static String getCurrentJobStep(Job job) {
    // If job is not started or not confirmed, return not started
    if (job.statusEnum == JobStatus.open || job.statusEnum == JobStatus.assigned) {
      return 'not_started';
    }
    
    // If job is completed, return completed
    if (job.statusEnum == JobStatus.completed) {
      return 'completed';
    }
    
    // For started/in-progress jobs, we can make educated guesses based on status
    // but the actual current step should come from driver_flow table
    if (job.statusEnum == JobStatus.started) {
      // Job has started but we don't know the exact step
      // This is a limitation - we should show a generic "in progress" message
      return 'in_progress';
    }
    
    if (job.statusEnum == JobStatus.inProgress) {
      // Job is actively in progress
      return 'in_progress';
    }
    
    if (job.statusEnum == JobStatus.readyToClose) {
      // Job is ready to be closed
      return 'vehicle_return';
    }
    
    return 'not_started';
  }

  /// Get display text for current job step
  static String getCurrentStepDisplayText(String stepId) {
    switch (stepId) {
      case 'not_started':
        return 'Ready to Start';
      case 'vehicle_collection':
        return 'Vehicle Collection';
      case 'pickup_arrival':
        return 'Arrive at Pickup';
      case 'passenger_pickup':
        return 'Pickup Arrival';
      case 'passenger_onboard':
        return 'Passenger Onboard';
      case 'dropoff_arrival':
        return 'Arrive at Dropoff';
      case 'trip_complete':
        return 'Trip Complete';
      case 'vehicle_return':
        return 'Vehicle Return';
      case 'completed':
        return 'Job Complete';
      case 'in_progress':
        return 'Job In Progress';
      default:
        return 'In Progress';
    }
  }

  /// Get color for current job step
  static Color getCurrentStepColor(String stepId) {
    switch (stepId) {
      case 'not_started':
        return Colors.orange;
      case 'vehicle_collection':
      case 'pickup_arrival':
      case 'passenger_pickup':
      case 'passenger_onboard':
      case 'dropoff_arrival':
      case 'trip_complete':
      case 'vehicle_return':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
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
    required bool isJobConfirmed,
  }) {
    // Check if current user is the assigned driver
    final isAssignedDriver = currentUserId == jobDriverId;

    // For "Start Job" button (open/assigned status), only show if job is confirmed
    if (jobStatus == JobStatus.open || jobStatus == JobStatus.assigned) {
      return isAssignedDriver && isJobConfirmed;
    }

    // For other statuses (started, inProgress), show regardless of confirmation
    return isAssignedDriver &&
        (jobStatus == JobStatus.started || jobStatus == JobStatus.inProgress);
  }

  /// Check if driver confirmation button should be shown
  static bool shouldShowDriverConfirmationButton({
    required String? currentUserId,
    required String? jobDriverId,
    required JobStatus jobStatus,
    required bool isJobConfirmed,
  }) {
    // Check if current user is the assigned driver
    final isAssignedDriver = currentUserId == jobDriverId;
    
    // Only show confirmation button for assigned drivers on open/assigned jobs that are not yet confirmed
    return isAssignedDriver && 
           (jobStatus == JobStatus.open || jobStatus == JobStatus.assigned) && 
           !isJobConfirmed;
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
      case 'completed':
        return 'Job has been completed and closed';
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
      case 'completed':
        return 'Job Complete';
      default:
        return 'Unknown Step';
    }
  }

  /// Get step title with address for driver flow
  static String getStepTitleWithAddress(String stepId, String? address) {
    final baseTitle = getStepTitle(stepId);

    if (address == null || address.trim().isEmpty) {
      return baseTitle;
    }

    switch (stepId) {
      case 'pickup_arrival':
        return '$baseTitle - $address';
      case 'dropoff_arrival':
        return '$baseTitle - $address';
      default:
        return baseTitle;
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
      case 'completed':
        return Icons.done_all_rounded;
      default:
        return Icons.info;
    }
  }
}
