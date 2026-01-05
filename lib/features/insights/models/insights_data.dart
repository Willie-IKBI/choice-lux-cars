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
  final double averageCompletionDays; // Average days to complete jobs
  final double onTimeRate; // Percentage of jobs completed on time (0-100)
  // Sprint 1 additions
  final double averageTimeToStart; // Average days between createdAt and jobStartDate
  final int jobsStartingToday; // Count of jobs with jobStartDate today
  final int jobsStartingTomorrow; // Count of jobs with jobStartDate tomorrow
  final int overdueJobs; // Jobs past jobStartDate not completed
  final int unassignedJobs; // Jobs without driver or vehicle

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
    required this.averageCompletionDays,
    required this.onTimeRate,
    required this.averageTimeToStart,
    required this.jobsStartingToday,
    required this.jobsStartingTomorrow,
    required this.overdueJobs,
    required this.unassignedJobs,
  });
}

class DriverInsights {
  final int totalDrivers;
  final int activeDrivers;
  final double averageJobsPerDriver;
  final double averageRevenuePerDriver;
  final List<TopDriver> topDrivers;
  // Sprint 1 additions
  final double driverUtilizationRate; // % of time drivers are active
  final int unassignedJobsCount; // Jobs without driver
  final List<TopDriver> bottomPerformers; // Lowest performing drivers
  
  // Phase 2: Additional performance metrics
  final double averageJobCompletionTime; // hours
  final double averageTimeToPickup; // minutes
  final double onTimePickupRate; // percentage
  final double averageJobsPerDay; // jobs/day
  final double revenuePerHour; // R/hour
  final double paymentCollectionRate; // percentage
  final double averageProgressCompletion; // percentage
  final int jobsCompletedThisWeek;
  final int jobsCompletedThisMonth;
  final int activeJobsNow;
  final int jobsStartedToday;
  final double averageResponseTime; // hours
  final String? topLocationByJobs;
  final Map<String, double> revenueByLocation;
  final double efficiencyScore; // 0-100
  final String? mostProductiveDay;
  final String? peakPerformanceHours;
  final double averageDistancePerJob; // km

  DriverInsights({
    required this.totalDrivers,
    required this.activeDrivers,
    required this.averageJobsPerDriver,
    required this.averageRevenuePerDriver,
    required this.topDrivers,
    required this.driverUtilizationRate,
    required this.unassignedJobsCount,
    required this.bottomPerformers,
    // Phase 2: Default values for new metrics (will be calculated in repository)
    this.averageJobCompletionTime = 0.0,
    this.averageTimeToPickup = 0.0,
    this.onTimePickupRate = 0.0,
    this.averageJobsPerDay = 0.0,
    this.revenuePerHour = 0.0,
    this.paymentCollectionRate = 0.0,
    this.averageProgressCompletion = 0.0,
    this.jobsCompletedThisWeek = 0,
    this.jobsCompletedThisMonth = 0,
    this.activeJobsNow = 0,
    this.jobsStartedToday = 0,
    this.averageResponseTime = 0.0,
    this.topLocationByJobs,
    this.revenueByLocation = const {},
    this.efficiencyScore = 0.0,
    this.mostProductiveDay,
    this.peakPerformanceHours,
    this.averageDistancePerJob = 0.0,
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
  final double averageJobsPerVehicle;
  final double averageIncomePerVehicle;
  final List<TopVehicle> topVehicles;
  // Sprint 1 additions
  final double vehicleUtilizationRate; // % of time vehicles are in use
  final int unassignedJobsCount; // Jobs without vehicle
  final List<TopVehicle> leastUsedVehicles; // Underutilized vehicles
  
  // Phase 2: Additional vehicle metrics
  final double totalDistanceTraveled; // km
  final double averageDistancePerVehicle; // km
  final double averageDistancePerJob; // km
  final double highestOdometerReading; // km
  final String? vehicleWithMostDistance; // Vehicle name
  final int jobsCompletedThisWeek;
  final int jobsCompletedThisMonth;
  final int activeJobsNow;
  final double averageJobsPerDay; // jobs/day
  final double revenuePerKm; // R/km
  final double averageTimePerJob; // hours
  final double vehicleEfficiencyScore; // 0-100
  final String? mostEfficientVehicle; // Vehicle name
  final String? topLocationByUsage;
  final Map<String, double> revenueByLocation;
  final double averageKmPerDay; // km/day

  VehicleInsights({
    required this.totalVehicles,
    required this.activeVehicles,
    required this.averageJobsPerVehicle,
    required this.averageIncomePerVehicle,
    required this.topVehicles,
    required this.vehicleUtilizationRate,
    required this.unassignedJobsCount,
    required this.leastUsedVehicles,
    // Phase 2: Default values for new metrics (will be calculated in repository)
    this.totalDistanceTraveled = 0.0,
    this.averageDistancePerVehicle = 0.0,
    this.averageDistancePerJob = 0.0,
    this.highestOdometerReading = 0.0,
    this.vehicleWithMostDistance,
    this.jobsCompletedThisWeek = 0,
    this.jobsCompletedThisMonth = 0,
    this.activeJobsNow = 0,
    this.averageJobsPerDay = 0.0,
    this.revenuePerKm = 0.0,
    this.averageTimePerJob = 0.0,
    this.vehicleEfficiencyScore = 0.0,
    this.mostEfficientVehicle,
    this.topLocationByUsage,
    this.revenueByLocation = const {},
    this.averageKmPerDay = 0.0,
  });
}

class TopVehicle {
  final String vehicleId;
  final String vehicleName;
  final String registration;
  final int jobCount;
  final double revenue;

  TopVehicle({
    required this.vehicleId,
    required this.vehicleName,
    required this.registration,
    required this.jobCount,
    required this.revenue,
  });
}

class ClientInsights {
  final int totalClients;
  final int activeClients;
  final double averageJobsPerClient;
  final double averageRevenuePerClient;
  final List<TopClient> topClients;
  // Sprint 1 additions
  final List<TopClient> topClientsByRevenue; // Clients sorted by revenue
  final double clientRetentionRate; // % repeat clients
  
  // Phase 2: Additional client metrics
  final int newClientsThisPeriod; // New clients in selected period
  final int repeatClientsCount; // Clients with multiple jobs
  final double averageDaysBetweenJobs; // Average days between jobs for repeat clients
  final TopClient? topClientByJobFrequency; // Client with most jobs
  final int clientsWithOutstandingPayments; // Count of clients with outstanding payments
  final double totalOutstandingAmount; // Total outstanding amount across all clients
  final double averageQuoteToJobConversionRate; // % of quotes converted to jobs
  final Map<String, int> clientsByLocation; // Client count by location (Jhb, Cpt, Dbn)
  final Map<String, double> revenueGrowthByClient; // Revenue growth % per client
  final double averageJobValuePerClient; // Average job value per client
  final TopClient? mostActiveClient; // Most active client (by job count)
  final int clientsWithNoJobs; // Clients with no jobs in period

  ClientInsights({
    required this.totalClients,
    required this.activeClients,
    required this.averageJobsPerClient,
    required this.averageRevenuePerClient,
    required this.topClients,
    required this.topClientsByRevenue,
    required this.clientRetentionRate,
    // Phase 2: Default values for new metrics
    this.newClientsThisPeriod = 0,
    this.repeatClientsCount = 0,
    this.averageDaysBetweenJobs = 0.0,
    this.topClientByJobFrequency,
    this.clientsWithOutstandingPayments = 0,
    this.totalOutstandingAmount = 0.0,
    this.averageQuoteToJobConversionRate = 0.0,
    this.clientsByLocation = const {},
    this.revenueGrowthByClient = const {},
    this.averageJobValuePerClient = 0.0,
    this.mostActiveClient,
    this.clientsWithNoJobs = 0,
  });
}

class TopClient {
  final String clientId;
  final String clientName;
  final int jobCount;
  final int quoteCount;
  final double totalValue;

  TopClient({
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
  // Sprint 1 additions
  final double? paymentCollectionRate; // % of jobs with collectPayment=true that were collected (null if no data)
  final Map<String, double> revenueByLocation; // Revenue breakdown by Jhb/Cpt/Dbn
  final double outstandingPayments; // Jobs with collectPayment=true but not completed
  // Additional insights
  final double totalCollected; // Total collected payments
  final double totalUncollected; // Total uncollected payments
  final double averagePaymentAmount; // Average payment per collected job
  final int jobsRequiringPaymentCollection; // Count of jobs with amount_collect=true
  final double revenueGrowthWeekOverWeek; // Week-over-week growth %
  final double revenueGrowthMonthOverMonth; // Month-over-month growth %

  FinancialInsights({
    required this.totalRevenue,
    required this.revenueThisWeek,
    required this.revenueThisMonth,
    required this.averageJobValue,
    required this.revenueGrowth,
    required this.paymentCollectionRate,
    required this.revenueByLocation,
    required this.outstandingPayments,
    required this.totalCollected,
    required this.totalUncollected,
    required this.averagePaymentAmount,
    required this.jobsRequiringPaymentCollection,
    required this.revenueGrowthWeekOverWeek,
    required this.revenueGrowthMonthOverMonth,
  });
}

/// Time period enum for filtering
enum TimePeriod {
  today,
  thisWeek,
  thisMonth,
  thisQuarter,
  thisYear,
  custom,
}

extension TimePeriodExtension on TimePeriod {
  String get displayName {
    switch (this) {
      case TimePeriod.today:
        return 'Today';
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
