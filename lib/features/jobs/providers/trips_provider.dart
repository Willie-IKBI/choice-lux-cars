import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/jobs/models/trip.dart';
import 'package:choice_lux_cars/features/jobs/data/trips_repository.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

/// Notifier for managing trips state using AsyncNotifier
class TripsNotifier extends AsyncNotifier<List<Trip>> {
  late final TripsRepository _tripsRepository;

  @override
  Future<List<Trip>> build() async {
    _tripsRepository = ref.watch(tripsRepositoryProvider);
    return _fetchTrips();
  }

  /// Fetch all trips from the repository
  Future<List<Trip>> _fetchTrips() async {
    try {
      Log.d('Fetching trips...');
      
      final result = await _tripsRepository.fetchTrips();
      
      if (result.isSuccess) {
        final trips = result.data!;
        Log.d('Fetched ${trips.length} trips successfully');
        return trips;
      } else {
        Log.e('Error fetching trips: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error fetching trips: $error');
      rethrow;
    }
  }

  /// Fetch trips for a specific job using the repository
  Future<void> fetchTripsForJob(String jobId) async {
    try {
      Log.d('Fetching trips for job: $jobId');
      
      final result = await _tripsRepository.fetchTripsForJob(jobId);
      
      if (result.isSuccess) {
        final trips = result.data!;
        state = AsyncValue.data(trips);
        Log.d('Fetched ${trips.length} trips for job: $jobId');
      } else {
        Log.e('Error fetching trips for job: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error fetching trips for job: $error');
      rethrow;
    }
  }

  /// Create a new trip using the repository
  Future<Map<String, dynamic>> createTrip(Trip trip) async {
    try {
      Log.d('Creating trip for job: ${trip.jobId}');
      
      final result = await _tripsRepository.createTrip(trip);
      
      if (result.isSuccess) {
        // Refresh trips list
        await fetchTripsForJob(trip.jobId);
        Log.d('Trip created successfully');
        return result.data!;
      } else {
        Log.e('Error creating trip: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error creating trip: $error');
      rethrow;
    }
  }

  /// Update an existing trip using the repository
  Future<void> updateTrip(Trip trip) async {
    try {
      Log.d('Updating trip: ${trip.id}');
      
      final result = await _tripsRepository.updateTrip(trip);
      
      if (result.isSuccess) {
        // Update local state optimistically
        final currentTrips = state.value ?? [];
        final updatedTrips = currentTrips.map((t) => t.id == trip.id ? trip : t).toList();
        state = AsyncValue.data(updatedTrips);
        Log.d('Trip updated successfully');
      } else {
        Log.e('Error updating trip: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error updating trip: $error');
      rethrow;
    }
  }

  /// Update trip status using the repository
  Future<void> updateTripStatus(String tripId, String status) async {
    try {
      Log.d('Updating trip status: $tripId to $status');
      
      final result = await _tripsRepository.updateTripStatus(tripId, status);
      
      if (result.isSuccess) {
        // Update local state optimistically
        final currentTrips = state.value ?? [];
        final updatedTrips = currentTrips.map((trip) {
          if (trip.id == tripId) {
            return trip.copyWith(status: status);
          }
          return trip;
        }).toList();
        
        state = AsyncValue.data(updatedTrips);
        Log.d('Trip status updated successfully');
      } else {
        Log.e('Error updating trip status: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error updating trip status: $error');
      rethrow;
    }
  }

  /// Delete a trip using the repository
  Future<void> deleteTrip(String tripId, String jobId) async {
    try {
      Log.d('Deleting trip: $tripId');
      
      final result = await _tripsRepository.deleteTrip(tripId);
      
      if (result.isSuccess) {
        // Refresh trips for the job
        await fetchTripsForJob(jobId);
        Log.d('Trip deleted successfully');
      } else {
        Log.e('Error deleting trip: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error deleting trip: $error');
      rethrow;
    }
  }

  /// Get trips by status using the repository
  Future<List<Trip>> getTripsByStatus(String status) async {
    try {
      Log.d('Getting trips by status: $status');
      
      final result = await _tripsRepository.getTripsByStatus(status);
      
      if (result.isSuccess) {
        return result.data!;
      } else {
        Log.e('Error getting trips by status: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error getting trips by status: $error');
      rethrow;
    }
  }

  /// Get trips by driver using the repository
  Future<List<Trip>> getTripsByDriver(String driverId) async {
    try {
      Log.d('Getting trips by driver: $driverId');
      
      final result = await _tripsRepository.getTripsByDriver(driverId);
      
      if (result.isSuccess) {
        return result.data!;
      } else {
        Log.e('Error getting trips by driver: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error getting trips by driver: $error');
      rethrow;
    }
  }

  /// Clear trips (for new job creation)
  void clearTrips() {
    state = const AsyncValue.data([]);
  }

  /// Get total amount for all trips
  double get totalAmount => (state.value ?? []).fold(0, (sum, trip) => sum + trip.amount);

  /// Refresh trips data
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Provider for TripsNotifier using AsyncNotifierProvider
final tripsProvider = AsyncNotifierProvider<TripsNotifier, List<Trip>>(() => TripsNotifier());

/// Async provider for trips by job that exposes AsyncValue<List<Trip>>
final tripsByJobProvider = AsyncNotifierProvider.family<TripsNotifier, List<Trip>, String>((jobId) => TripsNotifier());
