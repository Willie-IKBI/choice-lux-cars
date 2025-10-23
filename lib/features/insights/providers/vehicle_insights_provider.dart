import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/insights/data/insights_repository.dart';
import 'package:choice_lux_cars/features/insights/models/insights_data.dart';
import 'package:choice_lux_cars/core/services/supabase_service.dart';

/// Provider for vehicle insights data
final vehicleInsightsProvider = FutureProvider.family<VehicleInsights, (TimePeriod, LocationFilter)>((ref, params) async {
  final repository = ref.watch(insightsRepositoryProvider);
  final (period, location) = params;
  
  print('VehicleInsightsProvider - Fetching vehicle insights for period: ${period.displayName}, location: ${location.displayName}');
  
  try {
    final result = await repository.fetchVehicleInsights(
      period: period,
      location: location,
    );
    
    if (result.isSuccess) {
      print('VehicleInsightsProvider - Successfully fetched vehicle insights');
      return result.data!;
    } else {
      print('VehicleInsightsProvider - Failed to fetch vehicle insights: ${result.error}');
      throw Exception('Failed to fetch vehicle insights: ${result.error}');
    }
  } catch (e) {
    print('VehicleInsightsProvider - Exception fetching vehicle insights: $e');
    rethrow;
  }
});
