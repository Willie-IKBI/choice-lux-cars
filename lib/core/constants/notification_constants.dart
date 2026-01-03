/// Centralized constants for notification system
class NotificationConstants {
  // Notification Types
  static const String jobAssignment = 'job_assignment';
  static const String jobReassignment = 'job_reassignment';
  static const String jobStatusChange = 'job_status_change';
  static const String jobCancelled = 'job_cancelled';
  static const String jobConfirmation = 'job_confirmation';
  static const String jobStart = 'job_start';
  static const String jobCompletion = 'job_completion';
  static const String stepCompletion = 'step_completion';
  static const String jobStartDeadlineWarning90min = 'job_start_deadline_warning_90min';
  static const String jobStartDeadlineWarning60min = 'job_start_deadline_warning_60min';
  static const String paymentReminder = 'payment_reminder';
  static const String systemAlert = 'system_alert';

  // Notification Priorities
  static const String priorityLow = 'low';
  static const String priorityNormal = 'normal';
  static const String priorityHigh = 'high';
  static const String priorityUrgent = 'urgent';

  // Notification Messages
  static String getJobAssignmentMessage(
    String jobNumber, {
    bool isReassignment = false,
  }) {
    if (isReassignment) {
      return 'Job $jobNumber has been reassigned to you. Please confirm your assignment.';
    }
    return 'New job $jobNumber has been assigned to you. Please confirm your assignment.';
  }

  static String getJobStatusChangeMessage(
    String jobNumber,
    String oldStatus,
    String newStatus,
  ) {
    return 'Job $jobNumber status changed from $oldStatus to $newStatus.';
  }

  static String getJobCancellationMessage(String jobNumber) {
    return 'Job $jobNumber has been cancelled.';
  }

  static String getPaymentReminderMessage(String jobNumber, String amount) {
    return 'Payment reminder for job $jobNumber: $amount';
  }

  static String getSystemAlertMessage(String message) {
    return message;
  }

  static String getJobConfirmationMessage(String jobNumber, String driverName) {
    return 'Job Confirmed: $driverName confirmed job #$jobNumber';
  }

  // Action Types
  static const String actionViewJob = 'view_job';
  static const String actionViewPayment = 'view_payment';
  static const String actionSystemAlert = 'system_alert';

  // Route Templates
  static String getJobSummaryRoute(int jobId) => '/jobs/$jobId/summary';
  static String getJobPaymentRoute(int jobId) => '/jobs/$jobId/payment';

  // Error Messages
  static const String errorJobAssignmentFailed =
      'Failed to assign job to driver';
  static const String errorNotificationCreationFailed =
      'Failed to create notification';
  static const String errorJobNotFound = 'Job not found';
  static const String errorInvalidJobId = 'Invalid job ID format';
}
