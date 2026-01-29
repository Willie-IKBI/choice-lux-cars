import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:choice_lux_cars/features/admin/models/ops_today_summary.dart';

/// Fetches today's jobs (device local date) and driver_flow, computes KPI counts.
/// Minimal fields only; no refactor of jobs module.
class OperationsDashboardService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Today = device local date boundaries (00:00 to tomorrow 00:00).
  static Future<OpsTodaySummary> getTodaySummary() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final todayStartStr = todayStart.toIso8601String();
    final todayEndStr = todayEnd.toIso8601String();

    // 1) Fetch today's jobs – minimal fields
    final jobsResponse = await _supabase
        .from('jobs')
        .select('id, job_status, driver_id, agent_id, job_start_date')
        .gte('job_start_date', todayStartStr)
        .lt('job_start_date', todayEndStr);

    final jobs = jobsResponse as List<dynamic>;
    if (jobs.isEmpty) {
      return OpsTodaySummary.empty;
    }

    final jobIds = jobs.map<int>((j) => j['id'] as int).toList();

    // 2) Fetch driver_flow for those job ids
    final flowResponse = await _supabase
        .from('driver_flow')
        .select('job_id, current_step, last_activity_at, job_closed_time, passenger_no_show_ind')
        .inFilter('job_id', jobIds);

    final flowList = flowResponse as List<dynamic>;
    final flowByJobId = <int, Map<String, dynamic>>{
      for (final row in flowList) row['job_id'] as int: row as Map<String, dynamic>,
    };

    // 3) Compute KPI counts in Dart (mutually exclusive buckets except total)
    const completedStatus = 'completed';
    const inProgressStatuses = ['started', 'in_progress', 'ready_to_close'];
    const waitingSteps = ['pickup_arrival', 'passenger_pickup', 'dropoff_arrival'];
    const terminalSteps = ['vehicle_return', 'completed', 'job_closed'];
    const problemStaleMinutes = 120;

    final cutoff = now.subtract(const Duration(minutes: problemStaleMinutes));

    int completedCount = 0;
    int problemCount = 0;
    int waitingArrivedCount = 0;
    int inProgressCount = 0;
    final alertItems = <OpsAlertItem>[];

    for (final job in jobs) {
      final jobMap = job as Map<String, dynamic>;
      final jobId = jobMap['id'] as int;
      final status = (jobMap['job_status']?.toString() ?? '').toLowerCase();
      final df = flowByJobId[jobId];
      final currentStep = (df?['current_step']?.toString() ?? '').toLowerCase();
      final lastActivityStr = df?['last_activity_at']?.toString();
      final lastActivityAt = lastActivityStr != null ? DateTime.tryParse(lastActivityStr) : null;

      final isCompleted = status == completedStatus;
      if (isCompleted) {
        completedCount++;
        continue;
      }

      final driverId = jobMap['driver_id']?.toString();
      final agentId = jobMap['agent_id']?.toString();
      final hasDriver = driverId != null && driverId.isNotEmpty;
      final hasAgent = agentId != null && agentId.isNotEmpty;

      // One primary reason per job. Priority: 1) Unassigned, 2) Missing agent, 3) Vehicle return not closed, 4) Stuck
      if (!hasDriver) {
        problemCount++;
        alertItems.add(OpsAlertItem(
          jobId: jobId,
          reason: 'Unassigned job',
          lastActivityAt: lastActivityAt,
          currentStep: currentStep,
          ageMinutes: lastActivityAt != null ? now.difference(lastActivityAt).inMinutes : 0,
          requiresClose: false,
        ));
        continue;
      }
      if (!hasAgent) {
        problemCount++;
        alertItems.add(OpsAlertItem(
          jobId: jobId,
          reason: 'Missing agent assignment',
          lastActivityAt: lastActivityAt,
          currentStep: currentStep,
          ageMinutes: lastActivityAt != null ? now.difference(lastActivityAt).inMinutes : 0,
          requiresClose: false,
        ));
        continue;
      }

      // Problem (v1): last_activity_at older than 120 min OR current_step == vehicle_return and not closed
      final lastActivityOld = lastActivityAt != null && lastActivityAt.isBefore(cutoff);
      final stuckOnVehicleReturn = currentStep == 'vehicle_return';
      final isProblem = lastActivityOld || stuckOnVehicleReturn;
      if (isProblem) {
        problemCount++;
        final requiresClose = stuckOnVehicleReturn;
        final int ageMinutes = lastActivityAt != null
            ? now.difference(lastActivityAt).inMinutes
            : problemStaleMinutes;
        final String reason;
        if (stuckOnVehicleReturn) {
          reason = 'Vehicle returned but job not closed';
        } else {
          final stepLabel = currentStep.isEmpty ? 'current step' : currentStep;
          final duration = _formatDurationMinutes(ageMinutes);
          reason = 'Stuck in $stepLabel for $duration';
        }
        alertItems.add(OpsAlertItem(
          jobId: jobId,
          reason: reason,
          lastActivityAt: lastActivityAt,
          currentStep: currentStep,
          ageMinutes: ageMinutes,
          requiresClose: requiresClose,
        ));
        continue;
      }

      // Waiting/Arrived = pickup/dropoff waiting states (conservative)
      final isWaiting = waitingSteps.contains(currentStep);
      if (isWaiting) {
        waitingArrivedCount++;
        continue;
      }

      // In progress = started/in_progress/ready_to_close OR driver_flow step not terminal
      final hasActiveStatus = inProgressStatuses.contains(status);
      final hasActiveStep = df != null && !terminalSteps.contains(currentStep);
      if (hasActiveStatus || hasActiveStep) {
        inProgressCount++;
      }
    }

    // 4) Driver workload from same jobs + flow (no extra job fetch)
    final driverItems = await _buildDriverWorkload(
      jobs as List<Map<String, dynamic>>,
      flowByJobId,
      now,
      cutoff,
      completedStatus,
      problemStaleMinutes,
    );

    return OpsTodaySummary(
      total: jobs.length,
      inProgress: inProgressCount,
      waitingArrived: waitingArrivedCount,
      completed: completedCount,
      problem: problemCount,
      alerts: alertItems,
      drivers: driverItems,
    );
  }

  /// Returns today's job IDs for the given category (same classification as KPI cards).
  /// [category] one of: total, completed, in_progress, waiting_arrived, problem.
  static Future<List<int>> getTodayJobIdsByCategory(String category) async {
    final summary = await getTodaySummary();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final todayStartStr = todayStart.toIso8601String();
    final todayEndStr = todayEnd.toIso8601String();

    final jobsResponse = await _supabase
        .from('jobs')
        .select('id, job_status, driver_id, agent_id, job_start_date')
        .gte('job_start_date', todayStartStr)
        .lt('job_start_date', todayEndStr);

    final jobs = jobsResponse as List<dynamic>;
    if (jobs.isEmpty) return [];

    final jobIds = jobs.map<int>((j) => j['id'] as int).toList();
    final flowResponse = await _supabase
        .from('driver_flow')
        .select('job_id, current_step, last_activity_at')
        .inFilter('job_id', jobIds);

    final flowList = flowResponse as List<dynamic>;
    final flowByJobId = <int, Map<String, dynamic>>{
      for (final row in flowList) row['job_id'] as int: row as Map<String, dynamic>,
    };

    const completedStatus = 'completed';
    const inProgressStatuses = ['started', 'in_progress', 'ready_to_close'];
    const waitingSteps = ['pickup_arrival', 'passenger_pickup', 'dropoff_arrival'];
    const terminalSteps = ['vehicle_return', 'completed', 'job_closed'];
    const problemStaleMinutes = 120;
    final cutoff = now.subtract(const Duration(minutes: problemStaleMinutes));

    final completedIds = <int>[];
    final problemIds = <int>[];
    final waitingArrivedIds = <int>[];
    final inProgressIds = <int>[];

    for (final job in jobs) {
      final jobMap = job as Map<String, dynamic>;
      final jobId = jobMap['id'] as int;
      final status = (jobMap['job_status']?.toString() ?? '').toLowerCase();
      final df = flowByJobId[jobId];
      final currentStep = (df?['current_step']?.toString() ?? '').toLowerCase();
      final lastActivityStr = df?['last_activity_at']?.toString();
      final lastActivityAt = lastActivityStr != null ? DateTime.tryParse(lastActivityStr) : null;

      if (status == completedStatus) {
        completedIds.add(jobId);
        continue;
      }

      final driverId = jobMap['driver_id']?.toString();
      final agentId = jobMap['agent_id']?.toString();
      final hasDriver = driverId != null && driverId.isNotEmpty;
      final hasAgent = agentId != null && agentId.isNotEmpty;

      if (!hasDriver || !hasAgent) {
        problemIds.add(jobId);
        continue;
      }

      final lastActivityOld = lastActivityAt != null && lastActivityAt.isBefore(cutoff);
      final stuckOnVehicleReturn = currentStep == 'vehicle_return';
      if (lastActivityOld || stuckOnVehicleReturn) {
        problemIds.add(jobId);
        continue;
      }

      if (waitingSteps.contains(currentStep)) {
        waitingArrivedIds.add(jobId);
        continue;
      }

      final hasActiveStatus = inProgressStatuses.contains(status);
      final hasActiveStep = df != null && !terminalSteps.contains(currentStep);
      if (hasActiveStatus || hasActiveStep) {
        inProgressIds.add(jobId);
      }
    }

    switch (category) {
      case 'total':
        return jobIds;
      case 'completed':
        return completedIds;
      case 'in_progress':
        return inProgressIds;
      case 'waiting_arrived':
        return waitingArrivedIds;
      case 'problem':
        return problemIds;
      default:
        return jobIds;
    }
  }

  static Future<List<OpsDriverWorkloadItem>> _buildDriverWorkload(
    List<Map<String, dynamic>> jobs,
    Map<int, Map<String, dynamic>> flowByJobId,
    DateTime now,
    DateTime cutoff,
    String completedStatus,
    int problemStaleMinutes,
  ) async {
    // Group by driver_id (ignore null)
    final byDriver = <String, List<Map<String, dynamic>>>{};
    for (final job in jobs) {
      final driverId = job['driver_id']?.toString();
      if (driverId == null || driverId.isEmpty) continue;
      byDriver.putIfAbsent(driverId, () => []).add(job);
    }
    if (byDriver.isEmpty) return [];

    final driverIds = byDriver.keys.toList();

    // One query: driver display info
    final profilesResponse = await _supabase
        .from('profiles')
        .select('id, display_name, number')
        .inFilter('id', driverIds);

    final profileList = profilesResponse as List<dynamic>;
    final nameByDriverId = <String, String>{};
    final phoneByDriverId = <String, String>{};
    for (final row in profileList) {
      final map = row as Map<String, dynamic>;
      final id = map['id']?.toString() ?? '';
      final name = map['display_name']?.toString();
      nameByDriverId[id] = name != null && name.isNotEmpty
          ? name
          : 'Driver ${id.length >= 8 ? id.substring(0, 8) : id}';
      final num = map['number']?.toString()?.trim();
      if (num != null && num.isNotEmpty) phoneByDriverId[id] = num;
    }

    final driverItems = <OpsDriverWorkloadItem>[];
    for (final entry in byDriver.entries) {
      final driverId = entry.key;
      final driverJobs = entry.value;
      final jobsToday = driverJobs.length;

      // Non-completed jobs with last_activity_at for active pick
      final nonCompleted = driverJobs.where((j) {
        final s = (j['job_status']?.toString() ?? '').toLowerCase();
        return s != completedStatus;
      }).toList();

      int? activeJobId;
      String? activeStep;
      if (nonCompleted.isNotEmpty) {
        // Prefer the one with newest last_activity_at
        nonCompleted.sort((a, b) {
          final dfA = flowByJobId[a['id'] as int];
          final dfB = flowByJobId[b['id'] as int];
          final tA = dfA?['last_activity_at'] != null
              ? DateTime.tryParse(dfA!['last_activity_at'].toString())
              : null;
          final tB = dfB?['last_activity_at'] != null
              ? DateTime.tryParse(dfB!['last_activity_at'].toString())
              : null;
          if (tA == null && tB == null) return 0;
          if (tA == null) return 1;
          if (tB == null) return -1;
          return tB.compareTo(tA); // newest first
        });
        final first = nonCompleted.first;
        activeJobId = first['id'] as int;
        final df = flowByJobId[activeJobId];
        activeStep = df?['current_step']?.toString();
      }

      // longWaitJobs: not completed AND (stale 120 min OR vehicle_return)
      int longWaitJobs = 0;
      for (final j in driverJobs) {
        final s = (j['job_status']?.toString() ?? '').toLowerCase();
        if (s == completedStatus) continue;
        final df = flowByJobId[j['id'] as int];
        final step = (df?['current_step']?.toString() ?? '').toLowerCase();
        final lastStr = df?['last_activity_at']?.toString();
        final lastAt = lastStr != null ? DateTime.tryParse(lastStr) : null;
        final stale = lastAt != null && lastAt.isBefore(cutoff);
        if (step == 'vehicle_return' || stale) longWaitJobs++;
      }

      // state: idle = no activeJobId, stuck = longWaitJobs > 0, else busy
      String state = 'idle';
      if (activeJobId != null) {
        state = longWaitJobs > 0 ? 'stuck' : 'busy';
      }

      driverItems.add(OpsDriverWorkloadItem(
        driverId: driverId,
        driverName: nameByDriverId[driverId] ?? 'Driver ${driverId.length >= 8 ? driverId.substring(0, 8) : driverId}',
        jobsToday: jobsToday,
        state: state,
        longWaitJobs: longWaitJobs,
        activeJobId: activeJobId,
        activeStep: activeStep,
        phoneNumber: phoneByDriverId[driverId],
      ));
    }

    // Sort by driver name for stable list
    driverItems.sort((a, b) => a.driverName.compareTo(b.driverName));
    return driverItems;
  }

  static String _formatDurationMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}
