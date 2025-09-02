import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:choice_lux_cars/core/supabase/supabase_client_provider.dart';
import 'package:choice_lux_cars/features/vehicles/models/vehicle.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/core/types/result.dart';
import 'package:choice_lux_cars/core/errors/app_exception.dart';

/// Repository for vehicle-related data operations
///
/// Encapsulates all Supabase queries and returns domain models.
/// This layer separates data access from business logic.
class VehiclesRepository {
  final SupabaseClient _supabase;

  VehiclesRepository(this._supabase);

  /// Fetch all vehicles from the database
  Future<Result<List<Vehicle>>> fetchVehicles() async {
    try {
      Log.d('Fetching vehicles from database');

      final response = await _supabase
          .from('vehicles')
          .select()
          .order('make', ascending: true);

      Log.d('Fetched ${response.length} vehicles from database');

      final vehicles = response.map((json) => Vehicle.fromJson(json)).toList();
      return Result.success(vehicles);
    } catch (error) {
      Log.e('Error fetching vehicles: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Create a new vehicle
  Future<Result<Map<String, dynamic>>> createVehicle(Vehicle vehicle) async {
    try {
      Log.d('Creating vehicle: ${vehicle.make} ${vehicle.model}');

      final vehicleData = vehicle.toJson();
      // Ensure any nullable fields are properly handled
      if (vehicleData['status'] == null) {
        vehicleData['status'] = 'available';
      }
      // Handle any other nullable fields that might cause type issues
      vehicleData.removeWhere((key, value) => value == null);

      final response = await _supabase
          .from('vehicles')
          .insert(vehicleData)
          .select()
          .single();

      Log.d('Vehicle created successfully with ID: ${response['id']}');
      return Result.success(response);
    } catch (error) {
      Log.e('Error creating vehicle: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Update an existing vehicle
  Future<Result<void>> updateVehicle(Vehicle vehicle) async {
    try {
      Log.d('Updating vehicle: ${vehicle.id}');

      if (vehicle.id == null) {
        return const Result.failure(
          UnknownException('Vehicle ID is required for update'),
        );
      }

      await _supabase
          .from('vehicles')
          .update(vehicle.toJson())
          .eq('id', vehicle.id!);

      Log.d('Vehicle updated successfully');
      return const Result.success(null);
    } catch (error) {
      Log.e('Error updating vehicle: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Delete a vehicle
  Future<Result<void>> deleteVehicle(String vehicleId) async {
    try {
      Log.d('Deleting vehicle: $vehicleId');

      await _supabase.from('vehicles').delete().eq('id', vehicleId);

      Log.d('Vehicle deleted successfully');
      return const Result.success(null);
    } catch (error) {
      Log.e('Error deleting vehicle: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Get vehicle by ID
  Future<Result<Vehicle?>> getVehicleById(String vehicleId) async {
    try {
      Log.d('Fetching vehicle by ID: $vehicleId');

      final response = await _supabase
          .from('vehicles')
          .select()
          .eq('id', vehicleId)
          .maybeSingle();

      if (response != null) {
        Log.d('Vehicle found: ${response['make']} ${response['model']}');
        return Result.success(Vehicle.fromJson(response));
      } else {
        Log.d('Vehicle not found: $vehicleId');
        return const Result.success(null);
      }
    } catch (error) {
      Log.e('Error fetching vehicle by ID: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Get vehicles by make
  Future<Result<List<Vehicle>>> getVehiclesByMake(String make) async {
    try {
      Log.d('Fetching vehicles by make: $make');

      final response = await _supabase
          .from('vehicles')
          .select()
          .eq('make', make)
          .order('model', ascending: true);

      Log.d('Fetched ${response.length} vehicles with make: $make');

      final vehicles = response.map((json) => Vehicle.fromJson(json)).toList();
      return Result.success(vehicles);
    } catch (error) {
      Log.e('Error fetching vehicles by make: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Get available vehicles (not assigned to active jobs)
  Future<Result<List<Vehicle>>> getAvailableVehicles() async {
    try {
      Log.d('Fetching available vehicles');

      final response = await _supabase
          .from('vehicles')
          .select()
          .eq('is_active', true)
          .order('make', ascending: true);

      Log.d('Fetched ${response.length} available vehicles');

      final vehicles = response.map((json) => Vehicle.fromJson(json)).toList();
      return Result.success(vehicles);
    } catch (error) {
      Log.e('Error fetching available vehicles: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Search vehicles by make, model, or registration plate
  Future<Result<List<Vehicle>>> searchVehicles(String query) async {
    try {
      Log.d('Searching vehicles with query: $query');

      final response = await _supabase
          .from('vehicles')
          .select()
          .or(
            'make.ilike.%$query%,model.ilike.%$query%,reg_plate.ilike.%$query%',
          )
          .order('make', ascending: true);

      Log.d('Found ${response.length} vehicles matching query: $query');

      final vehicles = response.map((json) => Vehicle.fromJson(json)).toList();
      return Result.success(vehicles);
    } catch (error) {
      Log.e('Error searching vehicles: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Update vehicle status
  Future<Result<void>> updateVehicleStatus(
    String vehicleId,
    String status,
  ) async {
    try {
      Log.d('Updating vehicle status: $vehicleId to $status');

      await _supabase
          .from('vehicles')
          .update({'status': status})
          .eq('id', vehicleId);

      Log.d('Vehicle status updated successfully');
      return const Result.success(null);
    } catch (error) {
      Log.e('Error updating vehicle status: $error');
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

/// Provider for VehiclesRepository
final vehiclesRepositoryProvider = Provider<VehiclesRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return VehiclesRepository(supabase);
});
