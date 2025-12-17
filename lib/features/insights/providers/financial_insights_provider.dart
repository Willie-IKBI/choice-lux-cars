import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/insights/data/insights_repository.dart';
import 'package:choice_lux_cars/features/insights/models/insights_data.dart';
import 'package:choice_lux_cars/core/services/supabase_service.dart';

/// Provider for financial insights data
final financialInsightsProvider = FutureProvider.family<FinancialInsights, (TimePeriod, LocationFilter, DateTime?, DateTime?)>((ref, params) async {
  final repository = ref.watch(insightsRepositoryProvider);
  final (period, location, customStartDate, customEndDate) = params;
  
  print('FinancialInsightsProvider - Fetching financial insights for period: ${period.displayName}, location: ${location.displayName}');
  
  try {
    final result = await repository.fetchFinancialInsights(
      period: period,
      location: location,
      customStartDate: customStartDate,
      customEndDate: customEndDate,
    );
    
    if (result.isSuccess) {
      print('FinancialInsightsProvider - Successfully fetched financial insights');
      return result.data!;
    } else {
      print('FinancialInsightsProvider - Failed to fetch financial insights: ${result.error}');
      throw Exception('Failed to fetch financial insights: ${result.error}');
    }
  } catch (e) {
    print('FinancialInsightsProvider - Exception fetching financial insights: $e');
    rethrow;
  }
});
