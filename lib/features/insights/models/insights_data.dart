/// Data models for insights and analytics
class InsightsData {
  final QuoteInsights quoteInsights;
  final JobInsights jobInsights;
  final DriverInsights driverInsights;
  final VehicleInsights vehicleInsights;
  final ClientInsights clientInsights;
  final FinancialInsights financialInsights;
  final ClientRevenueInsights clientRevenueInsights;

  InsightsData({
    required this.quoteInsights,
    required this.jobInsights,
    required this.driverInsights,
    required this.vehicleInsights,
    required this.clientInsights,
    required this.financialInsights,
    required this.clientRevenueInsights,
  });
}

class QuoteInsights {
  final int totalQuotes;
  final int quotesThisWeek;
  final int quotesThisMonth;
  final double averageQuoteValue;
  final double conversionRate; // quotes to jobs
  final int quotesPerClient;

  QuoteInsights({
    required this.totalQuotes,
    required this.quotesThisWeek,
    required this.quotesThisMonth,
    required this.averageQuoteValue,
    required this.conversionRate,
    required this.quotesPerClient,
  });
}

class JobInsights {
  final int totalJobs;
  final int jobsThisWeek;
  final int jobsThisMonth;
  final int openJobs;
  final int inProgressJobs;
  final int completedJobs;
  final int cancelledJobs;
  final double averageJobsPerWeek;
  final double completionRate;

  JobInsights({
    required this.totalJobs,
    required this.jobsThisWeek,
    required this.jobsThisMonth,
    required this.openJobs,
    required this.inProgressJobs,
    required this.completedJobs,
    required this.cancelledJobs,
    required this.averageJobsPerWeek,
    required this.completionRate,
  });
}

class DriverInsights {
  final int totalDrivers;
  final int activeDrivers;
  final double averageJobsPerDriver;
  final double averageRevenuePerDriver;
  final List<TopDriver> topDrivers;

  DriverInsights({
    required this.totalDrivers,
    required this.activeDrivers,
    required this.averageJobsPerDriver,
    required this.averageRevenuePerDriver,
    required this.topDrivers,
  });
}

class TopDriver {
  final String driverId;
  final String driverName;
  final int jobCount;
  final double revenue;

  TopDriver({
    required this.driverId,
    required this.driverName,
    required this.jobCount,
    required this.revenue,
  });
}

class VehicleInsights {
  final int totalVehicles;
  final int activeVehicles;
  final int inactiveVehicles;
  final int underMaintenanceVehicles;
  final double averageJobsPerVehicle;
  final double averageIncomePerVehicle;
  final double averageUtilizationRate; // Average utilization rate across all vehicles (%)
  final double averageMileagePerVehicle; // Average total mileage per vehicle (km)
  final double averageMileagePerJob; // Average mileage per job (km)
  final List<TopVehicle> topVehicles; // Top by job count
  final List<TopVehicle> topVehiclesByRevenue; // Top by revenue
  final List<UnderutilizedVehicle> underutilizedVehicles; // Vehicles with low utilization
  final List<VehicleLicenseAlert> licenseExpiringSoon; // Vehicles with license expiring < 30 days
  final Map<String, int> vehiclesByBranch; // Branch name -> vehicle count
  final Map<String, double> utilizationByBranch; // Branch name -> average utilization rate

  VehicleInsights({
    required this.totalVehicles,
    required this.activeVehicles,
    this.inactiveVehicles = 0,
    this.underMaintenanceVehicles = 0,
    required this.averageJobsPerVehicle,
    required this.averageIncomePerVehicle,
    this.averageUtilizationRate = 0.0,
    this.averageMileagePerVehicle = 0.0,
    this.averageMileagePerJob = 0.0,
    required this.topVehicles,
    this.topVehiclesByRevenue = const [],
    this.underutilizedVehicles = const [],
    this.licenseExpiringSoon = const [],
    this.vehiclesByBranch = const {},
    this.utilizationByBranch = const {},
  });
}

class TopVehicle {
  final String vehicleId;
  final String vehicleName;
  final String registration;
  final int jobCount;
  final double revenue;
  final double? utilizationRate; // Optional utilization rate (%)
  final double? efficiencyScore; // Optional: jobCount * revenue for ranking
  final double? totalMileage; // Optional: total mileage in km
  final double? averageMileagePerJob; // Optional: average mileage per job in km

  TopVehicle({
    required this.vehicleId,
    required this.vehicleName,
    required this.registration,
    required this.jobCount,
    required this.revenue,
    this.utilizationRate,
    this.efficiencyScore,
    this.totalMileage,
    this.averageMileagePerJob,
  });
}

class UnderutilizedVehicle {
  final String vehicleId;
  final String vehicleName;
  final String registration;
  final int jobCount;
  final double revenue;
  final double utilizationRate; // Utilization rate (%)
  final String? branchName; // Branch name if available

  UnderutilizedVehicle({
    required this.vehicleId,
    required this.vehicleName,
    required this.registration,
    required this.jobCount,
    required this.revenue,
    required this.utilizationRate,
    this.branchName,
  });
}

class VehicleLicenseAlert {
  final String vehicleId;
  final String vehicleName;
  final String registration;
  final DateTime licenseExpiryDate;
  final int daysUntilExpiry; // Negative if expired

  VehicleLicenseAlert({
    required this.vehicleId,
    required this.vehicleName,
    required this.registration,
    required this.licenseExpiryDate,
    required this.daysUntilExpiry,
  });
}

class ClientInsights {
  final int totalClients;
  final int activeClients;
  final int vipClients;
  final int pendingClients;
  final int inactiveClients;
  final int newClients; // Clients with first job/quote in period
  final int atRiskClients; // Clients with no activity in 30+ days
  final double averageJobsPerClient;
  final double averageRevenuePerClient;
  final double averageJobValuePerClient; // Average job amount per client
  final double averageQuoteValuePerClient; // Average quote amount per client
  final double averageQuotesPerClient;
  final double quoteToJobConversionRate; // Overall conversion rate (%)
  final double averageAgentsPerClient; // Average number of agents per client
  final List<TopClient> topClients; // Top by total value
  final List<TopClient> topClientsByJobs; // Top by job count
  final List<TopClient> topClientsByRevenue; // Top by revenue
  final List<TopClient> topClientsByQuotes; // Top by quote value
  final List<TopClient> topClientsByConversionRate; // Top by conversion rate
  final List<AtRiskClient> atRiskClientsList; // Detailed at-risk clients
  final List<NewClient> newClientsList; // Detailed new clients
  final List<TopAgent> topAgents; // Top agents by client value
  final Map<String, int> clientsByStatus; // Status -> count
  final Map<String, double> revenueByStatus; // Status -> total revenue
  final Map<String, int> jobsByStatus; // Job status -> count (aggregated across all clients)
  final Map<String, int> quotesByStatus; // Quote status -> count
  final Map<String, int> clientsByTier; // Tier (VIP/Regular) -> count
  final Map<String, double> revenueByTier; // Tier -> total revenue

  ClientInsights({
    required this.totalClients,
    required this.activeClients,
    this.vipClients = 0,
    this.pendingClients = 0,
    this.inactiveClients = 0,
    this.newClients = 0,
    this.atRiskClients = 0,
    required this.averageJobsPerClient,
    required this.averageRevenuePerClient,
    this.averageJobValuePerClient = 0.0,
    this.averageQuoteValuePerClient = 0.0,
    this.averageQuotesPerClient = 0.0,
    this.quoteToJobConversionRate = 0.0,
    this.averageAgentsPerClient = 0.0,
    required this.topClients,
    this.topClientsByJobs = const [],
    this.topClientsByRevenue = const [],
    this.topClientsByQuotes = const [],
    this.topClientsByConversionRate = const [],
    this.atRiskClientsList = const [],
    this.newClientsList = const [],
    this.topAgents = const [],
    this.clientsByStatus = const {},
    this.revenueByStatus = const {},
    this.jobsByStatus = const {},
    this.quotesByStatus = const {},
    this.clientsByTier = const {},
    this.revenueByTier = const {},
  });
}

class TopClient {
  final String clientId;
  final String clientName;
  final String? clientStatus; // active, vip, pending, inactive
  final int jobCount;
  final int quoteCount;
  final double jobRevenue; // Revenue from jobs only
  final double quoteValue; // Value from quotes only
  final double totalValue; // Total (jobs + quotes)
  final double? conversionRate; // Quote to job conversion rate (%)
  final double? averageJobValue; // Average job amount
  final double? averageQuoteValue; // Average quote amount
  final int? agentCount; // Number of agents for this client
  final DateTime? lastActivityDate; // Last job or quote date
  final int? daysSinceLastActivity; // Days since last activity

  TopClient({
    required this.clientId,
    required this.clientName,
    this.clientStatus,
    required this.jobCount,
    required this.quoteCount,
    required this.jobRevenue,
    required this.quoteValue,
    required this.totalValue,
    this.conversionRate,
    this.averageJobValue,
    this.averageQuoteValue,
    this.agentCount,
    this.lastActivityDate,
    this.daysSinceLastActivity,
  });
}

class AtRiskClient {
  final String clientId;
  final String clientName;
  final DateTime? lastActivityDate;
  final int daysSinceLastActivity;
  final int totalJobs; // All-time job count
  final int totalQuotes; // All-time quote count
  final double lifetimeValue; // All-time revenue

  AtRiskClient({
    required this.clientId,
    required this.clientName,
    this.lastActivityDate,
    required this.daysSinceLastActivity,
    required this.totalJobs,
    required this.totalQuotes,
    required this.lifetimeValue,
  });
}

class NewClient {
  final String clientId;
  final String clientName;
  final DateTime firstActivityDate;
  final int jobCount; // Jobs in period
  final int quoteCount; // Quotes in period
  final double revenue; // Revenue in period

  NewClient({
    required this.clientId,
    required this.clientName,
    required this.firstActivityDate,
    required this.jobCount,
    required this.quoteCount,
    required this.revenue,
  });
}

class TopAgent {
  final String agentId;
  final String agentName;
  final String clientId;
  final String clientName;
  final int jobCount;
  final int quoteCount;
  final double totalValue; // Total value from jobs + quotes

  TopAgent({
    required this.agentId,
    required this.agentName,
    required this.clientId,
    required this.clientName,
    required this.jobCount,
    required this.quoteCount,
    required this.totalValue,
  });
}

class FinancialInsights {
  final double totalRevenue;
  final double revenueThisWeek;
  final double revenueThisMonth;
  final double averageJobValue;
  final double revenueGrowth;

  FinancialInsights({
    required this.totalRevenue,
    required this.revenueThisWeek,
    required this.revenueThisMonth,
    required this.averageJobValue,
    required this.revenueGrowth,
  });
}

/// Time period enum for filtering
enum TimePeriod {
  // Historical periods
  today,
  yesterday,
  last3Days,
  thisWeek,
  thisMonth,
  thisQuarter,
  thisYear,
  custom,
  // Planning periods
  tomorrow,
  next3Days,
}

extension TimePeriodExtension on TimePeriod {
  String get displayName {
    switch (this) {
      case TimePeriod.today:
        return 'Today';
      case TimePeriod.yesterday:
        return 'Yesterday';
      case TimePeriod.last3Days:
        return 'Last 3 Days';
      case TimePeriod.thisWeek:
        return 'This Week';
      case TimePeriod.thisMonth:
        return 'This Month';
      case TimePeriod.thisQuarter:
        return 'This Quarter';
      case TimePeriod.thisYear:
        return 'This Year';
      case TimePeriod.custom:
        return 'Custom Range';
      case TimePeriod.tomorrow:
        return 'Tomorrow';
      case TimePeriod.next3Days:
        return 'Next 3 Days';
    }
  }
}

/// Location filter enum for filtering insights by location
enum LocationFilter {
  all,
  jhb,
  cpt,
  dbn,
  unspecified,
}

extension LocationFilterExtension on LocationFilter {
  String get displayName {
    switch (this) {
      case LocationFilter.all:
        return 'All Locations';
      case LocationFilter.jhb:
        return 'Johannesburg';
      case LocationFilter.cpt:
        return 'Cape Town';
      case LocationFilter.dbn:
        return 'Durban';
      case LocationFilter.unspecified:
        return 'Unspecified';
    }
  }
}

/// Client revenue data model
class ClientRevenue {
  final String clientId;
  final String clientName;
  final double totalRevenue;
  final int jobCount;
  final double averageJobValue;

  ClientRevenue({
    required this.clientId,
    required this.clientName,
    required this.totalRevenue,
    required this.jobCount,
    required this.averageJobValue,
  });
}

/// Client revenue insights model
class ClientRevenueInsights {
  final List<ClientRevenue> topClients;
  final double totalRevenue;
  final double averageRevenuePerClient;
  final int totalClients;

  ClientRevenueInsights({
    required this.topClients,
    required this.totalRevenue,
    required this.averageRevenuePerClient,
    required this.totalClients,
  });
}
