/// Centralized constants for notification system
class NotificationConstants {
  // Notification Types
  static const String jobAssignment = 'job_assignment';
  static const String jobReassignment = 'job_reassignment';
  static const String jobStatusChange = 'job_status_change';
  static const String jobCancellation = 'job_cancellation';
  static const String jobCancelled = 'job_cancelled'; // Alternative name used in some places
  static const String jobConfirmation = 'job_confirmation';
  static const String jobStart = 'job_start';
  static const String stepCompletion = 'step_completion';
  static const String jobCompletion = 'job_completion';
  static const String jobStartDeadlineWarning90min = 'job_start_deadline_warning_90min';
  static const String jobStartDeadlineWarning30min = 'job_start_deadline_warning_30min';
  static const String paymentReminder = 'payment_reminder';
  static const String systemAlert = 'system_alert';

  /// List of all notification types (for iteration in settings UI)
  static const List<String> allNotificationTypes = [
    jobAssignment,
    jobReassignment,
    jobConfirmation,
    jobCancelled,
    jobStatusChange,
    jobStart,
    stepCompletion,
    jobCompletion,
    jobStartDeadlineWarning90min,
    jobStartDeadlineWarning30min,
    paymentReminder,
    systemAlert,
  ];

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

  /// Get human-readable display name for a notification type
  static String getNotificationTypeDisplayName(String notificationType) {
    switch (notificationType) {
      case jobAssignment:
        return 'Job Assignment';
      case jobReassignment:
        return 'Job Reassignment';
      case jobConfirmation:
        return 'Job Confirmation';
      case jobCancelled:
      case jobCancellation:
        return 'Job Cancellation';
      case jobStatusChange:
        return 'Job Status Change';
      case jobStart:
        return 'Job Start';
      case stepCompletion:
        return 'Step Completion';
      case jobCompletion:
        return 'Job Completion';
      case jobStartDeadlineWarning90min:
        return 'Job Start Warning (90 min)';
      case jobStartDeadlineWarning30min:
        return 'Job Start Warning (30 min)';
      case paymentReminder:
        return 'Payment Reminder';
      case systemAlert:
        return 'System Alert';
      default:
        return notificationType.replaceAll('_', ' ').split(' ').map((word) => 
          word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)
        ).join(' ');
    }
  }

  /// Get description for a notification type (for settings UI)
  static String getNotificationTypeDescription(String notificationType) {
    switch (notificationType) {
      case jobAssignment:
        return 'Receive push notifications when a new job is assigned to you';
      case jobReassignment:
        return 'Receive push notifications when a job is reassigned to you';
      case jobConfirmation:
        return 'Receive push notifications when drivers confirm job assignments';
      case jobCancelled:
      case jobCancellation:
        return 'Receive push notifications when a job is cancelled';
      case jobStatusChange:
        return 'Receive push notifications when job status changes';
      case jobStart:
        return 'Receive push notifications when drivers start jobs';
      case stepCompletion:
        return 'Receive push notifications when drivers complete job steps';
      case jobCompletion:
        return 'Receive push notifications when jobs are completed';
      case jobStartDeadlineWarning90min:
        return 'Receive push notifications 90 minutes before pickup if job hasn\'t started';
      case jobStartDeadlineWarning30min:
        return 'Receive push notifications 30 minutes before pickup if job hasn\'t started';
      case paymentReminder:
        return 'Receive push notifications for payment reminders';
      case systemAlert:
        return 'Receive push notifications for system alerts and announcements';
      default:
        return 'Push notification preference for $notificationType';
    }
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
