import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:choice_lux_cars/core/supabase/supabase_client_provider.dart';
import 'package:choice_lux_cars/features/jobs/models/trip.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/core/types/result.dart';
import 'package:choice_lux_cars/core/errors/app_exception.dart';

/// Repository for trip-related data operations
/// 
/// Encapsulates all Supabase queries and returns domain models.
/// This layer separates data access from business logic.
class TripsRepository {
  final SupabaseClient _supabase;

  TripsRepository(this._supabase);

  /// Fetch all trips from the database
  Future<Result<List<Trip>>> fetchTrips() async {
    try {
      Log.d('Fetching trips from database');
      
      final response = await _supabase
          .from('trips')
          .select()
          .order('created_at', ascending: false);

      Log.d('Fetched ${response.length} trips from database');
      
      final trips = response.map((json) => Trip.fromJson(json)).toList();
      return Result.success(trips);
    } catch (error) {
      Log.e('Error fetching trips: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Fetch trips for a specific job
  Future<Result<List<Trip>>> fetchTripsForJob(String jobId) async {
    try {
      Log.d('Fetching trips for job: $jobId');
      
      final response = await _supabase
          .from('trips')
          .select()
          .eq('job_id', jobId)
          .order('created_at', ascending: false);

      Log.d('Fetched ${response.length} trips for job: $jobId');
      
      final trips = response.map((json) => Trip.fromJson(json)).toList();
      return Result.success(trips);
    } catch (error) {
      Log.e('Error fetching trips for job: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Create a new trip
  Future<Result<Map<String, dynamic>>> createTrip(Trip trip) async {
    try {
      Log.d('Creating trip for job: ${trip.jobId}');
      
      final response = await _supabase
          .from('trips')
          .insert(trip.toJson())
          .select()
          .single();

      Log.d('Trip created successfully with ID: ${response['id']}');
      return Result.success(response);
    } catch (error) {
      Log.e('Error creating trip: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Update an existing trip
  Future<Result<void>> updateTrip(Trip trip) async {
    try {
      Log.d('Updating trip: ${trip.id}');
      
      await _supabase
          .from('trips')
          .update(trip.toJson())
          .eq('id', trip.id);

      Log.d('Trip updated successfully');
      return const Result.success(null);
    } catch (error) {
      Log.e('Error updating trip: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Update trip status
  Future<Result<void>> updateTripStatus(String tripId, String status) async {
    try {
      Log.d('Updating trip status: $tripId to $status');
      
      await _supabase
          .from('trips')
          .update({'status': status})
          .eq('id', tripId);

      Log.d('Trip status updated successfully');
      return const Result.success(null);
    } catch (error) {
      Log.e('Error updating trip status: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Delete a trip
  Future<Result<void>> deleteTrip(String tripId) async {
    try {
      Log.d('Deleting trip: $tripId');
      
      await _supabase
          .from('trips')
          .delete()
          .eq('id', tripId);

      Log.d('Trip deleted successfully');
      return const Result.success(null);
    } catch (error) {
      Log.e('Error deleting trip: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Get trips by status
  Future<Result<List<Trip>>> getTripsByStatus(String status) async {
    try {
      Log.d('Fetching trips with status: $status');
      
      final response = await _supabase
          .from('trips')
          .select()
          .eq('status', status)
          .order('created_at', ascending: false);

      Log.d('Fetched ${response.length} trips with status: $status');
      
      final trips = response.map((json) => Trip.fromJson(json)).toList();
      return Result.success(trips);
    } catch (error) {
      Log.e('Error fetching trips by status: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Get trips by driver
  Future<Result<List<Trip>>> getTripsByDriver(String driverId) async {
    try {
      Log.d('Fetching trips for driver: $driverId');
      
      final response = await _supabase
          .from('trips')
          .select()
          .eq('driver_id', driverId)
          .order('created_at', ascending: false);

      Log.d('Fetched ${response.length} trips for driver: $driverId');
      
      final trips = response.map((json) => Trip.fromJson(json)).toList();
      return Result.success(trips);
    } catch (error) {
      Log.e('Error fetching trips by driver: $error');
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

/// Provider for TripsRepository
final tripsRepositoryProvider = Provider<TripsRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return TripsRepository(supabase);
});
