import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/jobs/models/job.dart';
import 'package:choice_lux_cars/features/jobs/data/jobs_repository.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/features/notifications/services/notification_service.dart';

/// Notifier for managing jobs state using AsyncNotifier
class JobsNotifier extends AsyncNotifier<List<Job>> {
  @override
  Future<List<Job>> build() async {
    // IMPORTANT: watch profile so this provider rebuilds/refetches when user changes.
    // Without this, jobs can remain cached from a previous session (e.g. admin -> driver).
    ref.watch(currentUserProfileProvider);
    _checkPermissions();
    return _fetchJobs();
  }

  /// Check if current user can create jobs
  void _checkPermissions() {
    final userProfile = ref.read(currentUserProfileProvider);
    final userRole = userProfile?.role?.toLowerCase();

    final canCreate =
        userRole == 'administrator' ||
        userRole == 'super_admin' ||
        userRole == 'manager' ||
        userRole == 'driver_manager';

    // Note: canCreateJobs is now handled in the UI layer based on user role
  }

  /// Fetch all jobs from the repository
  /// 
  /// Performance optimization: Fetches up to 200 jobs initially to improve load time.
  /// For super_admin/administrator/manager, this prevents loading thousands of jobs at once.
  Future<List<Job>> _fetchJobs() async {
    try {
      Log.d('Fetching jobs...');

      final userProfile = ref.read(currentUserProfileProvider);
      final userId = userProfile?.id;
      final userRole = userProfile?.role?.toLowerCase();

      if (userId == null || userRole == null) {
        Log.e('User profile or role not available - cannot fetch jobs');
        return [];
      }

      // Performance optimization: For admins/managers, limit initial fetch to 200 jobs
      // This significantly improves load time. More jobs can be loaded on demand if needed.
      final limit = (userRole == 'administrator' || userRole == 'super_admin' || userRole == 'manager') 
          ? 200 
          : 100; // Drivers/driver_managers typically have fewer jobs

      final repository = ref.read(jobsRepositoryProvider);
      final result = await repository.fetchJobs(
        userId: userId,
        userRole: userRole,
        limit: limit,
        offset: 0,
      );

      if (result.isSuccess) {
        var jobs = result.data!;

        // Defensive client-side enforcement: drivers must only ever see jobs allocated to them.
        if (userRole == 'driver') {
          jobs = jobs.where((j) => j.driverId == userId).toList();
        }

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

      final repository = ref.read(jobsRepositoryProvider);
      final result = await repository.createJob(job);

      if (result.isSuccess) {
        // Refresh jobs list and wait for it to complete
        // This ensures the dashboard has fresh data when user navigates back
        ref.invalidateSelf();
        Log.d('Job created successfully, refreshing jobs list...');
        
        // Wait for the provider to rebuild with fresh data
        // This ensures the dashboard shows the new job immediately
        await refreshJobs();
        
        Log.d('Jobs list refreshed after job creation');
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

      final repository = ref.read(jobsRepositoryProvider);
      final result = await repository.updateJob(job);

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

      final repository = ref.read(jobsRepositoryProvider);
      final result = await repository.updateJobStatus(jobId, status);

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

      final repository = ref.read(jobsRepositoryProvider);
      final result = await repository.updateJobPaymentAmount(
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

      final repository = ref.read(jobsRepositoryProvider);
      final result = await repository.deleteJob(jobId);

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

      // Get user context for role-based filtering
      final userProfile = ref.read(currentUserProfileProvider);
      final userId = userProfile?.id;
      final userRole = userProfile?.role?.toLowerCase();

      final repository = ref.read(jobsRepositoryProvider);
      final result = await repository.getJobsByStatus(
        status,
        userId: userId,
        userRole: userRole,
      );
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

      final repository = ref.read(jobsRepositoryProvider);
      final result = await repository.getJobsByDriver(driverId);
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
  Future<List<Job>> getJobsByClient(String clientId) async {
    try {
      Log.d('Getting jobs by client: $clientId');

      // Get user context for role-based filtering
      final userProfile = ref.read(currentUserProfileProvider);
      final userId = userProfile?.id;
      final userRole = userProfile?.role?.toLowerCase();

      final repository = ref.read(jobsRepositoryProvider);
      final result = await repository.getJobsByClient(
        clientId,
        userId: userId,
        userRole: userRole,
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
  Future<void> fetchJobs() async => refreshJobs();

  /// Check if current user can create jobs
  bool get canCreateJobs {
    final userProfile = ref.read(currentUserProfileProvider);
    final userRole = userProfile?.role?.toLowerCase();

    return userRole == 'administrator' ||
        userRole == 'super_admin' ||
        userRole == 'manager' ||
        userRole == 'driver_manager';
  }

  /// Fetch a single job by ID
  Future<Job?> fetchJobById(String jobId) async {
    try {
      Log.d('Fetching job by ID: $jobId');

      final repository = ref.read(jobsRepositoryProvider);
      final result = await repository.fetchJobById(jobId);

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
      final repository = ref.read(jobsRepositoryProvider);
      final result = await repository.updateJobConfirmation(jobId);

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

        // Refresh jobs list from server to ensure UI is in sync
        // This ensures confirmed jobs appear correctly in the jobs tab
        try {
          Log.d('Refreshing jobs list after confirmation...');
          await fetchJobs();
          Log.d('Jobs list refreshed successfully');
        } catch (refreshError) {
          Log.e('Error refreshing jobs list after confirmation: $refreshError');
          // Don't fail the confirmation if refresh fails - optimistic update is already applied
        }

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
}

/// Provider for JobsNotifier using AsyncNotifierProvider
final jobsProvider = AsyncNotifierProvider<JobsNotifier, List<Job>>(JobsNotifier.new);
