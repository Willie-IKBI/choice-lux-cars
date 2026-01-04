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
  final double averageJobsPerVehicle;
  final double averageIncomePerVehicle;
  final List<TopVehicle> topVehicles;

  VehicleInsights({
    required this.totalVehicles,
    required this.activeVehicles,
    required this.averageJobsPerVehicle,
    required this.averageIncomePerVehicle,
    required this.topVehicles,
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

  ClientInsights({
    required this.totalClients,
    required this.activeClients,
    required this.averageJobsPerClient,
    required this.averageRevenuePerClient,
    required this.topClients,
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
