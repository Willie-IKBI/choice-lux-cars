import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/jobs/models/trip_progress.dart';
import 'package:choice_lux_cars/features/jobs/data/trip_progress_repository.dart';
import 'package:choice_lux_cars/features/jobs/services/trip_progress_service.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

/// Notifier for managing trip progress state for a specific job
class TripProgressNotifier extends FamilyAsyncNotifier<List<TripProgress>, int> {
  TripProgressRepository get _repository => ref.read(tripProgressRepositoryProvider);

  @override
  Future<List<TripProgress>> build(int jobId) async {
    return _fetchTripsForJob(jobId);
  }

  /// Fetch trip progress rows for the job
  Future<List<TripProgress>> _fetchTripsForJob(int jobId) async {
    try {
      Log.d('Fetching trip progress for job: $jobId');
      final result = await _repository.getTripsForJob(jobId);
      
      if (result.isSuccess) {
        final trips = result.data!;
        Log.d('Fetched ${trips.length} trip progress rows for job $jobId');
        return trips;
      } else {
        Log.e('Error fetching trip progress: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error in _fetchTripsForJob: $error');
      rethrow;
    }
  }

  /// Refresh trip progress data
  Future<void> refresh() async {
    final jobId = arg;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchTripsForJob(jobId));
  }

  /// Advance trip to next status
  /// 
  /// Computes the next status using TripProgressService and updates via repository.
  /// Handles errors and provides user-friendly messages.
  Future<void> advanceTrip(int tripProgressId, String currentStatus) async {
    try {
      // Get next action
      final nextAction = TripProgressService.getNextAction(currentStatus);
      if (nextAction == null) {
        Log.d('No next action for status: $currentStatus');
        return;
      }

      Log.d('Advancing trip $tripProgressId from $currentStatus to ${nextAction.nextStatus}');

      // Update status
      final result = await _repository.updateTripStatus(
        tripProgressId,
        nextAction.nextStatus,
      );

      if (result.isSuccess) {
        Log.d('Trip progress updated successfully');
        // Refresh to get updated data (including auto-set timestamps)
        await refresh();
      } else {
        Log.e('Error updating trip progress: ${result.error!.message}');
        throw result.error!;
      }
    } catch (error) {
      Log.e('Error in advanceTrip: $error');
      rethrow;
    }
  }
}

/// Provider for trip progress list (read-only)
/// 
/// Usage: ref.watch(tripProgressListProvider(jobId))
final tripProgressListProvider = AsyncNotifierProvider.family<
    TripProgressNotifier,
    List<TripProgress>,
    int>(
  TripProgressNotifier.new,
);

/// Provider for trip progress controller (with actions)
/// 
/// Usage: ref.read(tripProgressControllerProvider(jobId).notifier).advanceTrip(...)
final tripProgressControllerProvider = tripProgressListProvider;

