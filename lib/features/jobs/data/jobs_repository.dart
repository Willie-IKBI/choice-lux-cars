import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:choice_lux_cars/core/supabase/supabase_client_provider.dart';
import 'package:choice_lux_cars/features/jobs/models/job.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/core/types/result.dart';
import 'package:choice_lux_cars/core/errors/app_exception.dart';

/// Repository for job-related data operations
///
/// Encapsulates all Supabase queries and returns domain models.
/// This layer separates data access from business logic.
class JobsRepository {
  final SupabaseClient _supabase;

  JobsRepository(this._supabase);

  /// Fetch all jobs from the database
  Future<Result<List<Job>>> fetchJobs() async {
    try {
      Log.d('Fetching jobs from database');

      final response = await _supabase
          .from('jobs')
          .select()
          .order('created_at', ascending: false);

      Log.d('Fetched ${response.length} jobs from database');

      final jobs = response.map((json) => Job.fromJson(json)).toList();
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

      await _supabase.from('jobs').update(job.toJson()).eq('id', job.id);

      Log.d('Job updated successfully');
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

      await _supabase.from('jobs').update({'status': status}).eq('id', jobId);

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

  /// Get jobs by status
  Future<Result<List<Job>>> getJobsByStatus(String status) async {
    try {
      Log.d('Fetching jobs with status: $status');

      final response = await _supabase
          .from('jobs')
          .select()
          .eq('status', status)
          .order('created_at', ascending: false);

      Log.d('Fetched ${response.length} jobs with status: $status');

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

  /// Get jobs by client
  Future<Result<List<Job>>> getJobsByClient(String clientId) async {
    try {
      Log.d('Fetching jobs for client: $clientId');

      final response = await _supabase
          .from('jobs')
          .select('*')
          .eq('client_id', clientId)
          .order('created_at', ascending: false);

      Log.d('Fetched ${response.length} jobs for client: $clientId');

      final jobs = response.map((json) => Job.fromJson(json)).toList();
      return Result.success(jobs);
    } catch (error) {
      Log.e('Error fetching jobs by client: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Get completed jobs by client
  Future<Result<List<Job>>> getCompletedJobsByClient(String clientId) async {
    try {
      Log.d('Fetching completed jobs for client: $clientId');

      final response = await _supabase
          .from('jobs')
          .select('*')
          .eq('client_id', clientId)
          .eq('job_status', 'completed')
          .order('created_at', ascending: false);

      Log.d('Fetched ${response.length} completed jobs for client: $clientId');

      final jobs = response.map((json) => Job.fromJson(json)).toList();
      return Result.success(jobs);
    } catch (error) {
      Log.e('Error fetching completed jobs by client: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Get completed jobs revenue by client
  Future<Result<double>> getCompletedJobsRevenueByClient(
    String clientId,
  ) async {
    try {
      Log.d('Fetching completed jobs revenue for client: $clientId');

      final response = await _supabase
          .from('jobs')
          .select('amount')
          .eq('client_id', clientId)
          .eq('job_status', 'completed')
          .not('amount', 'is', null);

      Log.d(
        'Fetched ${response.length} completed jobs with revenue for client: $clientId',
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

      Log.d('Total revenue for client $clientId: $totalRevenue');
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
