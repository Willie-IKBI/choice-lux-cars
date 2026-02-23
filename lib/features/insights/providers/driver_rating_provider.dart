import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/insights/data/driver_rating_service.dart';

/// Result of driver rating (average of last 10 trips).
class DriverRatingResult {
  final double? avg;
  final int count;

  const DriverRatingResult({this.avg, this.count = 0});
}

/// Fetches the displayed driver rating (avg of last 10 trips) for a driver.
final driverRatingProvider = FutureProvider.family<DriverRatingResult, String>((ref, driverId) async {
  final result = await DriverRatingService.getDriverRating(driverId);
  return DriverRatingResult(avg: result.avg, count: result.count);
});

/// Fetches the rating for a specific job (avg of all trips in that job).
final jobDriverRatingProvider = FutureProvider.family<DriverRatingResult, int>((ref, jobId) async {
  final result = await DriverRatingService.getRatingForJob(jobId);
  return DriverRatingResult(avg: result.avg, count: result.count);
});

/// Number of jobs where the user was allocated as driver.
final driverJobCountProvider = FutureProvider.family<int, String>((ref, driverId) async {
  return DriverRatingService.getDriverJobCount(driverId);
});

/// Full driver summary: total jobs, overall rating, recent job ratings. Null on error or when never a driver.
final driverSummaryProvider = FutureProvider.family<DriverSummaryResult?, String>((ref, driverId) async {
  return DriverRatingService.getDriverSummary(driverId);
});
