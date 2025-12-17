import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/insights/data/insights_repository.dart';
import 'package:choice_lux_cars/features/insights/models/insights_data.dart';
import 'package:choice_lux_cars/core/services/supabase_service.dart';

/// Provider for client insights data
final clientInsightsProvider = FutureProvider.family<ClientInsights, (TimePeriod, LocationFilter, DateTime?, DateTime?)>((ref, params) async {
  final repository = ref.watch(insightsRepositoryProvider);
  final (period, location, customStartDate, customEndDate) = params;
  
  print('ClientInsightsProvider - Fetching client insights for period: ${period.displayName}, location: ${location.displayName}');
  
  try {
    final result = await repository.fetchClientInsights(
      period: period,
      location: location,
      customStartDate: customStartDate,
      customEndDate: customEndDate,
    );
    
    if (result.isSuccess) {
      print('ClientInsightsProvider - Successfully fetched client insights');
      return result.data!;
    } else {
      print('ClientInsightsProvider - Failed to fetch client insights: ${result.error}');
      throw Exception('Failed to fetch client insights: ${result.error}');
    }
  } catch (e) {
    print('ClientInsightsProvider - Exception fetching client insights: $e');
    rethrow;
  }
});
