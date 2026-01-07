import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/jobs/models/trip.dart';
import 'package:choice_lux_cars/features/jobs/providers/trips_provider.dart';
import 'package:choice_lux_cars/features/jobs/widgets/add_trip_modal.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_drawer.dart';
import 'package:choice_lux_cars/shared/widgets/system_safe_scaffold.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:go_router/go_router.dart';
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
      if (trip.id == null || trip.id == '') {
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
      await ref.read(tripsByJobProvider(widget.jobId).notifier).deleteTrip(trip.id!);
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

    return SystemSafeScaffold(
      backgroundColor: Colors.transparent,
      appBar: const LuxuryAppBar(title: 'Trip Management'),
      drawer: const LuxuryDrawer(),
      body: tripsState.when(
        data: (trips) => _buildTripsContent(context, trips),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTripModal,
        backgroundColor: ChoiceLuxTheme.richGold,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
        tooltip: 'Add Trip',
        elevation: 6,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildTripsContent(BuildContext context, List<Trip> trips) {
    final totalAmount = trips.fold(0.0, (sum, trip) => sum + trip.amount);
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = ResponsiveTokens.getPadding(screenWidth);
    final spacing = ResponsiveTokens.getSpacing(screenWidth);
    
    // Check if user is driver
    final userProfile = ref.watch(currentUserProfileProvider);
    final isDriver = userProfile?.role?.toLowerCase() == 'driver';

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(padding, padding, padding, 100), // Added bottom padding for FAB
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(padding * 1.5), // Slightly larger for header
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
                        // Hide total amount for drivers
                        isDriver 
                            ? '${trips.length} trips'
                            : '${trips.length} trips • Total: R${totalAmount.toStringAsFixed(2)}',
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
            SizedBox(height: spacing * 3),

            // Total amount (hidden for drivers)
            if (!isDriver)
              Container(
                padding: EdgeInsets.all(padding * 1.25),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = ResponsiveTokens.getPadding(screenWidth);
    final spacing = ResponsiveTokens.getSpacing(screenWidth);
    
    return Card(
      margin: EdgeInsets.only(bottom: spacing * 2),
      child: Padding(
        padding: EdgeInsets.all(padding),
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
            // Hide amount for drivers
            if (userProfile?.role?.toLowerCase() != 'driver')
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
