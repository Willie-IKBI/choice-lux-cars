import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:choice_lux_cars/core/supabase/supabase_client_provider.dart';
import 'package:choice_lux_cars/features/insights/models/insights_data.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/core/types/result.dart';
import 'package:choice_lux_cars/core/errors/app_exception.dart';
import 'package:choice_lux_cars/features/branches/branches.dart';

/// Repository for insights and analytics data operations
class InsightsRepository {
  final SupabaseClient _supabase;

  InsightsRepository(this._supabase);

  /// Helper function to map location filter to branch_id
  /// Returns branch_id (int) or null for all/unspecified
  int? _locationFilterToBranchId(LocationFilter location) {
    switch (location) {
      case LocationFilter.jhb:
        return Branch.johannesburgId;
      case LocationFilter.cpt:
        return Branch.capeTownId;
      case LocationFilter.dbn:
        return Branch.durbanId;
      case LocationFilter.all:
      case LocationFilter.unspecified:
        return null;
    }
  }

  /// Fetch comprehensive insights data
  Future<Result<InsightsData>> fetchInsights({
    TimePeriod period = TimePeriod.thisMonth,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    try {
      print('Fetching insights data for period: ${period.displayName}');

      final dateRange = _getDateRange(period, customStartDate, customEndDate);
      print('Date range: ${dateRange.start.toIso8601String()} to ${dateRange.end.toIso8601String()}');
      
      // Fetch all insights in parallel (skip quotes due to persistent issues)
      print('Starting parallel fetch of all insights...');
      final results = await Future.wait([
        _fetchJobInsights(dateRange),
        _fetchDriverInsights(dateRange),
        _fetchVehicleInsights(dateRange),
        _fetchClientInsights(dateRange),
        _fetchFinancialInsights(dateRange),
        _fetchClientRevenueInsights(dateRange),
      ]);

      // Check if any failed
      for (int i = 0; i < results.length; i++) {
        if (results[i].isFailure) {
          final insightType = ['Quote', 'Job', 'Driver', 'Vehicle', 'Client', 'Financial', 'ClientRevenue'][i];
          print('Failed to fetch $insightType insights: ${results[i].error}');
          return Result.failure(results[i].error!);
        }
      }

      final insightsData = InsightsData(
        quoteInsights: results[0].data! as QuoteInsights,
        jobInsights: results[1].data! as JobInsights,
        driverInsights: results[2].data! as DriverInsights,
        vehicleInsights: results[3].data! as VehicleInsights,
        clientInsights: results[4].data! as ClientInsights,
        financialInsights: results[5].data! as FinancialInsights,
        clientRevenueInsights: results[6].data! as ClientRevenueInsights,
      );

      Log.d('All insights data fetched successfully');
      Log.d('Summary: ${insightsData.jobInsights.totalJobs} jobs, ${insightsData.quoteInsights.totalQuotes} quotes, R${insightsData.financialInsights.totalRevenue.toStringAsFixed(0)} revenue');
      
      // Detailed logging for each insight type
      Log.d('Quote Insights: ${insightsData.quoteInsights.totalQuotes} total, R${insightsData.quoteInsights.averageQuoteValue.toStringAsFixed(0)} avg value');
      Log.d('Job Insights: ${insightsData.jobInsights.totalJobs} total, ${insightsData.jobInsights.completedJobs} completed, ${insightsData.jobInsights.completionRate.toStringAsFixed(1)}% completion rate');
      Log.d('Driver Insights: ${insightsData.driverInsights.totalDrivers} total, ${insightsData.driverInsights.topDrivers.length} top drivers');
      Log.d('Vehicle Insights: ${insightsData.vehicleInsights.totalVehicles} total, ${insightsData.vehicleInsights.topVehicles.length} top vehicles');
      Log.d('Client Insights: ${insightsData.clientInsights.totalClients} total, ${insightsData.clientInsights.topClients.length} top clients');
      Log.d('Financial Insights: R${insightsData.financialInsights.totalRevenue.toStringAsFixed(0)} total revenue');
      
      return Result.success(insightsData);
    } catch (error) {
      Log.e('Error fetching insights: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Fetch comprehensive insights data with location filtering
  Future<Result<InsightsData>> fetchInsightsWithFilters({
    TimePeriod period = TimePeriod.thisMonth,
    LocationFilter location = LocationFilter.all,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    try {
      print('Fetching insights data for period: ${period.displayName}, location: ${location.displayName}');

      final dateRange = _getDateRange(period, customStartDate, customEndDate);
      print('Date range: ${dateRange.start.toIso8601String()} to ${dateRange.end.toIso8601String()}');
      
      // Fetch all insights in parallel with location filtering
      print('Starting parallel fetch of all insights with location filter...');
      final results = await Future.wait([
        _fetchQuoteInsightsWithLocation(dateRange, location),
        _fetchJobInsightsWithLocation(dateRange, location),
        _fetchDriverInsightsWithLocation(dateRange, location),
        _fetchVehicleInsightsWithLocation(dateRange, location),
        _fetchClientInsightsWithLocation(dateRange, location),
        _fetchFinancialInsightsWithLocation(dateRange, location),
        _fetchClientRevenueInsights(dateRange), // Note: No location filter for client revenue yet
      ]);

      // Check if any failed
      for (int i = 0; i < results.length; i++) {
        if (results[i].isFailure) {
          final insightType = ['Quote', 'Job', 'Driver', 'Vehicle', 'Client', 'Financial', 'ClientRevenue'][i];
          print('Failed to fetch $insightType insights: ${results[i].error}');
          return Result.failure(results[i].error!);
        }
      }

      final insightsData = InsightsData(
        quoteInsights: results[0].data! as QuoteInsights,
        jobInsights: results[1].data! as JobInsights,
        driverInsights: results[2].data! as DriverInsights,
        vehicleInsights: results[3].data! as VehicleInsights,
        clientInsights: results[4].data! as ClientInsights,
        financialInsights: results[5].data! as FinancialInsights,
        clientRevenueInsights: results[6].data! as ClientRevenueInsights,
      );

      Log.d('All insights data fetched successfully with location filter');
      Log.d('Summary: ${insightsData.jobInsights.totalJobs} jobs, ${insightsData.quoteInsights.totalQuotes} quotes, R${insightsData.financialInsights.totalRevenue.toStringAsFixed(0)} revenue');
      
      return Result.success(insightsData);
    } catch (error) {
      Log.e('Error fetching insights with filters: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Fetch quote insights
  Future<Result<QuoteInsights>> _fetchQuoteInsights(DateRange dateRange) async {
    try {
      Log.d('Fetching quote insights...');
      // Total quotes
      final totalQuotesResponse = await _supabase
          .from('quotes')
          .select('id, quote_amount, created_at, client_id')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String());
      
      Log.d('Quotes query returned ${totalQuotesResponse.length} records');

      final totalQuotes = totalQuotesResponse.length;
      final totalQuoteValue = totalQuotesResponse
          .where((q) => q['quote_amount'] != null)
          .fold<double>(0.0, (sum, q) => sum + (q['quote_amount'] as num).toDouble());

      // Quotes this week
      final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
      final quotesThisWeekResponse = await _supabase
          .from('quotes')
          .select('id')
          .gte('created_at', weekStart.toIso8601String());

      // Quotes this month
      final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
      final quotesThisMonthResponse = await _supabase
          .from('quotes')
          .select('id')
          .gte('created_at', monthStart.toIso8601String());

      // Conversion rate (quotes to jobs)
      final jobsFromQuotesResponse = await _supabase
          .from('jobs')
          .select('id')
          .not('quote_no', 'is', null)
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String());

      final conversionRate = totalQuotes > 0 
          ? (jobsFromQuotesResponse.length / totalQuotes) * 100 
          : 0.0;

      // Quotes per client
      final uniqueClients = totalQuotesResponse
          .map((q) => q['client_id'])
          .toSet()
          .length;
      final quotesPerClient = uniqueClients > 0 ? totalQuotes / uniqueClients : 0;

      final insights = QuoteInsights(
        totalQuotes: totalQuotes,
        quotesThisWeek: quotesThisWeekResponse.length,
        quotesThisMonth: quotesThisMonthResponse.length,
        averageQuoteValue: totalQuotes > 0 ? totalQuoteValue / totalQuotes : 0.0,
        conversionRate: conversionRate,
        quotesPerClient: quotesPerClient.round(),
      );

      return Result.success(insights);
    } catch (error) {
      Log.e('Error fetching quote insights: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Fetch quote insights with location filtering
  Future<Result<QuoteInsights>> _fetchQuoteInsightsWithLocation(DateRange dateRange, LocationFilter location) async {
    try {
      Log.d('Fetching quote insights with location filter: ${location.displayName}...');
      
      // Location filtering for quotes is currently disabled as quotes may not have location field
      // Total quotes with location filter (skip location filtering for quotes)
      var query = _supabase
          .from('quotes')
          .select('id, quote_amount, created_at, client_id')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String());
      
      // Skip location filtering for quotes as they may not have location field
      // if (locationFilter != null) {
      //   query = query.eq('location', locationFilter);
      // } else if (location == LocationFilter.unspecified) {
      //   query = query.isFilter('location', null);
      // }
      
      final totalQuotesResponse = await query;
      
      Log.d('Quotes query with location filter returned ${totalQuotesResponse.length} records');

      final totalQuotes = totalQuotesResponse.length;
      final totalQuoteValue = totalQuotesResponse
          .where((q) => q['quote_amount'] != null)
          .fold<double>(0.0, (sum, q) => sum + (q['quote_amount'] as num).toDouble());

      // Quotes this week with location filter (skip location filtering for quotes)
      final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
      var weekQuery = _supabase
          .from('quotes')
          .select('id')
          .gte('created_at', weekStart.toIso8601String());
      
      // Skip location filtering for quotes
      // if (locationFilter != null) {
      //   weekQuery = weekQuery.eq('location', locationFilter);
      // } else if (location == LocationFilter.unspecified) {
      //   weekQuery = weekQuery.isFilter('location', null);
      // }
      
      final quotesThisWeekResponse = await weekQuery;

      // Quotes this month with location filter (skip location filtering for quotes)
      final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
      var monthQuery = _supabase
          .from('quotes')
          .select('id')
          .gte('created_at', monthStart.toIso8601String());
      
      // Skip location filtering for quotes
      // if (locationFilter != null) {
      //   monthQuery = monthQuery.eq('location', locationFilter);
      // } else if (location == LocationFilter.unspecified) {
      //   monthQuery = monthQuery.isFilter('location', null);
      // }
      
      final quotesThisMonthResponse = await monthQuery;

      final quoteInsights = QuoteInsights(
        totalQuotes: totalQuotes,
        quotesThisWeek: quotesThisWeekResponse.length,
        quotesThisMonth: quotesThisMonthResponse.length,
        averageQuoteValue: totalQuotes > 0 ? totalQuoteValue / totalQuotes : 0.0,
        conversionRate: 0.0, // TODO: Calculate conversion rate
        quotesPerClient: 0, // TODO: Calculate quotes per client
      );

      Log.d('Quote insights with location filter: ${quoteInsights.totalQuotes} total, R${totalQuoteValue.toStringAsFixed(0)} value');
      return Result.success(quoteInsights);
    } catch (error) {
      Log.e('Error fetching quote insights with location filter: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Fetch job insights
  Future<Result<JobInsights>> _fetchJobInsights(DateRange dateRange) async {
    try {
      Log.d('Fetching job insights...');
      // All jobs in period
      final jobsResponse = await _supabase
          .from('jobs')
          .select('id, job_status, created_at')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String());
      
      Log.d('Jobs query returned ${jobsResponse.length} records');

      final totalJobs = jobsResponse.length;
      
      // Jobs by status
      final openJobs = jobsResponse.where((j) => j['job_status'] == 'open').length;
      final inProgressJobs = jobsResponse.where((j) => j['job_status'] == 'in_progress').length;
      final completedJobs = jobsResponse.where((j) => j['job_status'] == 'completed').length;
      final cancelledJobs = jobsResponse.where((j) => j['job_status'] == 'cancelled').length;

      // Jobs this week
      final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
      final jobsThisWeekResponse = await _supabase
          .from('jobs')
          .select('id')
          .gte('created_at', weekStart.toIso8601String());

      // Jobs this month
      final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
      final jobsThisMonthResponse = await _supabase
          .from('jobs')
          .select('id')
          .gte('created_at', monthStart.toIso8601String());

      // Average jobs per week
      final weeksInPeriod = dateRange.end.difference(dateRange.start).inDays / 7;
      final averageJobsPerWeek = weeksInPeriod > 0 ? totalJobs / weeksInPeriod : 0.0;

      // Completion rate
      final completionRate = totalJobs > 0 ? (completedJobs / totalJobs) * 100 : 0.0;

      // Calculate average km and time for completed jobs
      double averageKmPerCompletedJob = 0.0;
      double averageTimePerCompletedJob = 0.0;
      
      if (completedJobs > 0) {
        // Get completed job IDs
        final completedJobIds = jobsResponse
            .where((j) => j['job_status'] == 'completed')
            .map((j) => j['id'] as int)
            .toList();
        
        if (completedJobIds.isNotEmpty) {
          // Query driver_flow for completed jobs
          final idsString = completedJobIds.join(',');
          final driverFlowQuery = _supabase
              .from('driver_flow')
              .select('job_id, odo_start_reading, job_closed_odo, vehicle_collected_at, job_closed_time')
              .filter('job_id', 'in', '($idsString)')
              .not('job_closed_odo', 'is', null)
              .not('odo_start_reading', 'is', null)
              .not('vehicle_collected_at', 'is', null)
              .not('job_closed_time', 'is', null);
          
          final driverFlowResponse = await driverFlowQuery;
          
          // Calculate distances and times
          final distances = <double>[];
          final times = <double>[];
          
          for (final flow in driverFlowResponse) {
            final startOdo = flow['odo_start_reading'];
            final endOdo = flow['job_closed_odo'];
            final vehicleCollectedAt = flow['vehicle_collected_at'];
            final jobClosedTime = flow['job_closed_time'];
            
            if (startOdo != null && endOdo != null) {
              final distance = (endOdo as num).toDouble() - (startOdo as num).toDouble();
              if (distance >= 0) {
                distances.add(distance);
              }
            }
            
            if (vehicleCollectedAt != null && jobClosedTime != null) {
              try {
                final startTime = DateTime.parse(vehicleCollectedAt);
                final endTime = DateTime.parse(jobClosedTime);
                final duration = endTime.difference(startTime);
                final hours = duration.inMinutes / 60.0;
                if (hours >= 0) {
                  times.add(hours);
                }
              } catch (e) {
                Log.e('Error parsing timestamps: $e');
              }
            }
          }
          
          if (distances.isNotEmpty) {
            averageKmPerCompletedJob = distances.reduce((a, b) => a + b) / distances.length;
          }
          
          if (times.isNotEmpty) {
            averageTimePerCompletedJob = times.reduce((a, b) => a + b) / times.length;
          }
        }
      }

      final insights = JobInsights(
        totalJobs: totalJobs,
        jobsThisWeek: jobsThisWeekResponse.length,
        jobsThisMonth: jobsThisMonthResponse.length,
        openJobs: openJobs,
        inProgressJobs: inProgressJobs,
        completedJobs: completedJobs,
        cancelledJobs: cancelledJobs,
        averageJobsPerWeek: averageJobsPerWeek,
        completionRate: completionRate,
        averageKmPerCompletedJob: averageKmPerCompletedJob,
        averageTimePerCompletedJob: averageTimePerCompletedJob,
      );

      return Result.success(insights);
    } catch (error) {
      Log.e('Error fetching job insights: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Fetch job insights with location filtering
  Future<Result<JobInsights>> _fetchJobInsightsWithLocation(DateRange dateRange, LocationFilter location) async {
    try {
      Log.d('Fetching job insights with location filter: ${location.displayName}...');
      
      // Map location filter to branch_id
      final branchId = _locationFilterToBranchId(location);

      // Compute insights based on earliest pickup_date per job (transport table)
      // Step 1: Fetch transport rows in range and compute earliest pickup per job
      final transportRows = await _supabase
          .from('transport')
          .select('job_id, pickup_date')
          .gte('pickup_date', dateRange.start.toIso8601String())
          .lte('pickup_date', dateRange.end.toIso8601String())
          .not('pickup_date', 'is', null);

      final Map<int, DateTime> jobEarliestPickup = {};
      for (final row in transportRows) {
        final jobId = row['job_id'] as int?;
        final pickupStr = row['pickup_date'] as String?;
        if (jobId == null || pickupStr == null) continue;
        final pickup = DateTime.parse(pickupStr);
        final existing = jobEarliestPickup[jobId];
        if (existing == null || pickup.isBefore(existing)) {
          jobEarliestPickup[jobId] = pickup;
        }
      }

      if (jobEarliestPickup.isEmpty) {
        final emptyInsights = JobInsights(
          totalJobs: 0,
          jobsThisWeek: 0,
          jobsThisMonth: 0,
          openJobs: 0,
          inProgressJobs: 0,
          completedJobs: 0,
          cancelledJobs: 0,
          averageJobsPerWeek: 0,
          completionRate: 0,
          averageKmPerCompletedJob: 0.0,
          averageTimePerCompletedJob: 0.0,
        );
        return Result.success(emptyInsights);
      }

      // Step 2: Fetch jobs for those IDs, apply branch filter
      final jobIds = jobEarliestPickup.keys.toList();
      var jobsQuery = _supabase
          .from('jobs')
          .select('id, job_status, branch_id');

      // Filter by IDs using in filter
      final idsString = jobIds.join(',');
      jobsQuery = jobsQuery.filter('id', 'in', '($idsString)');

      if (branchId != null) {
        jobsQuery = jobsQuery.eq('branch_id', branchId);
      } else if (location == LocationFilter.unspecified) {
        jobsQuery = jobsQuery.isFilter('branch_id', null);
      }

      final jobsResponse = await jobsQuery;

      Log.d('Jobs (by earliest pickup) with location filter returned ${jobsResponse.length} records');

      // Compute counts with OPEN = not in (completed, cancelled)
      final totalJobs = jobsResponse.length;
      final completedJobs = jobsResponse.where((j) => j['job_status'] == 'completed').length;
      final cancelledJobs = jobsResponse.where((j) => j['job_status'] == 'cancelled').length;
      final inProgressJobs = jobsResponse.where((j) => j['job_status'] == 'in_progress' || j['job_status'] == 'started').length;
      final openJobs = jobsResponse.where((j) => j['job_status'] != 'completed' && j['job_status'] != 'cancelled').length;

      // Jobs this week with branch filter
      final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
      var weekQuery = _supabase
          .from('jobs')
          .select('id')
          .gte('created_at', weekStart.toIso8601String());
      
      if (branchId != null) {
        weekQuery = weekQuery.eq('branch_id', branchId);
      } else if (location == LocationFilter.unspecified) {
        weekQuery = weekQuery.isFilter('branch_id', null);
      }
      
      final jobsThisWeekResponse = await weekQuery;

      // Jobs this month with branch filter
      final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
      var monthQuery = _supabase
          .from('jobs')
          .select('id')
          .gte('created_at', monthStart.toIso8601String());
      
      if (branchId != null) {
        monthQuery = monthQuery.eq('branch_id', branchId);
      } else if (location == LocationFilter.unspecified) {
        monthQuery = monthQuery.isFilter('branch_id', null);
      }
      
      final jobsThisMonthResponse = await monthQuery;

      // Calculate average km and time for completed jobs
      double averageKmPerCompletedJob = 0.0;
      double averageTimePerCompletedJob = 0.0;
      
      if (completedJobs > 0) {
        // Get completed job IDs
        final completedJobIds = jobsResponse
            .where((j) => j['job_status'] == 'completed')
            .map((j) => j['id'] as int)
            .toList();
        
        if (completedJobIds.isNotEmpty) {
          // Query driver_flow for completed jobs
          final idsString = completedJobIds.join(',');
          final driverFlowQuery = _supabase
              .from('driver_flow')
              .select('job_id, odo_start_reading, job_closed_odo, vehicle_collected_at, job_closed_time')
              .filter('job_id', 'in', '($idsString)')
              .not('job_closed_odo', 'is', null)
              .not('odo_start_reading', 'is', null)
              .not('vehicle_collected_at', 'is', null)
              .not('job_closed_time', 'is', null);
          
          final driverFlowResponse = await driverFlowQuery;
          
          // Calculate distances and times
          final distances = <double>[];
          final times = <double>[];
          
          for (final flow in driverFlowResponse) {
            final startOdo = flow['odo_start_reading'];
            final endOdo = flow['job_closed_odo'];
            final vehicleCollectedAt = flow['vehicle_collected_at'];
            final jobClosedTime = flow['job_closed_time'];
            
            if (startOdo != null && endOdo != null) {
              final distance = (endOdo as num).toDouble() - (startOdo as num).toDouble();
              if (distance >= 0) {
                distances.add(distance);
              }
            }
            
            if (vehicleCollectedAt != null && jobClosedTime != null) {
              try {
                final startTime = DateTime.parse(vehicleCollectedAt);
                final endTime = DateTime.parse(jobClosedTime);
                final duration = endTime.difference(startTime);
                final hours = duration.inMinutes / 60.0;
                if (hours >= 0) {
                  times.add(hours);
                }
              } catch (e) {
                Log.e('Error parsing timestamps: $e');
              }
            }
          }
          
          if (distances.isNotEmpty) {
            averageKmPerCompletedJob = distances.reduce((a, b) => a + b) / distances.length;
          }
          
          if (times.isNotEmpty) {
            averageTimePerCompletedJob = times.reduce((a, b) => a + b) / times.length;
          }
        }
      }

      final jobInsights = JobInsights(
        totalJobs: totalJobs,
        jobsThisWeek: jobsThisWeekResponse.length,
        jobsThisMonth: jobsThisMonthResponse.length,
        openJobs: openJobs,
        inProgressJobs: inProgressJobs,
        completedJobs: completedJobs,
        cancelledJobs: cancelledJobs,
        averageJobsPerWeek: totalJobs > 0 ? (totalJobs / 4.0) : 0.0, // Approximate weeks in month
        completionRate: totalJobs > 0 ? completedJobs / totalJobs : 0.0,
        averageKmPerCompletedJob: averageKmPerCompletedJob,
        averageTimePerCompletedJob: averageTimePerCompletedJob,
      );

      Log.d('Job insights with location filter: ${jobInsights.totalJobs} total, ${jobInsights.completedJobs} completed');
      return Result.success(jobInsights);
    } catch (error) {
      Log.e('Error fetching job insights with location filter: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Fetch driver insights
  Future<Result<DriverInsights>> _fetchDriverInsights(DateRange dateRange) async {
    try {
      Log.d('Fetching driver insights...');
      // Total drivers
      final driversResponse = await _supabase
          .from('profiles')
          .select('id, display_name')
          .eq('role', 'driver');
      
      Log.d('Drivers query returned ${driversResponse.length} records');

      final totalDrivers = driversResponse.length;
      final activeDrivers = driversResponse.length; // All drivers are considered active

      // Driver job counts and revenue
      final driverJobsResponse = await _supabase
          .from('jobs')
          .select('driver_id, amount')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String())
          .not('driver_id', 'is', null);

      // Group by driver
      final driverStats = <String, Map<String, dynamic>>{};
      for (final job in driverJobsResponse) {
        final driverId = job['driver_id'].toString();
        if (!driverStats.containsKey(driverId)) {
          driverStats[driverId] = {'count': 0, 'revenue': 0.0};
        }
        driverStats[driverId]!['count']++;
        if (job['amount'] != null) {
          driverStats[driverId]!['revenue'] += (job['amount'] as num).toDouble();
        }
      }

      // Calculate averages
      final totalJobCount = driverStats.values.fold<int>(0, (sum, stats) => sum + (stats['count'] as int));
      final totalRevenue = driverStats.values.fold<double>(0.0, (sum, stats) => sum + (stats['revenue'] as double));
      
      final averageJobsPerDriver = totalDrivers > 0 ? totalJobCount / totalDrivers : 0.0;
      final averageRevenuePerDriver = totalDrivers > 0 ? totalRevenue / totalDrivers : 0.0;

      // Top drivers
      final topDrivers = <TopDriver>[];
      for (final entry in driverStats.entries) {
        final driverId = entry.key;
        final stats = entry.value;
        final driver = driversResponse.firstWhere(
          (d) => d['id'] == driverId,
          orElse: () => {'id': driverId, 'display_name': 'Unknown Driver'},
        );
        
        topDrivers.add(TopDriver(
          driverId: driverId.toString(),
          driverName: driver['display_name'] ?? 'Unknown Driver',
          jobCount: stats['count'],
          revenue: stats['revenue'],
        ));
      }
      
      // Sort by job count and take top 5
      topDrivers.sort((a, b) => b.jobCount.compareTo(a.jobCount));
      final topDriversList = topDrivers.take(5).toList();

      final insights = DriverInsights(
        totalDrivers: totalDrivers,
        activeDrivers: activeDrivers,
        averageJobsPerDriver: averageJobsPerDriver,
        averageRevenuePerDriver: averageRevenuePerDriver,
        topDrivers: topDriversList,
      );

      return Result.success(insights);
    } catch (error) {
      Log.e('Error fetching driver insights: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Fetch driver insights with location filtering
  Future<Result<DriverInsights>> _fetchDriverInsightsWithLocation(DateRange dateRange, LocationFilter location) async {
    try {
      Log.d('Fetching driver insights with location filter: ${location.displayName}...');
      
      // Map location filter to branch_id
      final branchId = _locationFilterToBranchId(location);

      // Total drivers
      final driversResponse = await _supabase
          .from('profiles')
          .select('id, display_name')
          .eq('role', 'driver');
      
      Log.d('Drivers query returned ${driversResponse.length} records');

      final totalDrivers = driversResponse.length;
      final activeDrivers = driversResponse.length; // All drivers are considered active

      // Driver job counts and revenue with branch filter
      var driverJobsQuery = _supabase
          .from('jobs')
          .select('driver_id, amount')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String())
          .not('driver_id', 'is', null);
      
      if (branchId != null) {
        driverJobsQuery = driverJobsQuery.eq('branch_id', branchId);
      } else if (location == LocationFilter.unspecified) {
        driverJobsQuery = driverJobsQuery.isFilter('branch_id', null);
      }
      
      final driverJobsResponse = await driverJobsQuery;

      // Calculate driver statistics
      final Map<String, Map<String, dynamic>> driverStats = {};
      for (final job in driverJobsResponse) {
        final driverId = job['driver_id'].toString();
        if (!driverStats.containsKey(driverId)) {
          driverStats[driverId] = {'count': 0, 'revenue': 0.0};
        }
        driverStats[driverId]!['count']++;
        if (job['amount'] != null) {
          driverStats[driverId]!['revenue'] += (job['amount'] as num).toDouble();
        }
      }

      // Calculate averages
      final totalDriverJobs = driverStats.values.fold<int>(0, (sum, stats) => sum + (stats['count'] as int));
      final totalDriverRevenue = driverStats.values.fold<double>(0.0, (sum, stats) => sum + stats['revenue']);
      final averageJobsPerDriver = totalDrivers > 0 ? totalDriverJobs / totalDrivers : 0.0;
      final averageRevenuePerDriver = totalDrivers > 0 ? totalDriverRevenue / totalDrivers : 0.0;

      // Get top drivers
      final List<TopDriver> topDrivers = [];
      for (final entry in driverStats.entries) {
        final driverId = entry.key;
        final stats = entry.value;
        
        // Get driver name
        final driver = driversResponse.firstWhere(
          (d) => d['id'].toString() == driverId,
          orElse: () => {'display_name': 'Unknown Driver'},
        );
        
        topDrivers.add(TopDriver(
          driverId: driverId,
          driverName: driver['display_name'] ?? 'Unknown Driver',
          jobCount: stats['count'],
          revenue: stats['revenue'],
        ));
      }
      
      // Sort by job count and take top 5
      topDrivers.sort((a, b) => b.jobCount.compareTo(a.jobCount));
      final top5Drivers = topDrivers.take(5).toList();

      final driverInsights = DriverInsights(
        totalDrivers: totalDrivers,
        activeDrivers: activeDrivers,
        averageJobsPerDriver: averageJobsPerDriver,
        averageRevenuePerDriver: averageRevenuePerDriver,
        topDrivers: top5Drivers,
      );

      Log.d('Driver insights with location filter: ${driverInsights.totalDrivers} drivers, ${driverInsights.averageJobsPerDriver.toStringAsFixed(1)} avg jobs');
      return Result.success(driverInsights);
    } catch (error) {
      Log.e('Error fetching driver insights with location filter: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Fetch vehicle insights
  Future<Result<VehicleInsights>> _fetchVehicleInsights(DateRange dateRange) async {
    try {
      Log.d('Fetching vehicle insights...');
      
      // Fetch vehicles with all needed fields
      final vehiclesResponse = await _supabase
          .from('vehicles')
          .select('id, make, model, reg_plate, status, branch_id, license_expiry_date');
      
      Log.d('Vehicles query returned ${vehiclesResponse.length} records');

      final totalVehicles = vehiclesResponse.length;
      
      // Calculate status breakdown
      int activeVehicles = 0;
      int inactiveVehicles = 0;
      int underMaintenanceVehicles = 0;
      
      for (final vehicle in vehiclesResponse) {
        final status = (vehicle['status'] as String?)?.toLowerCase() ?? '';
        if (status.contains('maintenance') || status.contains('repair')) {
          underMaintenanceVehicles++;
        } else if (status == 'active' || status.isEmpty) {
          activeVehicles++;
        } else {
          inactiveVehicles++;
        }
      }

      // Fetch vehicle job data with dates for utilization calculation
      final vehicleJobsResponse = await _supabase
          .from('jobs')
          .select('id, vehicle_id, amount, created_at, job_start_date')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String())
          .not('vehicle_id', 'is', null);

      // Fetch odometer readings from driver_flow for mileage calculation
      final jobIds = vehicleJobsResponse.map((j) => j['id'] as int).toList();
      final driverFlowResponse = jobIds.isNotEmpty
          ? await _supabase
              .from('driver_flow')
              .select('job_id, odo_start_reading, job_closed_odo')
              .inFilter('job_id', jobIds)
              .not('odo_start_reading', 'is', null)
              .not('job_closed_odo', 'is', null)
          : <Map<String, dynamic>>[];

      // Create map of job_id -> mileage
      final jobMileage = <int, double>{};
      for (final flow in driverFlowResponse) {
        final jobId = flow['job_id'] as int?;
        final startOdo = flow['odo_start_reading'];
        final endOdo = flow['job_closed_odo'];
        if (jobId != null && startOdo != null && endOdo != null) {
          final mileage = (endOdo as num).toDouble() - (startOdo as num).toDouble();
          if (mileage > 0) {
            jobMileage[jobId] = mileage;
          }
        }
      }

      // Calculate days in period
      final daysInPeriod = dateRange.end.difference(dateRange.start).inDays + 1;

      // Group by vehicle and track unique days with jobs
      final vehicleStats = <String, Map<String, dynamic>>{};
      final vehicleJobDays = <String, Set<String>>{}; // vehicleId -> set of unique dates (YYYY-MM-DD)
      
      for (final job in vehicleJobsResponse) {
        final vehicleId = job['vehicle_id'].toString();
        final jobId = job['id'] as int;
        if (!vehicleStats.containsKey(vehicleId)) {
          vehicleStats[vehicleId] = {'count': 0, 'revenue': 0.0, 'mileage': 0.0, 'jobsWithMileage': 0};
          vehicleJobDays[vehicleId] = <String>{};
        }
        vehicleStats[vehicleId]!['count']++;
        if (job['amount'] != null) {
          vehicleStats[vehicleId]!['revenue'] += (job['amount'] as num).toDouble();
        }
        
        // Add mileage if available
        if (jobMileage.containsKey(jobId)) {
          vehicleStats[vehicleId]!['mileage'] += jobMileage[jobId]!;
          vehicleStats[vehicleId]!['jobsWithMileage']++;
        }
        
        // Track unique days with jobs for utilization
        final jobDate = job['created_at'] != null 
            ? DateTime.parse(job['created_at']).toIso8601String().split('T')[0]
            : null;
        if (jobDate != null) {
          vehicleJobDays[vehicleId]!.add(jobDate);
        }
      }

      // Calculate averages
      final totalJobCount = vehicleStats.values.fold<int>(0, (sum, stats) => sum + (stats['count'] as int));
      final totalRevenue = vehicleStats.values.fold<double>(0.0, (sum, stats) => sum + (stats['revenue'] as double));
      final totalMileage = vehicleStats.values.fold<double>(0.0, (sum, stats) => sum + (stats['mileage'] as double));
      final totalJobsWithMileage = vehicleStats.values.fold<int>(0, (sum, stats) => sum + (stats['jobsWithMileage'] as int));
      final vehiclesWithJobsCount = vehicleStats.length; // Only vehicles that actually had jobs
      
      // Average jobs per vehicle: calculate across vehicles that had jobs for more meaningful metric
      final averageJobsPerVehicle = vehiclesWithJobsCount > 0 
          ? totalJobCount / vehiclesWithJobsCount 
          : (totalVehicles > 0 ? totalJobCount / totalVehicles : 0.0);
      final averageIncomePerVehicle = vehiclesWithJobsCount > 0 
          ? totalRevenue / vehiclesWithJobsCount 
          : (totalVehicles > 0 ? totalRevenue / totalVehicles : 0.0);
      final averageMileagePerVehicle = vehiclesWithJobsCount > 0 
          ? totalMileage / vehiclesWithJobsCount 
          : (totalVehicles > 0 ? totalMileage / totalVehicles : 0.0);
      final averageMileagePerJob = totalJobsWithMileage > 0 ? totalMileage / totalJobsWithMileage : 0.0;

      // Build vehicle details map
      final vehicleDetails = <String, Map<String, dynamic>>{};
      final vehiclesByBranch = <String, int>{};
      final branchUtilization = <String, List<double>>{}; // branch -> list of utilization rates
      
      for (final vehicle in vehiclesResponse) {
        final vehicleId = vehicle['id'].toString();
        vehicleDetails[vehicleId] = vehicle;
        
        // Track vehicles by branch
        final branchId = vehicle['branch_id'];
        if (branchId != null) {
          // Fetch branch name
          try {
            final branchResponse = await _supabase
                .from('branches')
                .select('name')
                .eq('id', branchId)
                .maybeSingle();
            final branchName = branchResponse?['name'] ?? 'Unknown Branch';
            vehiclesByBranch[branchName] = (vehiclesByBranch[branchName] ?? 0) + 1;
          } catch (_) {
            // Branch lookup failed, skip
          }
        }
      }

      // Build TopVehicle list with utilization and efficiency scores
      final allTopVehicles = <TopVehicle>[];
      double totalUtilizationRate = 0.0;
      int vehiclesWithJobs = 0;
      
      for (final entry in vehicleStats.entries) {
        final vehicleId = entry.key;
        final stats = entry.value;
        final vehicle = vehicleDetails[vehicleId] ?? 
            {'make': 'Unknown', 'model': 'Unknown', 'reg_plate': 'Unknown', 'branch_id': null};
        
        // Calculate utilization rate
        final daysWithJobs = vehicleJobDays[vehicleId]?.length ?? 0;
        final utilizationRate = daysInPeriod > 0 ? (daysWithJobs / daysInPeriod) * 100 : 0.0;
        totalUtilizationRate += utilizationRate;
        if (daysWithJobs > 0) vehiclesWithJobs++;
        
        // Calculate efficiency score (jobCount * revenue)
        final efficiencyScore = stats['count'] * stats['revenue'];
        
        // Calculate mileage metrics
        final totalMileage = stats['mileage'] as double;
        final jobsWithMileage = stats['jobsWithMileage'] as int;
        final avgMileagePerJob = jobsWithMileage > 0 ? totalMileage / jobsWithMileage : null;
        
        // Get branch name
        String? branchName;
        final branchId = vehicle['branch_id'];
        if (branchId != null) {
          try {
            final branchResponse = await _supabase
                .from('branches')
                .select('name')
                .eq('id', branchId)
                .maybeSingle();
            branchName = branchResponse?['name'];
            if (branchName != null) {
              branchUtilization[branchName] ??= [];
              branchUtilization[branchName]!.add(utilizationRate);
            }
          } catch (_) {
            // Branch lookup failed
          }
        }
        
        allTopVehicles.add(TopVehicle(
          vehicleId: vehicleId,
          vehicleName: '${vehicle['make']} ${vehicle['model']}',
          registration: vehicle['reg_plate'] ?? 'Unknown',
          jobCount: stats['count'],
          revenue: stats['revenue'],
          utilizationRate: utilizationRate,
          efficiencyScore: efficiencyScore,
          totalMileage: totalMileage > 0 ? totalMileage : null,
          averageMileagePerJob: avgMileagePerJob,
        ));
      }
      
      // Calculate average utilization rate
      final averageUtilizationRate = vehiclesWithJobs > 0 
          ? totalUtilizationRate / vehiclesWithJobs 
          : 0.0;
      
      // Sort by job count and take top 5
      final topVehiclesByJobs = List<TopVehicle>.from(allTopVehicles);
      topVehiclesByJobs.sort((a, b) => b.jobCount.compareTo(a.jobCount));
      final topVehiclesList = topVehiclesByJobs.take(5).toList();
      
      // Sort by revenue and take top 5
      final topVehiclesByRevenue = List<TopVehicle>.from(allTopVehicles);
      topVehiclesByRevenue.sort((a, b) => b.revenue.compareTo(a.revenue));
      final topVehiclesByRevenueList = topVehiclesByRevenue.take(5).toList();
      
      // Identify underutilized vehicles (< 3 jobs OR < 30% utilization)
      final underutilizedVehicles = <UnderutilizedVehicle>[];
      for (final vehicle in allTopVehicles) {
        if (vehicle.jobCount < 3 || (vehicle.utilizationRate ?? 0) < 30.0) {
          final vehicleData = vehicleDetails[vehicle.vehicleId] ?? {};
          String? branchName;
          final branchId = vehicleData['branch_id'];
          if (branchId != null) {
            try {
              final branchResponse = await _supabase
                  .from('branches')
                  .select('name')
                  .eq('id', branchId)
                  .maybeSingle();
              branchName = branchResponse?['name'];
            } catch (_) {}
          }
          
          underutilizedVehicles.add(UnderutilizedVehicle(
            vehicleId: vehicle.vehicleId,
            vehicleName: vehicle.vehicleName,
            registration: vehicle.registration,
            jobCount: vehicle.jobCount,
            revenue: vehicle.revenue,
            utilizationRate: vehicle.utilizationRate ?? 0.0,
            branchName: branchName,
          ));
        }
      }
      
      // Check license expiry dates
      final licenseExpiringSoon = <VehicleLicenseAlert>[];
      final now = DateTime.now();
      for (final vehicle in vehiclesResponse) {
        final expiryDate = vehicle['license_expiry_date'];
        if (expiryDate != null) {
          try {
            final expiry = DateTime.parse(expiryDate);
            final daysUntilExpiry = expiry.difference(now).inDays;
            if (daysUntilExpiry <= 30) {
              licenseExpiringSoon.add(VehicleLicenseAlert(
                vehicleId: vehicle['id'].toString(),
                vehicleName: '${vehicle['make']} ${vehicle['model']}',
                registration: vehicle['reg_plate'] ?? 'Unknown',
                licenseExpiryDate: expiry,
                daysUntilExpiry: daysUntilExpiry,
              ));
            }
          } catch (_) {
            // Invalid date format, skip
          }
        }
      }
      
      // Calculate average utilization by branch
      final utilizationByBranch = <String, double>{};
      for (final entry in branchUtilization.entries) {
        if (entry.value.isNotEmpty) {
          final avgUtilization = entry.value.reduce((a, b) => a + b) / entry.value.length;
          utilizationByBranch[entry.key] = avgUtilization;
        }
      }

      final insights = VehicleInsights(
        totalVehicles: totalVehicles,
        activeVehicles: activeVehicles,
        inactiveVehicles: inactiveVehicles,
        underMaintenanceVehicles: underMaintenanceVehicles,
        averageJobsPerVehicle: averageJobsPerVehicle,
        averageIncomePerVehicle: averageIncomePerVehicle,
        averageUtilizationRate: averageUtilizationRate,
        averageMileagePerVehicle: averageMileagePerVehicle,
        averageMileagePerJob: averageMileagePerJob,
        topVehicles: topVehiclesList,
        topVehiclesByRevenue: topVehiclesByRevenueList,
        underutilizedVehicles: underutilizedVehicles,
        licenseExpiringSoon: licenseExpiringSoon,
        vehiclesByBranch: vehiclesByBranch,
        utilizationByBranch: utilizationByBranch,
      );

      return Result.success(insights);
    } catch (error) {
      Log.e('Error fetching vehicle insights: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Fetch vehicle insights with location filtering
  Future<Result<VehicleInsights>> _fetchVehicleInsightsWithLocation(DateRange dateRange, LocationFilter location) async {
    try {
      Log.d('Fetching vehicle insights with location filter: ${location.displayName}...');
      
      // Map location filter to branch_id
      final branchId = _locationFilterToBranchId(location);

      // Fetch vehicles with all needed fields, filtered by branch if specified
      var vehiclesQuery = _supabase
          .from('vehicles')
          .select('id, make, model, reg_plate, status, branch_id, license_expiry_date');
      
      if (branchId != null) {
        vehiclesQuery = vehiclesQuery.eq('branch_id', branchId);
      } else if (location == LocationFilter.unspecified) {
        vehiclesQuery = vehiclesQuery.isFilter('branch_id', null);
      }
      
      final vehiclesResponse = await vehiclesQuery;
      Log.d('Vehicles query returned ${vehiclesResponse.length} records');

      final totalVehicles = vehiclesResponse.length;
      
      // Calculate status breakdown
      int activeVehicles = 0;
      int inactiveVehicles = 0;
      int underMaintenanceVehicles = 0;
      
      for (final vehicle in vehiclesResponse) {
        final status = (vehicle['status'] as String?)?.toLowerCase() ?? '';
        if (status.contains('maintenance') || status.contains('repair')) {
          underMaintenanceVehicles++;
        } else if (status == 'active' || status.isEmpty) {
          activeVehicles++;
        } else {
          inactiveVehicles++;
        }
      }

      // Calculate days in period
      final daysInPeriod = dateRange.end.difference(dateRange.start).inDays + 1;

      // Vehicle job counts and revenue with branch filter
      var vehicleJobsQuery = _supabase
          .from('jobs')
          .select('id, vehicle_id, amount, created_at')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String())
          .not('vehicle_id', 'is', null);
      
      if (branchId != null) {
        vehicleJobsQuery = vehicleJobsQuery.eq('branch_id', branchId);
      } else if (location == LocationFilter.unspecified) {
        vehicleJobsQuery = vehicleJobsQuery.isFilter('branch_id', null);
      }
      
      final vehicleJobsResponse = await vehicleJobsQuery;

      // Fetch odometer readings from driver_flow for mileage calculation
      final jobIds = vehicleJobsResponse.map((j) => j['id'] as int).toList();
      final driverFlowResponse = jobIds.isNotEmpty
          ? await _supabase
              .from('driver_flow')
              .select('job_id, odo_start_reading, job_closed_odo')
              .inFilter('job_id', jobIds)
              .not('odo_start_reading', 'is', null)
              .not('job_closed_odo', 'is', null)
          : <Map<String, dynamic>>[];

      // Create map of job_id -> mileage
      final jobMileage = <int, double>{};
      for (final flow in driverFlowResponse) {
        final jobId = flow['job_id'] as int?;
        final startOdo = flow['odo_start_reading'];
        final endOdo = flow['job_closed_odo'];
        if (jobId != null && startOdo != null && endOdo != null) {
          final mileage = (endOdo as num).toDouble() - (startOdo as num).toDouble();
          if (mileage > 0) {
            jobMileage[jobId] = mileage;
          }
        }
      }

      // Group by vehicle and track unique days with jobs
      final vehicleStats = <String, Map<String, dynamic>>{};
      final vehicleJobDays = <String, Set<String>>{}; // vehicleId -> set of unique dates
      
      for (final job in vehicleJobsResponse) {
        final vehicleId = job['vehicle_id'].toString();
        final jobId = job['id'] as int;
        if (!vehicleStats.containsKey(vehicleId)) {
          vehicleStats[vehicleId] = {'count': 0, 'revenue': 0.0, 'mileage': 0.0, 'jobsWithMileage': 0};
          vehicleJobDays[vehicleId] = <String>{};
        }
        vehicleStats[vehicleId]!['count']++;
        if (job['amount'] != null) {
          vehicleStats[vehicleId]!['revenue'] += (job['amount'] as num).toDouble();
        }
        
        // Add mileage if available
        if (jobMileage.containsKey(jobId)) {
          vehicleStats[vehicleId]!['mileage'] += jobMileage[jobId]!;
          vehicleStats[vehicleId]!['jobsWithMileage']++;
        }
        
        // Track unique days with jobs for utilization
        final jobDate = job['created_at'] != null 
            ? DateTime.parse(job['created_at']).toIso8601String().split('T')[0]
            : null;
        if (jobDate != null) {
          vehicleJobDays[vehicleId]!.add(jobDate);
        }
      }

      // Calculate averages
      final totalVehicleJobs = vehicleStats.values.fold<int>(0, (sum, stats) => sum + (stats['count'] as int));
      final totalVehicleRevenue = vehicleStats.values.fold<double>(0.0, (sum, stats) => sum + stats['revenue']);
      final totalVehicleMileage = vehicleStats.values.fold<double>(0.0, (sum, stats) => sum + (stats['mileage'] as double));
      final totalJobsWithMileage = vehicleStats.values.fold<int>(0, (sum, stats) => sum + (stats['jobsWithMileage'] as int));
      final vehiclesWithJobsCount = vehicleStats.length; // Only vehicles that actually had jobs
      // Average jobs per vehicle: calculate across vehicles that had jobs, but also show overall average
      final averageJobsPerVehicle = vehiclesWithJobsCount > 0 
          ? totalVehicleJobs / vehiclesWithJobsCount 
          : (totalVehicles > 0 ? totalVehicleJobs / totalVehicles : 0.0);
      final averageRevenuePerVehicle = vehiclesWithJobsCount > 0 
          ? totalVehicleRevenue / vehiclesWithJobsCount 
          : (totalVehicles > 0 ? totalVehicleRevenue / totalVehicles : 0.0);
      final averageMileagePerVehicle = vehiclesWithJobsCount > 0 
          ? totalVehicleMileage / vehiclesWithJobsCount 
          : (totalVehicles > 0 ? totalVehicleMileage / totalVehicles : 0.0);
      final averageMileagePerJob = totalJobsWithMileage > 0 ? totalVehicleMileage / totalJobsWithMileage : 0.0;

      // Build vehicle details map
      final vehicleDetails = <String, Map<String, dynamic>>{};
      final vehiclesByBranch = <String, int>{};
      final branchUtilization = <String, List<double>>{};
      
      for (final vehicle in vehiclesResponse) {
        final vehicleId = vehicle['id'].toString();
        vehicleDetails[vehicleId] = vehicle;
        
        // Track vehicles by branch
        final vehicleBranchId = vehicle['branch_id'];
        if (vehicleBranchId != null) {
          try {
            final branchResponse = await _supabase
                .from('branches')
                .select('name')
                .eq('id', vehicleBranchId)
                .maybeSingle();
            final branchName = branchResponse?['name'] ?? 'Unknown Branch';
            vehiclesByBranch[branchName] = (vehiclesByBranch[branchName] ?? 0) + 1;
          } catch (_) {}
        }
      }

      // Build TopVehicle list with utilization and efficiency scores
      final allTopVehicles = <TopVehicle>[];
      double totalUtilizationRate = 0.0;
      int vehiclesWithJobs = 0;
      
      for (final entry in vehicleStats.entries) {
        final vehicleId = entry.key;
        final stats = entry.value;
        final vehicle = vehicleDetails[vehicleId] ?? 
            {'make': 'Unknown', 'model': 'Unknown', 'reg_plate': 'Unknown', 'branch_id': null};
        
        // Calculate utilization rate
        final daysWithJobs = vehicleJobDays[vehicleId]?.length ?? 0;
        final utilizationRate = daysInPeriod > 0 ? (daysWithJobs / daysInPeriod) * 100 : 0.0;
        totalUtilizationRate += utilizationRate;
        if (daysWithJobs > 0) vehiclesWithJobs++;
        
        // Calculate efficiency score
        final efficiencyScore = stats['count'] * stats['revenue'];
        
        // Calculate mileage metrics
        final totalMileage = stats['mileage'] as double;
        final jobsWithMileage = stats['jobsWithMileage'] as int;
        final avgMileagePerJob = jobsWithMileage > 0 ? totalMileage / jobsWithMileage : null;
        
        // Get branch name
        String? branchName;
        final vehicleBranchId = vehicle['branch_id'];
        if (vehicleBranchId != null) {
          try {
            final branchResponse = await _supabase
                .from('branches')
                .select('name')
                .eq('id', vehicleBranchId)
                .maybeSingle();
            branchName = branchResponse?['name'];
            if (branchName != null) {
              branchUtilization[branchName] ??= [];
              branchUtilization[branchName]!.add(utilizationRate);
            }
          } catch (_) {}
        }
        
        allTopVehicles.add(TopVehicle(
          vehicleId: vehicleId,
          vehicleName: '${vehicle['make']} ${vehicle['model']}',
          registration: vehicle['reg_plate'] ?? 'Unknown',
          jobCount: stats['count'],
          revenue: stats['revenue'],
          utilizationRate: utilizationRate,
          efficiencyScore: efficiencyScore,
          totalMileage: totalMileage > 0 ? totalMileage : null,
          averageMileagePerJob: avgMileagePerJob,
        ));
      }
      
      // Calculate average utilization rate
      final averageUtilizationRate = vehiclesWithJobs > 0 
          ? totalUtilizationRate / vehiclesWithJobs 
          : 0.0;
      
      // Sort by job count and take top 5
      final topVehiclesByJobs = List<TopVehicle>.from(allTopVehicles);
      topVehiclesByJobs.sort((a, b) => b.jobCount.compareTo(a.jobCount));
      final topVehiclesList = topVehiclesByJobs.take(5).toList();
      
      // Sort by revenue and take top 5
      final topVehiclesByRevenue = List<TopVehicle>.from(allTopVehicles);
      topVehiclesByRevenue.sort((a, b) => b.revenue.compareTo(a.revenue));
      final topVehiclesByRevenueList = topVehiclesByRevenue.take(5).toList();
      
      // Identify underutilized vehicles
      final underutilizedVehicles = <UnderutilizedVehicle>[];
      for (final vehicle in allTopVehicles) {
        if (vehicle.jobCount < 3 || (vehicle.utilizationRate ?? 0) < 30.0) {
          final vehicleData = vehicleDetails[vehicle.vehicleId] ?? {};
          String? branchName;
          final vehicleBranchId = vehicleData['branch_id'];
          if (vehicleBranchId != null) {
            try {
              final branchResponse = await _supabase
                  .from('branches')
                  .select('name')
                  .eq('id', vehicleBranchId)
                  .maybeSingle();
              branchName = branchResponse?['name'];
            } catch (_) {}
          }
          
          underutilizedVehicles.add(UnderutilizedVehicle(
            vehicleId: vehicle.vehicleId,
            vehicleName: vehicle.vehicleName,
            registration: vehicle.registration,
            jobCount: vehicle.jobCount,
            revenue: vehicle.revenue,
            utilizationRate: vehicle.utilizationRate ?? 0.0,
            branchName: branchName,
          ));
        }
      }
      
      // Check license expiry dates
      final licenseExpiringSoon = <VehicleLicenseAlert>[];
      final now = DateTime.now();
      for (final vehicle in vehiclesResponse) {
        final expiryDate = vehicle['license_expiry_date'];
        if (expiryDate != null) {
          try {
            final expiry = DateTime.parse(expiryDate);
            final daysUntilExpiry = expiry.difference(now).inDays;
            if (daysUntilExpiry <= 30) {
              licenseExpiringSoon.add(VehicleLicenseAlert(
                vehicleId: vehicle['id'].toString(),
                vehicleName: '${vehicle['make']} ${vehicle['model']}',
                registration: vehicle['reg_plate'] ?? 'Unknown',
                licenseExpiryDate: expiry,
                daysUntilExpiry: daysUntilExpiry,
              ));
            }
          } catch (_) {
            // Invalid date format, skip
          }
        }
      }
      
      // Calculate average utilization by branch
      final utilizationByBranch = <String, double>{};
      for (final entry in branchUtilization.entries) {
        if (entry.value.isNotEmpty) {
          final avgUtilization = entry.value.reduce((a, b) => a + b) / entry.value.length;
          utilizationByBranch[entry.key] = avgUtilization;
        }
      }

      final vehicleInsights = VehicleInsights(
        totalVehicles: totalVehicles,
        activeVehicles: activeVehicles,
        inactiveVehicles: inactiveVehicles,
        underMaintenanceVehicles: underMaintenanceVehicles,
        averageJobsPerVehicle: averageJobsPerVehicle,
        averageIncomePerVehicle: averageRevenuePerVehicle,
        averageUtilizationRate: averageUtilizationRate,
        averageMileagePerVehicle: averageMileagePerVehicle,
        averageMileagePerJob: averageMileagePerJob,
        topVehicles: topVehiclesList,
        topVehiclesByRevenue: topVehiclesByRevenueList,
        underutilizedVehicles: underutilizedVehicles,
        licenseExpiringSoon: licenseExpiringSoon,
        vehiclesByBranch: vehiclesByBranch,
        utilizationByBranch: utilizationByBranch,
      );

      Log.d('Vehicle insights with location filter: ${vehicleInsights.totalVehicles} vehicles, ${vehicleInsights.averageJobsPerVehicle.toStringAsFixed(1)} avg jobs');
      return Result.success(vehicleInsights);
    } catch (error) {
      Log.e('Error fetching vehicle insights with location filter: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Fetch client insights
  Future<Result<ClientInsights>> _fetchClientInsights(DateRange dateRange) async {
    try {
      Log.d('Fetching client insights...');
      
      // Fetch all clients with status and dates
      final clientsResponse = await _supabase
          .from('clients')
          .select('id, company_name, status, created_at, deleted_at');
      
      Log.d('Clients query returned ${clientsResponse.length} records');

      final totalClients = clientsResponse.length;
      
      // Calculate client status breakdown
      int activeClients = 0;
      int vipClients = 0;
      int pendingClients = 0;
      int inactiveClients = 0;
      final clientsByStatus = <String, int>{};
      
      for (final client in clientsResponse) {
        final status = (client['status'] as String?)?.toLowerCase() ?? 'active';
        final deletedAt = client['deleted_at'];
        final isDeleted = deletedAt != null;
        
        if (isDeleted) {
          inactiveClients++;
        } else {
          switch (status) {
            case 'active':
              activeClients++;
              break;
            case 'vip':
              vipClients++;
              activeClients++; // VIP is also active
              break;
            case 'pending':
              pendingClients++;
              break;
            case 'inactive':
              inactiveClients++;
              break;
          }
        }
        
        clientsByStatus[status] = (clientsByStatus[status] ?? 0) + 1;
      }

      // Fetch all jobs (period and all-time for engagement metrics)
      final clientJobsResponse = await _supabase
          .from('jobs')
          .select('client_id, amount, job_status, created_at')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String())
          .not('client_id', 'is', null);

      // Fetch all-time jobs for engagement metrics
      final allTimeJobsResponse = await _supabase
          .from('jobs')
          .select('client_id, amount, created_at')
          .not('client_id', 'is', null);

      // Fetch quotes (period and all-time)
      final clientQuotesResponse = await _supabase
          .from('quotes')
          .select('client_id, agent_id, quote_amount, quote_status, created_at')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String())
          .not('client_id', 'is', null);

      // Fetch all-time quotes
      final allTimeQuotesResponse = await _supabase
          .from('quotes')
          .select('client_id, quote_amount, created_at')
          .not('client_id', 'is', null);

      // Fetch agents
      final agentsResponse = await _supabase
          .from('agents')
          .select('id, agent_name, client_key, is_deleted')
          .eq('is_deleted', false);

      // Build client details map
      final clientDetails = <String, Map<String, dynamic>>{};
      for (final client in clientsResponse) {
        final clientId = client['id'].toString();
        clientDetails[clientId] = {
          'company_name': client['company_name'],
          'status': client['status'],
          'created_at': client['created_at'],
          'deleted_at': client['deleted_at'],
        };
      }

      // Group by client for period stats
      final clientStats = <String, Map<String, dynamic>>{};
      final clientAllTimeStats = <String, Map<String, dynamic>>{};
      final clientFirstActivity = <String, DateTime?>{};
      final clientLastActivity = <String, DateTime?>{};
      final clientJobStatuses = <String, Map<String, int>>{};
      final clientQuoteStatuses = <String, Map<String, int>>{};
      final agentStats = <String, Map<String, dynamic>>{}; // agentId -> stats
      final clientAgentMap = <String, Set<String>>{}; // clientId -> Set<agentId>
      
      // Process period jobs
      for (final job in clientJobsResponse) {
        final clientId = job['client_id'].toString();
        if (!clientStats.containsKey(clientId)) {
          clientStats[clientId] = {
            'jobCount': 0,
            'jobRevenue': 0.0,
            'quoteCount': 0,
            'quoteValue': 0.0,
            'jobs': [],
            'quotes': [],
          };
          clientJobStatuses[clientId] = {};
        }
        clientStats[clientId]!['jobCount']++;
        final jobStatus = (job['job_status'] as String?)?.toLowerCase() ?? 'open';
        clientJobStatuses[clientId]![jobStatus] = (clientJobStatuses[clientId]![jobStatus] ?? 0) + 1;
        if (job['amount'] != null) {
          clientStats[clientId]!['jobRevenue'] += (job['amount'] as num).toDouble();
        }
        final createdAt = job['created_at'] != null ? DateTime.parse(job['created_at']) : null;
        if (createdAt != null) {
          if (clientLastActivity[clientId] == null || createdAt.isAfter(clientLastActivity[clientId]!)) {
            clientLastActivity[clientId] = createdAt;
          }
          if (clientFirstActivity[clientId] == null || createdAt.isBefore(clientFirstActivity[clientId]!)) {
            clientFirstActivity[clientId] = createdAt;
          }
        }
      }

      // Process all-time jobs
      for (final job in allTimeJobsResponse) {
        final clientId = job['client_id'].toString();
        if (!clientAllTimeStats.containsKey(clientId)) {
          clientAllTimeStats[clientId] = {'jobCount': 0, 'jobRevenue': 0.0};
        }
        clientAllTimeStats[clientId]!['jobCount']++;
        if (job['amount'] != null) {
          clientAllTimeStats[clientId]!['jobRevenue'] += (job['amount'] as num).toDouble();
        }
        final createdAt = job['created_at'] != null ? DateTime.parse(job['created_at']) : null;
        if (createdAt != null) {
          if (clientLastActivity[clientId] == null || createdAt.isAfter(clientLastActivity[clientId]!)) {
            clientLastActivity[clientId] = createdAt;
          }
          if (clientFirstActivity[clientId] == null || createdAt.isBefore(clientFirstActivity[clientId]!)) {
            clientFirstActivity[clientId] = createdAt;
          }
        }
      }

      // Process period quotes
      for (final quote in clientQuotesResponse) {
        final clientId = quote['client_id'].toString();
        final agentId = quote['agent_id']?.toString();
        
        if (!clientStats.containsKey(clientId)) {
          clientStats[clientId] = {
            'jobCount': 0,
            'jobRevenue': 0.0,
            'quoteCount': 0,
            'quoteValue': 0.0,
            'jobs': [],
            'quotes': [],
          };
          clientQuoteStatuses[clientId] = {};
        }
        clientStats[clientId]!['quoteCount']++;
        final quoteStatus = (quote['quote_status'] as String?)?.toLowerCase() ?? 'draft';
        clientQuoteStatuses[clientId]![quoteStatus] = (clientQuoteStatuses[clientId]![quoteStatus] ?? 0) + 1;
        if (quote['quote_amount'] != null) {
          clientStats[clientId]!['quoteValue'] += (quote['quote_amount'] as num).toDouble();
        }
        
        // Track agent relationships
        if (agentId != null) {
          clientAgentMap.putIfAbsent(clientId, () => <String>{}).add(agentId);
          if (!agentStats.containsKey(agentId)) {
            agentStats[agentId] = {
              'jobCount': 0,
              'quoteCount': 0,
              'totalValue': 0.0,
              'clientId': clientId,
            };
          }
          agentStats[agentId]!['quoteCount']++;
          if (quote['quote_amount'] != null) {
            agentStats[agentId]!['totalValue'] += (quote['quote_amount'] as num).toDouble();
          }
        }
        
        final createdAt = quote['created_at'] != null ? DateTime.parse(quote['created_at']) : null;
        if (createdAt != null) {
          if (clientLastActivity[clientId] == null || createdAt.isAfter(clientLastActivity[clientId]!)) {
            clientLastActivity[clientId] = createdAt;
          }
          if (clientFirstActivity[clientId] == null || createdAt.isBefore(clientFirstActivity[clientId]!)) {
            clientFirstActivity[clientId] = createdAt;
          }
        }
      }

      // Process all-time quotes
      for (final quote in allTimeQuotesResponse) {
        final clientId = quote['client_id'].toString();
        final createdAt = quote['created_at'] != null ? DateTime.parse(quote['created_at']) : null;
        if (createdAt != null) {
          if (clientLastActivity[clientId] == null || createdAt.isAfter(clientLastActivity[clientId]!)) {
            clientLastActivity[clientId] = createdAt;
          }
          if (clientFirstActivity[clientId] == null || createdAt.isBefore(clientFirstActivity[clientId]!)) {
            clientFirstActivity[clientId] = createdAt;
          }
        }
      }

      // Process agent jobs
      final agentJobsResponse = await _supabase
          .from('jobs')
          .select('client_id, agent_id, amount')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String())
          .not('agent_id', 'is', null);
      
      for (final job in agentJobsResponse) {
        final agentId = job['agent_id'].toString();
        final clientId = job['client_id'].toString();
        if (!agentStats.containsKey(agentId)) {
          agentStats[agentId] = {
            'jobCount': 0,
            'quoteCount': 0,
            'totalValue': 0.0,
            'clientId': clientId,
          };
        }
        agentStats[agentId]!['jobCount']++;
        if (job['amount'] != null) {
          agentStats[agentId]!['totalValue'] += (job['amount'] as num).toDouble();
        }
      }

      // Calculate job status breakdown (aggregated)
      final jobsByStatus = <String, int>{};
      for (final job in clientJobsResponse) {
        final status = (job['job_status'] as String?)?.toLowerCase() ?? 'open';
        jobsByStatus[status] = (jobsByStatus[status] ?? 0) + 1;
      }

      // Calculate quote status breakdown (aggregated)
      final quotesByStatus = <String, int>{};
      for (final quote in clientQuotesResponse) {
        final status = (quote['quote_status'] as String?)?.toLowerCase() ?? 'draft';
        quotesByStatus[status] = (quotesByStatus[status] ?? 0) + 1;
      }

      // Calculate revenue by status
      final revenueByStatus = <String, double>{};
      for (final entry in clientStats.entries) {
        final clientId = entry.key;
        final client = clientDetails[clientId];
        final status = (client?['status'] as String?)?.toLowerCase() ?? 'active';
        final revenue = (entry.value['jobRevenue'] as double) + (entry.value['quoteValue'] as double);
        revenueByStatus[status] = (revenueByStatus[status] ?? 0.0) + revenue;
      }

      // Calculate clients by tier (VIP vs Regular)
      final clientsByTier = <String, int>{'VIP': vipClients, 'Regular': activeClients - vipClients};
      final revenueByTier = <String, double>{'VIP': 0.0, 'Regular': 0.0};
      for (final entry in clientStats.entries) {
        final clientId = entry.key;
        final client = clientDetails[clientId];
        final status = (client?['status'] as String?)?.toLowerCase() ?? 'active';
        final revenue = (entry.value['jobRevenue'] as double) + (entry.value['quoteValue'] as double);
        if (status == 'vip') {
          revenueByTier['VIP'] = (revenueByTier['VIP'] ?? 0.0) + revenue;
        } else {
          revenueByTier['Regular'] = (revenueByTier['Regular'] ?? 0.0) + revenue;
        }
      }

      // Calculate averages
      final totalJobCount = clientStats.values.fold<int>(0, (sum, stats) => sum + (stats['jobCount'] as int));
      final totalQuoteCount = clientStats.values.fold<int>(0, (sum, stats) => sum + (stats['quoteCount'] as int));
      final totalJobRevenue = clientStats.values.fold<double>(0.0, (sum, stats) => sum + (stats['jobRevenue'] as double));
      final totalQuoteValue = clientStats.values.fold<double>(0.0, (sum, stats) => sum + (stats['quoteValue'] as double));
      
      final averageJobsPerClient = totalClients > 0 ? totalJobCount / totalClients : 0.0;
      final averageQuotesPerClient = totalClients > 0 ? totalQuoteCount / totalClients : 0.0;
      final averageRevenuePerClient = totalClients > 0 ? (totalJobRevenue + totalQuoteValue) / totalClients : 0.0;
      final averageJobValuePerClient = clientStats.isNotEmpty ? totalJobRevenue / clientStats.length : 0.0;
      final averageQuoteValuePerClient = clientStats.isNotEmpty ? totalQuoteValue / clientStats.length : 0.0;

      // Calculate quote-to-job conversion rate
      final clientsWithQuotes = clientStats.values.where((s) => (s['quoteCount'] as int) > 0).length;
      final clientsWithJobsFromQuotes = clientStats.values.where((s) => 
        (s['quoteCount'] as int) > 0 && (s['jobCount'] as int) > 0
      ).length;
      final quoteToJobConversionRate = clientsWithQuotes > 0 
          ? (clientsWithJobsFromQuotes / clientsWithQuotes) * 100 
          : 0.0;

      // Calculate average agents per client
      final totalAgents = clientAgentMap.values.fold<int>(0, (sum, agents) => sum + agents.length);
      final averageAgentsPerClient = clientAgentMap.isNotEmpty ? totalAgents / clientAgentMap.length : 0.0;

      // Build TopClient list with all details
      final allTopClients = <TopClient>[];
      final now = DateTime.now();
      
      for (final entry in clientStats.entries) {
        final clientId = entry.key;
        final stats = entry.value;
        final client = clientDetails[clientId] ?? {};
        final jobRevenue = stats['jobRevenue'] as double;
        final quoteValue = stats['quoteValue'] as double;
        final jobCount = stats['jobCount'] as int;
        final quoteCount = stats['quoteCount'] as int;
        final conversionRate = quoteCount > 0 ? (jobCount / quoteCount) * 100 : null;
        final avgJobValue = jobCount > 0 ? jobRevenue / jobCount : null;
        final avgQuoteValue = quoteCount > 0 ? quoteValue / quoteCount : null;
        final agentCount = clientAgentMap[clientId]?.length;
        final lastActivity = clientLastActivity[clientId];
        final daysSinceLastActivity = lastActivity != null ? now.difference(lastActivity).inDays : null;
        
        allTopClients.add(TopClient(
          clientId: clientId,
          clientName: client['company_name'] ?? 'Unknown Client',
          clientStatus: client['status'] as String?,
          jobCount: jobCount,
          quoteCount: quoteCount,
          jobRevenue: jobRevenue,
          quoteValue: quoteValue,
          totalValue: jobRevenue + quoteValue,
          conversionRate: conversionRate,
          averageJobValue: avgJobValue,
          averageQuoteValue: avgQuoteValue,
          agentCount: agentCount,
          lastActivityDate: lastActivity,
          daysSinceLastActivity: daysSinceLastActivity,
        ));
      }

      // Sort and create top lists
      final topClientsByTotal = List<TopClient>.from(allTopClients);
      topClientsByTotal.sort((a, b) => b.totalValue.compareTo(a.totalValue));
      
      final topClientsByJobs = List<TopClient>.from(allTopClients);
      topClientsByJobs.sort((a, b) => b.jobCount.compareTo(a.jobCount));
      
      final topClientsByRevenue = List<TopClient>.from(allTopClients);
      topClientsByRevenue.sort((a, b) => b.jobRevenue.compareTo(a.jobRevenue));
      
      final topClientsByQuotes = List<TopClient>.from(allTopClients);
      topClientsByQuotes.sort((a, b) => b.quoteValue.compareTo(a.quoteValue));
      
      final topClientsByConversion = List<TopClient>.from(allTopClients.where((c) => c.conversionRate != null));
      topClientsByConversion.sort((a, b) => (b.conversionRate ?? 0).compareTo(a.conversionRate ?? 0));

      // Identify at-risk clients (no activity in 30+ days)
      final atRiskClientsList = <AtRiskClient>[];
      for (final clientId in clientDetails.keys) {
        final lastActivity = clientLastActivity[clientId];
        if (lastActivity != null) {
          final daysSince = now.difference(lastActivity).inDays;
          if (daysSince >= 30) {
            final allTimeStats = clientAllTimeStats[clientId] ?? {'jobCount': 0, 'jobRevenue': 0.0};
            final allTimeQuotes = allTimeQuotesResponse.where((q) => q['client_id'].toString() == clientId).length;
            final client = clientDetails[clientId] ?? {};
            atRiskClientsList.add(AtRiskClient(
              clientId: clientId,
              clientName: client['company_name'] ?? 'Unknown Client',
              lastActivityDate: lastActivity,
              daysSinceLastActivity: daysSince,
              totalJobs: allTimeStats['jobCount'] as int,
              totalQuotes: allTimeQuotes,
              lifetimeValue: allTimeStats['jobRevenue'] as double,
            ));
          }
        }
      }
      atRiskClientsList.sort((a, b) => b.daysSinceLastActivity.compareTo(a.daysSinceLastActivity));

      // Identify new clients (first activity in period)
      final newClientsList = <NewClient>[];
      for (final entry in clientStats.entries) {
        final clientId = entry.key;
        final firstActivity = clientFirstActivity[clientId];
        if (firstActivity != null && 
            firstActivity.isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
            firstActivity.isBefore(dateRange.end.add(const Duration(days: 1)))) {
          final stats = entry.value;
          final client = clientDetails[clientId] ?? {};
          newClientsList.add(NewClient(
            clientId: clientId,
            clientName: client['company_name'] ?? 'Unknown Client',
            firstActivityDate: firstActivity,
            jobCount: stats['jobCount'] as int,
            quoteCount: stats['quoteCount'] as int,
            revenue: (stats['jobRevenue'] as double) + (stats['quoteValue'] as double),
          ));
        }
      }

      // Build top agents list
      final topAgentsList = <TopAgent>[];
      for (final entry in agentStats.entries) {
        final agentId = entry.key;
        final stats = entry.value;
        final agent = agentsResponse.firstWhere(
          (a) => a['id'].toString() == agentId,
          orElse: () => {'agent_name': 'Unknown Agent'},
        );
        final clientId = stats['clientId'] as String;
        final client = clientDetails[clientId] ?? {};
        topAgentsList.add(TopAgent(
          agentId: agentId,
          agentName: agent['agent_name'] ?? 'Unknown Agent',
          clientId: clientId,
          clientName: client['company_name'] ?? 'Unknown Client',
          jobCount: stats['jobCount'] as int,
          quoteCount: stats['quoteCount'] as int,
          totalValue: stats['totalValue'] as double,
        ));
      }
      topAgentsList.sort((a, b) => b.totalValue.compareTo(a.totalValue));

      final insights = ClientInsights(
        totalClients: totalClients,
        activeClients: activeClients,
        vipClients: vipClients,
        pendingClients: pendingClients,
        inactiveClients: inactiveClients,
        newClients: newClientsList.length,
        atRiskClients: atRiskClientsList.length,
        averageJobsPerClient: averageJobsPerClient,
        averageRevenuePerClient: averageRevenuePerClient,
        averageJobValuePerClient: averageJobValuePerClient,
        averageQuoteValuePerClient: averageQuoteValuePerClient,
        averageQuotesPerClient: averageQuotesPerClient,
        quoteToJobConversionRate: quoteToJobConversionRate,
        averageAgentsPerClient: averageAgentsPerClient,
        topClients: topClientsByTotal.take(5).toList(),
        topClientsByJobs: topClientsByJobs.take(5).toList(),
        topClientsByRevenue: topClientsByRevenue.take(5).toList(),
        topClientsByQuotes: topClientsByQuotes.take(5).toList(),
        topClientsByConversionRate: topClientsByConversion.take(5).toList(),
        atRiskClientsList: atRiskClientsList.take(10).toList(),
        newClientsList: newClientsList,
        topAgents: topAgentsList.take(10).toList(),
        clientsByStatus: clientsByStatus,
        revenueByStatus: revenueByStatus,
        jobsByStatus: jobsByStatus,
        quotesByStatus: quotesByStatus,
        clientsByTier: clientsByTier,
        revenueByTier: revenueByTier,
      );

      return Result.success(insights);
    } catch (error) {
      Log.e('Error fetching client insights: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Fetch client insights with location filtering
  Future<Result<ClientInsights>> _fetchClientInsightsWithLocation(DateRange dateRange, LocationFilter location) async {
    try {
      Log.d('Fetching client insights with location filter: ${location.displayName}...');
      
      // Map location filter to branch_id
      final branchId = _locationFilterToBranchId(location);

      // Fetch all clients with status and dates
      final clientsResponse = await _supabase
          .from('clients')
          .select('id, company_name, status, created_at, deleted_at');
      
      Log.d('Clients query returned ${clientsResponse.length} records');

      final totalClients = clientsResponse.length;
      
      // Calculate client status breakdown
      int activeClients = 0;
      int vipClients = 0;
      int pendingClients = 0;
      int inactiveClients = 0;
      final clientsByStatus = <String, int>{};
      
      for (final client in clientsResponse) {
        final status = (client['status'] as String?)?.toLowerCase() ?? 'active';
        final deletedAt = client['deleted_at'];
        final isDeleted = deletedAt != null;
        
        if (isDeleted) {
          inactiveClients++;
        } else {
          switch (status) {
            case 'active':
              activeClients++;
              break;
            case 'vip':
              vipClients++;
              activeClients++; // VIP is also active
              break;
            case 'pending':
              pendingClients++;
              break;
            case 'inactive':
              inactiveClients++;
              break;
          }
        }
        
        clientsByStatus[status] = (clientsByStatus[status] ?? 0) + 1;
      }

      // Fetch jobs with branch filter
      var clientJobsQuery = _supabase
          .from('jobs')
          .select('client_id, agent_id, amount, job_status, created_at')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String())
          .not('client_id', 'is', null);
      
      if (branchId != null) {
        clientJobsQuery = clientJobsQuery.eq('branch_id', branchId);
      } else if (location == LocationFilter.unspecified) {
        clientJobsQuery = clientJobsQuery.isFilter('branch_id', null);
      }
      
      final clientJobsResponse = await clientJobsQuery;

      // Fetch all-time jobs (no branch filter for engagement metrics)
      final allTimeJobsResponse = await _supabase
          .from('jobs')
          .select('client_id, amount, created_at')
          .not('client_id', 'is', null);

      // Fetch quotes (no branch filter - quotes don't have branch_id)
      final clientQuotesResponse = await _supabase
          .from('quotes')
          .select('client_id, agent_id, quote_amount, quote_status, created_at')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String())
          .not('client_id', 'is', null);

      // Fetch all-time quotes
      final allTimeQuotesResponse = await _supabase
          .from('quotes')
          .select('client_id, quote_amount, created_at')
          .not('client_id', 'is', null);

      // Fetch agents
      final agentsResponse = await _supabase
          .from('agents')
          .select('id, agent_name, client_key, is_deleted')
          .eq('is_deleted', false);

      // Build client details map
      final clientDetails = <String, Map<String, dynamic>>{};
      for (final client in clientsResponse) {
        final clientId = client['id'].toString();
        clientDetails[clientId] = {
          'company_name': client['company_name'],
          'status': client['status'],
          'created_at': client['created_at'],
          'deleted_at': client['deleted_at'],
        };
      }

      // Group by client for period stats (same logic as _fetchClientInsights)
      final clientStats = <String, Map<String, dynamic>>{};
      final clientAllTimeStats = <String, Map<String, dynamic>>{};
      final clientFirstActivity = <String, DateTime?>{};
      final clientLastActivity = <String, DateTime?>{};
      final clientJobStatuses = <String, Map<String, int>>{};
      final clientQuoteStatuses = <String, Map<String, int>>{};
      final agentStats = <String, Map<String, dynamic>>{};
      final clientAgentMap = <String, Set<String>>{};
      
      // Process period jobs
      for (final job in clientJobsResponse) {
        final clientId = job['client_id'].toString();
        if (!clientStats.containsKey(clientId)) {
          clientStats[clientId] = {
            'jobCount': 0,
            'jobRevenue': 0.0,
            'quoteCount': 0,
            'quoteValue': 0.0,
            'jobs': [],
            'quotes': [],
          };
          clientJobStatuses[clientId] = {};
        }
        clientStats[clientId]!['jobCount']++;
        final jobStatus = (job['job_status'] as String?)?.toLowerCase() ?? 'open';
        clientJobStatuses[clientId]![jobStatus] = (clientJobStatuses[clientId]![jobStatus] ?? 0) + 1;
        if (job['amount'] != null) {
          clientStats[clientId]!['jobRevenue'] += (job['amount'] as num).toDouble();
        }
        final createdAt = job['created_at'] != null ? DateTime.parse(job['created_at']) : null;
        if (createdAt != null) {
          if (clientLastActivity[clientId] == null || createdAt.isAfter(clientLastActivity[clientId]!)) {
            clientLastActivity[clientId] = createdAt;
          }
          if (clientFirstActivity[clientId] == null || createdAt.isBefore(clientFirstActivity[clientId]!)) {
            clientFirstActivity[clientId] = createdAt;
          }
        }
      }

      // Process all-time jobs
      for (final job in allTimeJobsResponse) {
        final clientId = job['client_id'].toString();
        if (!clientAllTimeStats.containsKey(clientId)) {
          clientAllTimeStats[clientId] = {'jobCount': 0, 'jobRevenue': 0.0};
        }
        clientAllTimeStats[clientId]!['jobCount']++;
        if (job['amount'] != null) {
          clientAllTimeStats[clientId]!['jobRevenue'] += (job['amount'] as num).toDouble();
        }
        final createdAt = job['created_at'] != null ? DateTime.parse(job['created_at']) : null;
        if (createdAt != null) {
          if (clientLastActivity[clientId] == null || createdAt.isAfter(clientLastActivity[clientId]!)) {
            clientLastActivity[clientId] = createdAt;
          }
          if (clientFirstActivity[clientId] == null || createdAt.isBefore(clientFirstActivity[clientId]!)) {
            clientFirstActivity[clientId] = createdAt;
          }
        }
      }

      // Process period quotes
      for (final quote in clientQuotesResponse) {
        final clientId = quote['client_id'].toString();
        final agentId = quote['agent_id']?.toString();
        
        if (!clientStats.containsKey(clientId)) {
          clientStats[clientId] = {
            'jobCount': 0,
            'jobRevenue': 0.0,
            'quoteCount': 0,
            'quoteValue': 0.0,
            'jobs': [],
            'quotes': [],
          };
          clientQuoteStatuses[clientId] = {};
        }
        clientStats[clientId]!['quoteCount']++;
        final quoteStatus = (quote['quote_status'] as String?)?.toLowerCase() ?? 'draft';
        clientQuoteStatuses[clientId]![quoteStatus] = (clientQuoteStatuses[clientId]![quoteStatus] ?? 0) + 1;
        if (quote['quote_amount'] != null) {
          clientStats[clientId]!['quoteValue'] += (quote['quote_amount'] as num).toDouble();
        }
        
        if (agentId != null) {
          clientAgentMap.putIfAbsent(clientId, () => <String>{}).add(agentId);
          if (!agentStats.containsKey(agentId)) {
            agentStats[agentId] = {
              'jobCount': 0,
              'quoteCount': 0,
              'totalValue': 0.0,
              'clientId': clientId,
            };
          }
          agentStats[agentId]!['quoteCount']++;
          if (quote['quote_amount'] != null) {
            agentStats[agentId]!['totalValue'] += (quote['quote_amount'] as num).toDouble();
          }
        }
        
        final createdAt = quote['created_at'] != null ? DateTime.parse(quote['created_at']) : null;
        if (createdAt != null) {
          if (clientLastActivity[clientId] == null || createdAt.isAfter(clientLastActivity[clientId]!)) {
            clientLastActivity[clientId] = createdAt;
          }
          if (clientFirstActivity[clientId] == null || createdAt.isBefore(clientFirstActivity[clientId]!)) {
            clientFirstActivity[clientId] = createdAt;
          }
        }
      }

      // Process all-time quotes
      for (final quote in allTimeQuotesResponse) {
        final clientId = quote['client_id'].toString();
        final createdAt = quote['created_at'] != null ? DateTime.parse(quote['created_at']) : null;
        if (createdAt != null) {
          if (clientLastActivity[clientId] == null || createdAt.isAfter(clientLastActivity[clientId]!)) {
            clientLastActivity[clientId] = createdAt;
          }
          if (clientFirstActivity[clientId] == null || createdAt.isBefore(clientFirstActivity[clientId]!)) {
            clientFirstActivity[clientId] = createdAt;
          }
        }
      }

      // Process agent jobs
      var agentJobsQuery = _supabase
          .from('jobs')
          .select('client_id, agent_id, amount')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String())
          .not('agent_id', 'is', null);
      
      if (branchId != null) {
        agentJobsQuery = agentJobsQuery.eq('branch_id', branchId);
      } else if (location == LocationFilter.unspecified) {
        agentJobsQuery = agentJobsQuery.isFilter('branch_id', null);
      }
      
      final agentJobsResponse = await agentJobsQuery;
      
      for (final job in agentJobsResponse) {
        final agentId = job['agent_id'].toString();
        final clientId = job['client_id'].toString();
        if (!agentStats.containsKey(agentId)) {
          agentStats[agentId] = {
            'jobCount': 0,
            'quoteCount': 0,
            'totalValue': 0.0,
            'clientId': clientId,
          };
        }
        agentStats[agentId]!['jobCount']++;
        if (job['amount'] != null) {
          agentStats[agentId]!['totalValue'] += (job['amount'] as num).toDouble();
        }
      }

      // Calculate job status breakdown (aggregated)
      final jobsByStatus = <String, int>{};
      for (final job in clientJobsResponse) {
        final status = (job['job_status'] as String?)?.toLowerCase() ?? 'open';
        jobsByStatus[status] = (jobsByStatus[status] ?? 0) + 1;
      }

      // Calculate quote status breakdown (aggregated)
      final quotesByStatus = <String, int>{};
      for (final quote in clientQuotesResponse) {
        final status = (quote['quote_status'] as String?)?.toLowerCase() ?? 'draft';
        quotesByStatus[status] = (quotesByStatus[status] ?? 0) + 1;
      }

      // Calculate revenue by status
      final revenueByStatus = <String, double>{};
      for (final entry in clientStats.entries) {
        final clientId = entry.key;
        final client = clientDetails[clientId];
        final status = (client?['status'] as String?)?.toLowerCase() ?? 'active';
        final revenue = (entry.value['jobRevenue'] as double) + (entry.value['quoteValue'] as double);
        revenueByStatus[status] = (revenueByStatus[status] ?? 0.0) + revenue;
      }

      // Calculate clients by tier (VIP vs Regular)
      final clientsByTier = <String, int>{'VIP': vipClients, 'Regular': activeClients - vipClients};
      final revenueByTier = <String, double>{'VIP': 0.0, 'Regular': 0.0};
      for (final entry in clientStats.entries) {
        final clientId = entry.key;
        final client = clientDetails[clientId];
        final status = (client?['status'] as String?)?.toLowerCase() ?? 'active';
        final revenue = (entry.value['jobRevenue'] as double) + (entry.value['quoteValue'] as double);
        if (status == 'vip') {
          revenueByTier['VIP'] = (revenueByTier['VIP'] ?? 0.0) + revenue;
        } else {
          revenueByTier['Regular'] = (revenueByTier['Regular'] ?? 0.0) + revenue;
        }
      }

      // Calculate averages
      final totalJobCount = clientStats.values.fold<int>(0, (sum, stats) => sum + (stats['jobCount'] as int));
      final totalQuoteCount = clientStats.values.fold<int>(0, (sum, stats) => sum + (stats['quoteCount'] as int));
      final totalJobRevenue = clientStats.values.fold<double>(0.0, (sum, stats) => sum + (stats['jobRevenue'] as double));
      final totalQuoteValue = clientStats.values.fold<double>(0.0, (sum, stats) => sum + (stats['quoteValue'] as double));
      
      final averageJobsPerClient = totalClients > 0 ? totalJobCount / totalClients : 0.0;
      final averageQuotesPerClient = totalClients > 0 ? totalQuoteCount / totalClients : 0.0;
      final averageRevenuePerClient = totalClients > 0 ? (totalJobRevenue + totalQuoteValue) / totalClients : 0.0;
      final averageJobValuePerClient = clientStats.isNotEmpty ? totalJobRevenue / clientStats.length : 0.0;
      final averageQuoteValuePerClient = clientStats.isNotEmpty ? totalQuoteValue / clientStats.length : 0.0;

      // Calculate quote-to-job conversion rate
      final clientsWithQuotes = clientStats.values.where((s) => (s['quoteCount'] as int) > 0).length;
      final clientsWithJobsFromQuotes = clientStats.values.where((s) => 
        (s['quoteCount'] as int) > 0 && (s['jobCount'] as int) > 0
      ).length;
      final quoteToJobConversionRate = clientsWithQuotes > 0 
          ? (clientsWithJobsFromQuotes / clientsWithQuotes) * 100 
          : 0.0;

      // Calculate average agents per client
      final totalAgents = clientAgentMap.values.fold<int>(0, (sum, agents) => sum + agents.length);
      final averageAgentsPerClient = clientAgentMap.isNotEmpty ? totalAgents / clientAgentMap.length : 0.0;

      // Build TopClient list with all details
      final allTopClients = <TopClient>[];
      final now = DateTime.now();
      
      for (final entry in clientStats.entries) {
        final clientId = entry.key;
        final stats = entry.value;
        final client = clientDetails[clientId] ?? {};
        final jobRevenue = stats['jobRevenue'] as double;
        final quoteValue = stats['quoteValue'] as double;
        final jobCount = stats['jobCount'] as int;
        final quoteCount = stats['quoteCount'] as int;
        final conversionRate = quoteCount > 0 ? (jobCount / quoteCount) * 100 : null;
        final avgJobValue = jobCount > 0 ? jobRevenue / jobCount : null;
        final avgQuoteValue = quoteCount > 0 ? quoteValue / quoteCount : null;
        final agentCount = clientAgentMap[clientId]?.length;
        final lastActivity = clientLastActivity[clientId];
        final daysSinceLastActivity = lastActivity != null ? now.difference(lastActivity).inDays : null;
        
        allTopClients.add(TopClient(
          clientId: clientId,
          clientName: client['company_name'] ?? 'Unknown Client',
          clientStatus: client['status'] as String?,
          jobCount: jobCount,
          quoteCount: quoteCount,
          jobRevenue: jobRevenue,
          quoteValue: quoteValue,
          totalValue: jobRevenue + quoteValue,
          conversionRate: conversionRate,
          averageJobValue: avgJobValue,
          averageQuoteValue: avgQuoteValue,
          agentCount: agentCount,
          lastActivityDate: lastActivity,
          daysSinceLastActivity: daysSinceLastActivity,
        ));
      }

      // Sort and create top lists
      final topClientsByTotal = List<TopClient>.from(allTopClients);
      topClientsByTotal.sort((a, b) => b.totalValue.compareTo(a.totalValue));
      
      final topClientsByJobs = List<TopClient>.from(allTopClients);
      topClientsByJobs.sort((a, b) => b.jobCount.compareTo(a.jobCount));
      
      final topClientsByRevenue = List<TopClient>.from(allTopClients);
      topClientsByRevenue.sort((a, b) => b.jobRevenue.compareTo(a.jobRevenue));
      
      final topClientsByQuotes = List<TopClient>.from(allTopClients);
      topClientsByQuotes.sort((a, b) => b.quoteValue.compareTo(a.quoteValue));
      
      final topClientsByConversion = List<TopClient>.from(allTopClients.where((c) => c.conversionRate != null));
      topClientsByConversion.sort((a, b) => (b.conversionRate ?? 0).compareTo(a.conversionRate ?? 0));

      // Identify at-risk clients (no activity in 30+ days)
      final atRiskClientsList = <AtRiskClient>[];
      for (final clientId in clientDetails.keys) {
        final lastActivity = clientLastActivity[clientId];
        if (lastActivity != null) {
          final daysSince = now.difference(lastActivity).inDays;
          if (daysSince >= 30) {
            final allTimeStats = clientAllTimeStats[clientId] ?? {'jobCount': 0, 'jobRevenue': 0.0};
            final allTimeQuotes = allTimeQuotesResponse.where((q) => q['client_id'].toString() == clientId).length;
            final client = clientDetails[clientId] ?? {};
            atRiskClientsList.add(AtRiskClient(
              clientId: clientId,
              clientName: client['company_name'] ?? 'Unknown Client',
              lastActivityDate: lastActivity,
              daysSinceLastActivity: daysSince,
              totalJobs: allTimeStats['jobCount'] as int,
              totalQuotes: allTimeQuotes,
              lifetimeValue: allTimeStats['jobRevenue'] as double,
            ));
          }
        }
      }
      atRiskClientsList.sort((a, b) => b.daysSinceLastActivity.compareTo(a.daysSinceLastActivity));

      // Identify new clients (first activity in period)
      final newClientsList = <NewClient>[];
      for (final entry in clientStats.entries) {
        final clientId = entry.key;
        final firstActivity = clientFirstActivity[clientId];
        if (firstActivity != null && 
            firstActivity.isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
            firstActivity.isBefore(dateRange.end.add(const Duration(days: 1)))) {
          final stats = entry.value;
          final client = clientDetails[clientId] ?? {};
          newClientsList.add(NewClient(
            clientId: clientId,
            clientName: client['company_name'] ?? 'Unknown Client',
            firstActivityDate: firstActivity,
            jobCount: stats['jobCount'] as int,
            quoteCount: stats['quoteCount'] as int,
            revenue: (stats['jobRevenue'] as double) + (stats['quoteValue'] as double),
          ));
        }
      }

      // Build top agents list
      final topAgentsList = <TopAgent>[];
      for (final entry in agentStats.entries) {
        final agentId = entry.key;
        final stats = entry.value;
        final agent = agentsResponse.firstWhere(
          (a) => a['id'].toString() == agentId,
          orElse: () => {'agent_name': 'Unknown Agent'},
        );
        final clientId = stats['clientId'] as String;
        final client = clientDetails[clientId] ?? {};
        topAgentsList.add(TopAgent(
          agentId: agentId,
          agentName: agent['agent_name'] ?? 'Unknown Agent',
          clientId: clientId,
          clientName: client['company_name'] ?? 'Unknown Client',
          jobCount: stats['jobCount'] as int,
          quoteCount: stats['quoteCount'] as int,
          totalValue: stats['totalValue'] as double,
        ));
      }
      topAgentsList.sort((a, b) => b.totalValue.compareTo(a.totalValue));

      final insights = ClientInsights(
        totalClients: totalClients,
        activeClients: activeClients,
        vipClients: vipClients,
        pendingClients: pendingClients,
        inactiveClients: inactiveClients,
        newClients: newClientsList.length,
        atRiskClients: atRiskClientsList.length,
        averageJobsPerClient: averageJobsPerClient,
        averageRevenuePerClient: averageRevenuePerClient,
        averageJobValuePerClient: averageJobValuePerClient,
        averageQuoteValuePerClient: averageQuoteValuePerClient,
        averageQuotesPerClient: averageQuotesPerClient,
        quoteToJobConversionRate: quoteToJobConversionRate,
        averageAgentsPerClient: averageAgentsPerClient,
        topClients: topClientsByTotal.take(5).toList(),
        topClientsByJobs: topClientsByJobs.take(5).toList(),
        topClientsByRevenue: topClientsByRevenue.take(5).toList(),
        topClientsByQuotes: topClientsByQuotes.take(5).toList(),
        topClientsByConversionRate: topClientsByConversion.take(5).toList(),
        atRiskClientsList: atRiskClientsList.take(10).toList(),
        newClientsList: newClientsList,
        topAgents: topAgentsList.take(10).toList(),
        clientsByStatus: clientsByStatus,
        revenueByStatus: revenueByStatus,
        jobsByStatus: jobsByStatus,
        quotesByStatus: quotesByStatus,
        clientsByTier: clientsByTier,
        revenueByTier: revenueByTier,
      );

      Log.d('Client insights with location filter: ${insights.totalClients} clients, ${insights.averageJobsPerClient.toStringAsFixed(1)} avg jobs');
      return Result.success(insights);
    } catch (error) {
      Log.e('Error fetching client insights with location filter: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Fetch financial insights
  Future<Result<FinancialInsights>> _fetchFinancialInsights(DateRange dateRange) async {
    try {
      Log.d('Fetching financial insights...');
      // Total revenue in period
      final revenueResponse = await _supabase
          .from('jobs')
          .select('amount')
          .eq('job_status', 'completed')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String())
          .not('amount', 'is', null);
      
      Log.d('Financial query returned ${revenueResponse.length} records');

      final totalRevenue = revenueResponse
          .where((j) => j['amount'] != null)
          .fold<double>(0.0, (sum, job) => sum + (job['amount'] as num).toDouble());

      // Revenue this week
      final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
      final revenueThisWeekResponse = await _supabase
          .from('jobs')
          .select('amount')
          .eq('job_status', 'completed')
          .gte('created_at', weekStart.toIso8601String())
          .not('amount', 'is', null);

      final revenueThisWeek = revenueThisWeekResponse
          .where((j) => j['amount'] != null)
          .fold<double>(0.0, (sum, job) => sum + (job['amount'] as num).toDouble());

      // Revenue this month
      final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
      final revenueThisMonthResponse = await _supabase
          .from('jobs')
          .select('amount')
          .eq('job_status', 'completed')
          .gte('created_at', monthStart.toIso8601String())
          .not('amount', 'is', null);

      final revenueThisMonth = revenueThisMonthResponse
          .where((j) => j['amount'] != null)
          .fold<double>(0.0, (sum, job) => sum + (job['amount'] as num).toDouble());

      // Average job value
      final completedJobsCount = revenueResponse.length;
      final averageJobValue = completedJobsCount > 0 ? totalRevenue / completedJobsCount : 0.0;

      // Revenue growth (simplified - compare with previous period)
      final previousPeriodStart = dateRange.start.subtract(dateRange.end.difference(dateRange.start));
      final previousRevenueResponse = await _supabase
          .from('jobs')
          .select('amount')
          .eq('job_status', 'completed')
          .gte('created_at', previousPeriodStart.toIso8601String())
          .lt('created_at', dateRange.start.toIso8601String())
          .not('amount', 'is', null);

      final previousRevenue = previousRevenueResponse
          .where((j) => j['amount'] != null)
          .fold<double>(0.0, (sum, job) => sum + (job['amount'] as num).toDouble());

      final revenueGrowth = previousRevenue > 0 
          ? ((totalRevenue - previousRevenue) / previousRevenue) * 100 
          : 0.0;

      final insights = FinancialInsights(
        totalRevenue: totalRevenue,
        revenueThisWeek: revenueThisWeek,
        revenueThisMonth: revenueThisMonth,
        averageJobValue: averageJobValue,
        revenueGrowth: revenueGrowth,
      );

      return Result.success(insights);
    } catch (error) {
      Log.e('Error fetching financial insights: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Fetch financial insights with location filtering
  Future<Result<FinancialInsights>> _fetchFinancialInsightsWithLocation(DateRange dateRange, LocationFilter location) async {
    try {
      Log.d('Fetching financial insights with location filter: ${location.displayName}...');
      
      // Map location filter to branch_id
      final branchId = _locationFilterToBranchId(location);

      // Total revenue in period with branch filter
      var revenueQuery = _supabase
          .from('jobs')
          .select('amount')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String())
          .not('amount', 'is', null);
      
      if (branchId != null) {
        revenueQuery = revenueQuery.eq('branch_id', branchId);
      } else if (location == LocationFilter.unspecified) {
        revenueQuery = revenueQuery.isFilter('branch_id', null);
      }
      
      final revenueResponse = await revenueQuery;
      
      Log.d('Revenue query with branch filter returned ${revenueResponse.length} records');

      final totalRevenue = revenueResponse
          .where((r) => r['amount'] != null)
          .fold<double>(0.0, (sum, r) => sum + (r['amount'] as num).toDouble());

      // Revenue this week with branch filter
      final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
      var weekRevenueQuery = _supabase
          .from('jobs')
          .select('amount')
          .gte('created_at', weekStart.toIso8601String())
          .not('amount', 'is', null);
      
      if (branchId != null) {
        weekRevenueQuery = weekRevenueQuery.eq('branch_id', branchId);
      } else if (location == LocationFilter.unspecified) {
        weekRevenueQuery = weekRevenueQuery.isFilter('branch_id', null);
      }
      
      final revenueThisWeekResponse = await weekRevenueQuery;

      // Revenue this month with branch filter
      final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
      var monthRevenueQuery = _supabase
          .from('jobs')
          .select('amount')
          .gte('created_at', monthStart.toIso8601String())
          .not('amount', 'is', null);
      
      if (branchId != null) {
        monthRevenueQuery = monthRevenueQuery.eq('branch_id', branchId);
      } else if (location == LocationFilter.unspecified) {
        monthRevenueQuery = monthRevenueQuery.isFilter('branch_id', null);
      }
      
      final revenueThisMonthResponse = await monthRevenueQuery;

      final revenueThisWeek = revenueThisWeekResponse
          .where((r) => r['amount'] != null)
          .fold<double>(0.0, (sum, r) => sum + (r['amount'] as num).toDouble());

      final revenueThisMonth = revenueThisMonthResponse
          .where((r) => r['amount'] != null)
          .fold<double>(0.0, (sum, r) => sum + (r['amount'] as num).toDouble());

      final financialInsights = FinancialInsights(
        totalRevenue: totalRevenue,
        revenueThisWeek: revenueThisWeek,
        revenueThisMonth: revenueThisMonth,
        averageJobValue: revenueResponse.isNotEmpty ? totalRevenue / revenueResponse.length : 0.0,
        revenueGrowth: 0.0, // TODO: Calculate revenue growth
      );

      Log.d('Financial insights with location filter: R${financialInsights.totalRevenue.toStringAsFixed(0)} total, R${financialInsights.revenueThisWeek.toStringAsFixed(0)} this week');
      return Result.success(financialInsights);
    } catch (error) {
      Log.e('Error fetching financial insights with location filter: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Fetch jobs insights only
  Future<Result<JobInsights>> fetchJobsInsights({
    required TimePeriod period,
    required LocationFilter location,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    try {
      print('Fetching jobs insights for period: ${period.displayName}, location: ${location.displayName}');
      
      final dateRange = _getDateRange(period, customStartDate, customEndDate);
      print('Date range: ${dateRange.start.toIso8601String()} to ${dateRange.end.toIso8601String()}');
      
      final result = await _fetchJobInsightsWithLocation(dateRange, location);
      
      if (result.isSuccess) {
        print('Jobs insights fetched successfully');
        return result;
      } else {
        print('Failed to fetch jobs insights: ${result.error}');
        return result;
      }
    } catch (error) {
      print('Error fetching jobs insights: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Fetch financial insights only
  Future<Result<FinancialInsights>> fetchFinancialInsights({
    required TimePeriod period,
    required LocationFilter location,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    try {
      print('Fetching financial insights for period: ${period.displayName}, location: ${location.displayName}');
      
      final dateRange = _getDateRange(period, customStartDate, customEndDate);
      print('Date range: ${dateRange.start.toIso8601String()} to ${dateRange.end.toIso8601String()}');
      
      final result = await _fetchFinancialInsightsWithLocation(dateRange, location);
      
      if (result.isSuccess) {
        print('Financial insights fetched successfully');
        return result;
      } else {
        print('Failed to fetch financial insights: ${result.error}');
        return result;
      }
    } catch (error) {
      print('Error fetching financial insights: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Fetch driver insights only
  Future<Result<DriverInsights>> fetchDriverInsights({
    required TimePeriod period,
    required LocationFilter location,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    try {
      print('Fetching driver insights for period: ${period.displayName}, location: ${location.displayName}');
      
      final dateRange = _getDateRange(period, customStartDate, customEndDate);
      print('Date range: ${dateRange.start.toIso8601String()} to ${dateRange.end.toIso8601String()}');
      
      final result = await _fetchDriverInsightsWithLocation(dateRange, location);
      
      if (result.isSuccess) {
        print('Driver insights fetched successfully');
        return result;
      } else {
        print('Failed to fetch driver insights: ${result.error}');
        return result;
      }
    } catch (error) {
      print('Error fetching driver insights: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Fetch vehicle insights only
  Future<Result<VehicleInsights>> fetchVehicleInsights({
    required TimePeriod period,
    required LocationFilter location,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    try {
      print('Fetching vehicle insights for period: ${period.displayName}, location: ${location.displayName}');
      
      final dateRange = _getDateRange(period, customStartDate, customEndDate);
      print('Date range: ${dateRange.start.toIso8601String()} to ${dateRange.end.toIso8601String()}');
      
      final result = await _fetchVehicleInsightsWithLocation(dateRange, location);
      
      if (result.isSuccess) {
        print('Vehicle insights fetched successfully');
        return result;
      } else {
        print('Failed to fetch vehicle insights: ${result.error}');
        return result;
      }
    } catch (error) {
      print('Error fetching vehicle insights: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Fetch client insights only
  Future<Result<ClientInsights>> fetchClientInsights({
    required TimePeriod period,
    required LocationFilter location,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    try {
      print('Fetching client insights for period: ${period.displayName}, location: ${location.displayName}');
      
      final dateRange = _getDateRange(period, customStartDate, customEndDate);
      print('Date range: ${dateRange.start.toIso8601String()} to ${dateRange.end.toIso8601String()}');
      
      final result = await _fetchClientInsightsWithLocation(dateRange, location);
      
      if (result.isSuccess) {
        print('Client insights fetched successfully');
        return result;
      } else {
        print('Failed to fetch client insights: ${result.error}');
        return result;
      }
    } catch (error) {
      print('Error fetching client insights: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Fetch client revenue insights
  Future<Result<ClientRevenueInsights>> _fetchClientRevenueInsights(DateRange dateRange) async {
    try {
      Log.d('Fetching client revenue insights...');
      
      // Get all clients
      final clientsResponse = await _supabase
          .from('clients')
          .select('id, company_name');
      
      Log.d('Clients query returned ${clientsResponse.length} records');

      // Get client job revenue data
      final clientJobsResponse = await _supabase
          .from('jobs')
          .select('client_id, amount')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String())
          .not('client_id', 'is', null)
          .not('amount', 'is', null);

      // Calculate client revenue statistics
      final Map<String, Map<String, dynamic>> clientStats = {};
      for (final job in clientJobsResponse) {
        final clientId = job['client_id'].toString();
        if (!clientStats.containsKey(clientId)) {
          clientStats[clientId] = {'revenue': 0.0, 'jobCount': 0};
        }
        clientStats[clientId]!['revenue'] += (job['amount'] as num).toDouble();
        clientStats[clientId]!['jobCount']++;
      }

      // Calculate totals
      final totalRevenue = clientStats.values.fold<double>(0.0, (sum, stats) => sum + stats['revenue']);
      final totalClients = clientsResponse.length;
      final averageRevenuePerClient = totalClients > 0 ? totalRevenue / totalClients : 0.0;

      // Get top clients by revenue
      final List<ClientRevenue> topClients = [];
      for (final entry in clientStats.entries) {
        final clientId = entry.key;
        final stats = entry.value;
        
        // Get client name
        final client = clientsResponse.firstWhere(
          (c) => c['id'].toString() == clientId,
          orElse: () => {'company_name': 'Unknown Client'},
        );
        
        topClients.add(ClientRevenue(
          clientId: clientId,
          clientName: client['company_name'] ?? 'Unknown Client',
          totalRevenue: stats['revenue'],
          jobCount: stats['jobCount'],
          averageJobValue: stats['jobCount'] > 0 ? stats['revenue'] / stats['jobCount'] : 0.0,
        ));
      }
      
      // Sort by revenue and take top 10
      topClients.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
      final top10Clients = topClients.take(10).toList();

      final clientRevenueInsights = ClientRevenueInsights(
        topClients: top10Clients,
        totalRevenue: totalRevenue,
        averageRevenuePerClient: averageRevenuePerClient,
        totalClients: totalClients,
      );

      Log.d('Client revenue insights: ${clientRevenueInsights.totalClients} clients, R${clientRevenueInsights.totalRevenue.toStringAsFixed(0)} total revenue');
      return Result.success(clientRevenueInsights);
    } catch (error) {
      Log.e('Error fetching client revenue insights: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Get date range based on period
  DateRange _getDateRange(TimePeriod period, DateTime? customStart, DateTime? customEnd) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    switch (period) {
      case TimePeriod.today:
        return DateRange(today, today.add(const Duration(days: 1)));
      case TimePeriod.yesterday:
        return DateRange(yesterday, yesterday.add(const Duration(days: 1)));
      case TimePeriod.last3Days:
        // Last 3 days: yesterday + 2 days before (3 days total ending at yesterday)
        final threeDaysAgo = yesterday.subtract(const Duration(days: 2));
        return DateRange(threeDaysAgo, yesterday.add(const Duration(days: 1)));
      case TimePeriod.thisWeek:
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return DateRange(weekStart, weekStart.add(const Duration(days: 7)));
      case TimePeriod.thisMonth:
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 1);
        return DateRange(monthStart, monthEnd);
      case TimePeriod.thisQuarter:
        final quarter = (now.month - 1) ~/ 3;
        final quarterStart = DateTime(now.year, quarter * 3 + 1, 1);
        final quarterEnd = DateTime(now.year, quarter * 3 + 4, 1);
        return DateRange(quarterStart, quarterEnd);
      case TimePeriod.thisYear:
        final yearStart = DateTime(now.year, 1, 1);
        final yearEnd = DateTime(now.year + 1, 1, 1);
        return DateRange(yearStart, yearEnd);
      case TimePeriod.custom:
        if (customStart != null && customEnd != null) {
          return DateRange(customStart, customEnd);
        }
        return DateRange(today, today.add(const Duration(days: 1)));
      case TimePeriod.tomorrow:
        return DateRange(tomorrow, tomorrow.add(const Duration(days: 1)));
      case TimePeriod.next3Days:
        // Next 3 days: tomorrow + 2 days after (3 days total)
        return DateRange(tomorrow, tomorrow.add(const Duration(days: 3)));
    }
  }

  /// Fetch completed jobs with km and time metrics
  Future<Result<List<Map<String, dynamic>>>> fetchCompletedJobsWithMetrics({
    required DateTime startDate,
    required DateTime endDate,
    required LocationFilter location,
  }) async {
    try {
      Log.d('Fetching completed jobs with metrics for period: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');
      
      final branchId = _locationFilterToBranchId(location);

      // Step 1: Get completed jobs in date range
      // Use transport table to get jobs by pickup_date
      final transportRows = await _supabase
          .from('transport')
          .select('job_id, pickup_date')
          .gte('pickup_date', startDate.toIso8601String())
          .lte('pickup_date', endDate.toIso8601String())
          .not('pickup_date', 'is', null);

      final Map<int, DateTime> jobEarliestPickup = {};
      for (final row in transportRows) {
        final jobId = row['job_id'] as int?;
        final pickupStr = row['pickup_date'] as String?;
        if (jobId == null || pickupStr == null) continue;
        final pickup = DateTime.parse(pickupStr);
        final existing = jobEarliestPickup[jobId];
        if (existing == null || pickup.isBefore(existing)) {
          jobEarliestPickup[jobId] = pickup;
        }
      }

      if (jobEarliestPickup.isEmpty) {
        return Result.success([]);
      }

      // Step 2: Get completed jobs with branch filter
      final jobIds = jobEarliestPickup.keys.toList();
      var jobsQuery = _supabase
          .from('jobs')
          .select('id, job_number, driver_id, manager_id, job_status')
          .filter('id', 'in', '(${jobIds.join(',')})')
          .eq('job_status', 'completed');

      if (branchId != null) {
        jobsQuery = jobsQuery.eq('branch_id', branchId);
      } else if (location == LocationFilter.unspecified) {
        jobsQuery = jobsQuery.isFilter('branch_id', null);
      }

      final jobsResponse = await jobsQuery;

      if (jobsResponse.isEmpty) {
        return Result.success([]);
      }

      // Step 3: Get driver_flow data for completed jobs
      final completedJobIds = jobsResponse.map((j) => j['id'] as int).toList();
      final idsString = completedJobIds.join(',');
      
      final driverFlowQuery = _supabase
          .from('driver_flow')
          .select('job_id, odo_start_reading, job_closed_odo, vehicle_collected_at, job_closed_time')
          .filter('job_id', 'in', '($idsString)')
          .not('job_closed_odo', 'is', null)
          .not('odo_start_reading', 'is', null)
          .not('vehicle_collected_at', 'is', null)
          .not('job_closed_time', 'is', null);

      final driverFlowResponse = await driverFlowQuery;

      // Step 4: Get driver and manager names
      final driverIds = jobsResponse
          .map((j) => j['driver_id'] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();

      final managerIds = jobsResponse
          .map((j) => j['manager_id'] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();

      final Map<String, String> driverNames = {};
      final Map<String, String> managerNames = {};
      
      // Fetch all user IDs (drivers + managers) in one query
      final allUserIds = [...driverIds, ...managerIds].toSet().toList();
      if (allUserIds.isNotEmpty) {
        final profilesQuery = _supabase
            .from('profiles')
            .select('id, display_name')
            .inFilter('id', allUserIds);
        
        final profilesResponse = await profilesQuery;
        for (final profile in profilesResponse) {
          final id = profile['id'] as String?;
          final name = profile['display_name'] as String?;
          if (id != null && name != null) {
            if (driverIds.contains(id)) {
              driverNames[id] = name;
            }
            if (managerIds.contains(id)) {
              managerNames[id] = name;
            }
          }
        }
      }

      // Step 5: Combine data
      final Map<int, Map<String, dynamic>> flowMap = {};
      for (final flow in driverFlowResponse) {
        final jobId = flow['job_id'] as int?;
        if (jobId != null) {
          flowMap[jobId] = flow;
        }
      }

      final List<Map<String, dynamic>> result = [];
      for (final job in jobsResponse) {
        final jobId = job['id'] as int;
        final flow = flowMap[jobId];
        
        if (flow != null) {
          final driverId = job['driver_id'] as String?;
          final managerId = job['manager_id'] as String?;
          final driverName = driverId != null ? driverNames[driverId] ?? 'Unknown Driver' : 'Unknown Driver';
          final managerName = managerId != null ? managerNames[managerId] : null;
          final jobNumber = job['job_number'] as String? ?? jobId.toString();
          
          final startOdo = flow['odo_start_reading'];
          final endOdo = flow['job_closed_odo'];
          final vehicleCollectedAt = flow['vehicle_collected_at'];
          final jobClosedTime = flow['job_closed_time'];
          
          double kmTraveled = 0.0;
          double timeHours = 0.0;
          
          if (startOdo != null && endOdo != null) {
            kmTraveled = (endOdo as num).toDouble() - (startOdo as num).toDouble();
            if (kmTraveled < 0) kmTraveled = 0.0;
          }
          
          if (vehicleCollectedAt != null && jobClosedTime != null) {
            try {
              final startTime = DateTime.parse(vehicleCollectedAt);
              final endTime = DateTime.parse(jobClosedTime);
              final duration = endTime.difference(startTime);
              timeHours = duration.inMinutes / 60.0;
              if (timeHours < 0) timeHours = 0.0;
            } catch (e) {
              Log.e('Error parsing timestamps for job $jobId: $e');
            }
          }
          
          result.add({
            'jobId': jobId,
            'jobNumber': jobNumber,
            'driverName': driverName,
            'managerName': managerName,
            'kmTraveled': kmTraveled,
            'timeHours': timeHours,
          });
        }
      }

      // Don't sort here - let the screen sort by the metric type it needs

      Log.d('Fetched ${result.length} completed jobs with metrics');
      return Result.success(result);
    } catch (error) {
      Log.e('Error fetching completed jobs with metrics: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Map Supabase errors to appropriate AppException types
  Result<T> _mapSupabaseError<T>(dynamic error) {
    if (error is AuthException) {
      return Result.failure(AuthException(error.message));
    } else if (error is PostgrestException) {
      if (error.message.contains('network') ||
          error.message.contains('timeout') ||
          error.message.contains('connection')) {
        return Result.failure(NetworkException(error.message));
      }
      if (error.message.contains('JWT') ||
          error.message.contains('unauthorized') ||
          error.message.contains('forbidden')) {
        return Result.failure(AuthException(error.message));
      }
      return Result.failure(UnknownException(error.message));
    } else if (error is StorageException) {
      if (error.message.contains('network') ||
          error.message.contains('timeout')) {
        return Result.failure(NetworkException(error.message));
      }
      return Result.failure(UnknownException(error.message));
    } else {
      return Result.failure(UnknownException(error.toString()));
    }
  }
}

/// Provider for InsightsRepository
final insightsRepositoryProvider = Provider<InsightsRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return InsightsRepository(supabase);
});
