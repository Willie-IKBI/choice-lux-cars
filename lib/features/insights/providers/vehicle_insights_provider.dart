import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/insights/data/insights_repository.dart';
import 'package:choice_lux_cars/features/insights/models/insights_data.dart';
/// Provider for vehicle insights data
final vehicleInsightsProvider = FutureProvider.family<VehicleInsights, (TimePeriod, LocationFilter, DateTime?, DateTime?)>((ref, params) async {
  final repository = ref.watch(insightsRepositoryProvider);
  final (period, location, customStart, customEnd) = params;
  
  try {
    final result = await repository.fetchVehicleInsights(
      period: period,
      location: location,
      customStartDate: customStart,
      customEndDate: customEnd,
    );
    
    if (result.isSuccess) {
      return result.data!;
    } else {
      throw Exception('Failed to fetch vehicle insights: ${result.error}');
    }
  } catch (e) {
    rethrow;
  }
});
