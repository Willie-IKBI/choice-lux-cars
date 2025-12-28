import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/features/insights/models/insights_data.dart';
import 'package:choice_lux_cars/features/insights/data/insights_repository.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/widgets/system_safe_scaffold.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

class CompletedJobDetail {
  final int jobId;
  final String jobNumber;
  final String driverName;
  final String? managerName;
  final double kmTraveled;
  final double timeHours;

  CompletedJobDetail({
    required this.jobId,
    required this.jobNumber,
    required this.driverName,
    this.managerName,
    required this.kmTraveled,
    required this.timeHours,
  });
}

class CompletedJobsDetailsScreen extends ConsumerStatefulWidget {
  final TimePeriod timePeriod;
  final LocationFilter location;
  final String metricType; // 'km' or 'time'

  const CompletedJobsDetailsScreen({
    super.key,
    required this.timePeriod,
    required this.location,
    required this.metricType,
  });

  @override
  ConsumerState<CompletedJobsDetailsScreen> createState() => _CompletedJobsDetailsScreenState();
}

class _CompletedJobsDetailsScreenState extends ConsumerState<CompletedJobsDetailsScreen> {
  List<CompletedJobDetail> _jobs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(insightsRepositoryProvider);
      
      final dateRange = _getDateRange(widget.timePeriod);
      
      final result = await repository.fetchCompletedJobsWithMetrics(
        startDate: dateRange.start,
        endDate: dateRange.end,
        location: widget.location,
      );

      if (result.isSuccess) {
        final data = result.data!;
        // Sort by the relevant metric
        if (widget.metricType == 'km') {
          data.sort((a, b) => (b['kmTraveled'] as double).compareTo(a['kmTraveled'] as double));
        } else {
          data.sort((a, b) => (b['timeHours'] as double).compareTo(a['timeHours'] as double));
        }
        
        setState(() {
          _jobs = data.map((item) => CompletedJobDetail(
            jobId: item['jobId'] as int,
            jobNumber: item['jobNumber'] as String,
            driverName: item['driverName'] as String,
            managerName: item['managerName'] as String?,
            kmTraveled: item['kmTraveled'] as double,
            timeHours: item['timeHours'] as double,
          )).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result.error?.toString() ?? 'Failed to load jobs';
          _isLoading = false;
        });
      }
    } catch (e) {
      Log.e('Error loading completed jobs details: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  DateRange _getDateRange(TimePeriod period) {
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
        return DateRange(today, today.add(const Duration(days: 1)));
      case TimePeriod.tomorrow:
        return DateRange(tomorrow, tomorrow.add(const Duration(days: 1)));
      case TimePeriod.next3Days:
        return DateRange(tomorrow, tomorrow.add(const Duration(days: 3)));
    }
  }

  String _formatDuration(double hours) {
    if (hours < 0) return '0 min';
    
    final totalMinutes = (hours * 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    
    if (h > 0 && m > 0) {
      return '$h ${h == 1 ? 'hr' : 'hrs'} ${m}min';
    } else if (h > 0) {
      return '$h ${h == 1 ? 'hour' : 'hours'}';
    } else if (m > 0) {
      return '$m min';
    } else {
      return '< 1 min';
    }
  }

  String _getTitle() {
    if (widget.metricType == 'km') {
      return 'Average Km per Job - Details';
    } else {
      return 'Average Time per Job - Details';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 600;

    return SystemSafeScaffold(
      appBar: LuxuryAppBar(
        title: _getTitle(),
        showBackButton: true,
        onBackPressed: () => context.go('/insights'),
        onSignOut: () async {
          await ref.read(authProvider.notifier).signOut();
        },
      ),
      body: Column(
        children: [
          // Filter info bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: ChoiceLuxTheme.richGold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.timePeriod.displayName} • ${widget.location.displayName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_jobs.length} jobs',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Jobs list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(ChoiceLuxTheme.richGold),
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading jobs',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadJobs,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ChoiceLuxTheme.richGold,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _jobs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.work_off,
                                  color: Colors.white.withOpacity(0.5),
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No completed jobs found',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.all(isDesktop ? 24 : 16),
                            itemCount: _jobs.length,
                            itemBuilder: (context, index) {
                              final job = _jobs[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                                ),
                                child: Row(
                                  children: [
                                    // Driver icon
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: ChoiceLuxTheme.richGold.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        color: ChoiceLuxTheme.richGold,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Driver name and job number
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            job.driverName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Job #${job.jobNumber}',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.7),
                                              fontSize: 14,
                                            ),
                                          ),
                                          if (job.managerName != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Manager: ${job.managerName}',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.6),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    // Metric value
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        if (widget.metricType == 'km')
                                          Text(
                                            '${job.kmTraveled.toStringAsFixed(1)} km',
                                            style: TextStyle(
                                              color: Colors.teal,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        else
                                          Text(
                                            _formatDuration(job.timeHours),
                                            style: TextStyle(
                                              color: Colors.purple,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        Text(
                                          widget.metricType == 'km' ? 'Distance' : 'Duration',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.6),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

