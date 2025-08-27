import 'package:supabase_flutter/supabase_flutter.dart';
import '../../notifications/services/notification_service.dart';
import '../../../core/constants/notification_constants.dart';

class JobAssignmentService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final NotificationService _notificationService = NotificationService();

  /// Assign a job to a driver and create notification directly
  static Future<void> assignJobToDriver({
    required int jobId,
    required String driverId,
    bool isReassignment = false,
  }) async {
    try {
      print('=== ASSIGNING JOB TO DRIVER ===');
      print('Job ID: $jobId');
      print('Driver ID: $driverId');
      print('Is Reassignment: $isReassignment');

      // Step 1: Update the job with the driver assignment
      await _supabase
          .from('jobs')
          .update({
            'driver_id': driverId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', jobId);

      print('Job assigned to driver successfully');

      // Step 2: Get job details for notification
      final jobResponse = await _supabase
          .from('jobs')
          .select('job_number, passenger_name')
          .eq('id', jobId)
          .single();

      final jobNumber = jobResponse['job_number'] ?? 'Job #$jobId';
      final passengerName = jobResponse['passenger_name'] ?? 'Unknown Passenger';

      // Step 3: Create notification using centralized constants
      await _supabase
          .from('app_notifications')
          .insert({
            'user_id': driverId,
            'message': NotificationConstants.getJobAssignmentMessage(jobNumber, isReassignment: isReassignment),
            'notification_type': isReassignment ? NotificationConstants.jobReassignment : NotificationConstants.jobAssignment,
            'priority': NotificationConstants.priorityHigh,
            'job_id': jobId,
            'action_data': {
              'job_id': jobId,
              'job_number': jobNumber,
              'passenger_name': passengerName,
              'action': NotificationConstants.actionViewJob,
              'route': NotificationConstants.getJobSummaryRoute(jobId),
            },
          });

      print('Notification created successfully');
      print('Push notification will be sent via webhook + Edge Function');

      print('=== JOB ASSIGNMENT COMPLETED SUCCESSFULLY ===');
    } catch (e) {
      print('=== ERROR ASSIGNING JOB ===');
      print('Error: $e');
      throw Exception('${NotificationConstants.errorJobAssignmentFailed}: $e');
    }
  }

  /// DEPRECATED: Use jobsProvider.confirmJob() instead
  /// This method is kept for backward compatibility but should not be used
  @Deprecated('Use jobsProvider.confirmJob() instead')
  static Future<void> confirmJobAssignment({
    required int jobId,
    required String driverId,
  }) async {
    print('WARNING: confirmJobAssignment is deprecated. Use jobsProvider.confirmJob() instead.');
    throw UnsupportedError('Use jobsProvider.confirmJob() instead of this deprecated method');
  }

  /// Get jobs assigned to a specific driver
  static Future<List<Map<String, dynamic>>> getJobsForDriver(String driverId) async {
    try {
      final response = await _supabase
          .from('jobs')
          .select('*')
          .eq('driver_id', driverId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting jobs for driver: $e');
      throw Exception('Failed to get jobs for driver: $e');
    }
  }

  /// Get unassigned jobs
  static Future<List<Map<String, dynamic>>> getUnassignedJobs() async {
    try {
      // Get all jobs first, then filter in Dart for null driver_id
      final response = await _supabase
          .from('jobs')
          .select('*')
          .order('created_at', ascending: false);

      // Filter for jobs with null driver_id
      final unassignedJobs = response.where((job) => job['driver_id'] == null).toList();
      
      return List<Map<String, dynamic>>.from(unassignedJobs);
    } catch (e) {
      print('Error getting unassigned jobs: $e');
      throw Exception('Failed to get unassigned jobs: $e');
    }
  }

  /// Remove driver assignment from a job
  static Future<void> unassignJobFromDriver({
    required int jobId,
    required String driverId,
  }) async {
    try {
      print('=== UNASSIGNING JOB FROM DRIVER ===');
      print('Job ID: $jobId');
      print('Driver ID: $driverId');

      // Step 1: Update the job to remove driver assignment
      await _supabase
          .from('jobs')
          .update({
            'driver_id': null,
            'driver_confirm_ind': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', jobId)
          .eq('driver_id', driverId);

      print('Job unassigned from driver successfully');

      // Step 2: Mark notifications as dismissed
      await _supabase
          .from('app_notifications')
          .update({
            'is_hidden': true,
            'dismissed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('job_id', jobId)
          .eq('user_id', driverId)
          .eq('notification_type', NotificationConstants.jobAssignment);

      print('Notifications marked as dismissed');

      print('=== JOB UNASSIGNMENT COMPLETED SUCCESSFULLY ===');
    } catch (e) {
      print('=== ERROR UNASSIGNING JOB ===');
      print('Error: $e');
      throw Exception('Failed to unassign job: $e');
    }
  }
}
