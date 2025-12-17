import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/insights/data/insights_repository.dart';
import 'package:choice_lux_cars/features/insights/models/insights_data.dart';
import 'package:choice_lux_cars/core/services/supabase_service.dart';

/// Provider for driver insights data
final driverInsightsProvider = FutureProvider.family<DriverInsights, (TimePeriod, LocationFilter, DateTime?, DateTime?)>((ref, params) async {
  final repository = ref.watch(insightsRepositoryProvider);
  final (period, location, customStartDate, customEndDate) = params;
  
  print('DriverInsightsProvider - Fetching driver insights for period: ${period.displayName}, location: ${location.displayName}');
  
  try {
    final result = await repository.fetchDriverInsights(
      period: period,
      location: location,
      customStartDate: customStartDate,
      customEndDate: customEndDate,
    );
    
    if (result.isSuccess) {
      print('DriverInsightsProvider - Successfully fetched driver insights');
      return result.data!;
    } else {
      print('DriverInsightsProvider - Failed to fetch driver insights: ${result.error}');
      throw Exception('Failed to fetch driver insights: ${result.error}');
    }
  } catch (e) {
    print('DriverInsightsProvider - Exception fetching driver insights: $e');
    rethrow;
  }
});
