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
  /// 
  /// [statusFilter] - Optional status filter ('open', 'in_progress', 'closed', 'all', or null)
  /// [dateRangeDays] - Optional date range filter for completed/closed jobs (e.g., 90 for last 90 days)
  /// [limit] - Maximum number of jobs to fetch (default: 100 for performance)
  /// [offset] - Offset for pagination (default: 0)
  Future<Result<List<Job>>> fetchJobs({
    String? userId,
    String? userRole,
    String? statusFilter,
    int? dateRangeDays,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      Log.d('Fetching jobs for user: $userId with role: $userRole (limit: $limit, offset: $offset, status: $statusFilter)');

      // Check if userId is available for role-based filtering
      if (userId == null && userRole != 'administrator' && userRole != 'super_admin' && userRole != 'manager') {
        Log.e('UserId is required for role-based filtering');
        return const Result.success([]);
      }

      var query = _supabase.from('jobs').select();

      // Apply role-based filtering
      if (userRole == 'administrator' || userRole == 'super_admin' || userRole == 'manager') {
        // Administrators and managers see all jobs
        Log.d('User has full access - fetching jobs with filters');
      } else if (userRole == 'driver_manager' && userId != null) {
        // Driver managers see jobs they created/assigned + jobs assigned to them
        Log.d('Driver manager - fetching created jobs and jobs assigned to them');
        query = query.or('created_by.eq.$userId,driver_id.eq.$userId');
      } else if (userRole == 'driver' && userId != null) {
        // Drivers only see jobs assigned to them
        Log.d('Driver - fetching only assigned jobs for userId: $userId');
        query = query.eq('driver_id', userId);
      } else {
        // Unknown role or missing userId - default to no access
        Log.e('Unknown user role: $userRole or missing userId - returning empty list');
        return const Result.success([]);
      }

      // Apply status filter at database level for performance
      if (statusFilter != null && statusFilter != 'all') {
        if (statusFilter == 'open') {
          // Open jobs: status is 'open' or 'assigned'
          query = query.or('job_status.eq.open,job_status.eq.assigned');
          // Performance optimization: Exclude open/assigned jobs older than 3 days
          final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
          final threeDaysAgoDate = threeDaysAgo.toIso8601String().split('T')[0];
          query = query.gte('job_start_date', threeDaysAgoDate);
          Log.d('Applied date filter: excluding open/assigned jobs older than 3 days (before $threeDaysAgoDate)');
        } else if (statusFilter == 'in_progress') {
          query = query.or('job_status.eq.in_progress,job_status.eq.started,job_status.eq.ready_to_close');
        } else if (statusFilter == 'closed') {
          query = query.or('job_status.eq.completed,job_status.eq.closed,job_status.eq.cancelled');
        }
      }

      // Apply date range filter for completed/closed jobs at database level
      if (dateRangeDays != null && (statusFilter == 'closed' || statusFilter == 'all')) {
        final cutoffDate = DateTime.now().subtract(Duration(days: dateRangeDays));
        query = query.gte('updated_at', cutoffDate.toIso8601String());
        Log.d('Applied date range filter: last $dateRangeDays days (after ${cutoffDate.toIso8601String()})');
      }

      // Apply pagination and ordering at database level
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      Log.d('Fetched ${response.length} jobs for user: $userId with role: $userRole (limit: $limit, offset: $offset)');
      
      // Debug: Log the actual query being executed for drivers
      if (userRole == 'driver') {
        Log.d('Driver query executed - checking if any jobs have driver_id matching $userId');
        for (final job in response) {
          Log.d('Job ${job['id']}: driver_id=${job['driver_id']}, passenger_name=${job['passenger_name']}');
        }
      }

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

      // Validate decline_reason if status is 'declined'
      // CHECK constraint: decline_reason must be non-empty when job_status = 'declined'
      if (job.status == 'declined' &&
          (job.cancelReason == null || job.cancelReason!.trim().isEmpty)) {
        Log.e('Validation failed: decline_reason is required when job_status is declined');
        return Result.failure(UnknownException(
          'Decline reason is required when job status is declined',
        ));
      }

      // Get the current job to check for driver changes and validate agent_id
      final currentJobResponse = await _supabase
          .from('jobs')
          .select('driver_id, agent_id')
          .eq('id', job.id)
          .single();

      final currentDriverId = currentJobResponse['driver_id']?.toString();
      final newDriverId = job.driverId;
      final currentAgentId = currentJobResponse['agent_id']?.toString();

      // Prepare update map (excludes immutable fields like id and created_at)
      final updateMap = job.toUpdateMap();
      
      // Validate agent_id: 
      // - If updateMap includes agent_id, validate it's not null/empty
      // - If updateMap doesn't include agent_id, ensure current job has valid agent_id
      // Note: According to docs/data_model.md, agent_id is NOT NULL in database
      if (updateMap.containsKey('agent_id')) {
        final newAgentId = updateMap['agent_id'];
        // If newAgentId is null or empty string, this would violate NOT NULL constraint
        if (newAgentId == null || (newAgentId is String && newAgentId.isEmpty)) {
          Log.e('Validation failed: agent_id cannot be null or empty');
          return Result.failure(UnknownException(
            'Agent ID cannot be null or empty',
          ));
        }
      } else {
        // agent_id not in update map - Supabase will preserve current value
        // Validate that current job has valid agent_id
        if (currentAgentId == null || currentAgentId.isEmpty) {
          Log.e('Validation failed: Current job has null agent_id, cannot preserve it');
          return Result.failure(UnknownException(
            'Current job is missing Agent ID. Please set an Agent ID before updating.',
          ));
        }
        // Current job has valid agent_id, it will be preserved - this is fine
      }

      Log.d('Update payload keys: ${updateMap.keys.toList()}');
      Log.d('Update payload contains ${updateMap.length} fields');
      
      // Update the job using toUpdateMap() which excludes immutable fields
      await _supabase.from('jobs').update(updateMap).eq('id', job.id);

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

  /// Get driver flow data for a job
  Future<Result<Map<String, dynamic>?>> getDriverFlowData(String jobId) async {
    try {
      Log.d('Fetching driver flow data for job: $jobId');

      final response = await _supabase
          .from('driver_flow')
          .select('*')
          .eq('job_id', int.parse(jobId))
          .maybeSingle();

      if (response != null) {
        Log.d('Driver flow data found for job: $jobId');
        return Result.success(response);
      } else {
        Log.d('No driver flow data found for job: $jobId');
        return const Result.success(null);
      }
    } catch (error) {
      Log.e('Error fetching driver flow data: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Update job status
  Future<Result<void>> updateJobStatus(String jobId, String status) async {
    try {
      Log.d('Updating job status: $jobId to $status');

      // Prepare update data (jobs table column is job_status, not status)
      final updateData = <String, dynamic>{
        'job_status': status,
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

  /// Update job confirmation fields only (without changing status)
  Future<Result<void>> updateJobConfirmation(String jobId) async {
    try {
      Log.d('Updating job confirmation: $jobId');

      // Prepare update data - only driver_confirm_ind field
      final updateData = <String, dynamic>{
        'driver_confirm_ind': true,
        'confirmed_at': SATimeUtils.getCurrentSATimeISO(),
        'updated_at': SATimeUtils.getCurrentSATimeISO(),
      };

      await _supabase.from('jobs').update(updateData).eq('id', jobId);

      Log.d('Job confirmation updated successfully');
      return const Result.success(null);
    } catch (error) {
      Log.e('Error updating job confirmation: $error');
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
      if (userId == null && userRole != 'administrator' && userRole != 'super_admin' && userRole != 'manager') {
        Log.e('UserId is required for role-based filtering');
        return const Result.success([]);
      }

      PostgrestFilterBuilder query = _supabase
          .from('jobs')
          .select()
          .eq('status', status);

      // Apply role-based filtering based on confirmed requirements
      if (userRole == 'administrator' || userRole == 'super_admin' || userRole == 'manager') {
        // Administrators and managers see ALL jobs
        Log.d('User has full access - fetching all jobs with status: $status');
        // No additional filtering needed
      } else if (userRole == 'driver_manager' && userId != null) {
        // Driver managers see jobs they created + jobs assigned to them
        Log.d('Driver manager - fetching created jobs and jobs assigned to them with status: $status');
        query = query.or('created_by.eq.$userId,driver_id.eq.$userId');
      } else if (userRole == 'driver' && userId != null) {
        // Drivers see jobs assigned to them (current + completed)
        Log.d('Driver - fetching assigned jobs with status: $status for userId: $userId');
        query = query.eq('driver_id', userId);
      } else {
        // Unknown role or missing userId - default to no access
        Log.e('Unknown user role: $userRole or missing userId - returning empty list');
        return const Result.success([]);
      }

      // Performance optimization: Filter out open/assigned jobs older than 3 days at database level
      // Only apply this filter when fetching open or assigned status jobs
      if (status == 'open' || status == 'assigned') {
        final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
        final threeDaysAgoDate = threeDaysAgo.toIso8601String().split('T')[0]; // Format as YYYY-MM-DD
        
        // Exclude jobs older than 3 days
        query = query.gte('job_start_date', threeDaysAgoDate);
        
        Log.d('Applied date filter: excluding open/assigned jobs older than 3 days (before $threeDaysAgoDate)');
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
      if (userId == null && userRole != 'administrator' && userRole != 'super_admin' && userRole != 'manager') {
        Log.e('UserId is required for role-based filtering');
        return const Result.success([]);
      }

      PostgrestFilterBuilder query = _supabase
          .from('jobs')
          .select('*')
          .eq('client_id', clientId);

      // Apply role-based filtering based on confirmed requirements
      if (userRole == 'administrator' || userRole == 'super_admin' || userRole == 'manager') {
        // Administrators and managers see ALL jobs
        Log.d('User has full access - fetching all jobs for client: $clientId');
        // No additional filtering needed
      } else if (userRole == 'driver_manager' && userId != null) {
        // Driver managers see jobs they created + jobs assigned to them
        Log.d('Driver manager - fetching created jobs and jobs assigned to them for client: $clientId');
        query = query.or('created_by.eq.$userId,driver_id.eq.$userId');
      } else if (userRole == 'driver' && userId != null) {
        // Drivers see jobs assigned to them (current + completed)
        Log.d('Driver - fetching assigned jobs for client: $clientId for userId: $userId');
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
      if (userId == null && userRole != 'administrator' && userRole != 'super_admin' && userRole != 'manager') {
        Log.e('UserId is required for role-based filtering');
        return const Result.success([]);
      }

      PostgrestFilterBuilder query = _supabase
          .from('jobs')
          .select('*')
          .eq('client_id', clientId)
          .eq('job_status', 'completed');

      // Apply role-based filtering based on confirmed requirements
      if (userRole == 'administrator' || userRole == 'super_admin' || userRole == 'manager') {
        // Administrators and managers see ALL jobs
        Log.d('User has full access - fetching all completed jobs for client: $clientId');
        // No additional filtering needed
      } else if (userRole == 'driver_manager' && userId != null) {
        // Driver managers see jobs they created + jobs assigned to them
        Log.d('Driver manager - fetching created jobs and jobs assigned to them for client: $clientId');
        query = query.or('created_by.eq.$userId,driver_id.eq.$userId');
      } else if (userRole == 'driver' && userId != null) {
        // Drivers see jobs assigned to them (current + completed)
        Log.d('Driver - fetching assigned jobs for client: $clientId for userId: $userId');
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
      if (userId == null && userRole != 'administrator' && userRole != 'super_admin' && userRole != 'manager') {
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
      if (userRole == 'administrator' || userRole == 'super_admin' || userRole == 'manager') {
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

  /// Fetch jobs filtered by pickup_date range, location, and status for insights
  /// Uses earliest pickup_date from transport table per job
  /// Returns total count and jobs list for pagination
  Future<Result<Map<String, dynamic>>> fetchJobsWithInsightsFilters({
    required DateTime startDate,
    required DateTime endDate,
    String? location, // 'Jhb', 'Cpt', 'Dbn', or null for all
    String? status, // 'all', 'completed', 'open' (everything except completed/cancelled)
    int limit = 12,
    int offset = 0,
  }) async {
    try {
      Log.d('Fetching jobs with insights filters: startDate=$startDate, endDate=$endDate, location=$location, status=$status, limit=$limit, offset=$offset');

      // Step 1: Get all job IDs that have transport with pickup_date in range
      var transportQuery = _supabase
          .from('transport')
          .select('job_id, pickup_date')
          .gte('pickup_date', startDate.toIso8601String())
          .lte('pickup_date', endDate.toIso8601String())
          .not('pickup_date', 'is', null);

      final transportResponse = await transportQuery;
      
      // Get unique job IDs with earliest pickup_date per job
      final Map<int, DateTime> jobEarliestPickup = {};
      for (final transport in transportResponse) {
        final jobId = transport['job_id'] as int?;
        final pickupDateStr = transport['pickup_date'] as String?;
        if (jobId != null && pickupDateStr != null) {
          final pickupDate = DateTime.parse(pickupDateStr);
          if (!jobEarliestPickup.containsKey(jobId) || 
              pickupDate.isBefore(jobEarliestPickup[jobId]!)) {
            jobEarliestPickup[jobId] = pickupDate;
          }
        }
      }

      if (jobEarliestPickup.isEmpty) {
        Log.d('No jobs found with pickup_date in range');
        return Result.success({
          'jobs': <Job>[],
          'total': 0,
        });
      }

      // Step 2: Query jobs with filters
      // Build filter for multiple IDs using 'in' filter
      final jobIds = jobEarliestPickup.keys.toList();
      var jobsQuery = _supabase
          .from('jobs')
          .select('*');
      
      // Filter by job IDs using 'in' filter
      if (jobIds.isNotEmpty) {
        // Use inFilter for multiple values
        jobsQuery = jobsQuery.inFilter('id', jobIds);
      }

      // Filter by location (branch location)
      if (location != null && location.isNotEmpty) {
        jobsQuery = jobsQuery.eq('location', location);
      }

      // Filter by status
      if (status != null && status != 'all') {
        if (status == 'completed') {
          jobsQuery = jobsQuery.eq('job_status', 'completed');
        } else if (status == 'open') {
          // Open = everything except completed and cancelled
          jobsQuery = jobsQuery.not('job_status', 'in', '(completed,cancelled)');
        }
      }

      final jobsResponse = await jobsQuery;

      Log.d('Fetched ${jobsResponse.length} jobs matching filters');

      // Convert to Job models and attach earliest pickup_date
      final jobs = jobsResponse.map<Job>((json) => Job.fromJson(json)).toList();
      
      // Sort by earliest pickup_date
      jobs.sort((a, b) {
        final aPickup = jobEarliestPickup[a.id];
        final bPickup = jobEarliestPickup[b.id];
        if (aPickup == null && bPickup == null) return 0;
        if (aPickup == null) return 1;
        if (bPickup == null) return -1;
        return aPickup.compareTo(bPickup);
      });

      // Apply pagination
      final total = jobs.length;
      final paginatedJobs = jobs.skip(offset).take(limit).toList();

      Log.d('Returning ${paginatedJobs.length} jobs (offset=$offset, limit=$limit, total=$total)');
      
      return Result.success({
        'jobs': paginatedJobs,
        'total': total,
      });
    } catch (error) {
      Log.e('Error fetching jobs with insights filters: $error');
      return _mapSupabaseError(error);
    }
  }
}

/// Provider for JobsRepository
final jobsRepositoryProvider = Provider<JobsRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return JobsRepository(supabase);
});
