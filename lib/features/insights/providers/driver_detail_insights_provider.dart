import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/insights/data/driver_rating_service.dart';
import 'package:choice_lux_cars/features/jobs/data/jobs_repository.dart';
import 'package:choice_lux_cars/features/jobs/models/job.dart';

/// Combined data for the driver detail insights screen.
class DriverDetailData {
  final List<Job> jobs;
  final DriverSummaryResult? summary;
  final DriverDetailKpis kpis;

  const DriverDetailData({
    required this.jobs,
    this.summary,
    required this.kpis,
  });
}

/// Provider for a single driver's detail: jobs list, rating summary, and timing KPIs.
final driverDetailInsightsProvider = FutureProvider.family<DriverDetailData, String>((ref, driverId) async {
  final jobsRepo = ref.read(jobsRepositoryProvider);
  final jobsResult = await jobsRepo.getJobsByDriver(driverId);
  final jobs = jobsResult.isSuccess ? (jobsResult.data ?? []) : <Job>[];
  final summary = await DriverRatingService.getDriverSummary(driverId);
  final kpis = await DriverRatingService.getDriverDetailKpis(driverId);
  return DriverDetailData(jobs: jobs, summary: summary, kpis: kpis);
});
