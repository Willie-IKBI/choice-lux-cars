import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/insights/data/insights_repository.dart';
import 'package:choice_lux_cars/features/insights/models/insights_data.dart';
import 'package:choice_lux_cars/core/services/supabase_service.dart';

/// Provider for jobs insights data
final jobsInsightsProvider = FutureProvider.family<JobInsights, (TimePeriod, LocationFilter, DateTime?, DateTime?)>((ref, params) async {
  final repository = ref.watch(insightsRepositoryProvider);
  final (period, location, customStartDate, customEndDate) = params;
  
  print('JobsInsightsProvider - Fetching jobs insights for period: ${period.displayName}, location: ${location.displayName}');
  
  try {
    final result = await repository.fetchJobsInsights(
      period: period,
      location: location,
      customStartDate: customStartDate,
      customEndDate: customEndDate,
    );
    
    if (result.isSuccess) {
      print('JobsInsightsProvider - Successfully fetched jobs insights');
      return result.data!;
    } else {
      print('JobsInsightsProvider - Failed to fetch jobs insights: ${result.error}');
      throw Exception('Failed to fetch jobs insights: ${result.error}');
    }
  } catch (e) {
    print('JobsInsightsProvider - Exception fetching jobs insights: $e');
    rethrow;
  }
});
