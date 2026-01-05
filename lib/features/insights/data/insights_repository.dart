import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:choice_lux_cars/core/supabase/supabase_client_provider.dart';
import 'package:choice_lux_cars/features/insights/models/insights_data.dart';
import 'package:choice_lux_cars/features/insights/models/client_statement_data.dart';
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

      // Sprint 1: Calculate new metrics
      // Get all jobs with job_start_date for time calculations
      final allJobsData = await _supabase
          .from('jobs')
          .select('id, created_at, job_start_date, driver_id, vehicle_id, job_status')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String());

      // Calculate average time to start
      double averageTimeToStart = 0.0;
      final timeToStartDurations = <double>[];
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final tomorrowStart = todayStart.add(Duration(days: 1));
      final tomorrowEnd = tomorrowStart.add(Duration(days: 1));

      int jobsStartingToday = 0;
      int jobsStartingTomorrow = 0;
      int overdueJobs = 0;
      int unassignedJobs = 0;

      for (final job in allJobsData) {
        final createdAtStr = job['created_at'] as String?;
        final jobStartDateStr = job['job_start_date'] as String?;
        final driverId = job['driver_id']?.toString();
        final vehicleId = job['vehicle_id']?.toString();
        final jobStatus = job['job_status']?.toString() ?? '';

        // Calculate average time to start
        if (createdAtStr != null && jobStartDateStr != null) {
          try {
            final createdAt = DateTime.parse(createdAtStr);
            final jobStartDate = DateTime.parse(jobStartDateStr);
            final days = jobStartDate.difference(createdAt).inDays.toDouble();
            if (days >= 0) {
              timeToStartDurations.add(days);
            }

            // Count jobs starting today
            final jobStartDateOnly = DateTime(jobStartDate.year, jobStartDate.month, jobStartDate.day);
            if (jobStartDateOnly.isAtSameMomentAs(todayStart)) {
              jobsStartingToday++;
            }

            // Count jobs starting tomorrow
            if (jobStartDateOnly.isAtSameMomentAs(tomorrowStart)) {
              jobsStartingTomorrow++;
            }

            // Count overdue jobs (past start date and not completed)
            if (jobStartDate.isBefore(now) && jobStatus != 'completed' && jobStatus != 'cancelled') {
              overdueJobs++;
            }
          } catch (e) {
            Log.e('Error parsing dates for job ${job['id']}: $e');
          }
        }

        // Count unassigned jobs (missing driver or vehicle)
        if ((driverId == null || driverId.isEmpty) || (vehicleId == null || vehicleId.isEmpty)) {
          unassignedJobs++;
        }
      }

      averageTimeToStart = timeToStartDurations.isNotEmpty
          ? timeToStartDurations.reduce((a, b) => a + b) / timeToStartDurations.length
          : 0.0;

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
        averageTimeToStart: averageTimeToStart,
        jobsStartingToday: jobsStartingToday,
        jobsStartingTomorrow: jobsStartingTomorrow,
        overdueJobs: overdueJobs,
        unassignedJobs: unassignedJobs,
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
          averageTimeToStart: 0.0,
          jobsStartingToday: 0,
          jobsStartingTomorrow: 0,
          overdueJobs: 0,
          unassignedJobs: 0,
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

      // Sprint 1: Calculate new metrics with location filter
      // Get all jobs with job_start_date for time calculations
      var allJobsQuery = _supabase
          .from('jobs')
          .select('id, created_at, job_start_date, driver_id, vehicle_id, job_status')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String());
      
      if (locationFilter != null) {
        allJobsQuery = allJobsQuery.eq('location', locationFilter);
      } else if (location == LocationFilter.unspecified) {
        allJobsQuery = allJobsQuery.isFilter('location', null);
      }
      
      final allJobsData = await allJobsQuery;

      // Calculate average time to start
      double averageTimeToStart = 0.0;
      final timeToStartDurations = <double>[];
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final tomorrowStart = todayStart.add(Duration(days: 1));

      int jobsStartingToday = 0;
      int jobsStartingTomorrow = 0;
      int overdueJobs = 0;
      int unassignedJobs = 0;

      for (final job in allJobsData) {
        final createdAtStr = job['created_at'] as String?;
        final jobStartDateStr = job['job_start_date'] as String?;
        final driverId = job['driver_id']?.toString();
        final vehicleId = job['vehicle_id']?.toString();
        final jobStatus = job['job_status']?.toString() ?? '';

        // Calculate average time to start
        if (createdAtStr != null && jobStartDateStr != null) {
          try {
            final createdAt = DateTime.parse(createdAtStr);
            final jobStartDate = DateTime.parse(jobStartDateStr);
            final days = jobStartDate.difference(createdAt).inDays.toDouble();
            if (days >= 0) {
              timeToStartDurations.add(days);
            }

            // Count jobs starting today
            final jobStartDateOnly = DateTime(jobStartDate.year, jobStartDate.month, jobStartDate.day);
            if (jobStartDateOnly.isAtSameMomentAs(todayStart)) {
              jobsStartingToday++;
            }

            // Count jobs starting tomorrow
            if (jobStartDateOnly.isAtSameMomentAs(tomorrowStart)) {
              jobsStartingTomorrow++;
            }

            // Count overdue jobs (past start date and not completed)
            if (jobStartDate.isBefore(now) && jobStatus != 'completed' && jobStatus != 'cancelled') {
              overdueJobs++;
            }
          } catch (e) {
            Log.e('Error parsing dates for job ${job['id']}: $e');
          }
        }

        // Count unassigned jobs (missing driver or vehicle)
        if ((driverId == null || driverId.isEmpty) || (vehicleId == null || vehicleId.isEmpty)) {
          unassignedJobs++;
        }
      }

      averageTimeToStart = timeToStartDurations.isNotEmpty
          ? timeToStartDurations.reduce((a, b) => a + b) / timeToStartDurations.length
          : 0.0;

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
        averageTimeToStart: averageTimeToStart,
        jobsStartingToday: jobsStartingToday,
        jobsStartingTomorrow: jobsStartingTomorrow,
        overdueJobs: overdueJobs,
        unassignedJobs: unassignedJobs,
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

      // Sprint 1: Calculate new driver metrics
      // Bottom performers (lowest job count)
      final bottomDrivers = List<TopDriver>.from(topDrivers);
      bottomDrivers.sort((a, b) => a.jobCount.compareTo(b.jobCount));
      final bottomPerformersList = bottomDrivers.take(5).toList();

      // Driver utilization rate (drivers with jobs / total drivers)
      final driversWithJobs = driverStats.keys.length;
      final driverUtilizationRate = totalDrivers > 0 ? (driversWithJobs / totalDrivers) * 100 : 0.0;

      // Unassigned jobs count (jobs without driver)
      final allJobsForUnassigned = await _supabase
          .from('jobs')
          .select('driver_id')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String());
      
      final unassignedJobsCount = allJobsForUnassigned
          .where((j) => j['driver_id'] == null || j['driver_id'].toString().isEmpty)
          .length;

      // Phase 2: Calculate additional performance metrics
      // Fetch driver_flow data for performance calculations
      final driverFlowResponse = await _supabase
          .from('driver_flow')
          .select('job_id, job_started_at, pickup_arrive_time, job_closed_time, payment_collected_ind, progress_percentage, odo_start_reading, job_closed_odo')
          .gte('job_started_at', dateRange.start.toIso8601String())
          .lte('job_started_at', dateRange.end.toIso8601String())
          .not('job_started_at', 'is', null);

      // Calculate average job completion time (hours)
      final completedJobs = driverFlowResponse.where((df) => df['job_closed_time'] != null && df['job_started_at'] != null).toList();
      double averageJobCompletionTime = 0.0;
      if (completedJobs.isNotEmpty) {
        final completionTimes = completedJobs.map((df) {
          final start = DateTime.parse(df['job_started_at']);
          final end = DateTime.parse(df['job_closed_time']);
          return end.difference(start).inHours.toDouble();
        }).toList();
        averageJobCompletionTime = completionTimes.reduce((a, b) => a + b) / completionTimes.length;
      }

      // Calculate average time to pickup (minutes)
      final pickupJobs = driverFlowResponse.where((df) => df['pickup_arrive_time'] != null && df['job_started_at'] != null).toList();
      double averageTimeToPickup = 0.0;
      if (pickupJobs.isNotEmpty) {
        final pickupTimes = pickupJobs.map((df) {
          final start = DateTime.parse(df['job_started_at']);
          final pickup = DateTime.parse(df['pickup_arrive_time']);
          return pickup.difference(start).inMinutes.toDouble();
        }).toList();
        averageTimeToPickup = pickupTimes.reduce((a, b) => a + b) / pickupTimes.length;
      }

      // Calculate on-time pickup rate (compare with transport.pickup_date)
      // For now, we'll use a simplified calculation based on average time
      double onTimePickupRate = 0.0;
      if (pickupJobs.isNotEmpty) {
        // Consider on-time if pickup is within 30 minutes of expected
        final onTimeCount = pickupJobs.where((df) {
          final start = DateTime.parse(df['job_started_at']);
          final pickup = DateTime.parse(df['pickup_arrive_time']);
          final timeDiff = pickup.difference(start).inMinutes;
          return timeDiff <= 30; // 30 minutes threshold
        }).length;
        onTimePickupRate = (onTimeCount / pickupJobs.length) * 100;
      }

      // Calculate average jobs per day
      final daysInPeriod = dateRange.end.difference(dateRange.start).inDays;
      final averageJobsPerDay = daysInPeriod > 0 && activeDrivers > 0 
          ? (totalJobCount / daysInPeriod / activeDrivers) 
          : 0.0;

      // Calculate revenue per hour
      double revenuePerHour = 0.0;
      if (averageJobCompletionTime > 0 && totalRevenue > 0) {
        revenuePerHour = totalRevenue / (averageJobCompletionTime * completedJobs.length);
      }

      // Calculate payment collection rate
      final jobsWithPayment = driverFlowResponse.where((df) => df['payment_collected_ind'] == true).length;
      final paymentCollectionRate = driverFlowResponse.isNotEmpty 
          ? (jobsWithPayment / driverFlowResponse.length) * 100 
          : 0.0;

      // Calculate average progress completion
      final progressValues = driverFlowResponse
          .where((df) => df['progress_percentage'] != null)
          .map((df) => (df['progress_percentage'] as num).toDouble())
          .toList();
      final averageProgressCompletion = progressValues.isNotEmpty
          ? progressValues.reduce((a, b) => a + b) / progressValues.length
          : 0.0;

      // Calculate jobs completed this week
      final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
      weekStart.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
      final jobsCompletedThisWeek = completedJobs.where((df) {
        final closedTime = DateTime.parse(df['job_closed_time']);
        return closedTime.isAfter(weekStart);
      }).length;

      // Calculate jobs completed this month
      final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
      final jobsCompletedThisMonth = completedJobs.where((df) {
        final closedTime = DateTime.parse(df['job_closed_time']);
        return closedTime.isAfter(monthStart);
      }).length;

      // Calculate active jobs now
      final activeJobsResponse = await _supabase
          .from('jobs')
          .select('job_status, driver_id')
          .inFilter('job_status', ['assigned', 'in_progress'])
          .not('driver_id', 'is', null);
      final activeJobsNow = activeJobsResponse.length;

      // Calculate jobs started today
      final todayStart = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
      final jobsStartedToday = driverFlowResponse.where((df) {
        final started = DateTime.parse(df['job_started_at']);
        return started.isAfter(todayStart);
      }).length;

      // Calculate average response time (time from job creation to job_started_at)
      final jobsWithStartTime = await _supabase
          .from('jobs')
          .select('id, created_at, driver_id')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String())
          .not('driver_id', 'is', null);
      
      double averageResponseTime = 0.0;
      final responseTimes = <double>[];
      for (final job in jobsWithStartTime) {
        final jobId = job['id'];
        final jobCreated = DateTime.parse(job['created_at']);
        try {
          final flowData = driverFlowResponse.firstWhere(
            (df) => df['job_id'] == jobId && df['job_started_at'] != null,
          );
          if (flowData.isNotEmpty && flowData['job_started_at'] != null) {
            final started = DateTime.parse(flowData['job_started_at']);
            final diff = started.difference(jobCreated).inHours.toDouble();
            if (diff >= 0) {
              responseTimes.add(diff);
            }
          }
        } catch (e) {
          // Job not found in driver_flow, skip
        }
      }
      if (responseTimes.isNotEmpty) {
        averageResponseTime = responseTimes.reduce((a, b) => a + b) / responseTimes.length;
      }

      // Calculate revenue by location
      final jobsWithLocation = await _supabase
          .from('jobs')
          .select('location, amount, driver_id')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String())
          .not('driver_id', 'is', null);
      
      final revenueByLocation = <String, double>{};
      for (final job in jobsWithLocation) {
        final location = (job['location'] ?? 'Unspecified').toString();
        final amount = (job['amount'] as num?)?.toDouble() ?? 0.0;
        revenueByLocation[location] = (revenueByLocation[location] ?? 0.0) + amount;
      }

      // Find top location by jobs
      final locationJobCounts = <String, int>{};
      for (final job in jobsWithLocation) {
        final location = (job['location'] ?? 'Unspecified').toString();
        locationJobCounts[location] = (locationJobCounts[location] ?? 0) + 1;
      }
      final topLocationByJobs = locationJobCounts.entries.isNotEmpty
          ? locationJobCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null;

      // Calculate efficiency score (composite: completion time, on-time rate, revenue)
      double efficiencyScore = 0.0;
      if (completedJobs.isNotEmpty) {
        final completionScore = averageJobCompletionTime > 0 ? (100 / (averageJobCompletionTime / 10)).clamp(0.0, 50.0) : 0.0;
        final onTimeScore = onTimePickupRate * 0.3;
        final revenueScore = totalRevenue > 0 ? ((totalRevenue / 10000) * 20).clamp(0.0, 20.0) : 0.0;
        efficiencyScore = (completionScore + onTimeScore + revenueScore).clamp(0.0, 100.0);
      }

      // Calculate most productive day of week
      final dayJobCounts = <String, int>{};
      for (final job in driverJobsResponse) {
        final createdAt = DateTime.parse(job['created_at']);
        final dayName = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][createdAt.weekday - 1];
        dayJobCounts[dayName] = (dayJobCounts[dayName] ?? 0) + 1;
      }
      final mostProductiveDay = dayJobCounts.entries.isNotEmpty
          ? dayJobCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null;

      // Calculate peak performance hours
      final hourJobCounts = <int, int>{};
      for (final df in completedJobs) {
        final closedTime = DateTime.parse(df['job_closed_time']);
        hourJobCounts[closedTime.hour] = (hourJobCounts[closedTime.hour] ?? 0) + 1;
      }
      final peakHour = hourJobCounts.entries.isNotEmpty
          ? hourJobCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null;
      final peakPerformanceHours = peakHour != null ? '${peakHour.toString().padLeft(2, '0')}:00 - ${(peakHour + 1).toString().padLeft(2, '0')}:00' : null;

      // Calculate average distance per job (km)
      final jobsWithDistance = driverFlowResponse
          .where((df) => df['odo_start_reading'] != null && df['job_closed_odo'] != null)
          .toList();
      double averageDistancePerJob = 0.0;
      if (jobsWithDistance.isNotEmpty) {
        final distances = jobsWithDistance.map((df) {
          final start = (df['odo_start_reading'] as num).toDouble();
          final end = (df['job_closed_odo'] as num).toDouble();
          return (end - start).abs();
        }).toList();
        averageDistancePerJob = distances.reduce((a, b) => a + b) / distances.length;
      }

      final insights = DriverInsights(
        totalDrivers: totalDrivers,
        activeDrivers: activeDrivers,
        averageJobsPerDriver: averageJobsPerDriver,
        averageRevenuePerDriver: averageRevenuePerDriver,
        topDrivers: topDriversList,
        driverUtilizationRate: driverUtilizationRate,
        unassignedJobsCount: unassignedJobsCount,
        bottomPerformers: bottomPerformersList,
        averageJobCompletionTime: averageJobCompletionTime,
        averageTimeToPickup: averageTimeToPickup,
        onTimePickupRate: onTimePickupRate,
        averageJobsPerDay: averageJobsPerDay,
        revenuePerHour: revenuePerHour,
        paymentCollectionRate: paymentCollectionRate,
        averageProgressCompletion: averageProgressCompletion,
        jobsCompletedThisWeek: jobsCompletedThisWeek,
        jobsCompletedThisMonth: jobsCompletedThisMonth,
        activeJobsNow: activeJobsNow,
        jobsStartedToday: jobsStartedToday,
        averageResponseTime: averageResponseTime,
        topLocationByJobs: topLocationByJobs,
        revenueByLocation: revenueByLocation,
        efficiencyScore: efficiencyScore,
        mostProductiveDay: mostProductiveDay,
        peakPerformanceHours: peakPerformanceHours,
        averageDistancePerJob: averageDistancePerJob,
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

      // Sprint 1: Calculate new driver metrics with location filter
      // Bottom performers (lowest job count)
      final bottomDrivers = List<TopDriver>.from(topDrivers);
      bottomDrivers.sort((a, b) => a.jobCount.compareTo(b.jobCount));
      final bottomPerformersList = bottomDrivers.take(5).toList();

      // Driver utilization rate (drivers with jobs / total drivers)
      final driversWithJobs = driverStats.keys.length;
      final driverUtilizationRate = totalDrivers > 0 ? (driversWithJobs / totalDrivers) * 100 : 0.0;

      // Unassigned jobs count (jobs without driver) with location filter
      var unassignedJobsQuery = _supabase
          .from('jobs')
          .select('driver_id')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String());
      
      if (locationFilter != null) {
        unassignedJobsQuery = unassignedJobsQuery.eq('location', locationFilter);
      } else if (location == LocationFilter.unspecified) {
        unassignedJobsQuery = unassignedJobsQuery.isFilter('location', null);
      }
      
      final allJobsForUnassigned = await unassignedJobsQuery;
      final unassignedJobsCount = allJobsForUnassigned
          .where((j) => j['driver_id'] == null || j['driver_id'].toString().isEmpty)
          .length;

      final driverInsights = DriverInsights(
        totalDrivers: totalDrivers,
        activeDrivers: activeDrivers,
        averageJobsPerDriver: averageJobsPerDriver,
        averageRevenuePerDriver: averageRevenuePerDriver,
        topDrivers: top5Drivers,
        driverUtilizationRate: driverUtilizationRate,
        unassignedJobsCount: unassignedJobsCount,
        bottomPerformers: bottomPerformersList,
        // Additional metrics default to 0 for location-filtered (can be enhanced later)
        averageJobCompletionTime: 0.0,
        averageTimeToPickup: 0.0,
        onTimePickupRate: 0.0,
        averageJobsPerDay: 0.0,
        revenuePerHour: 0.0,
        paymentCollectionRate: 0.0,
        averageProgressCompletion: 0.0,
        jobsCompletedThisWeek: 0,
        jobsCompletedThisMonth: 0,
        activeJobsNow: 0,
        jobsStartedToday: 0,
        averageResponseTime: 0.0,
        topLocationByJobs: locationFilter,
        revenueByLocation: {},
        efficiencyScore: 0.0,
        mostProductiveDay: null,
        peakPerformanceHours: null,
        averageDistancePerJob: 0.0,
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

      // Sprint 1: Calculate new vehicle metrics
      // Least used vehicles (lowest job count)
      final leastUsedVehicles = List<TopVehicle>.from(topVehicles);
      leastUsedVehicles.sort((a, b) => a.jobCount.compareTo(b.jobCount));
      final leastUsedVehiclesList = leastUsedVehicles.take(5).toList();

      // Vehicle utilization rate (vehicles with jobs / total vehicles)
      final vehiclesWithJobs = vehicleStats.keys.length;
      final vehicleUtilizationRate = totalVehicles > 0 ? (vehiclesWithJobs / totalVehicles) * 100 : 0.0;

      // Unassigned jobs count (jobs without vehicle)
      final allJobsForUnassigned = await _supabase
          .from('jobs')
          .select('vehicle_id')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String());
      
      final unassignedJobsCount = allJobsForUnassigned
          .where((j) => j['vehicle_id'] == null || j['vehicle_id'].toString().isEmpty)
          .length;

      // Phase 2: Calculate additional vehicle metrics
      // Fetch driver_flow data for distance and odometer calculations
      final driverFlowResponse = await _supabase
          .from('driver_flow')
          .select('job_id, odo_start_reading, job_closed_odo, job_started_at, job_closed_time')
          .gte('job_started_at', dateRange.start.toIso8601String())
          .lte('job_started_at', dateRange.end.toIso8601String())
          .not('job_started_at', 'is', null);

      // Get jobs with vehicle_id to join with driver_flow
      final jobsWithVehicle = await _supabase
          .from('jobs')
          .select('id, vehicle_id, amount, location, job_status, updated_at')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String())
          .not('vehicle_id', 'is', null);

      // Fix: Query ALL odometer readings for highest odometer (not just date range)
      final allOdometerReadings = await _supabase
          .from('driver_flow')
          .select('job_id, job_closed_odo')
          .not('job_closed_odo', 'is', null);

      // Calculate distance traveled per vehicle
      final vehicleDistances = <String, double>{};
      final vehicleOdometerReadings = <String, double>{};
      double totalDistanceTraveled = 0.0;
      double highestOdometerReading = 0.0;
      String? vehicleWithMostDistance;
      double maxVehicleDistance = 0.0;

      // Fix: Find highest odometer across ALL time (not just date range)
      for (final df in allOdometerReadings) {
        if (df['job_closed_odo'] != null) {
          final endOdo = (df['job_closed_odo'] as num).toDouble();
          if (endOdo > highestOdometerReading) {
            highestOdometerReading = endOdo;
          }
        }
      }

      // Calculate distance for jobs in date range
      for (final df in driverFlowResponse) {
        final jobId = df['job_id'];
        
        // Fix: Handle cases where we have end reading but no start reading
        // Use end reading as distance if start is missing (for completed jobs)
        if (df['job_closed_odo'] != null) {
          final endOdo = (df['job_closed_odo'] as num).toDouble();
          
          // Find vehicle for this job - fix type conversion
          final job = jobsWithVehicle.firstWhere(
            (j) => j['id'].toString() == jobId.toString(),
            orElse: () => {},
          );
          
          if (job.isNotEmpty && job['vehicle_id'] != null) {
            final vehicleId = job['vehicle_id'].toString();
            
            // If we have start reading, calculate distance
            if (df['odo_start_reading'] != null) {
              final startOdo = (df['odo_start_reading'] as num).toDouble();
              final distance = (endOdo - startOdo).abs();
              
              vehicleDistances[vehicleId] = (vehicleDistances[vehicleId] ?? 0.0) + distance;
              totalDistanceTraveled += distance;
            }
            
            // Track highest odometer per vehicle
            vehicleOdometerReadings[vehicleId] = endOdo > (vehicleOdometerReadings[vehicleId] ?? 0.0)
                ? endOdo
                : (vehicleOdometerReadings[vehicleId] ?? 0.0);
          }
        }
      }

      // Find vehicle with most distance
      if (vehicleDistances.isNotEmpty) {
        final maxEntry = vehicleDistances.entries.reduce((a, b) => a.value > b.value ? a : b);
        maxVehicleDistance = maxEntry.value;
        final vehicle = vehiclesResponse.firstWhere(
          (v) => v['id'].toString() == maxEntry.key,
          orElse: () => {'make': 'Unknown', 'model': 'Vehicle'},
        );
        vehicleWithMostDistance = '${vehicle['make']} ${vehicle['model']}';
      }

      // Calculate average distance per vehicle
      final vehiclesWithDistance = vehicleDistances.keys.length;
      final averageDistancePerVehicle = vehiclesWithDistance > 0
          ? totalDistanceTraveled / vehiclesWithDistance
          : 0.0;

      // Calculate average distance per job
      final jobsWithDistance = driverFlowResponse
          .where((df) => df['odo_start_reading'] != null && df['job_closed_odo'] != null)
          .length;
      final averageDistancePerJob = jobsWithDistance > 0
          ? totalDistanceTraveled / jobsWithDistance
          : 0.0;

      // Calculate jobs completed this week
      final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
      weekStart.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
      final jobsCompletedThisWeek = jobsWithVehicle.where((job) {
        if (job['job_status'] == 'completed' && job['updated_at'] != null) {
          final updatedAt = DateTime.parse(job['updated_at']);
          return updatedAt.isAfter(weekStart);
        }
        return false;
      }).length;

      // Calculate jobs completed this month
      final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
      final jobsCompletedThisMonth = jobsWithVehicle.where((job) {
        if (job['job_status'] == 'completed' && job['updated_at'] != null) {
          final updatedAt = DateTime.parse(job['updated_at']);
          return updatedAt.isAfter(monthStart);
        }
        return false;
      }).length;

      // Calculate active jobs now
      final activeJobsResponse = await _supabase
          .from('jobs')
          .select('job_status, vehicle_id')
          .inFilter('job_status', ['assigned', 'in_progress'])
          .not('vehicle_id', 'is', null);
      final activeJobsNow = activeJobsResponse.length;

      // Calculate average jobs per day
      final daysInPeriod = dateRange.end.difference(dateRange.start).inDays;
      final averageJobsPerDay = daysInPeriod > 0 && activeVehicles > 0
          ? (totalJobCount / daysInPeriod / activeVehicles)
          : 0.0;

      // Calculate revenue per km
      final revenuePerKm = totalDistanceTraveled > 0
          ? totalRevenue / totalDistanceTraveled
          : 0.0;

      // Calculate average time per job
      final completedJobsWithTime = driverFlowResponse
          .where((df) => df['job_started_at'] != null && df['job_closed_time'] != null)
          .toList();
      double averageTimePerJob = 0.0;
      if (completedJobsWithTime.isNotEmpty) {
        final times = completedJobsWithTime.map((df) {
          final start = DateTime.parse(df['job_started_at']);
          final end = DateTime.parse(df['job_closed_time']);
          return end.difference(start).inHours.toDouble();
        }).toList();
        averageTimePerJob = times.reduce((a, b) => a + b) / times.length;
      }

      // Calculate vehicle efficiency score (composite: utilization, revenue, distance efficiency)
      double vehicleEfficiencyScore = 0.0;
      if (totalVehicles > 0) {
        final utilizationScore = vehicleUtilizationRate * 0.4;
        final revenueScore = totalRevenue > 0 ? ((totalRevenue / 10000) * 30).clamp(0.0, 30.0) : 0.0;
        
        // Fix: Make distance score calculation more lenient
        // If no distance data, still give some score based on utilization and revenue
        final distanceScore = totalDistanceTraveled > 0 
            ? ((totalDistanceTraveled / 1000) * 30).clamp(0.0, 30.0)
            : (vehicleUtilizationRate > 0 ? 10.0 : 0.0); // Give base score if vehicles are being used
        
        vehicleEfficiencyScore = (utilizationScore + revenueScore + distanceScore).clamp(0.0, 100.0);
      }

      // Find most efficient vehicle (highest revenue per km)
      String? mostEfficientVehicle;
      double maxEfficiency = 0.0;
      for (final entry in vehicleStats.entries) {
        final vehicleId = entry.key;
        final revenue = entry.value['revenue'] as double;
        final distance = vehicleDistances[vehicleId] ?? 0.0;
        if (distance > 0) {
          final efficiency = revenue / distance;
          if (efficiency > maxEfficiency) {
            maxEfficiency = efficiency;
            final vehicle = vehiclesResponse.firstWhere(
              (v) => v['id'].toString() == vehicleId,
              orElse: () => {'make': 'Unknown', 'model': 'Vehicle'},
            );
            mostEfficientVehicle = '${vehicle['make']} ${vehicle['model']}';
          }
        }
      }

      // Calculate top location by usage
      final locationJobCounts = <String, int>{};
      for (final job in jobsWithVehicle) {
        final location = (job['location'] ?? 'Unspecified').toString();
        locationJobCounts[location] = (locationJobCounts[location] ?? 0) + 1;
      }
      final topLocationByUsage = locationJobCounts.entries.isNotEmpty
          ? locationJobCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null;

      // Calculate revenue by location
      final revenueByLocation = <String, double>{};
      for (final job in jobsWithVehicle) {
        final location = (job['location'] ?? 'Unspecified').toString();
        final amount = (job['amount'] as num?)?.toDouble() ?? 0.0;
        revenueByLocation[location] = (revenueByLocation[location] ?? 0.0) + amount;
      }

      // Calculate average km per day
      // Fix: Handle division by zero and ensure we have valid data
      final averageKmPerDay = daysInPeriod > 0 && activeVehicles > 0 && totalDistanceTraveled > 0
          ? (totalDistanceTraveled / daysInPeriod / activeVehicles)
          : 0.0;

      final insights = VehicleInsights(
        totalVehicles: totalVehicles,
        activeVehicles: activeVehicles,
        averageJobsPerVehicle: averageJobsPerVehicle,
        averageIncomePerVehicle: averageIncomePerVehicle,
        topVehicles: topVehiclesList,
        vehicleUtilizationRate: vehicleUtilizationRate,
        unassignedJobsCount: unassignedJobsCount,
        leastUsedVehicles: leastUsedVehiclesList,
        totalDistanceTraveled: totalDistanceTraveled,
        averageDistancePerVehicle: averageDistancePerVehicle,
        averageDistancePerJob: averageDistancePerJob,
        highestOdometerReading: highestOdometerReading,
        vehicleWithMostDistance: vehicleWithMostDistance,
        jobsCompletedThisWeek: jobsCompletedThisWeek,
        jobsCompletedThisMonth: jobsCompletedThisMonth,
        activeJobsNow: activeJobsNow,
        averageJobsPerDay: averageJobsPerDay,
        revenuePerKm: revenuePerKm,
        averageTimePerJob: averageTimePerJob,
        vehicleEfficiencyScore: vehicleEfficiencyScore,
        mostEfficientVehicle: mostEfficientVehicle,
        topLocationByUsage: topLocationByUsage,
        revenueByLocation: revenueByLocation,
        averageKmPerDay: averageKmPerDay,
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

      // Sprint 1: Calculate new vehicle metrics with location filter
      // Least used vehicles (lowest job count)
      final leastUsedVehicles = List<TopVehicle>.from(topVehicles);
      leastUsedVehicles.sort((a, b) => a.jobCount.compareTo(b.jobCount));
      final leastUsedVehiclesList = leastUsedVehicles.take(5).toList();

      // Vehicle utilization rate (vehicles with jobs / total vehicles)
      final vehiclesWithJobs = vehicleStats.keys.length;
      final vehicleUtilizationRate = totalVehicles > 0 ? (vehiclesWithJobs / totalVehicles) * 100 : 0.0;

      // Unassigned jobs count (jobs without vehicle) with location filter
      var unassignedJobsQuery = _supabase
          .from('jobs')
          .select('vehicle_id')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String());
      
      if (locationFilter != null) {
        unassignedJobsQuery = unassignedJobsQuery.eq('location', locationFilter);
      } else if (location == LocationFilter.unspecified) {
        unassignedJobsQuery = unassignedJobsQuery.isFilter('location', null);
      }
      
      final allJobsForUnassigned = await unassignedJobsQuery;
      final unassignedJobsCount = allJobsForUnassigned
          .where((j) => j['vehicle_id'] == null || j['vehicle_id'].toString().isEmpty)
          .length;

      final vehicleInsights = VehicleInsights(
        totalVehicles: totalVehicles,
        activeVehicles: activeVehicles,
        averageJobsPerVehicle: averageJobsPerVehicle,
        averageIncomePerVehicle: averageRevenuePerVehicle,
        topVehicles: top5Vehicles,
        vehicleUtilizationRate: vehicleUtilizationRate,
        unassignedJobsCount: unassignedJobsCount,
        leastUsedVehicles: leastUsedVehiclesList,
        // Additional metrics default to 0 for location-filtered (can be enhanced later)
        totalDistanceTraveled: 0.0,
        averageDistancePerVehicle: 0.0,
        averageDistancePerJob: 0.0,
        highestOdometerReading: 0.0,
        vehicleWithMostDistance: null,
        jobsCompletedThisWeek: 0,
        jobsCompletedThisMonth: 0,
        activeJobsNow: 0,
        averageJobsPerDay: 0.0,
        revenuePerKm: 0.0,
        averageTimePerJob: 0.0,
        vehicleEfficiencyScore: 0.0,
        mostEfficientVehicle: null,
        topLocationByUsage: locationFilter,
        revenueByLocation: {},
        averageKmPerDay: 0.0,
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

      // Sprint 1: Calculate new client metrics
      // Top clients by revenue (sorted by jobRevenue, not totalValue)
      final topClientsByRevenue = <TopClient>[];
      for (final entry in clientStats.entries) {
        final clientId = entry.key;
        final stats = entry.value;
        final client = clientsResponse.firstWhere(
          (c) => c['id'].toString() == clientId,
          orElse: () => {'id': clientId, 'company_name': 'Unknown Client'},
        );
        
        topClientsByRevenue.add(TopClient(
          clientId: clientId.toString(),
          clientName: client['company_name'] ?? 'Unknown Client',
          jobCount: stats['jobCount'],
          quoteCount: stats['quoteCount'],
          totalValue: stats['jobRevenue'] as double,
        ));
      }
      topClientsByRevenue.sort((a, b) => b.totalValue.compareTo(a.totalValue));
      final topClientsByRevenueList = topClientsByRevenue.take(5).toList();

      // Client retention rate (clients with multiple jobs / total clients with jobs)
      final clientsWithMultipleJobs = clientStats.values.where((stats) => (stats['jobCount'] as int) > 1).length;
      final clientsWithJobs = clientStats.keys.length;
      final clientRetentionRate = clientsWithJobs > 0 ? (clientsWithMultipleJobs / clientsWithJobs) * 100 : 0.0;

      // Phase 2: Calculate additional client metrics
      // New clients this period (clients with first job in this period)
      final allClientJobs = await _supabase
          .from('jobs')
          .select('client_id, created_at')
          .not('client_id', 'is', null)
          .order('created_at', ascending: true);
      
      final clientFirstJobDates = <String, DateTime>{};
      for (final job in allClientJobs) {
        final clientId = job['client_id']?.toString() ?? '';
        if (clientId.isNotEmpty && job['created_at'] != null) {
          if (!clientFirstJobDates.containsKey(clientId)) {
            try {
              final createdAt = DateTime.parse(job['created_at'].toString());
              clientFirstJobDates[clientId] = createdAt;
            } catch (e) {
              // Skip invalid dates
              continue;
            }
          }
        }
      }
      
      final newClientsThisPeriod = clientFirstJobDates.values
          .where((firstJobDate) => 
              firstJobDate.isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
              firstJobDate.isBefore(dateRange.end.add(const Duration(days: 1))))
          .length;

      // Repeat clients count (clients with multiple jobs)
      final repeatClientsCount = clientsWithMultipleJobs;

      // Average days between jobs for repeat clients
      double averageDaysBetweenJobs = 0.0;
      if (repeatClientsCount > 0) {
        final clientJobDates = <String, List<DateTime>>{};
        for (final job in clientJobsResponse) {
          final clientId = job['client_id']?.toString() ?? '';
          if (clientId.isNotEmpty && job['created_at'] != null) {
            if (!clientJobDates.containsKey(clientId)) {
              clientJobDates[clientId] = [];
            }
            try {
              final createdAt = DateTime.parse(job['created_at'].toString());
              clientJobDates[clientId]!.add(createdAt);
            } catch (e) {
              // Skip invalid dates
              continue;
            }
          }
        }
        
        double totalDaysBetween = 0.0;
        int intervalsCount = 0;
        for (final dates in clientJobDates.values) {
          if (dates.length > 1) {
            dates.sort();
            for (int i = 1; i < dates.length; i++) {
              totalDaysBetween += dates[i].difference(dates[i - 1]).inDays.toDouble();
              intervalsCount++;
            }
          }
        }
        averageDaysBetweenJobs = intervalsCount > 0 ? totalDaysBetween / intervalsCount : 0.0;
      }

      // Top client by job frequency
      TopClient? topClientByJobFrequency;
      if (topClients.isNotEmpty) {
        topClientByJobFrequency = topClients.reduce((a, b) => a.jobCount > b.jobCount ? a : b);
      }

      // Clients with outstanding payments
      final jobsWithOutstanding = await _supabase
          .from('jobs')
          .select('client_id, amount, amount_collect, job_status')
          .eq('amount_collect', true)
          .neq('job_status', 'completed')
          .not('client_id', 'is', null);
      
      final clientsWithOutstanding = <String>{};
      double totalOutstandingAmount = 0.0;
      for (final job in jobsWithOutstanding) {
        final clientId = job['client_id'].toString();
        clientsWithOutstanding.add(clientId);
        if (job['amount'] != null) {
          totalOutstandingAmount += (job['amount'] as num).toDouble();
        }
      }

      // Average quote to job conversion rate
      double averageQuoteToJobConversionRate = 0.0;
      if (clientStats.isNotEmpty) {
        int totalQuotes = 0;
        int totalJobs = 0;
        for (final stats in clientStats.values) {
          totalQuotes += stats['quoteCount'] as int;
          totalJobs += stats['jobCount'] as int;
        }
        averageQuoteToJobConversionRate = totalQuotes > 0 ? (totalJobs / totalQuotes) * 100 : 0.0;
      }

      // Clients by location
      final jobsWithLocation = await _supabase
          .from('jobs')
          .select('client_id, location')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String())
          .not('client_id', 'is', null);
      
      final clientsByLocation = <String, Set<String>>{};
      for (final job in jobsWithLocation) {
        final location = (job['location'] ?? 'Unspecified').toString();
        final clientId = job['client_id']?.toString() ?? '';
        if (clientId.isNotEmpty) {
          if (!clientsByLocation.containsKey(location)) {
            clientsByLocation[location] = <String>{};
          }
          clientsByLocation[location]!.add(clientId);
        }
      }
      final clientsByLocationCount = clientsByLocation.map((key, value) => MapEntry(key, value.length));

      // Revenue growth by client (simplified - compare current period to previous period)
      final previousPeriodStart = dateRange.start.subtract(dateRange.end.difference(dateRange.start));
      final previousPeriodEnd = dateRange.start;
      final previousPeriodJobs = await _supabase
          .from('jobs')
          .select('client_id, amount')
          .gte('created_at', previousPeriodStart.toIso8601String())
          .lt('created_at', previousPeriodEnd.toIso8601String())
          .not('client_id', 'is', null);
      
      final previousRevenueByClient = <String, double>{};
      for (final job in previousPeriodJobs) {
        final clientId = job['client_id']?.toString() ?? '';
        if (clientId.isNotEmpty && job['amount'] != null) {
          previousRevenueByClient[clientId] = (previousRevenueByClient[clientId] ?? 0.0) + (job['amount'] as num).toDouble();
        }
      }
      
      final revenueGrowthByClient = <String, double>{};
      for (final entry in clientStats.entries) {
        final clientId = entry.key;
        final currentRevenue = entry.value['jobRevenue'] as double;
        final previousRevenue = previousRevenueByClient[clientId] ?? 0.0;
        if (previousRevenue > 0) {
          revenueGrowthByClient[clientId] = ((currentRevenue - previousRevenue) / previousRevenue) * 100;
        } else if (currentRevenue > 0) {
          revenueGrowthByClient[clientId] = 100.0; // New revenue
        }
      }

      // Average job value per client
      final averageJobValuePerClient = totalJobCount > 0 ? totalJobRevenue / totalJobCount : 0.0;

      // Most active client (by job count)
      TopClient? mostActiveClient;
      if (topClients.isNotEmpty) {
        mostActiveClient = topClients.reduce((a, b) => a.jobCount > b.jobCount ? a : b);
      }

      // Clients with no jobs in period
      final clientsWithJobsSet = clientStats.keys.toSet();
      final clientsWithNoJobs = totalClients - clientsWithJobsSet.length;

      final insights = ClientInsights(
        totalClients: totalClients,
        activeClients: activeClients,
        averageJobsPerClient: averageJobsPerClient,
        averageRevenuePerClient: averageRevenuePerClient,
        topClients: topClientsList,
        topClientsByRevenue: topClientsByRevenueList,
        clientRetentionRate: clientRetentionRate,
        newClientsThisPeriod: newClientsThisPeriod,
        repeatClientsCount: repeatClientsCount,
        averageDaysBetweenJobs: averageDaysBetweenJobs,
        topClientByJobFrequency: topClientByJobFrequency,
        clientsWithOutstandingPayments: clientsWithOutstanding.length,
        totalOutstandingAmount: totalOutstandingAmount,
        averageQuoteToJobConversionRate: averageQuoteToJobConversionRate,
        clientsByLocation: clientsByLocationCount,
        revenueGrowthByClient: revenueGrowthByClient,
        averageJobValuePerClient: averageJobValuePerClient,
        mostActiveClient: mostActiveClient,
        clientsWithNoJobs: clientsWithNoJobs,
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

      // Sprint 1: Calculate new client metrics with location filter
      // Top clients by revenue (sorted by jobRevenue, not totalValue)
      final topClientsByRevenue = <TopClient>[];
      for (final entry in clientStats.entries) {
        final clientId = entry.key;
        final stats = entry.value;
        final client = clientsResponse.firstWhere(
          (c) => c['id'].toString() == clientId,
          orElse: () => {'id': clientId, 'company_name': 'Unknown Client'},
        );
        
        topClientsByRevenue.add(TopClient(
          clientId: clientId.toString(),
          clientName: client['company_name'] ?? 'Unknown Client',
          jobCount: stats['jobCount'],
          quoteCount: stats['quoteCount'],
          totalValue: stats['jobRevenue'] as double,
        ));
      }
      topClientsByRevenue.sort((a, b) => b.totalValue.compareTo(a.totalValue));
      final topClientsByRevenueList = topClientsByRevenue.take(5).toList();

      // Client retention rate (clients with multiple jobs / total clients with jobs)
      final clientsWithMultipleJobs = clientStats.values.where((stats) => (stats['jobCount'] as int) > 1).length;
      final clientsWithJobs = clientStats.keys.length;
      final clientRetentionRate = clientsWithJobs > 0 ? (clientsWithMultipleJobs / clientsWithJobs) * 100 : 0.0;

      // Phase 2: Calculate additional client metrics (with location filter)
      // For location-filtered queries, we'll use simplified calculations
      // New clients this period
      final allClientJobsForNew = await _supabase
          .from('jobs')
          .select('client_id, created_at')
          .not('client_id', 'is', null)
          .order('created_at', ascending: true);
      
      if (locationFilter != null) {
        // Apply location filter if needed
      }
      
      final clientFirstJobDates = <String, DateTime>{};
      for (final job in allClientJobsForNew) {
        final clientId = job['client_id']?.toString() ?? '';
        if (clientId.isNotEmpty && job['created_at'] != null) {
          if (!clientFirstJobDates.containsKey(clientId)) {
            try {
              final createdAt = DateTime.parse(job['created_at'].toString());
              clientFirstJobDates[clientId] = createdAt;
            } catch (e) {
              // Skip invalid dates
              continue;
            }
          }
        }
      }
      
      final newClientsThisPeriod = clientFirstJobDates.values
          .where((firstJobDate) => 
              firstJobDate.isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
              firstJobDate.isBefore(dateRange.end.add(const Duration(days: 1))))
          .length;

      // Repeat clients count
      final repeatClientsCount = clientStats.values.where((stats) => (stats['jobCount'] as int) > 1).length;

      // Average days between jobs (simplified for location filter)
      double averageDaysBetweenJobs = 0.0;
      if (repeatClientsCount > 0) {
        final clientJobDates = <String, List<DateTime>>{};
        for (final job in clientJobsResponse) {
          final clientId = job['client_id']?.toString() ?? '';
          if (clientId.isNotEmpty && job['created_at'] != null) {
            if (!clientJobDates.containsKey(clientId)) {
              clientJobDates[clientId] = [];
            }
            try {
              final createdAt = DateTime.parse(job['created_at'].toString());
              clientJobDates[clientId]!.add(createdAt);
            } catch (e) {
              // Skip invalid dates
              continue;
            }
          }
        }
        
        double totalDaysBetween = 0.0;
        int intervalsCount = 0;
        for (final dates in clientJobDates.values) {
          if (dates.length > 1) {
            dates.sort();
            for (int i = 1; i < dates.length; i++) {
              totalDaysBetween += dates[i].difference(dates[i - 1]).inDays.toDouble();
              intervalsCount++;
            }
          }
        }
        averageDaysBetweenJobs = intervalsCount > 0 ? totalDaysBetween / intervalsCount : 0.0;
      }

      // Top client by job frequency
      TopClient? topClientByJobFrequency;
      if (top5Clients.isNotEmpty) {
        topClientByJobFrequency = top5Clients.reduce((a, b) => a.jobCount > b.jobCount ? a : b);
      }

      // Clients with outstanding payments (with location filter)
      var outstandingQuery = _supabase
          .from('jobs')
          .select('client_id, amount, amount_collect, job_status')
          .eq('amount_collect', true)
          .neq('job_status', 'completed')
          .not('client_id', 'is', null);
      
      if (locationFilter != null) {
        outstandingQuery = outstandingQuery.eq('location', locationFilter);
      } else if (location == LocationFilter.unspecified) {
        outstandingQuery = outstandingQuery.isFilter('location', null);
      }
      
      final jobsWithOutstanding = await outstandingQuery;
      final clientsWithOutstanding = <String>{};
      double totalOutstandingAmount = 0.0;
      for (final job in jobsWithOutstanding) {
        final clientId = job['client_id']?.toString() ?? '';
        if (clientId.isNotEmpty) {
          clientsWithOutstanding.add(clientId);
          if (job['amount'] != null) {
            totalOutstandingAmount += (job['amount'] as num).toDouble();
          }
        }
      }

      // Average quote to job conversion rate
      double averageQuoteToJobConversionRate = 0.0;
      if (clientStats.isNotEmpty) {
        int totalQuotes = 0;
        int totalJobs = 0;
        for (final stats in clientStats.values) {
          totalQuotes += stats['quoteCount'] as int;
          totalJobs += stats['jobCount'] as int;
        }
        averageQuoteToJobConversionRate = totalQuotes > 0 ? (totalJobs / totalQuotes) * 100 : 0.0;
      }

      // Clients by location (for location-filtered, this will be the filtered location)
      final clientsByLocationCount = <String, int>{};
      if (locationFilter != null) {
        clientsByLocationCount[locationFilter] = clientStats.keys.length;
      } else {
        final jobsWithLocation = await _supabase
            .from('jobs')
            .select('client_id, location')
            .gte('created_at', dateRange.start.toIso8601String())
            .lte('created_at', dateRange.end.toIso8601String())
            .not('client_id', 'is', null);
        
        final clientsByLocation = <String, Set<String>>{};
        for (final job in jobsWithLocation) {
          final loc = (job['location'] ?? 'Unspecified').toString();
          final clientId = job['client_id']?.toString() ?? '';
          if (clientId.isNotEmpty) {
            if (!clientsByLocation.containsKey(loc)) {
              clientsByLocation[loc] = <String>{};
            }
            clientsByLocation[loc]!.add(clientId);
          }
        }
        clientsByLocationCount.addAll(clientsByLocation.map((key, value) => MapEntry(key, value.length)));
      }

      // Revenue growth by client (simplified for location filter)
      final revenueGrowthByClient = <String, double>{};

      // Average job value per client
      final averageJobValuePerClient = totalClientJobs > 0 ? totalClientRevenue / totalClientJobs : 0.0;

      // Most active client
      TopClient? mostActiveClient;
      if (top5Clients.isNotEmpty) {
        mostActiveClient = top5Clients.reduce((a, b) => a.jobCount > b.jobCount ? a : b);
      }

      // Clients with no jobs in period
      final clientsWithJobsSet = clientStats.keys.toSet();
      final clientsWithNoJobs = totalClients - clientsWithJobsSet.length;

      final clientInsights = ClientInsights(
        totalClients: totalClients,
        activeClients: totalClients, // All clients are considered active
        averageJobsPerClient: averageJobsPerClient,
        averageRevenuePerClient: averageRevenuePerClient,
        topClients: top5Clients,
        topClientsByRevenue: topClientsByRevenueList,
        clientRetentionRate: clientRetentionRate,
        newClientsThisPeriod: newClientsThisPeriod,
        repeatClientsCount: repeatClientsCount,
        averageDaysBetweenJobs: averageDaysBetweenJobs,
        topClientByJobFrequency: topClientByJobFrequency,
        clientsWithOutstandingPayments: clientsWithOutstanding.length,
        totalOutstandingAmount: totalOutstandingAmount,
        averageQuoteToJobConversionRate: averageQuoteToJobConversionRate,
        clientsByLocation: clientsByLocationCount,
        revenueGrowthByClient: revenueGrowthByClient,
        averageJobValuePerClient: averageJobValuePerClient,
        mostActiveClient: mostActiveClient,
        clientsWithNoJobs: clientsWithNoJobs,
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

      // Revenue this week - Fixed calculation
      final now = DateTime.now();
      final weekStart = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1)); // Monday of current week
      final weekEnd = weekStart.add(Duration(days: 7));
      
      final revenueThisWeekResponse = await _supabase
          .from('jobs')
          .select('amount')
          .eq('job_status', 'completed')
          .gte('created_at', weekStart.toIso8601String())
          .lt('created_at', weekEnd.toIso8601String())
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

      // Sprint 1: Calculate new financial metrics
      // Get all jobs with payment and location data
      final allJobsData = await _supabase
          .from('jobs')
          .select('amount, amount_collect, job_status, location')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String());

      // Calculate payment collection rate
      int jobsWithCollectPayment = 0;
      int collectedPayments = 0;
      double totalCollected = 0.0;
      double totalUncollected = 0.0;
      double outstandingPayments = 0.0;
      double totalPaymentAmount = 0.0;
      int collectedJobsCount = 0;
      final revenueByLocation = <String, double>{'Jhb': 0.0, 'Cpt': 0.0, 'Dbn': 0.0};

      for (final job in allJobsData) {
        final amount = job['amount'] != null ? (job['amount'] as num).toDouble() : 0.0;
        final collectPayment = job['amount_collect'] == true;
        final jobStatus = job['job_status']?.toString() ?? '';
        final location = job['location']?.toString() ?? '';

        // Revenue by location (only completed jobs) - Fixed: case-insensitive matching
        if (jobStatus == 'completed' && amount > 0) {
          final locationUpper = location.toUpperCase().trim();
          if (locationUpper == 'JHB' || locationUpper == 'CPT' || locationUpper == 'DBN') {
            // Normalize to standard format
            final normalizedLocation = locationUpper == 'JHB' ? 'Jhb' 
                                      : locationUpper == 'CPT' ? 'Cpt' 
                                      : 'Dbn';
            revenueByLocation[normalizedLocation] = (revenueByLocation[normalizedLocation] ?? 0.0) + amount;
          } else if (locationUpper.isNotEmpty) {
            // Handle unexpected location values
            revenueByLocation['Other'] = (revenueByLocation['Other'] ?? 0.0) + amount;
          }
        }

        // Payment collection metrics
        if (collectPayment) {
          jobsWithCollectPayment++;
          if (jobStatus == 'completed' && amount > 0) {
            collectedPayments++;
            totalCollected += amount;
            totalPaymentAmount += amount;
            collectedJobsCount++;
          } else if (jobStatus != 'completed' && amount > 0) {
            totalUncollected += amount;
            outstandingPayments += amount;
          }
        }
      }

      // Payment collection rate - return null if no data
      final paymentCollectionRate = jobsWithCollectPayment > 0
          ? (collectedPayments / jobsWithCollectPayment) * 100
          : null;

      // Average payment amount
      final averagePaymentAmount = collectedJobsCount > 0
          ? totalPaymentAmount / collectedJobsCount
          : 0.0;

      // Calculate revenue growth (week-over-week and month-over-month)
      final lastWeekStart = weekStart.subtract(Duration(days: 7));
      final lastWeekEnd = weekStart;
      final lastWeekRevenueResponse = await _supabase
          .from('jobs')
          .select('amount')
          .eq('job_status', 'completed')
          .gte('created_at', lastWeekStart.toIso8601String())
          .lt('created_at', lastWeekEnd.toIso8601String())
          .not('amount', 'is', null);
      
      final lastWeekRevenue = lastWeekRevenueResponse
          .where((j) => j['amount'] != null)
          .fold<double>(0.0, (sum, job) => sum + (job['amount'] as num).toDouble());

      final revenueGrowthWeekOverWeek = lastWeekRevenue > 0
          ? ((revenueThisWeek - lastWeekRevenue) / lastWeekRevenue) * 100
          : 0.0;

      // Month-over-month growth
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = DateTime(now.year, now.month, 1);
      final lastMonthRevenueResponse = await _supabase
          .from('jobs')
          .select('amount')
          .eq('job_status', 'completed')
          .gte('created_at', lastMonthStart.toIso8601String())
          .lt('created_at', lastMonthEnd.toIso8601String())
          .not('amount', 'is', null);
      
      final lastMonthRevenue = lastMonthRevenueResponse
          .where((j) => j['amount'] != null)
          .fold<double>(0.0, (sum, job) => sum + (job['amount'] as num).toDouble());

      final revenueGrowthMonthOverMonth = lastMonthRevenue > 0
          ? ((revenueThisMonth - lastMonthRevenue) / lastMonthRevenue) * 100
          : 0.0;

      final insights = FinancialInsights(
        totalRevenue: totalRevenue,
        revenueThisWeek: revenueThisWeek,
        revenueThisMonth: revenueThisMonth,
        averageJobValue: averageJobValue,
        revenueGrowth: revenueGrowth,
        paymentCollectionRate: paymentCollectionRate,
        revenueByLocation: revenueByLocation,
        outstandingPayments: outstandingPayments,
        totalCollected: totalCollected,
        totalUncollected: totalUncollected,
        averagePaymentAmount: averagePaymentAmount,
        jobsRequiringPaymentCollection: jobsWithCollectPayment,
        revenueGrowthWeekOverWeek: revenueGrowthWeekOverWeek,
        revenueGrowthMonthOverMonth: revenueGrowthMonthOverMonth,
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

      // Revenue this week with location filter - Fixed calculation
      final now = DateTime.now();
      final weekStart = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1)); // Monday of current week
      final weekEnd = weekStart.add(Duration(days: 7));
      
      var weekRevenueQuery = _supabase
          .from('jobs')
          .select('amount')
          .eq('job_status', 'completed')
          .gte('created_at', weekStart.toIso8601String())
          .lt('created_at', weekEnd.toIso8601String())
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

      // Sprint 1: Calculate new financial metrics with location filter
      var allJobsQuery = _supabase
          .from('jobs')
          .select('amount, amount_collect, job_status, location')
          .gte('created_at', dateRange.start.toIso8601String())
          .lte('created_at', dateRange.end.toIso8601String());
      
      if (locationFilter != null) {
        allJobsQuery = allJobsQuery.eq('location', locationFilter);
      } else if (location == LocationFilter.unspecified) {
        allJobsQuery = allJobsQuery.isFilter('location', null);
      }
      
      final allJobsData = await allJobsQuery;

      // Calculate payment collection rate
      int jobsWithCollectPayment = 0;
      int collectedPayments = 0;
      double totalCollected = 0.0;
      double totalUncollected = 0.0;
      double outstandingPayments = 0.0;
      double totalPaymentAmount = 0.0;
      int collectedJobsCount = 0;
      final revenueByLocation = <String, double>{'Jhb': 0.0, 'Cpt': 0.0, 'Dbn': 0.0};

      for (final job in allJobsData) {
        final amount = job['amount'] != null ? (job['amount'] as num).toDouble() : 0.0;
        final collectPayment = job['amount_collect'] == true;
        final jobStatus = job['job_status']?.toString() ?? '';
        final locationStr = job['location']?.toString() ?? '';

        // Revenue by location (only completed jobs) - Fixed: case-insensitive matching
        if (jobStatus == 'completed' && amount > 0) {
          final locationUpper = locationStr.toUpperCase().trim();
          if (locationUpper == 'JHB' || locationUpper == 'CPT' || locationUpper == 'DBN') {
            // Normalize to standard format
            final normalizedLocation = locationUpper == 'JHB' ? 'Jhb' 
                                      : locationUpper == 'CPT' ? 'Cpt' 
                                      : 'Dbn';
            revenueByLocation[normalizedLocation] = (revenueByLocation[normalizedLocation] ?? 0.0) + amount;
          } else if (locationUpper.isNotEmpty) {
            // Handle unexpected location values
            revenueByLocation['Other'] = (revenueByLocation['Other'] ?? 0.0) + amount;
          }
        }

        // Payment collection metrics
        if (collectPayment) {
          jobsWithCollectPayment++;
          if (jobStatus == 'completed' && amount > 0) {
            collectedPayments++;
            totalCollected += amount;
            totalPaymentAmount += amount;
            collectedJobsCount++;
          } else if (jobStatus != 'completed' && amount > 0) {
            totalUncollected += amount;
            outstandingPayments += amount;
          }
        }
      }

      // Payment collection rate - return null if no data
      final paymentCollectionRate = jobsWithCollectPayment > 0
          ? (collectedPayments / jobsWithCollectPayment) * 100
          : null;

      // Average payment amount
      final averagePaymentAmount = collectedJobsCount > 0
          ? totalPaymentAmount / collectedJobsCount
          : 0.0;

      // Calculate revenue growth (week-over-week and month-over-month)
      final lastWeekStart = weekStart.subtract(Duration(days: 7));
      final lastWeekEnd = weekStart;
      var lastWeekRevenueQuery = _supabase
          .from('jobs')
          .select('amount')
          .eq('job_status', 'completed')
          .gte('created_at', lastWeekStart.toIso8601String())
          .lt('created_at', lastWeekEnd.toIso8601String())
          .not('amount', 'is', null);
      
      if (locationFilter != null) {
        lastWeekRevenueQuery = lastWeekRevenueQuery.eq('location', locationFilter);
      } else if (location == LocationFilter.unspecified) {
        lastWeekRevenueQuery = lastWeekRevenueQuery.isFilter('location', null);
      }
      
      final lastWeekRevenueResponse = await lastWeekRevenueQuery;
      final lastWeekRevenue = lastWeekRevenueResponse
          .where((j) => j['amount'] != null)
          .fold<double>(0.0, (sum, job) => sum + (job['amount'] as num).toDouble());

      final revenueGrowthWeekOverWeek = lastWeekRevenue > 0
          ? ((revenueThisWeek - lastWeekRevenue) / lastWeekRevenue) * 100
          : 0.0;

      // Month-over-month growth
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = DateTime(now.year, now.month, 1);
      var lastMonthRevenueQuery = _supabase
          .from('jobs')
          .select('amount')
          .eq('job_status', 'completed')
          .gte('created_at', lastMonthStart.toIso8601String())
          .lt('created_at', lastMonthEnd.toIso8601String())
          .not('amount', 'is', null);
      
      if (locationFilter != null) {
        lastMonthRevenueQuery = lastMonthRevenueQuery.eq('location', locationFilter);
      } else if (location == LocationFilter.unspecified) {
        lastMonthRevenueQuery = lastMonthRevenueQuery.isFilter('location', null);
      }
      
      final lastMonthRevenueResponse = await lastMonthRevenueQuery;
      final lastMonthRevenue = lastMonthRevenueResponse
          .where((j) => j['amount'] != null)
          .fold<double>(0.0, (sum, job) => sum + (job['amount'] as num).toDouble());

      final revenueGrowthMonthOverMonth = lastMonthRevenue > 0
          ? ((revenueThisMonth - lastMonthRevenue) / lastMonthRevenue) * 100
          : 0.0;

      final financialInsights = FinancialInsights(
        totalRevenue: totalRevenue,
        revenueThisWeek: revenueThisWeek,
        revenueThisMonth: revenueThisMonth,
        averageJobValue: revenueResponse.isNotEmpty ? totalRevenue / revenueResponse.length : 0.0,
        revenueGrowth: 0.0, // TODO: Calculate revenue growth
        paymentCollectionRate: paymentCollectionRate,
        revenueByLocation: revenueByLocation,
        outstandingPayments: outstandingPayments,
        totalCollected: totalCollected,
        totalUncollected: totalUncollected,
        averagePaymentAmount: averagePaymentAmount,
        jobsRequiringPaymentCollection: jobsWithCollectPayment,
        revenueGrowthWeekOverWeek: revenueGrowthWeekOverWeek,
        revenueGrowthMonthOverMonth: revenueGrowthMonthOverMonth,
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
  /// Fetch client statement for a specific client and date range
  Future<Result<ClientStatementData>> fetchClientStatement({
    required String clientId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      Log.d('Fetching client statement for client: $clientId, from ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');
      
      // Get client information
      final clientResponse = await _supabase
          .from('clients')
          .select('id, company_name')
          .eq('id', clientId)
          .single();
      
      final clientName = clientResponse['company_name'] ?? 'Unknown Client';
      
      // Get jobs for this client in the date range
      final jobsResponse = await _supabase
          .from('jobs')
          .select('id, job_number, job_start_date, job_status, amount, amount_collect, created_at, updated_at, vehicle_id')
          .eq('client_id', clientId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: false);
      
      if (jobsResponse.isEmpty) {
        return Result.success(ClientStatementData(
          clientId: clientId,
          clientName: clientName,
          statementPeriod: ClientStatementDateRange(start: startDate, end: endDate),
          jobs: [],
          totalRevenue: 0.0,
          totalJobs: 0,
          outstandingAmount: 0.0,
          collectedAmount: 0.0,
        ));
      }
      
      // Get transport details for these jobs
      final jobIds = jobsResponse.map((j) => j['id']).toList();
      final transportResponse = await _supabase
          .from('transport')
          .select('job_id, pickup_date, pickup_location, dropoff_location, client_pickup_time, client_dropoff_time')
          .inFilter('job_id', jobIds);
      
      // Get vehicle details for these jobs
      final vehiclesResponse = await _supabase
          .from('vehicles')
          .select('id, make, model, reg_plate');
      
      // Get payment collection status from driver_flow
      final driverFlowResponse = await _supabase
          .from('driver_flow')
          .select('job_id, payment_collected_ind, job_closed_time')
          .inFilter('job_id', jobIds);
      
      // Build statement jobs
      final statementJobs = <ClientStatementJob>[];
      double totalRevenue = 0.0;
      double outstandingAmount = 0.0;
      double collectedAmount = 0.0;
      
      for (final job in jobsResponse) {
        final jobId = job['id'].toString();
        
        // Find transport for this job
        final transport = transportResponse.firstWhere(
          (t) => t['job_id'].toString() == jobId,
          orElse: () => {},
        );
        
        // Find vehicle for this job
        final vehicleId = job['vehicle_id']?.toString();
        Map<String, dynamic>? vehicle;
        if (vehicleId != null) {
          vehicle = vehiclesResponse.firstWhere(
            (v) => v['id'].toString() == vehicleId,
            orElse: () => {},
          );
        }
        
        // Find payment collection status
        final driverFlow = driverFlowResponse.firstWhere(
          (df) => df['job_id'].toString() == jobId,
          orElse: () => {},
        );
        
        final amount = (job['amount'] as num?)?.toDouble() ?? 0.0;
        final paymentCollected = driverFlow['payment_collected_ind'] == true;
        final paymentDate = driverFlow['job_closed_time'] != null
            ? DateTime.parse(driverFlow['job_closed_time'])
            : null;
        
        totalRevenue += amount;
        if (job['amount_collect'] == true && job['job_status'] != 'completed') {
          outstandingAmount += amount;
        } else if (paymentCollected) {
          collectedAmount += amount;
        }
        
        final jobDate = job['job_start_date'] != null
            ? DateTime.parse(job['job_start_date'])
            : DateTime.parse(job['created_at']);
        
        statementJobs.add(ClientStatementJob(
          jobId: jobId,
          jobNumber: job['job_number']?.toString(),
          jobDate: jobDate,
          jobStatus: job['job_status'] ?? 'unknown',
          pickupLocation: transport['pickup_location']?.toString() ?? 'N/A',
          dropoffLocation: transport['dropoff_location']?.toString() ?? 'N/A',
          pickupDate: transport['pickup_date'] != null
              ? DateTime.parse(transport['pickup_date'])
              : null,
          dropoffDate: transport['client_dropoff_time'] != null
              ? DateTime.parse(transport['client_dropoff_time'])
              : null,
          vehicleMake: vehicle?['make']?.toString(),
          vehicleModel: vehicle?['model']?.toString(),
          vehicleRegPlate: vehicle?['reg_plate']?.toString(),
          amount: amount,
          paymentCollected: paymentCollected,
          paymentDate: paymentDate,
        ));
      }
      
      // Sort jobs by date (newest first)
      statementJobs.sort((a, b) => b.jobDate.compareTo(a.jobDate));
      
      final statementData = ClientStatementData(
        clientId: clientId,
        clientName: clientName,
        statementPeriod: ClientStatementDateRange(start: startDate, end: endDate),
        jobs: statementJobs,
        totalRevenue: totalRevenue,
        totalJobs: statementJobs.length,
        outstandingAmount: outstandingAmount,
        collectedAmount: collectedAmount,
      );
      
      Log.d('Client statement fetched: ${statementJobs.length} jobs, R${totalRevenue.toStringAsFixed(2)} total revenue');
      return Result.success(statementData);
    } catch (error) {
      Log.e('Error fetching client statement: $error');
      return _mapSupabaseError(error);
    }
  }

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
