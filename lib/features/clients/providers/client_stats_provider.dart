import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';
import '../../jobs/models/job.dart';
import '../../quotes/models/quote.dart';

// Provider for client jobs
final clientJobsProvider = FutureProvider.family<List<Job>, String>((ref, clientId) async {
  final jobsData = await SupabaseService.instance.getJobsByClient(clientId);
  return jobsData.map((json) => Job.fromMap(json)).toList();
});

// Provider for client completed jobs
final clientCompletedJobsProvider = FutureProvider.family<List<Job>, String>((ref, clientId) async {
  final jobsData = await SupabaseService.instance.getCompletedJobsByClient(clientId);
  return jobsData.map((json) => Job.fromMap(json)).toList();
});

// Provider for client quotes
final clientQuotesProvider = FutureProvider.family<List<Quote>, String>((ref, clientId) async {
  final quotesData = await SupabaseService.instance.getQuotesByClient(clientId);
  return quotesData.map((json) => Quote.fromMap(json)).toList();
});

// Provider for client completed jobs revenue
final clientRevenueProvider = FutureProvider.family<double, String>((ref, clientId) async {
  return await SupabaseService.instance.getCompletedJobsRevenueByClient(clientId);
});

// Provider for client statistics summary
final clientStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, clientId) async {
  final completedJobs = await ref.read(clientCompletedJobsProvider(clientId).future);
  final quotes = await ref.read(clientQuotesProvider(clientId).future);
  final revenue = await ref.read(clientRevenueProvider(clientId).future);

  return {
    'completedJobs': completedJobs.length,
    'totalQuotes': quotes.length,
    'totalRevenue': revenue,
  };
});
