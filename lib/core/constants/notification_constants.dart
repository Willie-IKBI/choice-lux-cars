/// Centralized constants for notification system
class NotificationConstants {
  // Notification Types
  static const String jobAssignment = 'job_assignment';
  static const String jobReassignment = 'job_reassignment';
  static const String jobStatusChange = 'job_status_change';
  static const String jobCancellation = 'job_cancellation';
  static const String paymentReminder = 'payment_reminder';
  static const String systemAlert = 'system_alert';

  // Notification Priorities
  static const String priorityLow = 'low';
  static const String priorityNormal = 'normal';
  static const String priorityHigh = 'high';
  static const String priorityUrgent = 'urgent';

  // Notification Messages
  static String getJobAssignmentMessage(String jobNumber, {bool isReassignment = false}) {
    if (isReassignment) {
      return 'Job $jobNumber has been reassigned to you. Please confirm your assignment.';
    }
    return 'New job $jobNumber has been assigned to you. Please confirm your assignment.';
  }

  static String getJobStatusChangeMessage(String jobNumber, String oldStatus, String newStatus) {
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

  // Action Types
  static const String actionViewJob = 'view_job';
  static const String actionViewPayment = 'view_payment';
  static const String actionSystemAlert = 'system_alert';

  // Route Templates
  static String getJobSummaryRoute(int jobId) => '/jobs/$jobId/summary';
  static String getJobPaymentRoute(int jobId) => '/jobs/$jobId/payment';

  // Error Messages
  static const String errorJobAssignmentFailed = 'Failed to assign job to driver';
  static const String errorNotificationCreationFailed = 'Failed to create notification';
  static const String errorJobNotFound = 'Job not found';
  static const String errorInvalidJobId = 'Invalid job ID format';
}
