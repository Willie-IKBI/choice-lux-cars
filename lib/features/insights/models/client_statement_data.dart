/// Data models for client statements
class ClientStatementData {
  final String clientId;
  final String clientName;
  final ClientStatementDateRange statementPeriod;
  final List<ClientStatementJob> jobs;
  final double totalRevenue;
  final int totalJobs;
  final double outstandingAmount;
  final double collectedAmount;

  ClientStatementData({
    required this.clientId,
    required this.clientName,
    required this.statementPeriod,
    required this.jobs,
    required this.totalRevenue,
    required this.totalJobs,
    required this.outstandingAmount,
    required this.collectedAmount,
  });
}

class ClientStatementDateRange {
  final DateTime start;
  final DateTime end;

  ClientStatementDateRange({
    required this.start,
    required this.end,
  });
}

class ClientStatementJob {
  final String jobId;
  final String? jobNumber;
  final DateTime jobDate;
  final String jobStatus;
  final String pickupLocation;
  final String dropoffLocation;
  final DateTime? pickupDate;
  final DateTime? dropoffDate;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleRegPlate;
  final double amount;
  final bool paymentCollected;
  final DateTime? paymentDate;

  ClientStatementJob({
    required this.jobId,
    this.jobNumber,
    required this.jobDate,
    required this.jobStatus,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.pickupDate,
    this.dropoffDate,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleRegPlate,
    required this.amount,
    required this.paymentCollected,
    this.paymentDate,
  });
}


