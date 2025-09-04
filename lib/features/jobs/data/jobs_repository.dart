import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:choice_lux_cars/core/supabase/supabase_client_provider.dart';
import 'package:choice_lux_cars/features/jobs/models/job.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/core/types/result.dart';
import 'package:choice_lux_cars/core/errors/app_exception.dart';
import 'package:choice_lux_cars/features/jobs/services/job_assignment_service.dart';
import 'package:choice_lux_cars/shared/utils/sa_time_utils.dart';

/// Repository for job-related data operations
///
/// Encapsulates all Supabase queries and returns domain models.
/// This layer separates data access from business logic.
class JobsRepository {
  final SupabaseClient _supabase;

  JobsRepository(this._supabase);

  /// Fetch jobs based on user role and permissions
  Future<Result<List<Job>>> fetchJobs({
    String? userId,
    String? userRole,
  }) async {
    try {
      Log.d('Fetching jobs for user: $userId with role: $userRole');

      // Check if userId is available for role-based filtering
      if (userId == null && userRole != 'administrator' && userRole != 'manager') {
        Log.e('UserId is required for role-based filtering');
        return const Result.success([]);
      }

      PostgrestFilterBuilder query = _supabase.from('jobs').select();

      // Apply role-based filtering
      if (userRole == 'administrator' || userRole == 'manager') {
        // Administrators and managers see all jobs
        Log.d('User has full access - fetching all jobs');
      } else if (userRole == 'driver_manager' && userId != null) {
        // Driver managers see jobs they created/assigned + jobs assigned to them
        Log.d('Driver manager - fetching created jobs and jobs assigned to them');
        query = query.or('created_by.eq.$userId,driver_id.eq.$userId');
      } else if (userRole == 'driver' && userId != null) {
        // Drivers only see jobs assigned to them
        Log.d('Driver - fetching only assigned jobs');
        query = query.eq('driver_id', userId);
      } else {
        // Unknown role or missing userId - default to no access
        Log.e('Unknown user role: $userRole or missing userId - returning empty list');
        return const Result.success([]);
      }

      final response = await query.order('created_at', ascending: false);

      Log.d('Fetched ${response.length} jobs for user: $userId with role: $userRole');

      final jobs = response.map<Job>((json) => Job.fromJson(json as Map<String, dynamic>)).toList();
      return Result.success(jobs);
    } catch (error) {
      Log.e('Error fetching jobs: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Create a new job
  Future<Result<Map<String, dynamic>>> createJob(Job job) async {
    try {
      Log.d('Creating job: ${job.passengerName}');

      final response = await _supabase
          .from('jobs')
          .insert(job.toJson())
          .select()
          .single();

      Log.d('Job created successfully with ID: ${response['id']}');

      // Send notification to assigned driver if one is assigned
      if (job.driverId != null && job.driverId!.isNotEmpty) {
        try {
          Log.d('Sending notification to assigned driver: ${job.driverId}');
          await JobAssignmentService.notifyDriverOfNewJob(
            jobId: response['id'].toString(),
            driverId: job.driverId!,
          );
          Log.d('Driver notification sent successfully');
        } catch (notificationError) {
          // Don't fail job creation if notification fails
          Log.e('Warning: Failed to send driver notification: $notificationError');
        }
      } else {
        Log.d('No driver assigned to job, skipping notification');
      }

      return Result.success(response);
    } catch (error) {
      Log.e('Error creating job: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Update an existing job
  Future<Result<void>> updateJob(Job job) async {
    try {
      Log.d('Updating job: ${job.id}');

      // Get the current job to check for driver changes
      final currentJobResponse = await _supabase
          .from('jobs')
          .select('driver_id')
          .eq('id', job.id)
          .single();

      final currentDriverId = currentJobResponse['driver_id']?.toString();
      final newDriverId = job.driverId;

      // Update the job
      await _supabase.from('jobs').update(job.toJson()).eq('id', job.id);

      Log.d('Job updated successfully');

      // Check if driver was reassigned
      if (currentDriverId != newDriverId && newDriverId != null && newDriverId.isNotEmpty) {
        try {
          Log.d('Driver reassigned from $currentDriverId to $newDriverId');
          await JobAssignmentService.notifyDriverOfReassignment(
            jobId: job.id.toString(),
            newDriverId: newDriverId,
            previousDriverId: currentDriverId,
          );
          Log.d('Driver reassignment notification sent successfully');
        } catch (notificationError) {
          // Don't fail job update if notification fails
          Log.e('Warning: Failed to send driver reassignment notification: $notificationError');
        }
      }

      return const Result.success(null);
    } catch (error) {
      Log.e('Error updating job: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Update job status
  Future<Result<void>> updateJobStatus(String jobId, String status) async {
    try {
      Log.d('Updating job status: $jobId to $status');

      // Prepare update data
      final updateData = <String, dynamic>{
        'status': status,
        'updated_at': SATimeUtils.getCurrentSATimeISO(),
      };

      // If confirming a job, also set driver confirmation fields
      if (status == 'confirmed') {
        updateData['driver_confirm_ind'] = true;
        updateData['confirmed_at'] = SATimeUtils.getCurrentSATimeISO();
        // Note: confirmed_by would need current user ID - this could be enhanced later
        Log.d('Setting driver confirmation fields for job confirmation');
      }

      await _supabase.from('jobs').update(updateData).eq('id', jobId);

      Log.d('Job status updated successfully');
      return const Result.success(null);
    } catch (error) {
      Log.e('Error updating job status: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Update job payment amount
  Future<Result<void>> updateJobPaymentAmount(
    String jobId,
    double amount,
  ) async {
    try {
      Log.d('Updating job payment amount: $jobId to $amount');

      await _supabase
          .from('jobs')
          .update({'payment_amount': amount})
          .eq('id', jobId);

      Log.d('Job payment amount updated successfully');
      return const Result.success(null);
    } catch (error) {
      Log.e('Error updating job payment amount: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Delete a job
  Future<Result<void>> deleteJob(String jobId) async {
    try {
      Log.d('Deleting job: $jobId');

      await _supabase.from('jobs').delete().eq('id', jobId);

      Log.d('Job deleted successfully');
      return const Result.success(null);
    } catch (error) {
      Log.e('Error deleting job: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Get jobs by status with role-based filtering
  Future<Result<List<Job>>> getJobsByStatus(
    String status, {
    String? userId,
    String? userRole,
  }) async {
    try {
      Log.d('Fetching jobs with status: $status for user: $userId with role: $userRole');

      // Check if userId is available for role-based filtering
      if (userId == null && userRole != 'administrator' && userRole != 'manager') {
        Log.e('UserId is required for role-based filtering');
        return const Result.success([]);
      }

      PostgrestFilterBuilder query = _supabase
          .from('jobs')
          .select()
          .eq('status', status);

      // Apply role-based filtering based on confirmed requirements
      if (userRole == 'administrator' || userRole == 'manager') {
        // Administrators and managers see ALL jobs
        Log.d('User has full access - fetching all jobs with status: $status');
        // No additional filtering needed
      } else if (userRole == 'driver_manager' && userId != null) {
        // Driver managers see jobs they created + jobs assigned to them
        Log.d('Driver manager - fetching created jobs and jobs assigned to them with status: $status');
        query = query.or('created_by.eq.$userId,driver_id.eq.$userId');
      } else if (userRole == 'driver' && userId != null) {
        // Drivers see jobs assigned to them (current + completed)
        Log.d('Driver - fetching assigned jobs with status: $status');
        query = query.eq('driver_id', userId);
      } else {
        // Unknown role or missing userId - default to no access
        Log.e('Unknown user role: $userRole or missing userId - returning empty list');
        return const Result.success([]);
      }

      final response = await query.order('created_at', ascending: false);

      Log.d('Fetched ${response.length} jobs with status: $status for user: $userId with role: $userRole');

      final jobs = response.map((json) => Job.fromJson(json)).toList();
      return Result.success(jobs);
    } catch (error) {
      Log.e('Error fetching jobs by status: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Get jobs by driver
  Future<Result<List<Job>>> getJobsByDriver(String driverId) async {
    try {
      Log.d('Fetching jobs for driver: $driverId');

      final response = await _supabase
          .from('jobs')
          .select('*')
          .eq('driver_id', driverId)
          .order('created_at', ascending: false);

      Log.d('Fetched ${response.length} jobs for driver: $driverId');

      final jobs = response.map((json) => Job.fromJson(json)).toList();
      return Result.success(jobs);
    } catch (error) {
      Log.e('Error fetching jobs by driver: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Get jobs by client with role-based filtering
  Future<Result<List<Job>>> getJobsByClient(
    String clientId, {
    String? userId,
    String? userRole,
  }) async {
    try {
      Log.d('Fetching jobs for client: $clientId for user: $userId with role: $userRole');

      // Check if userId is available for role-based filtering
      if (userId == null && userRole != 'administrator' && userRole != 'manager') {
        Log.e('UserId is required for role-based filtering');
        return const Result.success([]);
      }

      PostgrestFilterBuilder query = _supabase
          .from('jobs')
          .select('*')
          .eq('client_id', clientId);

      // Apply role-based filtering based on confirmed requirements
      if (userRole == 'administrator' || userRole == 'manager') {
        // Administrators and managers see ALL jobs
        Log.d('User has full access - fetching all jobs for client: $clientId');
        // No additional filtering needed
      } else if (userRole == 'driver_manager' && userId != null) {
        // Driver managers see jobs they created + jobs assigned to them
        Log.d('Driver manager - fetching created jobs and jobs assigned to them for client: $clientId');
        query = query.or('created_by.eq.$userId,driver_id.eq.$userId');
      } else if (userRole == 'driver' && userId != null) {
        // Drivers see jobs assigned to them (current + completed)
        Log.d('Driver - fetching assigned jobs for client: $clientId');
        query = query.eq('driver_id', userId);
      } else {
        // Unknown role or missing userId - default to no access
        Log.e('Unknown user role: $userRole or missing userId - returning empty list');
        return const Result.success([]);
      }

      final response = await query.order('created_at', ascending: false);

      Log.d('Fetched ${response.length} jobs for client: $clientId for user: $userId with role: $userRole');

      final jobs = response.map((json) => Job.fromJson(json)).toList();
      return Result.success(jobs);
    } catch (error) {
      Log.e('Error fetching jobs by client: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Get completed jobs by client with role-based filtering
  Future<Result<List<Job>>> getCompletedJobsByClient(
    String clientId, {
    String? userId,
    String? userRole,
  }) async {
    try {
      Log.d('Fetching completed jobs for client: $clientId for user: $userId with role: $userRole');

      // Check if userId is available for role-based filtering
      if (userId == null && userRole != 'administrator' && userRole != 'manager') {
        Log.e('UserId is required for role-based filtering');
        return const Result.success([]);
      }

      PostgrestFilterBuilder query = _supabase
          .from('jobs')
          .select('*')
          .eq('client_id', clientId)
          .eq('job_status', 'completed');

      // Apply role-based filtering based on confirmed requirements
      if (userRole == 'administrator' || userRole == 'manager') {
        // Administrators and managers see ALL jobs
        Log.d('User has full access - fetching all completed jobs for client: $clientId');
        // No additional filtering needed
      } else if (userRole == 'driver_manager' && userId != null) {
        // Driver managers see jobs they created + jobs assigned to them
        Log.d('Driver manager - fetching created jobs and jobs assigned to them for client: $clientId');
        query = query.or('created_by.eq.$userId,driver_id.eq.$userId');
      } else if (userRole == 'driver' && userId != null) {
        // Drivers see jobs assigned to them (current + completed)
        Log.d('Driver - fetching assigned jobs for client: $clientId');
        query = query.eq('driver_id', userId);
      } else {
        // Unknown role or missing userId - default to no access
        Log.e('Unknown user role: $userRole or missing userId - returning empty list');
        return const Result.success([]);
      }

      final response = await query.order('created_at', ascending: false);

      Log.d('Fetched ${response.length} completed jobs for client: $clientId for user: $userId with role: $userRole');

      final jobs = response.map((json) => Job.fromJson(json)).toList();
      return Result.success(jobs);
    } catch (error) {
      Log.e('Error fetching completed jobs by client: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Get completed jobs revenue by client with role-based filtering
  Future<Result<double>> getCompletedJobsRevenueByClient(
    String clientId, {
    String? userId,
    String? userRole,
  }) async {
    try {
      Log.d('Fetching completed jobs revenue for client: $clientId for user: $userId with role: $userRole');

      // Check if userId is available for role-based filtering
      if (userId == null && userRole != 'administrator' && userRole != 'manager') {
        Log.e('UserId is required for role-based filtering');
        return const Result.success(0.0);
      }

      PostgrestFilterBuilder query = _supabase
          .from('jobs')
          .select('amount')
          .eq('client_id', clientId)
          .eq('job_status', 'completed')
          .not('amount', 'is', null);

      // Apply role-based filtering based on confirmed requirements
      if (userRole == 'administrator' || userRole == 'manager') {
        // Administrators and managers see ALL jobs
        Log.d('User has full access - fetching all completed jobs revenue for client: $clientId');
        // No additional filtering needed
      } else if (userRole == 'driver_manager' && userId != null) {
        // Driver managers see jobs they created + jobs assigned to them
        Log.d('Driver manager - fetching created jobs and jobs assigned to them revenue for client: $clientId');
        query = query.or('created_by.eq.$userId,driver_id.eq.$userId');
      } else if (userRole == 'driver' && userId != null) {
        // Drivers see jobs assigned to them (current + completed)
        Log.d('Driver - fetching assigned jobs revenue for client: $clientId');
        query = query.eq('driver_id', userId);
      } else {
        // Unknown role or missing userId - default to no access
        Log.e('Unknown user role: $userRole or missing userId - returning 0.0');
        return const Result.success(0.0);
      }

      final response = await query;

      Log.d(
        'Fetched ${response.length} completed jobs with revenue for client: $clientId for user: $userId with role: $userRole',
      );

      double totalRevenue = 0.0;
      for (final row in response) {
        final amount = row['amount'];
        if (amount != null) {
          if (amount is num) {
            totalRevenue += amount.toDouble();
          } else if (amount is String) {
            totalRevenue += double.tryParse(amount) ?? 0.0;
          }
        }
      }

      Log.d('Total revenue for client $clientId for user $userId: $totalRevenue');
      return Result.success(totalRevenue);
    } catch (error) {
      Log.e('Error fetching completed jobs revenue by client: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Fetch a single job by ID
  Future<Result<Job?>> fetchJobById(String jobId) async {
    try {
      Log.d('Fetching job by ID: $jobId');

      final response = await _supabase
          .from('jobs')
          .select()
          .eq('id', jobId)
          .maybeSingle();

      if (response != null) {
        Log.d('Job found: ${response['passenger_name']}');
        return Result.success(Job.fromJson(response));
      } else {
        Log.d('Job not found: $jobId');
        return const Result.success(null);
      }
    } catch (error) {
      Log.e('Error fetching job by ID: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Map Supabase errors to appropriate AppException types
  Result<T> _mapSupabaseError<T>(dynamic error) {
    if (error is AuthException) {
      return Result.failure(AuthException(error.message));
    } else if (error is PostgrestException) {
      // Check if it's a network-related error
      if (error.message.contains('network') ||
          error.message.contains('timeout') ||
          error.message.contains('connection')) {
        return Result.failure(NetworkException(error.message));
      }
      // Check if it's an auth-related error
      if (error.message.contains('JWT') ||
          error.message.contains('unauthorized') ||
          error.message.contains('forbidden')) {
        return Result.failure(AuthException(error.message));
      }
      return Result.failure(UnknownException(error.message));
    } else if (error is StorageException) {
      if (error.message.contains('network') ||
          error.message.contains('timeout')) {
        return Result.failure(NetworkException(error.message));
      }
      return Result.failure(UnknownException(error.message));
    } else {
      return Result.failure(UnknownException(error.toString()));
    }
  }
}

/// Provider for JobsRepository
final jobsRepositoryProvider = Provider<JobsRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return JobsRepository(supabase);
});
