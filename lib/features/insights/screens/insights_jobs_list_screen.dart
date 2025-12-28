import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/features/insights/models/insights_data.dart';
import 'package:choice_lux_cars/features/jobs/jobs.dart';
import 'package:choice_lux_cars/features/clients/providers/clients_provider.dart';
import 'package:choice_lux_cars/features/vehicles/vehicles.dart';
import 'package:choice_lux_cars/features/users/users.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/widgets/system_safe_scaffold.dart';
import 'package:choice_lux_cars/shared/widgets/pagination_widget.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';

class InsightsJobsListScreen extends ConsumerStatefulWidget {
  final TimePeriod timePeriod;
  final LocationFilter location;
  final String status; // 'all', 'completed', 'open'

  const InsightsJobsListScreen({
    super.key,
    required this.timePeriod,
    required this.location,
    required this.status,
  });

  @override
  ConsumerState<InsightsJobsListScreen> createState() => _InsightsJobsListScreenState();
}

class _InsightsJobsListScreenState extends ConsumerState<InsightsJobsListScreen> {
  int _currentPage = 1;
  final int _itemsPerPage = 12;
  List<Job> _jobs = [];
  int _totalJobs = 0;
  bool _isLoading = false;
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
      final repository = ref.read(jobsRepositoryProvider);

      // Get date range from time period
      final dateRange = _getDateRange(widget.timePeriod);

      // Map location filter to branch_id
      int? branchId;
      switch (widget.location) {
        case LocationFilter.jhb:
          branchId = 3; // Johannesburg
          break;
        case LocationFilter.cpt:
          branchId = 2; // Cape Town
          break;
        case LocationFilter.dbn:
          branchId = 1; // Durban
          break;
        case LocationFilter.all:
        case LocationFilter.unspecified:
          branchId = null;
          break;
      }

      final offset = (_currentPage - 1) * _itemsPerPage;

      final currentUser = ref.read(currentUserProfileProvider);
      final role = currentUser?.role?.toLowerCase();
      final managerId =
          role == 'manager' ? currentUser?.id : null;

      final result = await repository.fetchJobsWithInsightsFilters(
        startDate: dateRange.start,
        endDate: dateRange.end,
        branchId: branchId,
        status: widget.status,
        limit: _itemsPerPage,
        offset: offset,
        managerId: managerId,
      );

      if (result.isSuccess) {
        final data = result.data as Map<String, dynamic>;
        setState(() {
          _jobs = data['jobs'] as List<Job>;
          _totalJobs = data['total'] as int;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result.error?.toString() ?? 'Failed to load jobs';
          _isLoading = false;
        });
      }
    } catch (e) {
      Log.e('Error loading jobs: $e');
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
        return DateRange(today, today.add(const Duration(days: 1)));
      case TimePeriod.tomorrow:
        return DateRange(tomorrow, tomorrow.add(const Duration(days: 1)));
      case TimePeriod.next3Days:
        // Next 3 days: tomorrow + 2 days after (3 days total)
        return DateRange(tomorrow, tomorrow.add(const Duration(days: 3)));
    }
  }

  String _getStatusLabel() {
    switch (widget.status) {
      case 'all':
        return 'All Jobs';
      case 'completed':
        return 'Completed Jobs';
      case 'open':
        return 'Open Jobs';
      default:
        return 'Jobs';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(screenWidth);
    final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
    final isTablet = ResponsiveBreakpoints.isTablet(screenWidth);
    final isDesktop = ResponsiveBreakpoints.isDesktop(screenWidth);

    final clientsAsync = ref.watch(clientsProvider);
    final vehiclesState = ref.watch(vehiclesProvider);
    final users = ref.watch(usersProvider);
    final userProfile = ref.watch(currentUserProfileProvider);

    final userRole = userProfile?.role?.toLowerCase();
    final canCreateVoucher =
        userRole == 'administrator' ||
        userRole == 'manager' ||
        userRole == 'driver_manager' ||
        userRole == 'drivermanager';
    final canCreateInvoice = canCreateVoucher;

    return SystemSafeScaffold(
      appBar: LuxuryAppBar(
        title: _getStatusLabel(),
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
                  '$_totalJobs jobs',
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
                                  'No jobs found',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : clientsAsync.when(
                            data: (clients) => Column(
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _jobs.length,
                                    itemBuilder: (context, index) {
                                      final job = _jobs[index];
                                      final client = clients.firstWhere(
                                        (c) => c.id.toString() == job.clientId,
                                        orElse: () => clients.first,
                                      );
                                      final vehicle = (vehiclesState.value ?? []).firstWhere(
                                        (v) => v.id.toString() == job.vehicleId,
                                        orElse: () => (vehiclesState.value ?? []).first,
                                      );
                                      final driver = (users.value ?? []).firstWhere(
                                        (u) => u.id == job.driverId,
                                        orElse: () => (users.value ?? []).first,
                                      );

                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: JobListCard(
                                          job: job,
                                          client: client,
                                          vehicle: vehicle,
                                          driver: driver,
                                          isSmallMobile: isSmallMobile,
                                          isMobile: isMobile,
                                          isTablet: isTablet,
                                          isDesktop: isDesktop,
                                          canCreateVoucher: canCreateVoucher,
                                          canCreateInvoice: canCreateInvoice,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                if (_totalJobs > _itemsPerPage)
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: PaginationWidget(
                                      currentPage: _currentPage,
                                      totalPages: (_totalJobs / _itemsPerPage).ceil(),
                                      onPageChanged: (page) {
                                        setState(() {
                                          _currentPage = page;
                                        });
                                        _loadJobs();
                                      },
                                      totalItems: _totalJobs,
                                      itemsPerPage: _itemsPerPage,
                                    ),
                                  ),
                              ],
                            ),
                            loading: () => const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(ChoiceLuxTheme.richGold),
                              ),
                            ),
                            error: (error, stack) => Center(
                              child: Text(
                                'Error loading clients: $error',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

