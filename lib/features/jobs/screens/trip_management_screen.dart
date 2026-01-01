import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/jobs/models/trip.dart';
import 'package:choice_lux_cars/features/jobs/providers/trips_provider.dart';
import 'package:choice_lux_cars/features/jobs/widgets/add_trip_modal.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_drawer.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/core/services/permission_service.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';

class TripManagementScreen extends ConsumerStatefulWidget {
  final String jobId;

  const TripManagementScreen({super.key, required this.jobId});

  @override
  ConsumerState<TripManagementScreen> createState() =>
      _TripManagementScreenState();
}

class _TripManagementScreenState extends ConsumerState<TripManagementScreen> {

  // SnackBar helper methods
  void showErrorSnackBar(BuildContext context, String message) {
    final m = ScaffoldMessenger.maybeOf(context);
    m?.showSnackBar(SnackBar(content: Text(message)));
  }

  void showSuccessSnackBar(BuildContext context, String message) {
    final m = ScaffoldMessenger.maybeOf(context);
    m?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _saveTrip(Trip trip) async {
    try {
      if (trip.id == '') {
        // Create new trip
        await ref.read(tripsByJobProvider(widget.jobId).notifier).createTrip(trip);
      } else {
        // Update existing trip
        await ref.read(tripsByJobProvider(widget.jobId).notifier).updateTrip(trip);
      }
      ref.invalidate(tripsByJobProvider(widget.jobId));
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
      await ref.read(tripsByJobProvider(widget.jobId).notifier).deleteTrip(trip.id);
      ref.invalidate(tripsByJobProvider(widget.jobId));
      if (mounted) {
        showSuccessSnackBar(context, 'Trip deleted successfully');
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Failed to delete trip: $e');
      }
    }
  }

  void _showAddTripModal() {
    showDialog(
      context: context,
      builder: (context) => AddTripModal(
        jobId: widget.jobId,
        onTripAdded: (trip) async {
          // Refresh the trips list after successful trip creation
          ref.invalidate(tripsByJobProvider(widget.jobId));
          if (mounted) {
            showSuccessSnackBar(context, 'Trip added successfully!');
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripsState = ref.watch(tripsByJobProvider(widget.jobId));

    return Scaffold(
      appBar: const LuxuryAppBar(title: 'Trip Management'),
      drawer: const LuxuryDrawer(),
      body: SafeArea(
        child: tripsState.when(
          data: (trips) => _buildTripsContent(trips),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: $error'),
                ElevatedButton(
                  onPressed: () => ref.invalidate(tripsByJobProvider(widget.jobId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildTripsContent(List<Trip> trips) {
    final totalAmount = trips.fold(0.0, (sum, trip) => sum + trip.amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Added bottom padding for FAB
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
                  ChoiceLuxTheme.charcoalGray.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ChoiceLuxTheme.richGold.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.route, color: ChoiceLuxTheme.richGold, size: 28),
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
            ...trips.map((trip) => _buildTripCard(trip)),
            const SizedBox(height: 24),

            // Total amount
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ChoiceLuxTheme.richGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ChoiceLuxTheme.richGold.withValues(alpha: 0.3),
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
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ChoiceLuxTheme.richGold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Done button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/jobs/${widget.jobId}/summary'),
                icon: const Icon(Icons.check),
                label: const Text('Done - Back to Job Summary'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ChoiceLuxTheme.richGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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
                    'Trip ${trip.id}',
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
            Text('Pickup: ${trip.pickupLocation}'),
            Text('Dropoff: ${trip.dropoffLocation}'),
          ],
        ),
      ),
    );
  }

  Widget? _buildFAB() {
    final userProfile = ref.watch(currentUserProfileProvider);
    final userRole = userProfile?.role;
    final permissionService = const PermissionService();
    
    if (!permissionService.isAdmin(userRole) &&
        !permissionService.isManager(userRole) &&
        !permissionService.isDriverManager(userRole)) {
      return null;
    }

    return FloatingActionButton(
      onPressed: _showAddTripModal,
      backgroundColor: ChoiceLuxTheme.richGold,
      foregroundColor: Colors.black,
      tooltip: 'Add Trip',
      elevation: 6,
      child: const Icon(Icons.add),
    );
  }
}
