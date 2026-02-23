import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

/// Driver effectiveness rating (0-5 stars) per trip.
/// Computed from vehicle fetch timing, dropoff vs estimated deadline, flow completion, and confirmation.
/// Only last 10 trips count toward displayed average.
class DriverRatingService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Estimated trip duration in minutes (pickup to dropoff) when no dropoff time exists.
  static const int estimatedTripDurationMinutes = 90;

  /// Ideal vehicle fetch: 60-120 min before job start = full score; 90-60 min = full; 60-0 = decay; after start = 0.
  static const int vehicleFetchIdealMinBefore = 90;
  static const int vehicleFetchOkMinBefore = 60;
  static const int vehicleFetchWindowMin = 120;

  /// Dropoff: 15 min early = 1.0; 2 min before = 0.4; late = 0.
  static const int dropoffBestEarlyMinutes = 15;
  static const int dropoffTightMinutes = 2;

  /// Confirmation: confirm at least 1 hour before start = full; less = decay; not confirmed = 0.
  static const int confirmationMinLeadTimeMinutes = 60;

  static DateTime? _parse(String? s) {
    if (s == null || s.toString().isEmpty) return null;
    return DateTime.tryParse(s.toString());
  }

  /// Compute 0-1 vehicle fetch score. Job start = earliest of job_start_date or first transport pickup_date.
  static double _vehicleFetchScore(
    DateTime? vehicleCollectedAt,
    DateTime? jobStartedAt,
    DateTime jobStartReference,
  ) {
    final at = vehicleCollectedAt ?? jobStartedAt;
    if (at == null) return 0.0;
    final minutesBeforeStart = jobStartReference.difference(at).inMinutes.toDouble();
    if (minutesBeforeStart < 0) return 0.0; // after start
    if (minutesBeforeStart >= vehicleFetchOkMinBefore && minutesBeforeStart <= vehicleFetchWindowMin) return 1.0;
    if (minutesBeforeStart >= vehicleFetchIdealMinBefore && minutesBeforeStart < vehicleFetchOkMinBefore) return 1.0;
    if (minutesBeforeStart < vehicleFetchIdealMinBefore && minutesBeforeStart > 0) {
      return (minutesBeforeStart / vehicleFetchIdealMinBefore).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  /// Dropoff score: estimated deadline = pickup time for leg + estimated duration. Late = 0; 15 min early = 1.
  static double _dropoffScore(
    DateTime? actualDropoffAt,
    DateTime pickupTimeForLeg,
  ) {
    if (actualDropoffAt == null) return 0.0;
    final deadline = pickupTimeForLeg.add(Duration(minutes: estimatedTripDurationMinutes));
    final minutesBeforeDeadline = deadline.difference(actualDropoffAt).inMinutes.toDouble();
    if (minutesBeforeDeadline < 0) return 0.0; // late
    if (minutesBeforeDeadline >= dropoffBestEarlyMinutes) return 1.0;
    if (minutesBeforeDeadline <= dropoffTightMinutes) return 0.4;
    // Linear between 2 and 15 min early
    return 0.4 + (minutesBeforeDeadline - dropoffTightMinutes) / (dropoffBestEarlyMinutes - dropoffTightMinutes) * 0.6;
  }

  /// Flow completion: job closed, odo, pdp, trips completed.
  static double _flowScore(
    Map<String, dynamic>? driverFlow,
    List<Map<String, dynamic>> tripProgressRows,
  ) {
    if (driverFlow == null) return 0.0;
    final closed = driverFlow['job_closed_time'] != null && driverFlow['job_closed_odo'] != null;
    if (!closed) return 0.0;
    final hasOdo = driverFlow['odo_start_reading'] != null;
    final hasPdp = driverFlow['pdp_start_image'] != null && (driverFlow['pdp_start_image'] as String?).toString().isNotEmpty;
    final allTripsCompleted = tripProgressRows.every((t) => t['status'] == 'completed');
    if (!allTripsCompleted) return 0.5;
    if (!hasOdo || !hasPdp) return 0.5;
    return 1.0;
  }

  /// Confirmation: well before start = 1; < 1 hour before = lower; not confirmed = 0.
  static double _confirmationScore(DateTime? confirmedAt, DateTime? jobStartDate, DateTime? createdAt) {
    if (confirmedAt == null || jobStartDate == null) return 0.0;
    final minutesBeforeStart = jobStartDate.difference(confirmedAt).inMinutes.toDouble();
    if (minutesBeforeStart < 0) return 0.0;
    if (minutesBeforeStart >= confirmationMinLeadTimeMinutes) return 1.0;
    return (minutesBeforeStart / confirmationMinLeadTimeMinutes).clamp(0.0, 1.0);
  }

  /// Composite 0-5 stars from four 0-1 components (equal weight). If dropoff is 0, cap at 1 star.
  static double _compositeToStars(double vehicle, double dropoff, double flow, double confirmation) {
    final composite = (vehicle + dropoff + flow + confirmation) / 4.0;
    double stars = composite * 5.0;
    if (dropoff <= 0.0 && stars > 1.0) stars = 1.0;
    return stars.clamp(0.0, 5.0);
  }

  /// Compute per-trip score for one trip index. Returns score 0-5 and component breakdown.
  static ({
    double score,
    double vehicleFetchScore,
    double dropoffScore,
    double flowScore,
    double confirmationScore,
  }) computeTripScore({
    required int jobId,
    required int tripIndex,
    required Map<String, dynamic> job,
    required Map<String, dynamic>? driverFlow,
    required List<Map<String, dynamic>> tripProgressRows,
    required List<Map<String, dynamic>> transportRows,
  }) {
    final jobStartDate = _parse(job['job_start_date']) ?? _parse(transportRows.isNotEmpty ? transportRows.first['pickup_date'] : null);
    if (jobStartDate == null) {
      return (score: 0.0, vehicleFetchScore: 0.0, dropoffScore: 0.0, flowScore: 0.0, confirmationScore: 0.0);
    }

    final vehicleCollectedAt = _parse(driverFlow?['vehicle_collected_at']?.toString());
    final jobStartedAt = _parse(driverFlow?['job_started_at']?.toString());
    final vehicleFetch = _vehicleFetchScore(vehicleCollectedAt, jobStartedAt, jobStartDate);

    DateTime pickupTimeForLeg = jobStartDate;
    if (tripIndex <= transportRows.length) {
      final transportRow = transportRows[tripIndex - 1];
      final pt = _parse(transportRow['pickup_date']?.toString());
      if (pt != null) pickupTimeForLeg = pt;
    }
    Map<String, dynamic>? tripRow;
    for (final t in tripProgressRows) {
      if ((t['trip_index'] as num?)?.toInt() == tripIndex) {
        tripRow = t;
        break;
      }
    }
    final pickupAt = tripRow != null ? _parse(tripRow['pickup_arrived_at']?.toString()) : null;
    if (pickupAt != null) pickupTimeForLeg = pickupAt;
    final dropoffAt = tripRow != null ? _parse(tripRow['dropoff_arrived_at']?.toString()) : null;
    if (dropoffAt == null && driverFlow != null && tripIndex == 1) {
      final dfDropoff = _parse(driverFlow['dropoff_arrive_at']?.toString());
      if (dfDropoff != null) {
        final dropoff = _dropoffScore(dfDropoff, pickupTimeForLeg);
        final flow = _flowScore(driverFlow, tripProgressRows);
        final confirmedAt = _parse(job['confirmed_at']?.toString());
        final createdAt = _parse(job['created_at']?.toString());
        final confirmation = _confirmationScore(confirmedAt, jobStartDate, createdAt);
        final score = _compositeToStars(vehicleFetch, dropoff, flow, confirmation);
        return (score: score, vehicleFetchScore: vehicleFetch, dropoffScore: dropoff, flowScore: flow, confirmationScore: confirmation);
      }
    }
    final dropoff = _dropoffScore(dropoffAt, pickupTimeForLeg);
    final flow = _flowScore(driverFlow, tripProgressRows);
    final confirmedAt = _parse(job['confirmed_at']?.toString());
    final createdAt = _parse(job['created_at']?.toString());
    final confirmation = _confirmationScore(confirmedAt, jobStartDate, createdAt);
    final score = _compositeToStars(vehicleFetch, dropoff, flow, confirmation);
    return (score: score, vehicleFetchScore: vehicleFetch, dropoffScore: dropoff, flowScore: flow, confirmationScore: confirmation);
  }

  /// Load job, driver_flow, trip_progress, transport for job; compute per-trip scores; upsert into driver_trip_ratings.
  static Future<void> computeAndStoreRatingsForJob(int jobId) async {
    try {
      final jobResponse = await _supabase.from('jobs').select('id, driver_id, job_start_date, created_at, confirmed_at').eq('id', jobId).maybeSingle();
      if (jobResponse == null) {
        Log.d('DriverRatingService: job $jobId not found');
        return;
      }
      final driverId = jobResponse['driver_id']?.toString();
      if (driverId == null || driverId.isEmpty) {
        Log.d('DriverRatingService: job $jobId has no driver_id');
        return;
      }

      final driverFlowResponse = await _supabase.from('driver_flow').select().eq('job_id', jobId).maybeSingle();
      if (driverFlowResponse == null) {
        Log.d('DriverRatingService: no driver_flow for job $jobId');
        return;
      }
      if (driverFlowResponse['job_closed_time'] == null) {
        Log.d('DriverRatingService: job $jobId not closed, skip rating');
        return;
      }

      final tripProgressResponse = await _supabase.from('trip_progress').select().eq('job_id', jobId).order('trip_index', ascending: true);
      final tripProgressRows = List<Map<String, dynamic>>.from(tripProgressResponse as List<dynamic>);

      final transportResponse = await _supabase.from('transport').select('id, pickup_date').eq('job_id', jobId).order('id', ascending: true);
      final transportRows = List<Map<String, dynamic>>.from(transportResponse as List<dynamic>);

      final tripCount = tripProgressRows.isEmpty ? (transportRows.isEmpty ? 1 : transportRows.length) : tripProgressRows.length;
      for (var i = 1; i <= tripCount; i++) {
        final result = computeTripScore(
          jobId: jobId,
          tripIndex: i,
          job: jobResponse,
          driverFlow: driverFlowResponse,
          tripProgressRows: tripProgressRows,
          transportRows: transportRows,
        );
        await _supabase.from('driver_trip_ratings').upsert({
          'driver_id': driverId,
          'job_id': jobId,
          'trip_index': i,
          'score': result.score,
          'vehicle_fetch_score': result.vehicleFetchScore,
          'dropoff_ontime_score': result.dropoffScore,
          'flow_complete_score': result.flowScore,
          'confirmation_score': result.confirmationScore,
        }, onConflict: 'driver_id,job_id,trip_index');
      }
      Log.d('DriverRatingService: stored ratings for job $jobId ($tripCount trip(s))');
    } catch (e, st) {
      Log.e('DriverRatingService: computeAndStoreRatingsForJob failed', e, st);
    }
  }

  /// Get average rating for a specific job (all trips in that job). Returns avg (null if no rows) and count.
  static Future<({double? avg, int count})> getRatingForJob(int jobId) async {
    try {
      final response = await _supabase
          .from('driver_trip_ratings')
          .select('score')
          .eq('job_id', jobId);
      final rows = response as List<dynamic>;
      if (rows.isEmpty) return (avg: null, count: 0);
      final scores = rows.map((r) => (r['score'] as num?)?.toDouble() ?? 0.0).toList();
      final sum = scores.reduce((a, b) => a + b);
      return (avg: sum / scores.length, count: scores.length);
    } catch (e) {
      Log.e('DriverRatingService: getRatingForJob failed for job $jobId', e);
      return (avg: null, count: 0);
    }
  }

  /// Get average rating from last 10 trips for a driver. Returns avg (null if no trips) and count.
  static Future<({double? avg, int count})> getDriverRating(String driverId) async {
    try {
      final response = await _supabase
          .from('driver_trip_ratings')
          .select('score')
          .eq('driver_id', driverId)
          .order('created_at', ascending: false)
          .limit(10);
      final rows = response as List<dynamic>;
      if (rows.isEmpty) return (avg: null, count: 0);
      final scores = rows.map((r) => (r['score'] as num?)?.toDouble() ?? 0.0).toList();
      final sum = scores.reduce((a, b) => a + b);
      return (avg: sum / scores.length, count: scores.length);
    } catch (e) {
      Log.e('DriverRatingService: getDriverRating failed for $driverId', e);
      return (avg: null, count: 0);
    }
  }

  /// Number of jobs where this user was allocated as driver.
  static Future<int> getDriverJobCount(String driverId) async {
    try {
      final response = await _supabase
          .from('jobs')
          .select('id')
          .eq('driver_id', driverId);
      final rows = response as List<dynamic>;
      return rows.length;
    } catch (e) {
      Log.e('DriverRatingService: getDriverJobCount failed for $driverId', e);
      return 0;
    }
  }

  /// Driver summary: total jobs, last-10-trips average, and recent job ratings (avg per job).
  static const int recentJobRatingsLimit = 10;
  static const int tripRowsLimitForGrouping = 50;

  static Future<DriverSummaryResult?> getDriverSummary(String driverId) async {
    try {
      final totalJobsAsDriver = await getDriverJobCount(driverId);
      final rating = await getDriverRating(driverId);

      final tripRows = await _supabase
          .from('driver_trip_ratings')
          .select('job_id, score, created_at')
          .eq('driver_id', driverId)
          .order('created_at', ascending: false)
          .limit(tripRowsLimitForGrouping);
      final rows = List<Map<String, dynamic>>.from(tripRows as List<dynamic>);

      final jobToScores = <int, List<double>>{};
      final jobToLatestAt = <int, DateTime>{};
      for (final r in rows) {
        final jobId = (r['job_id'] as num?)?.toInt();
        if (jobId == null) continue;
        final score = (r['score'] as num?)?.toDouble() ?? 0.0;
        jobToScores.putIfAbsent(jobId, () => []).add(score);
        final at = DateTime.tryParse(r['created_at']?.toString() ?? '');
        if (at != null && (!jobToLatestAt.containsKey(jobId) || jobToLatestAt[jobId]!.isBefore(at))) {
          jobToLatestAt[jobId] = at;
        }
      }
      final jobIdsByLatest = jobToLatestAt.keys.toList()
        ..sort((a, b) => jobToLatestAt[b]!.compareTo(jobToLatestAt[a]!));
      final recentJobIds = jobIdsByLatest.take(recentJobRatingsLimit).toList();

      List<JobRatingEntry> recentJobRatings = [];
      if (recentJobIds.isNotEmpty) {
        final jobsResponse = await _supabase
            .from('jobs')
            .select('id, job_number')
            .inFilter('id', recentJobIds);
        final jobsList = List<Map<String, dynamic>>.from(jobsResponse as List<dynamic>);
        final jobNumberMap = { for (final j in jobsList) (j['id'] as num?)!.toInt(): j['job_number']?.toString() };

        for (final jobId in recentJobIds) {
          final scores = jobToScores[jobId] ?? [];
          if (scores.isEmpty) continue;
          final avgScore = scores.reduce((a, b) => a + b) / scores.length;
          recentJobRatings.add(JobRatingEntry(
            jobId: jobId,
            jobNumber: jobNumberMap[jobId],
            avgScore: avgScore,
            tripCount: scores.length,
          ));
        }
      }

      return DriverSummaryResult(
        totalJobsAsDriver: totalJobsAsDriver,
        overallAvg: rating.avg,
        last10TripCount: rating.count,
        recentJobRatings: recentJobRatings,
      );
    } catch (e, st) {
      Log.e('DriverRatingService: getDriverSummary failed for $driverId', e, st);
      return null;
    }
  }

  /// Per-driver timing KPIs for the driver detail insights screen.
  /// avgMinutesBeforeCollectingCar: average minutes before job start that the driver collected the vehicle (positive = before start).
  /// avgMinutesBeforePickup: average minutes before scheduled pickup that the driver arrived (positive = early).
  static Future<DriverDetailKpis> getDriverDetailKpis(String driverId) async {
    try {
      final jobsResponse = await _supabase
          .from('jobs')
          .select('id, job_start_date')
          .eq('driver_id', driverId);
      final jobsList = List<Map<String, dynamic>>.from(jobsResponse as List<dynamic>);
      if (jobsList.isEmpty) {
        return const DriverDetailKpis(
          avgMinutesBeforeCollectingCar: null,
          avgMinutesBeforePickup: null,
          jobsWithCollectCount: 0,
          jobsWithPickupCount: 0,
        );
      }
      final jobIds = jobsList.map((j) => (j['id'] as num).toInt()).toList();
      final jobToStartDate = <int, DateTime>{};
      for (final j in jobsList) {
        final id = (j['id'] as num).toInt();
        final start = _parse(j['job_start_date']?.toString());
        if (start != null) jobToStartDate[id] = start;
      }

      final driverFlowResponse = await _supabase
          .from('driver_flow')
          .select('job_id, vehicle_collected_at, pickup_arrive_time')
          .inFilter('job_id', jobIds);
      final driverFlowList = List<Map<String, dynamic>>.from(driverFlowResponse as List<dynamic>);

      final transportResponse = await _supabase
          .from('transport')
          .select('job_id, pickup_date')
          .inFilter('job_id', jobIds)
          .order('id', ascending: true);
      final transportList = List<Map<String, dynamic>>.from(transportResponse as List<dynamic>);
      final jobToFirstPickupDate = <int, DateTime>{};
      for (final t in transportList) {
        final jobId = (t['job_id'] as num?)?.toInt();
        if (jobId == null) continue;
        if (jobToFirstPickupDate.containsKey(jobId)) continue;
        final pd = _parse(t['pickup_date']?.toString());
        if (pd != null) jobToFirstPickupDate[jobId] = pd;
      }

      final collectMinutes = <double>[];
      final pickupMinutes = <double>[];
      for (final df in driverFlowList) {
        final jobId = (df['job_id'] as num?)?.toInt();
        if (jobId == null) continue;
        final jobStart = jobToStartDate[jobId] ?? jobToFirstPickupDate[jobId];
        if (jobStart == null) continue;

        final vehicleCollectedAt = _parse(df['vehicle_collected_at']?.toString());
        if (vehicleCollectedAt != null) {
          final minutes = jobStart.difference(vehicleCollectedAt).inMinutes.toDouble();
          if (minutes >= 0) collectMinutes.add(minutes);
        }

        final pickupArriveTime = _parse(df['pickup_arrive_time']?.toString());
        if (pickupArriveTime != null) {
          final scheduled = jobToFirstPickupDate[jobId] ?? jobStart;
          final minutes = scheduled.difference(pickupArriveTime).inMinutes.toDouble();
          pickupMinutes.add(minutes);
        }
      }

      double? avgCollect;
      if (collectMinutes.isNotEmpty) {
        avgCollect = collectMinutes.reduce((a, b) => a + b) / collectMinutes.length;
      }
      double? avgPickup;
      if (pickupMinutes.isNotEmpty) {
        avgPickup = pickupMinutes.reduce((a, b) => a + b) / pickupMinutes.length;
      }
      return DriverDetailKpis(
        avgMinutesBeforeCollectingCar: avgCollect,
        avgMinutesBeforePickup: avgPickup,
        jobsWithCollectCount: collectMinutes.length,
        jobsWithPickupCount: pickupMinutes.length,
      );
    } catch (e, st) {
      Log.e('DriverRatingService: getDriverDetailKpis failed for $driverId', e, st);
      return const DriverDetailKpis(
        avgMinutesBeforeCollectingCar: null,
        avgMinutesBeforePickup: null,
        jobsWithCollectCount: 0,
        jobsWithPickupCount: 0,
      );
    }
  }
}

/// Result of getDriverSummary for use in UI.
class DriverSummaryResult {
  final int totalJobsAsDriver;
  final double? overallAvg;
  final int last10TripCount;
  final List<JobRatingEntry> recentJobRatings;

  const DriverSummaryResult({
    required this.totalJobsAsDriver,
    this.overallAvg,
    required this.last10TripCount,
    required this.recentJobRatings,
  });
}

class JobRatingEntry {
  final int jobId;
  final String? jobNumber;
  final double avgScore;
  final int tripCount;

  const JobRatingEntry({
    required this.jobId,
    this.jobNumber,
    required this.avgScore,
    required this.tripCount,
  });
}

/// Per-driver timing KPIs for the driver detail insights screen.
class DriverDetailKpis {
  /// Average minutes before job start that the driver collected the vehicle (positive = before start). Null if no data.
  final double? avgMinutesBeforeCollectingCar;
  /// Average minutes before scheduled pickup that the driver arrived (positive = early, negative = late). Null if no data.
  final double? avgMinutesBeforePickup;
  final int jobsWithCollectCount;
  final int jobsWithPickupCount;

  const DriverDetailKpis({
    this.avgMinutesBeforeCollectingCar,
    this.avgMinutesBeforePickup,
    required this.jobsWithCollectCount,
    required this.jobsWithPickupCount,
  });
}
