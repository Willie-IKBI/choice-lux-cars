import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/jobs/models/trip_progress.dart';
import 'package:choice_lux_cars/features/jobs/providers/trip_progress_provider.dart';
import 'package:choice_lux_cars/features/jobs/services/trip_progress_service.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/utils/snackbar_utils.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/core/errors/app_exception.dart';
import 'package:intl/intl.dart';

/// Widget displaying trip progress for a job
/// 
/// Shows all trips with their status and allows driver to advance the active trip.
class TripProgressCard extends ConsumerWidget {
  final int jobId;
  final bool isMobile;

  const TripProgressCard({
    super.key,
    required this.jobId,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripProgressAsync = ref.watch(tripProgressListProvider(jobId));
    final controller = ref.read(tripProgressControllerProvider(jobId).notifier);

    return tripProgressAsync.when(
      data: (trips) {
        if (trips.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          decoration: BoxDecoration(
            gradient: ChoiceLuxTheme.cardGradient,
            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
            border: Border.all(
              color: ChoiceLuxTheme.richGold.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.route,
                    color: ChoiceLuxTheme.richGold,
                    size: isMobile ? 20 : 24,
                  ),
                  SizedBox(width: isMobile ? 8 : 12),
                  Text(
                    'Trip Progress',
                    style: TextStyle(
                      color: ChoiceLuxTheme.richGold,
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 6 : 8),
              Text(
                'Track and complete each trip in sequence',
                style: TextStyle(
                  color: ChoiceLuxTheme.platinumSilver,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
              SizedBox(height: isMobile ? 16 : 20),
              // Trip list
              ...trips.map((trip) => _buildTripRow(context, ref, trip, trips, controller)),
            ],
          ),
        );
      },
      loading: () => Container(
        width: double.infinity,
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        decoration: BoxDecoration(
          gradient: ChoiceLuxTheme.cardGradient,
          borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
          border: Border.all(
            color: ChoiceLuxTheme.richGold.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ChoiceLuxTheme.richGold),
          ),
        ),
      ),
      error: (error, stack) {
        Log.e('Error loading trip progress: $error');
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          decoration: BoxDecoration(
            gradient: ChoiceLuxTheme.cardGradient,
            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
            border: Border.all(
              color: ChoiceLuxTheme.richGold.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                color: ChoiceLuxTheme.errorColor,
                size: isMobile ? 24 : 32,
              ),
              SizedBox(height: isMobile ? 8 : 12),
              Text(
                'Failed to load trip progress',
                style: TextStyle(
                  color: ChoiceLuxTheme.softWhite,
                  fontSize: isMobile ? 14 : 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTripRow(
    BuildContext context,
    WidgetRef ref,
    TripProgress trip,
    List<TripProgress> allTrips,
    TripProgressNotifier controller,
  ) {
    final isActive = _isActiveTrip(trip, allTrips);
    final nextAction = TripProgressService.getNextAction(trip.status);
    final tripProgressState = ref.watch(tripProgressControllerProvider(jobId));
    final isLoading = tripProgressState.isLoading;

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                colors: [
                  ChoiceLuxTheme.richGold.withValues(alpha: 0.15),
                  ChoiceLuxTheme.richGold.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isActive ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
        border: Border.all(
          color: isActive
              ? ChoiceLuxTheme.richGold.withValues(alpha: 0.5)
              : ChoiceLuxTheme.richGold.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trip header
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 12,
                  vertical: isMobile ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: ChoiceLuxTheme.richGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Trip ${trip.tripIndex}',
                  style: TextStyle(
                    color: ChoiceLuxTheme.richGold,
                    fontSize: isMobile ? 12 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              _buildStatusChip(trip.status, isMobile),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 12),
          // Timestamps
          if (trip.pickupArrivedAt != null ||
              trip.passengerOnboardAt != null ||
              trip.dropoffArrivedAt != null ||
              trip.completedAt != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (trip.pickupArrivedAt != null)
                  _buildTimestampRow(
                    'Arrived at pickup',
                    trip.pickupArrivedAt!,
                    isMobile,
                  ),
                if (trip.passengerOnboardAt != null)
                  _buildTimestampRow(
                    'Passenger onboard',
                    trip.passengerOnboardAt!,
                    isMobile,
                  ),
                if (trip.dropoffArrivedAt != null)
                  _buildTimestampRow(
                    'Arrived at dropoff',
                    trip.dropoffArrivedAt!,
                    isMobile,
                  ),
                if (trip.completedAt != null)
                  _buildTimestampRow(
                    'Completed',
                    trip.completedAt!,
                    isMobile,
                  ),
                SizedBox(height: isMobile ? 8 : 12),
              ],
            ),
          // Action button (only for active trip)
          if (isActive && nextAction != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading
                    ? null
                    : () => _handleAdvanceTrip(
                          context,
                          ref,
                          trip,
                          nextAction,
                          controller,
                        ),
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : const Icon(Icons.arrow_forward),
                label: Text(nextAction.label),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ChoiceLuxTheme.richGold,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 24,
                    vertical: isMobile ? 12 : 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, bool isMobile) {
    Color chipColor;
    String label;

    switch (status) {
      case 'pending':
        chipColor = ChoiceLuxTheme.platinumSilver;
        label = 'Pending';
        break;
      case 'pickup_arrived':
        chipColor = Colors.blue;
        label = 'At Pickup';
        break;
      case 'passenger_onboard':
        chipColor = Colors.orange;
        label = 'Onboard';
        break;
      case 'dropoff_arrived':
        chipColor = Colors.purple;
        label = 'At Dropoff';
        break;
      case 'completed':
        chipColor = Colors.green;
        label = 'Completed';
        break;
      default:
        chipColor = ChoiceLuxTheme.platinumSilver;
        label = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 12,
        vertical: isMobile ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: chipColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: chipColor,
          fontSize: isMobile ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTimestampRow(String label, DateTime timestamp, bool isMobile) {
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('MMM dd');

    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 4 : 6),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            size: isMobile ? 14 : 16,
            color: ChoiceLuxTheme.platinumSilver,
          ),
          SizedBox(width: isMobile ? 6 : 8),
          Text(
            '$label: ${dateFormat.format(timestamp)} ${timeFormat.format(timestamp)}',
            style: TextStyle(
              color: ChoiceLuxTheme.platinumSilver,
              fontSize: isMobile ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Determine if this trip is the active one (first non-completed trip)
  bool _isActiveTrip(TripProgress trip, List<TripProgress> allTrips) {
    // Find first non-completed trip
    final activeTrip = allTrips.firstWhere(
      (t) => !t.isCompleted,
      orElse: () => allTrips.last, // If all completed, highlight last one
    );
    return trip.id == activeTrip.id;
  }

  Future<void> _handleAdvanceTrip(
    BuildContext context,
    WidgetRef ref,
    TripProgress trip,
    TripProgressAction nextAction,
    TripProgressNotifier controller,
  ) async {
    try {
      await controller.advanceTrip(trip.id, trip.status);

      if (context.mounted) {
        SnackBarUtils.showSuccess(
          context,
          'Updated to ${nextAction.label.toLowerCase()}',
        );
      }
    } catch (error) {
      Log.e('Error advancing trip: $error');
      if (context.mounted) {
        String errorMessage;
        if (error is Exception) {
          // Try to extract user-friendly message
          errorMessage = TripProgressService.mapErrorToMessage(
            error is AppException
                ? error
                : UnknownException(error.toString()),
          );
        } else {
          errorMessage = 'An error occurred. Please try again.';
        }

        SnackBarUtils.showError(context, errorMessage);
      }
  }
}
}

