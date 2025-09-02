import 'package:choice_lux_cars/features/jobs/data/jobs_repository.dart';
import 'package:choice_lux_cars/features/notifications/providers/notification_provider.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

/// Service for handling job assignments and notifications
class JobAssignmentService {
  final JobsRepository _jobsRepository;

  JobAssignmentService(this._jobsRepository);

  /// Assign a job to a driver and create notification
  static Future<void> assignJobToDriver({
    required int jobId,
    required String driverId,
    required bool isReassignment,
  }) async {
    try {
      Log.d(
        'Assigning job $jobId to driver $driverId (reassignment: $isReassignment)',
      );

      // This would need to be updated to use the repository pattern
      // For now, keeping the existing logic but marking as needing update
      Log.d(
        'Job assignment logic needs to be updated to use repository pattern',
      );

      // TODO: Update to use JobsRepository.updateJob() method
      // TODO: Update to use NotificationRepository.createNotification() method
    } catch (error) {
      Log.e('Error assigning job to driver: $error');
      rethrow;
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
