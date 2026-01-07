import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/jobs/providers/jobs_provider.dart';
import 'package:choice_lux_cars/features/jobs/models/job.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';

import 'package:choice_lux_cars/features/clients/providers/clients_provider.dart';
import 'package:choice_lux_cars/features/vehicles/providers/vehicles_provider.dart';
import 'package:choice_lux_cars/features/users/providers/users_provider.dart';
import 'package:choice_lux_cars/features/clients/models/client.dart';
import 'package:choice_lux_cars/features/vehicles/models/vehicle.dart';
import 'package:choice_lux_cars/features/users/models/user.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_drawer.dart';
import 'package:choice_lux_cars/shared/widgets/system_safe_scaffold.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';
import 'package:choice_lux_cars/shared/widgets/pagination_widget.dart';

import 'package:choice_lux_cars/features/jobs/widgets/job_card.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen>
    with WidgetsBindingObserver {
  String _currentFilter = 'open'; // open, in_progress, closed, all
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 12;
  String _dateRangeFilter = '90'; // '7', '30', '90', 'all' - days for completed jobs

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      // Refresh jobs when app is resumed
      ref.read(jobsProvider.notifier).fetchJobs();
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      // Use centralized responsive system with enhanced mobile-first approach
      final screenWidth = MediaQuery.of(context).size.width;
      final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(screenWidth);
      final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
      final isTablet = ResponsiveBreakpoints.isTablet(screenWidth);
      final isDesktop = ResponsiveBreakpoints.isDesktop(screenWidth);

      final jobs = ref.watch(jobsProvider);
      final canCreateJobs = ref.watch(jobsProvider.notifier).canCreateJobs;

      // Load related data
      final vehiclesState = ref.watch(vehiclesProvider);
      final users = ref.watch(usersProvider);
      final clientsAsync = ref.watch(clientsProvider);
      final userProfile = ref.watch(currentUserProfileProvider);

      // Debug information
      Log.d('=== JOBS SCREEN DEBUG ===');
      Log.d('Current user: ${userProfile?.id} (${userProfile?.role})');
      Log.d('Total jobs in provider: ${(jobs.value ?? []).length}');
      if ((jobs.value ?? []).isNotEmpty) {
        final firstJob = (jobs.value ?? []).first;
        Log.d('Sample job: ${firstJob.id} - ${firstJob.status} - ${firstJob.passengerName}');
        Log.d('Sample job confirmation: isConfirmed=${firstJob.isConfirmed}, driverConfirmation=${firstJob.driverConfirmation}');
      }

      // Check if user can create vouchers based on role
      final userRole = userProfile?.role?.toLowerCase();
      final canCreateVoucher = userRole == 'administrator' ||
          userRole == 'super_admin' ||
          userRole == 'manager' ||
          userRole == 'driver_manager' ||
          userRole == 'drivermanager';

      // Check if user can create invoices (same permissions as vouchers for now)
      final canCreateInvoice = canCreateVoucher;

      // Apply filters
      List<Job> filteredJobs = _filterJobs(jobs.value ?? []);
      Log.d('Filtered jobs: ${filteredJobs.length} (filter: $_currentFilter)');

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        filteredJobs = filteredJobs.where((job) {
          final passengerName = job.passengerName?.toLowerCase() ?? '';
          final clientName = job.clientId.toString().toLowerCase();
          final searchLower = _searchQuery.toLowerCase();
          return passengerName.contains(searchLower) ||
              clientName.contains(searchLower) ||
              job.id.toString().toLowerCase().contains(searchLower);
        }).toList();
      }

      // Pagination
      final totalPages = (filteredJobs.length / _itemsPerPage).ceil();
      final startIndex = (_currentPage - 1) * _itemsPerPage;
      final endIndex = startIndex + _itemsPerPage;
      final paginatedJobs = filteredJobs.sublist(
        startIndex,
        endIndex > filteredJobs.length ? filteredJobs.length : endIndex,
      );

      // Responsive padding - matching dashboard screen
      final horizontalPadding = isSmallMobile ? 8.0 : isMobile ? 12.0 : 24.0;
      final verticalPadding = isSmallMobile ? 8.0 : isMobile ? 12.0 : 8.0;
      final sectionSpacing = isSmallMobile ? 16.0 : isMobile ? 24.0 : 12.0;

      return Stack(
        children: [
          Container(color: ChoiceLuxTheme.jetBlack),
          SystemSafeScaffold(
            backgroundColor: Colors.transparent,
            appBar: LuxuryAppBar(
              title: 'Jobs',
              showBackButton: true,
              onBackPressed: () => context.go('/'),
            ),
            drawer: const LuxuryDrawer(),
            body: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    children: [
                      _buildFilterSection(isSmallMobile, isMobile, isTablet, isDesktop),
                      SizedBox(height: sectionSpacing),
                      _buildSearchSection(isSmallMobile, isMobile, isTablet, isDesktop, canCreateJobs),
                      SizedBox(height: sectionSpacing * 0.5),
                      _buildResultsCount(
                        filteredJobs.length,
                        isSmallMobile,
                        isMobile,
                        isTablet,
                        isDesktop,
                      ),
                      SizedBox(height: sectionSpacing),
                      paginatedJobs.isEmpty
                          ? _buildEmptyState(
                              isSmallMobile,
                              isMobile,
                              isTablet,
                              isDesktop,
                            )
                          : clientsAsync.when(
                              data: (clients) => _buildJobsList(
                                paginatedJobs,
                                clients,
                                (vehiclesState.value ?? []),
                                (users.value ?? []),
                                isSmallMobile,
                                isMobile,
                                isTablet,
                                isDesktop,
                                canCreateVoucher,
                                canCreateInvoice,
                              ),
                              loading: () => _buildLoadingState(
                                isSmallMobile,
                                isMobile,
                                isTablet,
                                isDesktop,
                              ),
                              error: (error, stack) => _buildErrorState(
                                error,
                                isSmallMobile,
                                isMobile,
                                isTablet,
                                isDesktop,
                              ),
                            ),
                      SizedBox(height: sectionSpacing),
                      if (totalPages > 1)
                        _buildPaginationSection(
                          totalPages,
                          filteredJobs.length,
                          isSmallMobile,
                          isMobile,
                          isTablet,
                          isDesktop,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } catch (e, stackTrace) {
      Log.e('Jobs build error: $e', e, stackTrace);
      return Scaffold(
        backgroundColor: ChoiceLuxTheme.jetBlack,
        appBar: const LuxuryAppBar(
          title: 'Jobs',
          subtitle: 'ERROR',
          showBackButton: true,
        ),
        body: const Center(
          child: Text(
            'An unexpected error occurred while rendering Jobs.',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }
  }

  // Enhanced Filter Section
  Widget _buildFilterSection(
    bool isSmallMobile,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    final padding = ResponsiveTokens.getPadding(
      MediaQuery.of(context).size.width,
    );
    final spacing = ResponsiveTokens.getSpacing(
      MediaQuery.of(context).size.width,
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status filter buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterButton(
                  'Open Jobs',
                  'open',
                  isSmallMobile,
                  isMobile,
                  isTablet,
                  isDesktop,
                ),
                SizedBox(
                  width: isSmallMobile
                      ? 6
                      : isMobile
                      ? 8
                      : 12,
                ),
                _buildFilterButton(
                  'Jobs in Progress',
                  'in_progress',
                  isSmallMobile,
                  isMobile,
                  isTablet,
                  isDesktop,
                ),
                SizedBox(
                  width: isSmallMobile
                      ? 6
                      : isMobile
                      ? 8
                      : 12,
                ),
                _buildFilterButton(
                  'Closed Jobs',
                  'closed',
                  isSmallMobile,
                  isMobile,
                  isTablet,
                  isDesktop,
                ),
                SizedBox(
                  width: isSmallMobile
                      ? 6
                      : isMobile
                      ? 8
                      : 12,
                ),
                _buildFilterButton(
                  'All Jobs',
                  'all',
                  isSmallMobile,
                  isMobile,
                  isTablet,
                  isDesktop,
                ),
              ],
            ),
          ),
          // Date range selector (only show for closed and all filters)
          if (_currentFilter == 'closed' || _currentFilter == 'all') ...[
            SizedBox(height: spacing),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDateRangeChip(
                    'Last 7 Days',
                    '7',
                    isSmallMobile,
                    isMobile,
                  ),
                  SizedBox(width: isSmallMobile ? 6 : 8),
                  _buildDateRangeChip(
                    'Last 30 Days',
                    '30',
                    isSmallMobile,
                    isMobile,
                  ),
                  SizedBox(width: isSmallMobile ? 6 : 8),
                  _buildDateRangeChip(
                    'Last 90 Days',
                    '90',
                    isSmallMobile,
                    isMobile,
                  ),
                  SizedBox(width: isSmallMobile ? 6 : 8),
                  _buildDateRangeChip(
                    'All Time',
                    'all',
                    isSmallMobile,
                    isMobile,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Enhanced Search Section
  Widget _buildSearchSection(
    bool isSmallMobile,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
    bool canCreateJobs,
  ) {
    final padding = ResponsiveTokens.getPadding(
      MediaQuery.of(context).size.width,
    );
    final spacing = ResponsiveTokens.getSpacing(
      MediaQuery.of(context).size.width,
    );
    final cornerRadius = ResponsiveTokens.getCornerRadius(
      MediaQuery.of(context).size.width,
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: spacing),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: isSmallMobile
                    ? 'Search jobs...'
                    : 'Search jobs by passenger name, client, or job ID...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(cornerRadius),
                ),
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.1),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isSmallMobile
                      ? 12
                      : isMobile
                      ? 16
                      : 20,
                  vertical: isSmallMobile
                      ? 8
                      : isMobile
                      ? 12
                      : 16,
                ),
              ),
            ),
          ),
          if (canCreateJobs) ...[
            SizedBox(
              width: isSmallMobile
                  ? 8
                  : isMobile
                  ? 12
                  : 16,
            ),
            Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                return ElevatedButton.icon(
                  onPressed: () => context.go('/jobs/create'),
                  icon: Icon(Icons.add, size: ResponsiveTokens.getIconSize(screenWidth) * 0.75),
              label: Text(
                isSmallMobile ? 'New' : 'Create Job',
                style: TextStyle(
                  fontSize: isSmallMobile ? 12 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ChoiceLuxTheme.richGold,
                    foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallMobile ? 12 : 16,
                  vertical: isSmallMobile ? 8 : 12,
                ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(cornerRadius),
                  ),
                ),
              );
            },
          ),
          ],
          if (_searchQuery.isNotEmpty) ...[
            SizedBox(
              width: isSmallMobile
                  ? 6
                  : isMobile
                  ? 8
                  : 12,
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallMobile
                    ? 6
                    : isMobile
                    ? 8
                    : 12,
                vertical: isSmallMobile
                    ? 4
                    : isMobile
                    ? 6
                    : 8,
              ),
              decoration: BoxDecoration(
                color: ChoiceLuxTheme.richGold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Filtered: $_currentFilter',
                style: TextStyle(
                  fontSize: ResponsiveTokens.getFontSize(
                    MediaQuery.of(context).size.width,
                    baseSize: 12.0,
                  ),
                  color: ChoiceLuxTheme.richGold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Enhanced Results Count
  Widget _buildResultsCount(
    int count,
    bool isSmallMobile,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    final padding = ResponsiveTokens.getPadding(
      MediaQuery.of(context).size.width,
    );
    final spacing = ResponsiveTokens.getSpacing(
      MediaQuery.of(context).size.width,
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: spacing),
      child: Row(
        children: [
          Text(
            '$count jobs found',
            style: TextStyle(
              fontSize: ResponsiveTokens.getFontSize(
                MediaQuery.of(context).size.width,
                baseSize: 14.0,
              ),
              color: ChoiceLuxTheme.platinumSilver,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced Empty State
  Widget _buildEmptyState(
    bool isSmallMobile,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    final padding = ResponsiveTokens.getPadding(
      MediaQuery.of(context).size.width,
    );
    final spacing = ResponsiveTokens.getSpacing(
      MediaQuery.of(context).size.width,
    );
    final iconSize = ResponsiveTokens.getIconSize(
      MediaQuery.of(context).size.width,
    );
    final fontSize = ResponsiveTokens.getFontSize(
      MediaQuery.of(context).size.width,
      baseSize: 14.0,
    );

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(padding * 2),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.work_outline,
                  size: iconSize * 2,
                  color: ChoiceLuxTheme.platinumSilver,
                ),
                SizedBox(height: spacing * 2),
                Text(
                  'No jobs found',
                  style: TextStyle(
                    fontSize: fontSize + 4,
                    fontWeight: FontWeight.w600,
                    color: ChoiceLuxTheme.softWhite,
                  ),
                ),
                SizedBox(height: spacing),
                Text(
                  'Try adjusting your filters or create a new job',
                  style: TextStyle(
                    color: ChoiceLuxTheme.platinumSilver,
                    fontSize: fontSize,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced Jobs List
  Widget _buildJobsList(
    List<Job> jobs,
    List<Client> clients,
    List<Vehicle> vehicles,
    List<User> users,
    bool isSmallMobile,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
    bool canCreateVoucher,
    bool canCreateInvoice,
  ) {
    final padding = ResponsiveTokens.getPadding(
      MediaQuery.of(context).size.width,
    );
    final spacing = ResponsiveTokens.getSpacing(
      MediaQuery.of(context).size.width,
    );

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: spacing),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];

        // Find related data
        Client? client;
        Vehicle? vehicle;
        User? driver;

        try {
          client = clients.firstWhere((c) => c.id.toString() == job.clientId);
        } catch (e) {
          client = null;
        }

        try {
          vehicle = vehicles.firstWhere(
            (v) => v.id.toString() == job.vehicleId,
          );
        } catch (e) {
          vehicle = null;
        }

        try {
          driver = users.firstWhere((u) => u.id == job.driverId);
        } catch (e) {
          driver = null;
        }

        return Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: JobCard(
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
    );
  }

  // Enhanced Loading State
  Widget _buildLoadingState(
    bool isSmallMobile,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    return const Center(
      child: CircularProgressIndicator(color: ChoiceLuxTheme.richGold),
    );
  }

  // Enhanced Error State
  Widget _buildErrorState(
    Object error,
    bool isSmallMobile,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    final fontSize = ResponsiveTokens.getFontSize(
      MediaQuery.of(context).size.width,
      baseSize: 14.0,
    );

    return Center(
      child: Text(
        'Error loading clients: $error',
        style: TextStyle(fontSize: fontSize, color: ChoiceLuxTheme.errorColor),
      ),
    );
  }

  // Enhanced Pagination Section
  Widget _buildPaginationSection(
    int totalPages,
    int totalItems,
    bool isSmallMobile,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    final padding = ResponsiveTokens.getPadding(
      MediaQuery.of(context).size.width,
    );

    return Container(
      padding: EdgeInsets.all(padding),
      child: PaginationWidget(
        currentPage: _currentPage,
        totalPages: totalPages,
        onPageChanged: (page) => setState(() => _currentPage = page),
        totalItems: totalItems,
        itemsPerPage: _itemsPerPage,
      ),
    );
  }

  // Enhanced Filter Button
  Widget _buildFilterButton(
    String label,
    String filter,
    bool isSmallMobile,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    final isSelected = _currentFilter == filter;
    final fontSize = ResponsiveTokens.getFontSize(
      MediaQuery.of(context).size.width,
      baseSize: 14.0,
    );

    return GestureDetector(
      onTap: () => setState(() {
        _currentFilter = filter;
        _currentPage = 1; // Reset to first page when filter changes
      }),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallMobile
              ? 10
              : isMobile
              ? 14
              : isTablet
              ? 18
              : 20,
          vertical: isSmallMobile
              ? 6
              : isMobile
              ? 8
              : isTablet
              ? 10
              : 12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? ChoiceLuxTheme.richGold : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? ChoiceLuxTheme.richGold
                : ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : ChoiceLuxTheme.platinumSilver,
            fontSize: fontSize,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Date Range Chip
  Widget _buildDateRangeChip(
    String label,
    String value,
    bool isSmallMobile,
    bool isMobile,
  ) {
    final isSelected = _dateRangeFilter == value;
    final fontSize = isSmallMobile ? 11.0 : 12.0;

    return GestureDetector(
      onTap: () => setState(() {
        _dateRangeFilter = value;
        _currentPage = 1; // Reset to first page when date range changes
      }),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallMobile ? 8 : 12,
          vertical: isSmallMobile ? 5 : 7,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? ChoiceLuxTheme.richGold.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? ChoiceLuxTheme.richGold
                : ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? ChoiceLuxTheme.richGold
                : ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.8),
            fontSize: fontSize,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  List<Job> _filterJobs(List<Job> jobs) {
    final now = DateTime.now();
    final cutoffDate = _dateRangeFilter == 'all'
        ? null
        : now.subtract(Duration(days: int.parse(_dateRangeFilter)));
    
    switch (_currentFilter) {
      case 'open':
        // Treat 'open' and 'assigned' as open jobs
        return jobs
            .where((job) => job.status == 'open' || job.status == 'assigned')
            .toList();
      case 'in_progress':
        return jobs
            .where(
              (job) =>
                  job.status == 'in_progress' ||
                  job.status == 'started' ||
                  job.status == 'ready_to_close',
            )
            .toList();
      case 'closed':
        // Closed jobs (completed, closed, cancelled) with date filter (default 90 days)
        var closed = jobs
            .where((job) =>
                job.status == 'completed' ||
                job.status == 'closed' ||
                job.status == 'cancelled')
            .toList();
        
        if (cutoffDate != null) {
          closed = closed.where((job) {
            final jobDate = job.updatedAt ?? job.createdAt;
            return jobDate.isAfter(cutoffDate);
          }).toList();
        }
        return closed;
      case 'all':
        // All jobs, but exclude completed/closed/cancelled older than 90 days
        if (cutoffDate != null) {
          return jobs.where((job) {
            final isCompleted = job.status == 'completed' ||
                job.status == 'closed' ||
                job.status == 'cancelled';
            if (isCompleted) {
              final jobDate = job.updatedAt ?? job.createdAt;
              return jobDate.isAfter(cutoffDate);
            }
            return true; // Include all non-completed jobs
          }).toList();
        }
        return jobs;
      default:
        return jobs;
    }
  }

  void _manualRefresh() {
    ref.read(jobsProvider.notifier).fetchJobs();
  }
}
