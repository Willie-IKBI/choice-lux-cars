import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:choice_lux_cars/core/supabase/supabase_client_provider.dart';
import 'package:choice_lux_cars/features/jobs/models/trip_progress.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/core/types/result.dart';
import 'package:choice_lux_cars/core/errors/app_exception.dart';

/// Repository for trip_progress table operations
/// 
/// Handles all data access for trip progress tracking.
/// Respects RLS policies (driver can SELECT/UPDATE for their assigned jobs only).
class TripProgressRepository {
  final SupabaseClient _supabase;

  TripProgressRepository(this._supabase);

  /// Fetch all trip progress rows for a job, ordered by trip_index
  Future<Result<List<TripProgress>>> getTripsForJob(int jobId) async {
    try {
      Log.d('Fetching trip progress for job: $jobId');

      final response = await _supabase
          .from('trip_progress')
          .select()
          .eq('job_id', jobId)
          .order('trip_index', ascending: true);

      Log.d('Fetched ${response.length} trip progress rows for job $jobId');

      final trips = response
          .map((json) => TripProgress.fromJson(json))
          .toList();

      return Result.success(trips);
    } catch (error) {
      Log.e('Error fetching trip progress for job $jobId: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Update trip status
  /// 
  /// The database trigger will:
  /// - Validate the status transition is valid
  /// - Auto-set timestamps when status changes
  /// - Enforce immutability of timestamps
  /// - Set updated_at automatically
  Future<Result<TripProgress>> updateTripStatus(int tripProgressId, String nextStatus) async {
    try {
      Log.d('Updating trip progress $tripProgressId to status: $nextStatus');

      final response = await _supabase
          .from('trip_progress')
          .update({'status': nextStatus})
          .eq('id', tripProgressId)
          .select()
          .single();

      Log.d('Trip progress updated successfully');
      return Result.success(TripProgress.fromJson(response));
    } catch (error) {
      Log.e('Error updating trip progress status: $error');
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
      // Check if it's a constraint/validation error (from trigger)
      if (error.message.contains('Invalid status transition') ||
          error.message.contains('Cannot change') ||
          error.message.contains('immutable')) {
        return Result.failure(ValidationException(error.message));
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

/// Provider for TripProgressRepository
final tripProgressRepositoryProvider = Provider<TripProgressRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return TripProgressRepository(supabase);
});

