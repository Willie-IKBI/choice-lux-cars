import 'package:choice_lux_cars/features/notifications/notifications.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

/// Service for handling job assignments and notifications
class JobAssignmentService {

  /// Assign a job to a driver and create notification
  static Future<void> assignJobToDriver({
    required String jobId,
    required String driverId,
    required bool isReassignment,
  }) async {
    try {
      Log.d(
        'Assigning job $jobId to driver $driverId (reassignment: $isReassignment)',
      );

      // Send notification to the assigned driver
      await NotificationService().sendJobAssignmentNotification(
        userId: driverId,
        jobId: jobId,
        jobNumber: 'JOB-$jobId',
        isReassignment: isReassignment,
      );

      Log.d('Job assignment notification sent successfully');
    } catch (error) {
      Log.e('Error assigning job to driver: $error');
      rethrow;
    }
  }

  /// Send notification when a new job is created with a driver assigned
  static Future<void> notifyDriverOfNewJob({
    required String jobId,
    required String driverId,
  }) async {
    try {
      Log.d('Sending new job notification to driver $driverId for job $jobId');

      await NotificationService().sendJobAssignmentNotification(
        userId: driverId,
        jobId: jobId,
        jobNumber: 'JOB-$jobId',
        isReassignment: false,
      );

      Log.d('New job notification sent successfully');
    } catch (error) {
      Log.e('Error sending new job notification: $error');
      // Don't rethrow - notification failure shouldn't break job creation
    }
  }

  /// Send notification when a job is reassigned to a different driver
  static Future<void> notifyDriverOfReassignment({
    required String jobId,
    required String newDriverId,
    required String? previousDriverId,
  }) async {
    try {
      Log.d('Sending reassignment notification to driver $newDriverId for job $jobId');

      await NotificationService().sendJobAssignmentNotification(
        userId: newDriverId,
        jobId: jobId,
        jobNumber: 'JOB-$jobId',
        isReassignment: true,
      );

      Log.d('Job reassignment notification sent successfully');
    } catch (error) {
      Log.e('Error sending reassignment notification: $error');
      // Don't rethrow - notification failure shouldn't break job update
    }
  }

  /// Get unassigned jobs
  static Future<List<Map<String, dynamic>>> getUnassignedJobs() async {
    try {
      Log.d('Getting unassigned jobs');

      // This would need to be updated to use the repository pattern
      // For now, returning empty list as placeholder
      Log.d('getUnassignedJobs needs to be updated to use repository pattern');

      // TODO: Update to use JobsRepository.getJobsByStatus('open') method

      return [];
    } catch (error) {
      Log.e('Error getting unassigned jobs: $error');
      rethrow;
    }
  }
}
