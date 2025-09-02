import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/jobs/models/trip.dart';
import 'package:choice_lux_cars/features/jobs/providers/trips_provider.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_drawer.dart';
import 'package:choice_lux_cars/shared/utils/snackbar_utils.dart';
import 'package:choice_lux_cars/app/theme.dart';

class TripManagementScreen extends ConsumerStatefulWidget {
  final String jobId;

  const TripManagementScreen({super.key, required this.jobId});

  @override
  ConsumerState<TripManagementScreen> createState() =>
      _TripManagementScreenState();
}

class _TripManagementScreenState extends ConsumerState<TripManagementScreen> {
  List<Trip> _transportDetails = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(tripsByJobProvider(widget.jobId).notifier).refresh();
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Failed to load trips: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveTrip(Trip trip) async {
    try {
      if (trip.id == null) {
        // Create new trip
        await ref.read(tripsProvider.notifier).addTrip(trip);
      } else {
        // Update existing trip
        await ref.read(tripsProvider.notifier).updateTrip(trip);
      }
      await _loadTrips();
      if (mounted) {
        showSuccessSnackBar(context, 'Trip saved successfully');
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Failed to save trip: $e');
      }
    }
  }

  Future<void> _deleteTrip(Trip trip) async {
    try {
      await ref.read(tripsProvider.notifier).deleteTrip(trip.id!);
      await _loadTrips();
      if (mounted) {
        showSuccessSnackBar(context, 'Trip deleted successfully');
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Failed to delete trip: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripsState = ref.watch(tripsByJobProvider(widget.jobId));

    return Scaffold(
      appBar: const LuxuryAppBar(title: 'Trip Management'),
      drawer: const LuxuryDrawer(),
      body: tripsState.when(
        data: (trips) => _buildTripsContent(trips),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              ElevatedButton(onPressed: _loadTrips, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripsContent(List<Trip> trips) {
    final totalAmount = trips.fold(0.0, (sum, trip) => sum + trip.amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ChoiceLuxTheme.charcoalGray,
                  ChoiceLuxTheme.charcoalGray.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.route, color: ChoiceLuxTheme.richGold, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Trip Management',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${trips.length} trips • Total: R${totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Trips list
          if (trips.isNotEmpty) ...[
            ...trips.map((trip) => _buildTripCard(trip)).toList(),
            const SizedBox(height: 24),

            // Total amount
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'R${totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ChoiceLuxTheme.richGold,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Empty state
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.route_outlined, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text(
                    'No trips added yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add trips to get started',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTripCard(Trip trip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Trip ${trip.id ?? 'New'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _saveTrip(trip),
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit',
                ),
                IconButton(
                  onPressed: () => _deleteTrip(trip),
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Amount: R${trip.amount.toStringAsFixed(2)}'),
            if (trip.pickupLocation != null)
              Text('Pickup: ${trip.pickupLocation}'),
            if (trip.dropoffLocation != null)
              Text('Dropoff: ${trip.dropoffLocation}'),
          ],
        ),
      ),
    );
  }
}
