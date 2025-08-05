import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle.dart';
import '../../../core/services/supabase_service.dart';

class VehiclesState {
  final List<Vehicle> vehicles;
  final bool isLoading;
  final String? error;

  VehiclesState({
    this.vehicles = const [],
    this.isLoading = false,
    this.error,
  });

  VehiclesState copyWith({
    List<Vehicle>? vehicles,
    bool? isLoading,
    String? error,
  }) {
    return VehiclesState(
      vehicles: vehicles ?? this.vehicles,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class VehiclesNotifier extends StateNotifier<VehiclesState> {
  VehiclesNotifier() : super(VehiclesState()) {
    fetchVehicles(); // Auto-fetch vehicles on initialization
  }

  Future<void> fetchVehicles() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final vehicles = await SupabaseService.getVehicles();
      state = state.copyWith(vehicles: vehicles, isLoading: false);
    } catch (e) {

      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final newVehicle = await SupabaseService.createVehicle(vehicle);
      final updatedVehicles = <Vehicle>[...state.vehicles, newVehicle];
      state = state.copyWith(vehicles: updatedVehicles, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedVehicle = await SupabaseService.updateVehicle(vehicle);
      final updatedVehicles = state.vehicles.map((v) => v.id == vehicle.id ? updatedVehicle : v).toList();
      state = state.copyWith(vehicles: updatedVehicles, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }
}

final vehiclesProvider = StateNotifierProvider<VehiclesNotifier, VehiclesState>((ref) => VehiclesNotifier()); 