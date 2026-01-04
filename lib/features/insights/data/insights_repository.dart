import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:choice_lux_cars/core/supabase/supabase_client_provider.dart';
import 'package:choice_lux_cars/features/insights/models/insights_data.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/core/types/result.dart';
import 'package:choice_lux_cars/core/errors/app_exception.dart';

/// Repository for insights and analytics data operations
class InsightsRepository {
  final SupabaseClient _supabase;

  InsightsRepository(this._supabase);

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
      
      // Build location filter
      String? locationFilter;
      if (location != LocationFilter.all) {
        switch (location) {
          case LocationFilter.jhb:
            locationFilter = 'Jhb';
            break;
          case LocationFilter.cpt:
            locationFilter = 'Cpt';
            break;
          case LocationFilter.dbn:
            locationFilter = 'Dbn';
            break;
          case LocationFilter.unspecified:
            locationFilter = null; // Will filter for null values
            break;
          case LocationFilter.all:
            break;
        }
      }

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

      // Calculate average completion days and on-time rate
      final completedJobsData = await _supabase
          .from('jobs')
          .select('id, created_at, updated_at, job_start_date')
          .eq('job_status', 'completed')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String())
          .not('updated_at', 'is', null);

      double averageCompletionDays = 0.0;
      double onTimeRate = 0.0;

      if (completedJobsData.isNotEmpty) {
        // Calculate average completion days
        final completionDurations = <double>[];
        for (final job in completedJobsData) {
          final createdAtStr = job['created_at'] as String?;
          final updatedAtStr = job['updated_at'] as String?;
          if (createdAtStr != null && updatedAtStr != null) {
            try {
              final createdAt = DateTime.parse(createdAtStr);
              final updatedAt = DateTime.parse(updatedAtStr);
              final days = updatedAt.difference(createdAt).inDays.toDouble();
              if (days >= 0) {
                completionDurations.add(days);
              }
            } catch (e) {
              Log.e('Error parsing dates for job ${job['id']}: $e');
            }
          }
        }
        averageCompletionDays = completionDurations.isNotEmpty
            ? completionDurations.reduce((a, b) => a + b) / completionDurations.length
            : 0.0;

        // Calculate on-time rate (completed on or before job_start_date)
        int onTimeCount = 0;
        for (final job in completedJobsData) {
          final jobStartDateStr = job['job_start_date'] as String?;
          final updatedAtStr = job['updated_at'] as String?;
          if (jobStartDateStr != null && updatedAtStr != null) {
            try {
              final jobStartDate = DateTime.parse(jobStartDateStr);
              final completedDate = DateTime.parse(updatedAtStr);
              // Consider job on-time if completed on or before the start date
              // (jobs can be completed early or on the scheduled day)
              if (completedDate.isBefore(jobStartDate.add(Duration(days: 1))) ||
                  completedDate.difference(jobStartDate).inDays <= 1) {
                onTimeCount++;
              }
            } catch (e) {
              Log.e('Error parsing dates for on-time calculation ${job['id']}: $e');
            }
          }
        }
        onTimeRate = completedJobsData.isNotEmpty
            ? (onTimeCount / completedJobsData.length) * 100
            : 0.0;
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
        averageCompletionDays: averageCompletionDays,
        onTimeRate: onTimeRate,
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
      
      // Build location filter
      String? locationFilter;
      if (location != LocationFilter.all) {
        switch (location) {
          case LocationFilter.jhb:
            locationFilter = 'Jhb';
            break;
          case LocationFilter.cpt:
            locationFilter = 'Cpt';
            break;
          case LocationFilter.dbn:
            locationFilter = 'Dbn';
            break;
          case LocationFilter.unspecified:
            locationFilter = null; // Will filter for null values
            break;
          case LocationFilter.all:
            break;
        }
      }

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
          averageCompletionDays: 0.0,
          onTimeRate: 0.0,
        );
        return Result.success(emptyInsights);
      }

      // Step 2: Fetch jobs for those IDs, apply location filter
      final jobIds = jobEarliestPickup.keys.toList();
      var jobsQuery = _supabase
          .from('jobs')
          .select('id, job_status, location');

      // Filter by IDs using in filter
      // Prefer inFilter if available in current SDK
      // Fallback to filter('id','in','(1,2,3)') if needed
      try {
        // ignore: deprecated_member_use
        // @ts-ignore - runtime check
        // dart analyzer will allow if available
        // dynamic call to support both versions
        // Will be caught in catch if unsupported
        // jobsQuery = jobsQuery.inFilter('id', jobIds);
      } catch (_) {}

      final idsString = jobIds.join(',');
      jobsQuery = jobsQuery.filter('id', 'in', '($idsString)');

      if (locationFilter != null) {
        jobsQuery = jobsQuery.eq('location', locationFilter);
      } else if (location == LocationFilter.unspecified) {
        jobsQuery = jobsQuery.isFilter('location', null);
      }

      final jobsResponse = await jobsQuery;

      Log.d('Jobs (by earliest pickup) with location filter returned ${jobsResponse.length} records');

      // Compute counts with OPEN = not in (completed, cancelled)
      final totalJobs = jobsResponse.length;
      final completedJobs = jobsResponse.where((j) => j['job_status'] == 'completed').length;
      final cancelledJobs = jobsResponse.where((j) => j['job_status'] == 'cancelled').length;
      final inProgressJobs = jobsResponse.where((j) => j['job_status'] == 'in_progress' || j['job_status'] == 'started').length;
      final openJobs = jobsResponse.where((j) => j['job_status'] != 'completed' && j['job_status'] != 'cancelled').length;

      // Jobs this week with location filter
      final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
      var weekQuery = _supabase
          .from('jobs')
          .select('id')
          .gte('created_at', weekStart.toIso8601String());
      
      if (locationFilter != null) {
        weekQuery = weekQuery.eq('location', locationFilter);
      } else if (location == LocationFilter.unspecified) {
        weekQuery = weekQuery.isFilter('location', null);
      }
      
      final jobsThisWeekResponse = await weekQuery;

      // Jobs this month with location filter
      final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
      var monthQuery = _supabase
          .from('jobs')
          .select('id')
          .gte('created_at', monthStart.toIso8601String());
      
      if (locationFilter != null) {
        monthQuery = monthQuery.eq('location', locationFilter);
      } else if (location == LocationFilter.unspecified) {
        monthQuery = monthQuery.isFilter('location', null);
      }
      
      final jobsThisMonthResponse = await monthQuery;

      // Calculate average completion days and on-time rate for filtered jobs
      final completedJobIds = jobsResponse
          .where((j) => j['job_status'] == 'completed')
          .map((j) => j['id'] as int)
          .toList();

      double averageCompletionDays = 0.0;
      double onTimeRate = 0.0;

      if (completedJobIds.isNotEmpty) {
        // Fetch completed jobs with date fields
        // Build query for completed jobs using filter with multiple IDs
        var completedJobsQuery = _supabase
            .from('jobs')
            .select('id, created_at, updated_at, job_start_date')
            .eq('job_status', 'completed');
        
        // Filter by job IDs - use filter with comma-separated IDs
        if (completedJobIds.isNotEmpty) {
          final idsString = completedJobIds.join(',');
          completedJobsQuery = completedJobsQuery.filter('id', 'in', '($idsString)');
        }

        final completedJobsData = await completedJobsQuery;

        if (completedJobsData.isNotEmpty) {
          // Calculate average completion days
          final completionDurations = <double>[];
          for (final job in completedJobsData) {
            final createdAtStr = job['created_at'] as String?;
            final updatedAtStr = job['updated_at'] as String?;
            if (createdAtStr != null && updatedAtStr != null) {
              try {
                final createdAt = DateTime.parse(createdAtStr);
                final updatedAt = DateTime.parse(updatedAtStr);
                final days = updatedAt.difference(createdAt).inDays.toDouble();
                if (days >= 0) {
                  completionDurations.add(days);
                }
              } catch (e) {
                Log.e('Error parsing dates for job ${job['id']}: $e');
              }
            }
          }
          averageCompletionDays = completionDurations.isNotEmpty
              ? completionDurations.reduce((a, b) => a + b) / completionDurations.length
              : 0.0;

          // Calculate on-time rate (completed on or before job_start_date + 1 day buffer)
          int onTimeCount = 0;
          for (final job in completedJobsData) {
            final jobStartDateStr = job['job_start_date'] as String?;
            final updatedAtStr = job['updated_at'] as String?;
            if (jobStartDateStr != null && updatedAtStr != null) {
              try {
                final jobStartDate = DateTime.parse(jobStartDateStr);
                final completedDate = DateTime.parse(updatedAtStr);
                // Consider job on-time if completed on or within 1 day of the start date
                if (completedDate.isBefore(jobStartDate.add(Duration(days: 1))) ||
                    completedDate.difference(jobStartDate).inDays <= 1) {
                  onTimeCount++;
                }
              } catch (e) {
                Log.e('Error parsing dates for on-time calculation ${job['id']}: $e');
              }
            }
          }
          onTimeRate = completedJobsData.isNotEmpty
              ? (onTimeCount / completedJobsData.length) * 100
              : 0.0;
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
        averageCompletionDays: averageCompletionDays,
        onTimeRate: onTimeRate,
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
      
      // Build location filter
      String? locationFilter;
      if (location != LocationFilter.all) {
        switch (location) {
          case LocationFilter.jhb:
            locationFilter = 'Jhb';
            break;
          case LocationFilter.cpt:
            locationFilter = 'Cpt';
            break;
          case LocationFilter.dbn:
            locationFilter = 'Dbn';
            break;
          case LocationFilter.unspecified:
            locationFilter = null; // Will filter for null values
            break;
          case LocationFilter.all:
            break;
        }
      }

      // Total drivers
      final driversResponse = await _supabase
          .from('profiles')
          .select('id, display_name')
          .eq('role', 'driver');
      
      Log.d('Drivers query returned ${driversResponse.length} records');

      final totalDrivers = driversResponse.length;
      final activeDrivers = driversResponse.length; // All drivers are considered active

      // Driver job counts and revenue with location filter
      var driverJobsQuery = _supabase
          .from('jobs')
          .select('driver_id, amount')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String())
          .not('driver_id', 'is', null);
      
      if (locationFilter != null) {
        driverJobsQuery = driverJobsQuery.eq('location', locationFilter);
      } else if (location == LocationFilter.unspecified) {
        driverJobsQuery = driverJobsQuery.isFilter('location', null);
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
      // Total vehicles
      final vehiclesResponse = await _supabase
          .from('vehicles')
          .select('id, make, model, reg_plate');
      
      Log.d('Vehicles query returned ${vehiclesResponse.length} records');

      final totalVehicles = vehiclesResponse.length;
      final activeVehicles = vehiclesResponse.length; // All vehicles are considered active

      // Vehicle job counts and revenue
      final vehicleJobsResponse = await _supabase
          .from('jobs')
          .select('vehicle_id, amount')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String());

      // Group by vehicle
      final vehicleStats = <String, Map<String, dynamic>>{};
      for (final job in vehicleJobsResponse) {
        final vehicleId = job['vehicle_id'].toString();
        if (!vehicleStats.containsKey(vehicleId)) {
          vehicleStats[vehicleId] = {'count': 0, 'revenue': 0.0};
        }
        vehicleStats[vehicleId]!['count']++;
        if (job['amount'] != null) {
          vehicleStats[vehicleId]!['revenue'] += (job['amount'] as num).toDouble();
        }
      }

      // Calculate averages
      final totalJobCount = vehicleStats.values.fold<int>(0, (sum, stats) => sum + (stats['count'] as int));
      final totalRevenue = vehicleStats.values.fold<double>(0.0, (sum, stats) => sum + (stats['revenue'] as double));
      
      final averageJobsPerVehicle = totalVehicles > 0 ? totalJobCount / totalVehicles : 0.0;
      final averageIncomePerVehicle = totalVehicles > 0 ? totalRevenue / totalVehicles : 0.0;

      // Top vehicles
      final topVehicles = <TopVehicle>[];
      for (final entry in vehicleStats.entries) {
        final vehicleId = entry.key;
        final stats = entry.value;
        final vehicle = vehiclesResponse.firstWhere(
          (v) => v['id'].toString() == vehicleId,
          orElse: () => {'id': vehicleId, 'make': 'Unknown', 'model': 'Unknown', 'reg_plate': 'Unknown'},
        );
        
        topVehicles.add(TopVehicle(
          vehicleId: vehicleId.toString(),
          vehicleName: '${vehicle['make']} ${vehicle['model']}',
          registration: vehicle['reg_plate'] ?? 'Unknown',
          jobCount: stats['count'],
          revenue: stats['revenue'],
        ));
      }
      
      // Sort by job count and take top 5
      topVehicles.sort((a, b) => b.jobCount.compareTo(a.jobCount));
      final topVehiclesList = topVehicles.take(5).toList();

      final insights = VehicleInsights(
        totalVehicles: totalVehicles,
        activeVehicles: activeVehicles,
        averageJobsPerVehicle: averageJobsPerVehicle,
        averageIncomePerVehicle: averageIncomePerVehicle,
        topVehicles: topVehiclesList,
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
      
      // Build location filter
      String? locationFilter;
      if (location != LocationFilter.all) {
        switch (location) {
          case LocationFilter.jhb:
            locationFilter = 'Jhb';
            break;
          case LocationFilter.cpt:
            locationFilter = 'Cpt';
            break;
          case LocationFilter.dbn:
            locationFilter = 'Dbn';
            break;
          case LocationFilter.unspecified:
            locationFilter = null; // Will filter for null values
            break;
          case LocationFilter.all:
            break;
        }
      }

      // Total vehicles
      final vehiclesResponse = await _supabase
          .from('vehicles')
          .select('id, make, model, reg_plate');
      
      Log.d('Vehicles query returned ${vehiclesResponse.length} records');

      final totalVehicles = vehiclesResponse.length;
      final activeVehicles = vehiclesResponse.length; // All vehicles are considered active

      // Vehicle job counts and revenue with location filter
      var vehicleJobsQuery = _supabase
          .from('jobs')
          .select('vehicle_id, amount')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String())
          .not('vehicle_id', 'is', null);
      
      if (locationFilter != null) {
        vehicleJobsQuery = vehicleJobsQuery.eq('location', locationFilter);
      } else if (location == LocationFilter.unspecified) {
        vehicleJobsQuery = vehicleJobsQuery.isFilter('location', null);
      }
      
      final vehicleJobsResponse = await vehicleJobsQuery;

      // Calculate vehicle statistics
      final Map<String, Map<String, dynamic>> vehicleStats = {};
      for (final job in vehicleJobsResponse) {
        final vehicleId = job['vehicle_id'].toString();
        if (!vehicleStats.containsKey(vehicleId)) {
          vehicleStats[vehicleId] = {'count': 0, 'revenue': 0.0};
        }
        vehicleStats[vehicleId]!['count']++;
        if (job['amount'] != null) {
          vehicleStats[vehicleId]!['revenue'] += (job['amount'] as num).toDouble();
        }
      }

      // Calculate averages
      final totalVehicleJobs = vehicleStats.values.fold<int>(0, (sum, stats) => sum + (stats['count'] as int));
      final totalVehicleRevenue = vehicleStats.values.fold<double>(0.0, (sum, stats) => sum + stats['revenue']);
      final averageJobsPerVehicle = totalVehicles > 0 ? totalVehicleJobs / totalVehicles : 0.0;
      final averageRevenuePerVehicle = totalVehicles > 0 ? totalVehicleRevenue / totalVehicles : 0.0;

      // Get top vehicles
      final List<TopVehicle> topVehicles = [];
      for (final entry in vehicleStats.entries) {
        final vehicleId = entry.key;
        final stats = entry.value;
        
        // Get vehicle details
        final vehicle = vehiclesResponse.firstWhere(
          (v) => v['id'].toString() == vehicleId,
          orElse: () => {'make': 'Unknown', 'model': 'Vehicle', 'reg_plate': 'Unknown'},
        );
        
        topVehicles.add(TopVehicle(
          vehicleId: vehicleId,
          vehicleName: '${vehicle['make']} ${vehicle['model']}',
          registration: vehicle['reg_plate'] ?? 'Unknown',
          jobCount: stats['count'],
          revenue: stats['revenue'],
        ));
      }
      
      // Sort by job count and take top 5
      topVehicles.sort((a, b) => b.jobCount.compareTo(a.jobCount));
      final top5Vehicles = topVehicles.take(5).toList();

      final vehicleInsights = VehicleInsights(
        totalVehicles: totalVehicles,
        activeVehicles: activeVehicles,
        averageJobsPerVehicle: averageJobsPerVehicle,
        averageIncomePerVehicle: averageRevenuePerVehicle,
        topVehicles: top5Vehicles,
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
      // Total clients
      final clientsResponse = await _supabase
          .from('clients')
          .select('id, company_name');
      
      Log.d('Clients query returned ${clientsResponse.length} records');

      final totalClients = clientsResponse.length;
      final activeClients = clientsResponse.length; // All clients are considered active

      // Client job counts and revenue
      final clientJobsResponse = await _supabase
          .from('jobs')
          .select('client_id, amount')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String());

      // Client quote counts
      final clientQuotesResponse = await _supabase
          .from('quotes')
          .select('client_id, quote_amount')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String());

      // Group by client
      final clientStats = <String, Map<String, dynamic>>{};
      
      // Process jobs
      for (final job in clientJobsResponse) {
        final clientId = job['client_id'].toString();
        if (!clientStats.containsKey(clientId)) {
          clientStats[clientId] = {'jobCount': 0, 'jobRevenue': 0.0, 'quoteCount': 0, 'quoteValue': 0.0};
        }
        clientStats[clientId]!['jobCount']++;
        if (job['amount'] != null) {
          clientStats[clientId]!['jobRevenue'] += (job['amount'] as num).toDouble();
        }
      }

      // Process quotes
      for (final quote in clientQuotesResponse) {
        final clientId = quote['client_id'].toString();
        if (!clientStats.containsKey(clientId)) {
          clientStats[clientId] = {'jobCount': 0, 'jobRevenue': 0.0, 'quoteCount': 0, 'quoteValue': 0.0};
        }
        clientStats[clientId]!['quoteCount']++;
        if (quote['quote_amount'] != null) {
          clientStats[clientId]!['quoteValue'] += (quote['quote_amount'] as num).toDouble();
        }
      }

      // Calculate averages
      final totalJobCount = clientStats.values.fold<int>(0, (sum, stats) => sum + (stats['jobCount'] as int));
      final totalJobRevenue = clientStats.values.fold<double>(0.0, (sum, stats) => sum + (stats['jobRevenue'] as double));
      
      final averageJobsPerClient = totalClients > 0 ? totalJobCount / totalClients : 0.0;
      final averageRevenuePerClient = totalClients > 0 ? totalJobRevenue / totalClients : 0.0;

      // Top clients
      final topClients = <TopClient>[];
      for (final entry in clientStats.entries) {
        final clientId = entry.key;
        final stats = entry.value;
        final client = clientsResponse.firstWhere(
          (c) => c['id'].toString() == clientId,
          orElse: () => {'id': clientId, 'company_name': 'Unknown Client'},
        );
        
        topClients.add(TopClient(
          clientId: clientId.toString(),
          clientName: client['company_name'] ?? 'Unknown Client',
          jobCount: stats['jobCount'],
          quoteCount: stats['quoteCount'],
          totalValue: stats['jobRevenue'] + stats['quoteValue'],
        ));
      }
      
      // Sort by total value and take top 5
      topClients.sort((a, b) => b.totalValue.compareTo(a.totalValue));
      final topClientsList = topClients.take(5).toList();

      final insights = ClientInsights(
        totalClients: totalClients,
        activeClients: activeClients,
        averageJobsPerClient: averageJobsPerClient,
        averageRevenuePerClient: averageRevenuePerClient,
        topClients: topClientsList,
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
      
      // Build location filter
      String? locationFilter;
      if (location != LocationFilter.all) {
        switch (location) {
          case LocationFilter.jhb:
            locationFilter = 'Jhb';
            break;
          case LocationFilter.cpt:
            locationFilter = 'Cpt';
            break;
          case LocationFilter.dbn:
            locationFilter = 'Dbn';
            break;
          case LocationFilter.unspecified:
            locationFilter = null; // Will filter for null values
            break;
          case LocationFilter.all:
            break;
        }
      }

      // Total clients
      final clientsResponse = await _supabase
          .from('clients')
          .select('id, company_name');
      
      Log.d('Clients query returned ${clientsResponse.length} records');

      final totalClients = clientsResponse.length;

      // Client job counts and revenue with location filter
      var clientJobsQuery = _supabase
          .from('jobs')
          .select('client_id, amount')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String())
          .not('client_id', 'is', null);
      
      if (locationFilter != null) {
        clientJobsQuery = clientJobsQuery.eq('location', locationFilter);
      } else if (location == LocationFilter.unspecified) {
        clientJobsQuery = clientJobsQuery.isFilter('location', null);
      }
      
      final clientJobsResponse = await clientJobsQuery;

      // Client quotes with location filter
      var clientQuotesQuery = _supabase
          .from('quotes')
          .select('client_id, quote_amount')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String())
          .not('client_id', 'is', null);
      
      if (locationFilter != null) {
        clientQuotesQuery = clientQuotesQuery.eq('location', locationFilter);
      } else if (location == LocationFilter.unspecified) {
        clientQuotesQuery = clientQuotesQuery.isFilter('location', null);
      }
      
      final clientQuotesResponse = await clientQuotesQuery;

      // Calculate client statistics
      final Map<String, Map<String, dynamic>> clientStats = {};
      
      // Process jobs
      for (final job in clientJobsResponse) {
        final clientId = job['client_id'].toString();
        if (!clientStats.containsKey(clientId)) {
          clientStats[clientId] = {'jobCount': 0, 'jobRevenue': 0.0, 'quoteCount': 0, 'quoteValue': 0.0};
        }
        clientStats[clientId]!['jobCount']++;
        if (job['amount'] != null) {
          clientStats[clientId]!['jobRevenue'] += (job['amount'] as num).toDouble();
        }
      }

      // Process quotes
      for (final quote in clientQuotesResponse) {
        final clientId = quote['client_id'].toString();
        if (!clientStats.containsKey(clientId)) {
          clientStats[clientId] = {'jobCount': 0, 'jobRevenue': 0.0, 'quoteCount': 0, 'quoteValue': 0.0};
        }
        clientStats[clientId]!['quoteCount']++;
        if (quote['quote_amount'] != null) {
          clientStats[clientId]!['quoteValue'] += (quote['quote_amount'] as num).toDouble();
        }
      }

      // Calculate averages
      final totalClientJobs = clientStats.values.fold<int>(0, (sum, stats) => sum + (stats['jobCount'] as int));
      final totalClientQuotes = clientStats.values.fold<int>(0, (sum, stats) => sum + (stats['quoteCount'] as int));
      final totalClientRevenue = clientStats.values.fold<double>(0.0, (sum, stats) => sum + stats['jobRevenue'] + stats['quoteValue']);
      final averageJobsPerClient = totalClients > 0 ? totalClientJobs / totalClients : 0.0;
      final averageQuotesPerClient = totalClients > 0 ? totalClientQuotes / totalClients : 0.0;
      final averageRevenuePerClient = totalClients > 0 ? totalClientRevenue / totalClients : 0.0;

      // Get top clients
      final List<TopClient> topClients = [];
      for (final entry in clientStats.entries) {
        final clientId = entry.key;
        final stats = entry.value;
        
        // Get client name
        final client = clientsResponse.firstWhere(
          (c) => c['id'].toString() == clientId,
          orElse: () => {'company_name': 'Unknown Client'},
        );
        
        topClients.add(TopClient(
          clientId: clientId,
          clientName: client['company_name'] ?? 'Unknown Client',
          jobCount: stats['jobCount'],
          quoteCount: stats['quoteCount'],
          totalValue: stats['jobRevenue'] + stats['quoteValue'],
        ));
      }
      
      // Sort by total value and take top 5
      topClients.sort((a, b) => b.totalValue.compareTo(a.totalValue));
      final top5Clients = topClients.take(5).toList();

      final clientInsights = ClientInsights(
        totalClients: totalClients,
        activeClients: totalClients, // All clients are considered active
        averageJobsPerClient: averageJobsPerClient,
        averageRevenuePerClient: averageRevenuePerClient,
        topClients: top5Clients,
      );

      Log.d('Client insights with location filter: ${clientInsights.totalClients} clients, ${clientInsights.averageJobsPerClient.toStringAsFixed(1)} avg jobs');
      return Result.success(clientInsights);
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
      
      // Build location filter
      String? locationFilter;
      if (location != LocationFilter.all) {
        switch (location) {
          case LocationFilter.jhb:
            locationFilter = 'Jhb';
            break;
          case LocationFilter.cpt:
            locationFilter = 'Cpt';
            break;
          case LocationFilter.dbn:
            locationFilter = 'Dbn';
            break;
          case LocationFilter.unspecified:
            locationFilter = null; // Will filter for null values
            break;
          case LocationFilter.all:
            break;
        }
      }

      // Total revenue in period with location filter
      var revenueQuery = _supabase
          .from('jobs')
          .select('amount')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String())
          .not('amount', 'is', null);
      
      if (locationFilter != null) {
        revenueQuery = revenueQuery.eq('location', locationFilter);
      } else if (location == LocationFilter.unspecified) {
        revenueQuery = revenueQuery.isFilter('location', null);
      }
      
      final revenueResponse = await revenueQuery;
      
      Log.d('Revenue query with location filter returned ${revenueResponse.length} records');

      final totalRevenue = revenueResponse
          .where((r) => r['amount'] != null)
          .fold<double>(0.0, (sum, r) => sum + (r['amount'] as num).toDouble());

      // Revenue this week with location filter
      final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
      var weekRevenueQuery = _supabase
          .from('jobs')
          .select('amount')
          .gte('created_at', weekStart.toIso8601String())
          .not('amount', 'is', null);
      
      if (locationFilter != null) {
        weekRevenueQuery = weekRevenueQuery.eq('location', locationFilter);
      } else if (location == LocationFilter.unspecified) {
        weekRevenueQuery = weekRevenueQuery.isFilter('location', null);
      }
      
      final revenueThisWeekResponse = await weekRevenueQuery;

      // Revenue this month with location filter
      final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
      var monthRevenueQuery = _supabase
          .from('jobs')
          .select('amount')
          .gte('created_at', monthStart.toIso8601String())
          .not('amount', 'is', null);
      
      if (locationFilter != null) {
        monthRevenueQuery = monthRevenueQuery.eq('location', locationFilter);
      } else if (location == LocationFilter.unspecified) {
        monthRevenueQuery = monthRevenueQuery.isFilter('location', null);
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

    switch (period) {
      case TimePeriod.today:
        return DateRange(today, today.add(Duration(days: 1)));
      case TimePeriod.thisWeek:
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return DateRange(weekStart, weekStart.add(Duration(days: 7)));
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
        return DateRange(today, today.add(Duration(days: 1)));
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

/// Date range helper class
class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange(this.start, this.end);
}

/// Provider for InsightsRepository
final insightsRepositoryProvider = Provider<InsightsRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return InsightsRepository(supabase);
});
