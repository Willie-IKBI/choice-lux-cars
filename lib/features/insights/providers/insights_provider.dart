import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/insights/data/insights_repository.dart';
import 'package:choice_lux_cars/features/insights/models/insights_data.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

/// State for insights with filters
class InsightsWithFiltersState {
  final InsightsData? data;
  final bool isLoading;
  final String? error;

  InsightsWithFiltersState({
    this.data,
    this.isLoading = false,
    this.error,
  });

  InsightsWithFiltersState copyWith({
    InsightsData? data,
    bool? isLoading,
    String? error,
  }) {
    return InsightsWithFiltersState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Notifier for insights with filters
class InsightsWithFiltersNotifier extends StateNotifier<InsightsWithFiltersState> {
  final InsightsRepository _repository;

  InsightsWithFiltersNotifier(this._repository) : super(InsightsWithFiltersState());

  Future<void> fetchInsights({
    required TimePeriod period,
    required LocationFilter location,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      print('Fetching insights data with filters - Period: ${period.displayName}, Location: ${location.displayName}');
      final result = await _repository.fetchInsightsWithFilters(
        period: period,
        location: location,
        customStartDate: customStartDate,
        customEndDate: customEndDate,
      );
      
      if (result.isSuccess) {
        print('Insights data fetched successfully with filters');
        print('Provider returning insights data: ${result.data!.jobInsights.totalJobs} jobs, ${result.data!.quoteInsights.totalQuotes} quotes');
        
        if (result.data == null) {
          print('Insights data is null after successful fetch with filters');
          state = state.copyWith(isLoading: false, error: 'Insights data is null');
          return;
        }
        
        print('Provider successfully returning insights data');
        state = state.copyWith(data: result.data!, isLoading: false, error: null);
      } else {
        print('Failed to fetch insights with filters: ${result.error}');
        state = state.copyWith(isLoading: false, error: 'Failed to fetch insights: ${result.error}');
      }
    } catch (e, stackTrace) {
      print('Exception in insights provider with filters: $e');
      print('Stack trace: $stackTrace');
      state = state.copyWith(isLoading: false, error: 'Exception: $e');
    }
  }
}

/// Provider for insights data
final insightsProvider = FutureProvider<InsightsData>((ref) async {
  final repository = ref.watch(insightsRepositoryProvider);
  
  Log.d('Fetching insights data');
  final result = await repository.fetchInsights();
  
  if (result.isSuccess) {
    Log.d('Insights data fetched successfully');
    return result.data!;
  } else {
    Log.e('Failed to fetch insights: ${result.error}');
    throw Exception('Failed to fetch insights: ${result.error}');
  }
});

/// Provider for insights with time period filtering
final insightsWithPeriodProvider = FutureProvider.family<InsightsData, TimePeriod>((ref, period) async {
  try {
    final repository = ref.watch(insightsRepositoryProvider);
    
    print('Fetching insights data for period: ${period.displayName}');
    final result = await repository.fetchInsights(period: period);
    
    if (result.isSuccess) {
      print('Insights data fetched successfully for period: ${period.displayName}');
      print('Provider returning insights data: ${result.data!.jobInsights.totalJobs} jobs, ${result.data!.quoteInsights.totalQuotes} quotes');
      
      // Validate data before returning
      if (result.data == null) {
        Log.e('Insights data is null after successful fetch');
        throw Exception('Insights data is null');
      }
      
      return result.data!;
    } else {
      print('Failed to fetch insights for period ${period.displayName}: ${result.error}');
      throw Exception('Failed to fetch insights: ${result.error}');
    }
  } catch (e, stackTrace) {
    print('Exception in insights provider: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
});

/// Provider for custom date range insights
final insightsWithCustomRangeProvider = FutureProvider.family<InsightsData, Map<String, DateTime>>((ref, dateRange) async {
  final repository = ref.watch(insightsRepositoryProvider);
  
  final startDate = dateRange['start']!;
  final endDate = dateRange['end']!;
  
  Log.d('Fetching insights data for custom range: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');
  final result = await repository.fetchInsights(
    period: TimePeriod.custom,
    customStartDate: startDate,
    customEndDate: endDate,
  );
  
  if (result.isSuccess) {
    Log.d('Insights data fetched successfully for custom range');
    return result.data!;
  } else {
    Log.e('Failed to fetch insights for custom range: ${result.error}');
    throw Exception('Failed to fetch insights: ${result.error}');
  }
});

/// Provider for insights with filters notifier
final insightsWithFiltersNotifierProvider = StateNotifierProvider<InsightsWithFiltersNotifier, InsightsWithFiltersState>((ref) {
  final repository = ref.watch(insightsRepositoryProvider);
  return InsightsWithFiltersNotifier(repository);
});
