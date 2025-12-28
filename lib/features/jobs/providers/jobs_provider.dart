import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/jobs/models/job.dart';
import 'package:choice_lux_cars/features/jobs/data/jobs_repository.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/features/notifications/notifications.dart';

/// Notifier for managing jobs state using AsyncNotifier
class JobsNotifier extends AsyncNotifier<List<Job>> {
  /// Get the jobs repository
  JobsRepository get _jobsRepository => ref.read(jobsRepositoryProvider);

  @override
  Future<List<Job>> build() async {
    _checkPermissions();
    return _fetchJobs();
  }

  /// Check if current user can create jobs
  void _checkPermissions() {
    // Note: canCreateJobs is now handled in the UI layer based on user role
  }

  /// Fetch all jobs from the repository
  /// Automatically filters by branch_id for non-admin users
  Future<List<Job>> _fetchJobs() async {
    try {
      Log.d('Fetching jobs...');

      final userProfile = ref.read(currentUserProfileProvider);
      final userId = userProfile?.id;
      final userRole = userProfile?.role?.toLowerCase();
      final branchId = userProfile?.branchId; // Get branchId from current user

      if (userId == null || userRole == null) {
        Log.e('User profile or role not available - cannot fetch jobs');
        return [];
      }

      // Admin (branchId == null) sees all jobs, non-admin sees only their branch
      final result = await _jobsRepository.fetchJobs(
        userId: userId,
        userRole: userRole,
        branchId: branchId,
      );

      if (result.isSuccess) {
        final jobs = result.data!;
        Log.d('Fetched ${jobs.length} jobs successfully for user: $userId with role: $userRole');
        return jobs;
      } else {
        Log.e('Error fetching jobs: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error fetching jobs: $error');
      rethrow;
    }
  }

  /// Create a new job using the repository
  Future<Map<String, dynamic>?> createJob(Job job) async {
    try {
      Log.d('Creating job: ${job.passengerName}');

      final result = await _jobsRepository.createJob(job);

      if (result.isSuccess) {
        // Refresh jobs list
        ref.invalidateSelf();
        Log.d('Job created successfully');
        return result.data;
      } else {
        Log.e('Error creating job: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error creating job: $error');
      rethrow;
    }
  }

  /// Update an existing job using the repository
  Future<void> updateJob(Job job) async {
    try {
      Log.d('Updating job: ${job.id}');

      final result = await _jobsRepository.updateJob(job);

      if (result.isSuccess) {
        // Update local state optimistically
        final currentJobs = state.value ?? [];
        final updatedJobs = currentJobs
            .map((j) => j.id == job.id ? job : j)
            .toList();
        state = AsyncValue.data(updatedJobs);
        Log.d('Job updated successfully');
      } else {
        Log.e('Error updating job: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error updating job: $error');
      rethrow;
    }
  }

  /// Update job status using the repository
  Future<void> updateJobStatus(String jobId, String status) async {
    try {
      Log.d('Updating job status: $jobId to $status');

      final result = await _jobsRepository.updateJobStatus(jobId, status);

      if (result.isSuccess) {
        // Update local state optimistically
        final currentJobs = state.value ?? [];
        final updatedJobs = currentJobs.map((job) {
          if (job.id.toString() == jobId) {
            return job.copyWith(status: status);
          }
          return job;
        }).toList();

        state = AsyncValue.data(updatedJobs);
        Log.d('Job status updated successfully');
      } else {
        Log.e('Error updating job status: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error updating job status: $error');
      rethrow;
    }
  }

  /// Update job payment amount using the repository
  Future<void> updateJobPaymentAmount(String jobId, double amount) async {
    try {
      Log.d('Updating job payment amount: $jobId to $amount');

      final result = await _jobsRepository.updateJobPaymentAmount(
        jobId,
        amount,
      );

      if (result.isSuccess) {
        // Update local state optimistically
        final currentJobs = state.value ?? [];
        final updatedJobs = currentJobs.map((job) {
          if (job.id == jobId) {
            return job.copyWith(paymentAmount: amount);
          }
          return job;
        }).toList();

        state = AsyncValue.data(updatedJobs);
        Log.d('Job payment amount updated successfully');
      } else {
        Log.e('Error updating job payment amount: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error updating job payment amount: $error');
      rethrow;
    }
  }

  /// Delete a job using the repository
  Future<void> deleteJob(String jobId) async {
    try {
      Log.d('Deleting job: $jobId');

      final result = await _jobsRepository.deleteJob(jobId);

      if (result.isSuccess) {
        // Update local state optimistically
        final currentJobs = state.value ?? [];
        final updatedJobs = currentJobs
            .where((job) => job.id != jobId)
            .toList();
        state = AsyncValue.data(updatedJobs);
        Log.d('Job deleted successfully');
      } else {
        Log.e('Error deleting job: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error deleting job: $error');
      rethrow;
    }
  }

  /// Get jobs by status using the repository
  Future<List<Job>> getJobsByStatus(String status) async {
    try {
      Log.d('Getting jobs by status: $status');

      if (status == 'all') {
        return state.value ?? [];
      }

      final result = await _jobsRepository.getJobsByStatus(status);
      if (result.isSuccess) {
        return result.data!;
      } else {
        Log.e('Error getting jobs by status: ${result.error!.message}');
        return [];
      }
    } catch (error) {
      Log.e('Error getting jobs by status: $error');
      rethrow;
    }
  }

  /// Get jobs by driver using the repository
  Future<List<Job>> getJobsByDriver(String driverId) async {
    try {
      Log.d('Getting jobs by driver: $driverId');

      final result = await _jobsRepository.getJobsByDriver(driverId);
      if (result.isSuccess) {
        return result.data!;
      } else {
        Log.e('Error getting jobs by driver: ${result.error!.message}');
        return [];
      }
    } catch (error) {
      Log.e('Error getting jobs by driver: $error');
      rethrow;
    }
  }

  /// Get jobs by client using the repository
  /// Automatically filters by branch_id for non-admin users
  /// [branchId] - Optional override branch filter. If not provided, uses current user's branchId (non-admin) or null (admin).
  Future<List<Job>> getJobsByClient(
    String clientId, {
    int? branchId, // Optional override branch filter
  }) async {
    try {
      final currentUser = ref.read(currentUserProfileProvider);
      final userId = currentUser?.id;
      final userRole = currentUser?.role?.toLowerCase();
      
      // Determine effective branchId: use override if provided, otherwise use current user's branchId
      // Admin (branchId == null) sees all branches, non-admin sees only their branch
      final effectiveBranchId = branchId ?? currentUser?.branchId;
      
      Log.d('Getting jobs by client: $clientId${effectiveBranchId != null ? ' (branch: $effectiveBranchId)' : ' (all branches - admin)'}');

      final result = await _jobsRepository.getJobsByClient(
        clientId,
        userId: userId,
        userRole: userRole,
        branchId: effectiveBranchId,
      );
      if (result.isSuccess) {
        return result.data!;
      } else {
        Log.e('Error getting jobs by client: ${result.error!.message}');
        return [];
      }
    } catch (error) {
      Log.e('Error getting jobs by client: $error');
      rethrow;
    }
  }

  /// Refresh jobs data (alias for refresh)
  Future<void> refreshJobs() async {
    Log.d('Refreshing jobs data...');
    // Force a complete refresh by setting state to loading and then rebuilding
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async => await _fetchJobs());
    Log.d('Jobs data refresh completed');
  }

  /// Convenience alias for old call sites
  Future<void> fetchJobs() async => refreshJobs?.call() ?? _refreshCompat();

  Future<void> _refreshCompat() async {
    // Fallback refresh if refreshJobs() does not exist yet
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async => await build());
  }

  /// Check if current user can create jobs
  bool get canCreateJobs {
    final userProfile = ref.read(currentUserProfileProvider);
    final userRole = userProfile?.role?.toLowerCase();
    final isAdmin = userProfile?.isAdmin ?? false;

    return isAdmin ||
        userRole == 'manager' ||
        userRole == 'driver_manager' ||
        userRole == 'drivermanager';
  }

  /// Fetch a single job by ID
  Future<Job?> fetchJobById(String jobId) async {
    try {
      Log.d('Fetching job by ID: $jobId');

      final result = await _jobsRepository.fetchJobById(jobId);

      if (result.isSuccess) {
        final job = result.data;
        Log.d('Job fetched successfully: ${job?.passengerName}');
        return job;
      } else {
        Log.e('Error fetching job by ID: ${result.error!.message}');
        return null;
      }
    } catch (error) {
      Log.e('Error fetching job by ID: $error');
      return null;
    }
  }

  /// Confirm a job (change status to confirmed)
  Future<void> confirmJob(String jobId) async {
    try {
      Log.d('=== CONFIRM JOB DEBUG ===');
      Log.d('Confirming job: $jobId');
      Log.d('Current jobs count: ${state.value?.length ?? 0}');

      // Update only the confirmation fields, not the status
      final result = await _jobsRepository.updateJobConfirmation(jobId);

      if (result.isSuccess) {
        Log.d('Database update successful');
        // Update local state optimistically with all confirmation fields
        final currentJobs = state.value ?? [];
        Log.d('Current jobs before update: ${currentJobs.length}');
        
        final updatedJobs = currentJobs.map((job) {
          if (job.id.toString() == jobId) {
            Log.d('Found job to update: ${job.id} -> ${job.passengerName}');
            final updatedJob = job.copyWith(
              driverConfirmation: true,
              confirmedAt: DateTime.now(),
            );
            Log.d('Updated job - driverConfirmation: ${updatedJob.driverConfirmation}, isConfirmed: ${updatedJob.isConfirmed}');
            return updatedJob;
          }
          return job;
        }).toList();
        
        Log.d('Updated jobs count: ${updatedJobs.length}');
        state = AsyncValue.data(updatedJobs);
        Log.d('State updated successfully');
        Log.d('New state jobs count: ${state.value?.length ?? 0}');

        // Fan-out notification to administrators/managers/driver_managers
        try {
          final int parsedJobId = int.tryParse(jobId) ?? 0;
          if (parsedJobId > 0) {
            await NotificationService.sendJobConfirmationNotification(jobId: parsedJobId);
          }
        } catch (e) {
          Log.e('Error sending job confirmation notifications: $e');
        }
      } else {
        Log.e('Error confirming job: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error confirming job: $error');
      return null;
    }
  }

  /// Cancel a job (admin only)
  Future<void> cancelJob({
    required String jobId,
    required String reason,
  }) async {
    try {
      final currentUser = ref.read(currentUserProfileProvider);
      final role = currentUser?.role?.toLowerCase();

      if (currentUser == null || role != 'administrator') {
        throw Exception('Only administrators can cancel jobs.');
      }

      final result = await _jobsRepository.cancelJob(
        jobId: jobId,
        reason: reason,
        cancelledBy: currentUser.id,
      );

      if (result.isSuccess) {
        final cancelledJob = result.data!;
        final updatedJobs = (state.value ?? []).map((job) {
          if (job.id.toString() == jobId) {
            return job.copyWith(
              status: 'cancelled',
              cancelReason: cancelledJob.cancelReason,
              cancelledBy: cancelledJob.cancelledBy,
              cancelledAt: cancelledJob.cancelledAt,
            );
          }
          return job;
        }).toList();

        state = AsyncValue.data(updatedJobs);
      } else {
        throw Exception(result.error?.message ?? 'Failed to cancel job');
      }
    } catch (error) {
      Log.e('Error cancelling job: $error');
      rethrow;
    }
  }
}

/// Provider for JobsNotifier using AsyncNotifierProvider
final jobsProvider = AsyncNotifierProvider<JobsNotifier, List<Job>>(JobsNotifier.new);
