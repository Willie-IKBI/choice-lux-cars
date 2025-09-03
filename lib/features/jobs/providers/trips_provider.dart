import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/jobs/models/trip.dart';
import 'package:choice_lux_cars/features/jobs/data/trips_repository.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

/// Notifier for managing global trips state using AsyncNotifier
/// Handles operations that affect all trips or create/update/delete operations
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
      Log.d('Fetching all trips...');

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

  /// Create a new trip using the repository
  Future<Map<String, dynamic>> createTrip(Trip trip) async {
    try {
      Log.d('Creating trip for job: ${trip.jobId}');

      final result = await _tripsRepository.createTrip(trip);

      if (result.isSuccess) {
        // Refresh global trips list
        await refresh();
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
        final updatedTrips = currentTrips
            .map((t) => t.id == trip.id ? trip : t)
            .toList();
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
  Future<void> deleteTrip(String tripId, {String? jobId}) async {
    try {
      Log.d('Deleting trip: $tripId');

      final result = await _tripsRepository.deleteTrip(tripId: tripId, jobId: jobId);

      if (result.isSuccess) {
        // Refresh global trips list
        await refresh();
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
      Log.d('Getting trips for driver: $driverId');

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
  double get totalAmount =>
      (state.value ?? []).fold(0, (sum, trip) => sum + trip.amount);

  /// Refresh trips data
  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  /// Add a new trip (alias for createTrip)
  Future<Map<String, dynamic>> addTrip(Trip trip) async {
    return createTrip(trip);
  }
}

/// Notifier for managing trips by job using FamilyAsyncNotifier
/// Handles job-specific trip operations like fetching trips for a specific job
class TripsByJobNotifier extends FamilyAsyncNotifier<List<Trip>, String> {
  late final TripsRepository _tripsRepository;
  late final String jobId;

  @override
  Future<List<Trip>> build(String jobId) async {
    _tripsRepository = ref.watch(tripsRepositoryProvider);
    this.jobId = jobId;
    return _fetchTripsForJob();
  }

  /// Fetch trips for a specific job from the repository
  Future<List<Trip>> _fetchTripsForJob() async {
    try {
      Log.d('=== TRIPS BY JOB PROVIDER: _fetchTripsForJob() called ===');
      Log.d('Job ID: $jobId');
      Log.d('Job ID type: ${jobId.runtimeType}');

      final result = await _tripsRepository.fetchTripsForJob(jobId);
      Log.d('Repository result: ${result.toString()}');
      Log.d('Repository isSuccess: ${result.isSuccess}');

      if (result.isSuccess) {
        final trips = result.data!;
        Log.d('Fetched ${trips.length} trips for job: $jobId');
        if (trips.isNotEmpty) {
          Log.d('First trip details: ID: ${trips.first.id}, JobID: ${trips.first.jobId}');
        }
        return trips;
      } else {
        Log.e('Error fetching trips for job: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error fetching trips for job: $error');
      rethrow;
    }
  }

  /// Refresh trips by job data
  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  /// Create a new trip for this specific job
  Future<Map<String, dynamic>> createTrip(Trip trip) async {
    try {
      Log.d('Creating trip for job: ${trip.jobId}');

      final result = await _tripsRepository.createTrip(trip);

      if (result.isSuccess) {
        // Refresh this job's trips
        await refresh();
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

  /// Update an existing trip for this specific job
  Future<void> updateTrip(Trip trip) async {
    try {
      Log.d('Updating trip: ${trip.id}');

      final result = await _tripsRepository.updateTrip(trip);

      if (result.isSuccess) {
        // Refresh this job's trips
        await refresh();
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

  /// Delete a trip from this specific job
  Future<void> deleteTrip(String tripId) async {
    try {
      Log.d('Deleting trip: $tripId');

      final result = await _tripsRepository.deleteTrip(tripId: tripId, jobId: jobId);

      if (result.isSuccess) {
        // Refresh this job's trips
        await refresh();
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
}

/// Provider for TripsNotifier using AsyncNotifierProvider
/// Use this for global trip operations (create, update, delete, get all trips)
final tripsProvider = AsyncNotifierProvider<TripsNotifier, List<Trip>>(TripsNotifier.new);

/// Async provider for trips by job that exposes AsyncValue<List<Trip>>
/// Use this for job-specific trip operations (fetch trips for job, create/update/delete for specific job)
final tripsByJobProvider =
    AsyncNotifierProvider.family<TripsByJobNotifier, List<Trip>, String>(
      TripsByJobNotifier.new,
    );
