/// Driver workload row for Operations Dashboard (read-only).
class OpsDriverWorkloadItem {
  final String driverId;
  final String driverName;
  final int jobsToday;
  final String state; // idle, busy, stuck
  final int longWaitJobs;
  final int? activeJobId;
  final String? activeStep;
  final String? phoneNumber;

  const OpsDriverWorkloadItem({
    required this.driverId,
    required this.driverName,
    required this.jobsToday,
    required this.state,
    required this.longWaitJobs,
    this.activeJobId,
    this.activeStep,
    this.phoneNumber,
  });
}

/// Single alert/exception item for Operations Dashboard (read-only).
class OpsAlertItem {
  final int jobId;
  final String reason;
  final DateTime? lastActivityAt;
  final String currentStep;
  final int ageMinutes;
  final bool requiresClose;

  const OpsAlertItem({
    required this.jobId,
    required this.reason,
    this.lastActivityAt,
    required this.currentStep,
    required this.ageMinutes,
    required this.requiresClose,
  });
}

/// Today summary KPIs for Operations Dashboard (device local date).
class OpsTodaySummary {
  final int total;
  final int inProgress;
  final int waitingArrived;
  final int completed;
  final int problem;
  final List<OpsAlertItem> alerts;
  final List<OpsDriverWorkloadItem> drivers;

  const OpsTodaySummary({
    required this.total,
    required this.inProgress,
    required this.waitingArrived,
    required this.completed,
    required this.problem,
    this.alerts = const [],
    this.drivers = const [],
  });

  static const OpsTodaySummary empty = OpsTodaySummary(
    total: 0,
    inProgress: 0,
    waitingArrived: 0,
    completed: 0,
    problem: 0,
    alerts: [],
    drivers: [],
  );
}
