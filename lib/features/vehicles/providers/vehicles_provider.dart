import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/vehicles/models/vehicle.dart';
import 'package:choice_lux_cars/features/vehicles/data/vehicles_repository.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';

/// Notifier for managing vehicles state using AsyncNotifier
class VehiclesNotifier extends AsyncNotifier<List<Vehicle>> {
  /// Get the vehicles repository
  VehiclesRepository get _vehiclesRepository => ref.read(vehiclesRepositoryProvider);

  @override
  Future<List<Vehicle>> build() async {
    // Watch current user to get branchId for filtering
    final currentUser = ref.watch(currentUserProfileProvider);
    final branchId = currentUser?.branchId;
    
    return _fetchVehicles(branchId: branchId);
  }

  /// Fetch all vehicles from the repository
  /// 
  /// [branchId] - Optional branch ID to filter vehicles. If null (admin), returns all vehicles.
  Future<List<Vehicle>> _fetchVehicles({int? branchId}) async {
    try {
      if (branchId != null) {
        Log.d('Fetching vehicles for branch: $branchId');
      } else {
        Log.d('Fetching all vehicles (admin access)');
      }

      final result = await _vehiclesRepository.fetchVehicles(branchId: branchId);

      if (result.isSuccess) {
        final vehicles = result.data!;
        Log.d('Fetched ${vehicles.length} vehicles successfully');
        return vehicles;
      } else {
        Log.e('Error fetching vehicles: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error fetching vehicles: $error');
      rethrow;
    }
  }

  /// Create a new vehicle using the repository
  Future<Map<String, dynamic>> createVehicle(Vehicle vehicle) async {
    try {
      Log.d('Creating vehicle: ${vehicle.make} ${vehicle.model}');

      final result = await _vehiclesRepository.createVehicle(vehicle);

      if (result.isSuccess) {
        // Refresh vehicles list
        ref.invalidateSelf();
        Log.d('Vehicle created successfully');
        return result.data!;
      } else {
        Log.e('Error creating vehicle: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error creating vehicle: $error');
      rethrow;
    }
  }

  /// Update an existing vehicle using the repository
  Future<void> updateVehicle(Vehicle vehicle) async {
    try {
      Log.d('Updating vehicle: ${vehicle.id}');

      final result = await _vehiclesRepository.updateVehicle(vehicle);

      if (result.isSuccess) {
        // Update local state optimistically
        final currentVehicles = state.value ?? [];
        final updatedVehicles = currentVehicles
            .map((v) => v.id == vehicle.id ? vehicle : v)
            .toList();
        state = AsyncValue.data(updatedVehicles);
        Log.d('Vehicle updated successfully');
      } else {
        Log.e('Error updating vehicle: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error updating vehicle: $error');
      rethrow;
    }
  }

  /// Delete a vehicle using the repository
  Future<void> deleteVehicle(String vehicleId) async {
    try {
      Log.d('Deleting vehicle: $vehicleId');

      final result = await _vehiclesRepository.deleteVehicle(vehicleId);

      if (result.isSuccess) {
        // Update local state optimistically
        final currentVehicles = state.value ?? [];
        final updatedVehicles = currentVehicles
            .where((vehicle) => vehicle.id?.toString() != vehicleId)
            .toList();
        state = AsyncValue.data(updatedVehicles);
        Log.d('Vehicle deleted successfully');
      } else {
        Log.e('Error deleting vehicle: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error deleting vehicle: $error');
      rethrow;
    }
  }

  /// Get vehicle by ID using the repository
  Future<Vehicle?> getVehicleById(String vehicleId) async {
    try {
      Log.d('Getting vehicle by ID: $vehicleId');

      final result = await _vehiclesRepository.getVehicleById(vehicleId);

      if (result.isSuccess) {
        return result.data;
      } else {
        Log.e('Error getting vehicle by ID: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error getting vehicle by ID: $error');
      rethrow;
    }
  }

  /// Get available vehicles using the repository
  Future<List<Vehicle>> getAvailableVehicles() async {
    try {
      Log.d('Getting available vehicles');

      final result = await _vehiclesRepository.getAvailableVehicles();

      if (result.isSuccess) {
        return result.data!;
      } else {
        Log.e('Error getting available vehicles: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error getting available vehicles: $error');
      rethrow;
    }
  }

  /// Add a new vehicle (alias for createVehicle for consistency)
  Future<Map<String, dynamic>> addVehicle(Vehicle vehicle) async {
    return createVehicle(vehicle);
  }

  /// Refresh vehicles data
  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  /// Fetch vehicles manually (for UI refresh)
  Future<void> fetchVehicles() async {
    ref.invalidateSelf();
  }
}

/// Provider for VehiclesNotifier using AsyncNotifierProvider
final vehiclesProvider = AsyncNotifierProvider<VehiclesNotifier, List<Vehicle>>(
  () => VehiclesNotifier(),
);
