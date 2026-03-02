import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/insights/data/insights_repository.dart';
import 'package:choice_lux_cars/features/insights/models/insights_data.dart';
/// Provider for financial insights data
final financialInsightsProvider = FutureProvider.family<FinancialInsights, (TimePeriod, LocationFilter, DateTime?, DateTime?)>((ref, params) async {
  final repository = ref.watch(insightsRepositoryProvider);
  final (period, location, customStart, customEnd) = params;
  
  try {
    final result = await repository.fetchFinancialInsights(
      period: period,
      location: location,
      customStartDate: customStart,
      customEndDate: customEnd,
    );
    
    if (result.isSuccess) {
      return result.data!;
    } else {
      throw Exception('Failed to fetch financial insights: ${result.error}');
    }
  } catch (e) {
    rethrow;
  }
});
