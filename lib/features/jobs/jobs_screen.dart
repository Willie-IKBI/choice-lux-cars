import 'dart:async';

import 'package:flutter/foundation.dart';
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
  /// When set (e.g. 'operations'), back button navigates to that route instead of home.
  final String? fromRoute;
  /// Initial main filter: open, in_progress, closed, all.
  final String? initialFilter;
  /// Initial date filter for closed/all: today, yesterday, 7, 30, 90, all.
  final String? initialDateFilter;

  const JobsScreen({
    super.key,
    this.fromRoute,
    this.initialFilter,
    this.initialDateFilter,
  });

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen>
    with WidgetsBindingObserver {
  late String _currentFilter; // open, in_progress, closed, all
  String _searchQuery = '';
  Timer? _searchDebounceTimer;
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  final int _itemsPerPage = 12;
  late String _dateRangeFilter; // 'yesterday', 'today', '7', '30', '90', 'all' - for closed jobs
  String? _openJobsDateFilter = 'today'; // 'yesterday', 'today', 'tomorrow', or null (all). Default: today.
  String? _lastRoute; // Track last route to avoid unnecessary refreshes

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter ?? 'open';
    _dateRangeFilter = widget.initialDateFilter ?? '90';
    if (widget.initialFilter == 'open' || widget.initialFilter == 'all') {
      _openJobsDateFilter = widget.initialDateFilter ?? 'today';
    }
    WidgetsBinding.instance.addObserver(this);
    // Refresh jobs when screen mounts to ensure latest data is loaded
    // This fixes issue where jobs don't show immediately after driver is assigned
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(jobsProvider.notifier).fetchJobs();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh jobs when navigating back to /jobs route
    // This ensures fresh data when returning from job creation or other screens
    final currentRoute = GoRouterState.of(context).matchedLocation;
    if (currentRoute == '/jobs' && _lastRoute != '/jobs') {
      // Only refresh if we're coming from a different route
      if (kDebugMode) Log.d('Navigated to /jobs route, refreshing jobs list...');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(jobsProvider.notifier).fetchJobs();
        }
      });
    }
    _lastRoute = currentRoute;
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
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
      
      // Check if user can create jobs based on role (moved from notifier to avoid LateInitializationError)
      final userProfileForPermissions = ref.watch(currentUserProfileProvider);
      final userRoleForPermissions = userProfileForPermissions?.role?.toLowerCase();
      final canCreateJobs = userRoleForPermissions == 'administrator' ||
          userRoleForPermissions == 'super_admin' ||
          userRoleForPermissions == 'manager' ||
          userRoleForPermissions == 'driver_manager';

      // Load related data (non-blocking - load in parallel)
      final vehiclesState = ref.watch(vehiclesProvider);
      final users = ref.watch(usersProvider);
      final clientsAsync = ref.watch(clientsProvider);
      final userProfile = ref.watch(currentUserProfileProvider);

      // Convert lists to Maps for O(1) lookups (performance optimization)
      // This eliminates O(n) firstWhere searches for each job
      final clientsMap = <String, Client>{};
      final vehiclesMap = <String, Vehicle>{};
      final usersMap = <String, User>{};

      // Build Maps from AsyncValue data (non-blocking - uses cached or loading data)
      // If data is available, build the map. If not, map stays empty and lookups return null.
      if (clientsAsync.hasValue && clientsAsync.value != null) {
        for (final client in clientsAsync.value!) {
          clientsMap[client.id.toString()] = client;
        }
      }

      if (vehiclesState.hasValue && vehiclesState.value != null) {
        for (final vehicle in vehiclesState.value!) {
          vehiclesMap[vehicle.id.toString()] = vehicle;
        }
      }

      if (users.hasValue && users.value != null) {
        for (final user in users.value!) {
          usersMap[user.id] = user;
        }
      }

      if (kDebugMode) {
        Log.d('=== JOBS SCREEN DEBUG ===');
        Log.d('Current user: ${userProfile?.id} (${userProfile?.role})');
        Log.d('Total jobs in provider: ${(jobs.value ?? []).length}');
        if ((jobs.value ?? []).isNotEmpty) {
          final firstJob = (jobs.value ?? []).first;
          Log.d('Sample job: ${firstJob.id} - ${firstJob.status} - ${firstJob.passengerName}');
          Log.d('Sample job confirmation: isConfirmed=${firstJob.isConfirmed}, driverConfirmation=${firstJob.driverConfirmation}');
        }
      }

      // Check if user can create vouchers based on role
      final userRole = userProfile?.role?.toLowerCase();
      final canCreateVoucher = userRole == 'administrator' ||
          userRole == 'super_admin' ||
          userRole == 'manager' ||
          userRole == 'driver_manager';

      // Check if user can create invoices (same permissions as vouchers for now)
      final canCreateInvoice = canCreateVoucher;

      // Apply filters (only if jobs are loaded)
      final allJobs = jobs.value ?? [];
      List<Job> filteredJobs = allJobs;
      
      // Only apply filters if we have data (avoid filtering empty list during loading)
      if (allJobs.isNotEmpty) {
        filteredJobs = _filterJobs(allJobs);
        if (kDebugMode) Log.d('Filtered jobs: ${filteredJobs.length} (filter: $_currentFilter)');
      }

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        filteredJobs = filteredJobs.where((job) {
          final passengerName = job.passengerName?.toLowerCase() ?? '';
          final client = clientsMap[job.clientId];
          final clientSearchText = [
            client?.companyName,
            client?.contactPerson,
          ].whereType<String>().join(' ').toLowerCase();
          return passengerName.contains(searchLower) ||
              clientSearchText.contains(searchLower) ||
              job.id.toString().toLowerCase().contains(searchLower);
        }).toList();
      }

      // Pagination (defensive against range errors when list shrinks)
      final totalPages = filteredJobs.isEmpty ? 1 : (filteredJobs.length / _itemsPerPage).ceil();
      final requestedStart = (_currentPage - 1) * _itemsPerPage;
      final clampedStart =
          requestedStart < 0 ? 0 : (requestedStart >= filteredJobs.length ? 0 : requestedStart);
      final clampedEnd = filteredJobs.isEmpty 
          ? 0 
          : ((clampedStart + _itemsPerPage) > filteredJobs.length
              ? filteredJobs.length
              : clampedStart + _itemsPerPage);
      final paginatedJobs = filteredJobs.isEmpty 
          ? <Job>[]
          : filteredJobs.sublist(clampedStart, clampedEnd);

      // Responsive padding - matching dashboard screen
      final horizontalPadding = isSmallMobile ? 8.0 : isMobile ? 12.0 : 24.0;
      final verticalPadding = isSmallMobile ? 8.0 : isMobile ? 12.0 : 8.0;
      final sectionSpacing = isSmallMobile ? 16.0 : isMobile ? 24.0 : 12.0;

      return Stack(
        children: [
          // Layer 1: Solid background (match dashboard)
          Container(color: ChoiceLuxTheme.jetBlack),
          SystemSafeScaffold(
            backgroundColor: Colors.transparent,
            appBar: LuxuryAppBar(
              title: 'Jobs',
              showBackButton: true,
              onBackPressed: () {
                if (widget.fromRoute == 'operations') {
                  context.go('/admin/operations');
                } else {
                  context.go('/');
                }
              },
            ),
            drawer: const LuxuryDrawer(),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(jobsProvider.notifier).fetchJobs();
                    },
                    color: ChoiceLuxTheme.richGold,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: verticalPadding,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildFilterSection(isSmallMobile, isMobile, isTablet, isDesktop),
                                SizedBox(height: sectionSpacing),
                                _buildSearchSection(isSmallMobile, isMobile, canCreateJobs),
                                SizedBox(height: sectionSpacing * 0.5),
                                _buildResultsCount(
                                  filteredJobs.length,
                                  isSmallMobile,
                                  isMobile,
                                ),
                                SizedBox(height: sectionSpacing),
                              ],
                            ),
                          ),
                        ),
                        jobs.when(
                          data: (_) {
                            if (paginatedJobs.isEmpty) {
                              return SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(
                                  child: _buildEmptyState(isSmallMobile, isMobile),
                                ),
                              );
                            }
                            return _buildJobsListSliver(
                              paginatedJobs,
                              clientsMap,
                              vehiclesMap,
                              usersMap,
                              isSmallMobile,
                              isMobile,
                              isTablet,
                              isDesktop,
                              canCreateVoucher,
                              canCreateInvoice,
                            );
                          },
                          loading: () => SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: _buildLoadingState(isSmallMobile, isMobile),
                            ),
                          ),
                          error: (error, stack) => SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: _buildErrorState(
                                error,
                                isSmallMobile,
                                isMobile,
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(height: sectionSpacing),
                        ),
                        if (totalPages > 1)
                          SliverToBoxAdapter(
                            child: _buildPaginationSection(
                              totalPages,
                              filteredJobs.length,
                              isSmallMobile,
                              isMobile,
                            ),
                          ),
                      ],
                    ),
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
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Jobs build error: $e',
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
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
          // Date filter for open jobs (yesterday, today, tomorrow)
          if (_currentFilter == 'open') ...[
            SizedBox(height: spacing),
            _buildOpenJobsDateFilter(isSmallMobile, isMobile),
          ],
          // Date range selector (only show for closed and all filters)
          if (_currentFilter == 'closed' || _currentFilter == 'all') ...[
            SizedBox(height: spacing),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDateRangeChip(
                    'Yesterday',
                    'yesterday',
                    Icons.arrow_back,
                    isSmallMobile,
                    isMobile,
                  ),
                  SizedBox(width: isSmallMobile ? 6 : 8),
                  _buildDateRangeChip(
                    'Today',
                    'today',
                    Icons.today,
                    isSmallMobile,
                    isMobile,
                  ),
                  SizedBox(width: isSmallMobile ? 6 : 8),
                  _buildDateRangeChip(
                    'Last 7 Days',
                    '7',
                    Icons.calendar_view_week,
                    isSmallMobile,
                    isMobile,
                  ),
                  SizedBox(width: isSmallMobile ? 6 : 8),
                  _buildDateRangeChip(
                    'Last 30 Days',
                    '30',
                    Icons.calendar_view_month,
                    isSmallMobile,
                    isMobile,
                  ),
                  SizedBox(width: isSmallMobile ? 6 : 8),
                  _buildDateRangeChip(
                    'Last 90 Days',
                    '90',
                    Icons.calendar_today,
                    isSmallMobile,
                    isMobile,
                  ),
                  SizedBox(width: isSmallMobile ? 6 : 8),
                  _buildDateRangeChip(
                    'All Time',
                    'all',
                    Icons.all_inclusive,
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
              controller: _searchController,
              onChanged: (value) {
                _searchDebounceTimer?.cancel();
                _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    setState(() {
                      _searchQuery = value;
                      _currentPage = 1;
                    });
                  }
                });
              },
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
                _searchQuery.isNotEmpty
                    ? '$_currentFilter • Searching'
                    : 'Filtered: $_currentFilter',
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
  ) {
    // Build filter label for open jobs date filter
    String? filterLabel;
    if (_currentFilter == 'open' && _openJobsDateFilter != null) {
      switch (_openJobsDateFilter) {
        case 'yesterday':
          filterLabel = 'Yesterday';
          break;
        case 'today':
          filterLabel = 'Today';
          break;
        case 'tomorrow':
          filterLabel = 'Tomorrow';
          break;
      }
    }
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
            filterLabel != null
                ? '$count jobs found ($filterLabel)'
                : '$count jobs found',
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
        mainAxisSize: MainAxisSize.min,
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
              mainAxisSize: MainAxisSize.min,
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

  /// Sliver list of job cards for CustomScrollView
  Widget _buildJobsListSliver(
    List<Job> jobs,
    Map<String, Client> clientsMap,
    Map<String, Vehicle> vehiclesMap,
    Map<String, User> usersMap,
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

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: spacing),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final job = jobs[index];
            final client = clientsMap[job.clientId];
            final vehicle = vehiclesMap[job.vehicleId];
            final driver = usersMap[job.driverId];
            if (kDebugMode) {
              Log.d('Jobs sliver itemBuilder -> index=$index jobId=${job.id} status=${job.status}');
            }

            return Padding(
              padding: EdgeInsets.only(bottom: spacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Lightweight marker to confirm sliver child insertion before card paint.
                  const SizedBox(height: 1),
                  JobCard(
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
                    fromRoute: widget.fromRoute,
                  ),
                ],
              ),
            );
          },
          childCount: jobs.length,
        ),
      ),
    );
  }

  // Enhanced Loading State
  Widget _buildLoadingState(
    bool isSmallMobile,
    bool isMobile,
  ) {
    final padding = ResponsiveTokens.getPadding(
      MediaQuery.of(context).size.width,
    );
    final spacing = ResponsiveTokens.getSpacing(
      MediaQuery.of(context).size.width,
    );

    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: ChoiceLuxTheme.richGold),
            SizedBox(height: spacing * 2),
            Text(
              'Loading jobs...',
              style: TextStyle(
                color: ChoiceLuxTheme.platinumSilver,
                fontSize: ResponsiveTokens.getFontSize(
                  MediaQuery.of(context).size.width,
                  baseSize: 14.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced Error State
  Widget _buildErrorState(
    Object error,
    bool isSmallMobile,
    bool isMobile,
  ) {
    final padding = ResponsiveTokens.getPadding(
      MediaQuery.of(context).size.width,
    );
    final spacing = ResponsiveTokens.getSpacing(
      MediaQuery.of(context).size.width,
    );
    final fontSize = ResponsiveTokens.getFontSize(
      MediaQuery.of(context).size.width,
      baseSize: 14.0,
    );

    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: ChoiceLuxTheme.errorColor,
              size: 48,
            ),
            SizedBox(height: spacing),
            Text(
              'Error loading jobs',
              style: TextStyle(
                fontSize: fontSize + 2,
                fontWeight: FontWeight.w600,
                color: ChoiceLuxTheme.errorColor,
              ),
            ),
            SizedBox(height: spacing * 0.5),
            Text(
              error.toString(),
              style: TextStyle(
                fontSize: fontSize,
                color: ChoiceLuxTheme.platinumSilver,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing),
            ElevatedButton(
              onPressed: () => ref.read(jobsProvider.notifier).fetchJobs(),
              style: ElevatedButton.styleFrom(
                backgroundColor: ChoiceLuxTheme.richGold,
                foregroundColor: Colors.black,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced Pagination Section
  Widget _buildPaginationSection(
    int totalPages,
    int totalItems,
    bool isSmallMobile,
    bool isMobile,
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
        if (filter == 'open') {
          _openJobsDateFilter ??= 'today';
        } else {
          _openJobsDateFilter = null;
        }
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
    IconData? icon,
    bool isSmallMobile,
    bool isMobile,
  ) {
    final isSelected = _dateRangeFilter == value;
    final fontSize = isSmallMobile ? 11.0 : 12.0;
    final iconSize = isSmallMobile ? 12.0 : 14.0;

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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: iconSize,
                color: isSelected
                    ? ChoiceLuxTheme.richGold
                    : ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.8),
              ),
              SizedBox(width: isSmallMobile ? 4 : 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? ChoiceLuxTheme.richGold
                    : ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.8),
                fontSize: fontSize,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Open Jobs Date Filter Section
  Widget _buildOpenJobsDateFilter(bool isSmallMobile, bool isMobile) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildOpenJobsDateChip(
            'All',
            null,
            Icons.calendar_today,
            isSmallMobile,
            isMobile,
          ),
          SizedBox(width: isSmallMobile ? 6 : 8),
          _buildOpenJobsDateChip(
            'Yesterday',
            'yesterday',
            Icons.arrow_back,
            isSmallMobile,
            isMobile,
          ),
          SizedBox(width: isSmallMobile ? 6 : 8),
          _buildOpenJobsDateChip(
            'Today',
            'today',
            Icons.today,
            isSmallMobile,
            isMobile,
          ),
          SizedBox(width: isSmallMobile ? 6 : 8),
          _buildOpenJobsDateChip(
            'Tomorrow',
            'tomorrow',
            Icons.arrow_forward,
            isSmallMobile,
            isMobile,
          ),
        ],
      ),
    );
  }

  // Open Jobs Date Filter Chip
  Widget _buildOpenJobsDateChip(
    String label,
    String? value,
    IconData icon,
    bool isSmallMobile,
    bool isMobile,
  ) {
    final isSelected = _openJobsDateFilter == value;
    final fontSize = isSmallMobile ? 11.0 : 12.0;

    return GestureDetector(
      onTap: () => setState(() {
        _openJobsDateFilter = value;
        _currentPage = 1; // Reset to first page when date filter changes
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isSmallMobile ? 12 : 14,
              color: isSelected
                  ? ChoiceLuxTheme.richGold
                  : ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.8),
            ),
            SizedBox(width: isSmallMobile ? 4 : 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? ChoiceLuxTheme.richGold
                    : ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.8),
                fontSize: fontSize,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get date range for open jobs date filter
  /// Returns (startDateTime, endDateTime) tuple
  (DateTime, DateTime) _getDateRange(String filter) {
    final now = DateTime.now();
    
    switch (filter) {
      case 'yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        final start = DateTime(yesterday.year, yesterday.month, yesterday.day, 0, 0, 0);
        final end = DateTime(now.year, now.month, now.day, 0, 0, 0); // today 00:00:00 (exclusive)
        return (start, end);
      case 'today':
        final start = DateTime(now.year, now.month, now.day, 0, 0, 0);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return (start, end);
      case 'tomorrow':
        final tomorrow = now.add(const Duration(days: 1));
        final start = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 0, 0, 0);
        final end = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 59, 59);
        return (start, end);
      default:
        // Should not happen, but return today as fallback
        final start = DateTime(now.year, now.month, now.day, 0, 0, 0);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return (start, end);
    }
  }

  /// Get date range for closed jobs date filter
  /// Returns (startDateTime, endDateTime) tuple, or (null, null) for 'all'
  (DateTime?, DateTime?) _getClosedJobsDateRange(String filter) {
    final now = DateTime.now();
    
    switch (filter) {
      case 'yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        final start = DateTime(yesterday.year, yesterday.month, yesterday.day, 0, 0, 0);
        final end = DateTime(now.year, now.month, now.day, 0, 0, 0); // today 00:00:00 (exclusive)
        return (start, end);
      case 'today':
        final start = DateTime(now.year, now.month, now.day, 0, 0, 0);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return (start, end);
      case 'all':
        return (null, null);
      default:
        // Numeric values: '7', '30', '90'
        final days = int.tryParse(filter) ?? 90;
        final cutoffDate = now.subtract(Duration(days: days));
        return (cutoffDate, now);
    }
  }

  List<Job> _filterJobs(List<Job> jobs) {
    final now = DateTime.now();
    
    switch (_currentFilter) {
      case 'open':
        // Treat 'open' and 'assigned' as open jobs
        var openJobs = jobs
            .where((job) => job.status == 'open' || job.status == 'assigned')
            .toList();
        
        // Performance optimization: Exclude open/assigned jobs older than 3 days
        // This improves UI performance by filtering out stale open jobs
        final threeDaysAgo = now.subtract(const Duration(days: 3));
        openJobs = openJobs.where((job) {
          // Compare dates only (ignore time) for accurate day-based filtering
          final jobDate = DateTime(
            job.jobStartDate.year,
            job.jobStartDate.month,
            job.jobStartDate.day,
          );
          final cutoffDate = DateTime(
            threeDaysAgo.year,
            threeDaysAgo.month,
            threeDaysAgo.day,
          );
          // Include jobs with job_start_date >= (today - 3 days)
          // This means: include jobs from the last 3 days or future dates
          return !jobDate.isBefore(cutoffDate);
        }).toList();
        
        // Apply date filter if selected (yesterday/today/tomorrow)
        if (_openJobsDateFilter != null) {
          final dateRange = _getDateRange(_openJobsDateFilter!);
          openJobs = openJobs.where((job) {
            // Check if jobStartDate falls within the date range
            // Compare dates only (ignore time) for accurate day-based filtering
            final jobDate = DateTime(
              job.jobStartDate.year,
              job.jobStartDate.month,
              job.jobStartDate.day,
            );
            final rangeStart = DateTime(
              dateRange.$1.year,
              dateRange.$1.month,
              dateRange.$1.day,
            );
            final rangeEnd = DateTime(
              dateRange.$2.year,
              dateRange.$2.month,
              dateRange.$2.day,
            );
            if (_openJobsDateFilter == 'yesterday') {
              return !jobDate.isBefore(rangeStart) && jobDate.isBefore(rangeEnd);
            }
            return jobDate.isAtSameMomentAs(rangeStart) ||
                   jobDate.isAtSameMomentAs(rangeEnd) ||
                   (jobDate.isAfter(rangeStart) && jobDate.isBefore(rangeEnd));
          }).toList();
        }
        return openJobs;
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
        // Closed jobs (completed, closed, cancelled) with date filter
        var closed = jobs
            .where((job) =>
                job.status == 'completed' ||
                job.status == 'closed' ||
                job.status == 'cancelled')
            .toList();
        
        // CRITICAL: For drivers, ensure only jobs assigned to them are shown
        // This is a defensive check in addition to repository-level filtering
        final userProfile = ref.read(currentUserProfileProvider);
        final userRole = userProfile?.role?.toLowerCase();
        final userId = userProfile?.id;
        if (userRole == 'driver' && userId != null) {
          closed = closed.where((job) => job.driverId == userId).toList();
        }
        
        // Apply date range filter
        if (_dateRangeFilter == 'all') {
          // No filtering needed - show all closed jobs
        } else {
          final dateRange = _getClosedJobsDateRange(_dateRangeFilter);
          if (dateRange.$1 != null && dateRange.$2 != null) {
            closed = closed.where((job) {
              final jobDate = job.updatedAt ?? job.createdAt;
              
              // For yesterday/today: exact day match (compare dates only, ignore time)
              if (_dateRangeFilter == 'yesterday' || 
                  _dateRangeFilter == 'today') {
                final jobDateOnly = DateTime(
                  jobDate.year,
                  jobDate.month,
                  jobDate.day,
                );
                final rangeStart = DateTime(
                  dateRange.$1!.year,
                  dateRange.$1!.month,
                  dateRange.$1!.day,
                );
                final rangeEnd = DateTime(
                  dateRange.$2!.year,
                  dateRange.$2!.month,
                  dateRange.$2!.day,
                );
                if (_dateRangeFilter == 'yesterday') {
                  return !jobDateOnly.isBefore(rangeStart) && jobDateOnly.isBefore(rangeEnd);
                }
                return jobDateOnly.isAtSameMomentAs(rangeStart) ||
                       jobDateOnly.isAtSameMomentAs(rangeEnd) ||
                       (jobDateOnly.isAfter(rangeStart) && jobDateOnly.isBefore(rangeEnd));
              } else {
                // For 7/30/90 days: after cutoffDate (time-aware)
                return jobDate.isAfter(dateRange.$1!);
              }
            }).toList();
          }
        }
        return closed;
      case 'all':
        // All jobs: apply date filter to BOTH completed (by updatedAt) and non-completed (by job_start_date)
        // CRITICAL: For drivers, ensure only jobs assigned to them are shown
        var allJobs = jobs;
        final userProfileForAll = ref.read(currentUserProfileProvider);
        final userRoleForAll = userProfileForAll?.role?.toLowerCase();
        final userIdForAll = userProfileForAll?.id;
        if (userRoleForAll == 'driver' && userIdForAll != null) {
          allJobs = allJobs.where((job) => job.driverId == userIdForAll).toList();
        }
        
        if (_dateRangeFilter == 'all') {
          return allJobs; // Show all jobs
        } else {
          final dateRange = _getClosedJobsDateRange(_dateRangeFilter);
          if (dateRange.$1 != null && dateRange.$2 != null) {
            return allJobs.where((job) {
              // Use job_start_date for all jobs when filter is yesterday/today so
              // "Today" = jobs that start today, not jobs updated today (avoids inflated count).
              final startDate = DateTime(job.jobStartDate.year, job.jobStartDate.month, job.jobStartDate.day);
              if (_dateRangeFilter == 'yesterday' || _dateRangeFilter == 'today') {
                final rangeStart = DateTime(dateRange.$1!.year, dateRange.$1!.month, dateRange.$1!.day);
                final rangeEnd = DateTime(dateRange.$2!.year, dateRange.$2!.month, dateRange.$2!.day);
                if (_dateRangeFilter == 'yesterday') {
                  return !startDate.isBefore(rangeStart) && startDate.isBefore(rangeEnd);
                }
                return startDate.isAtSameMomentAs(rangeStart) ||
                       startDate.isAtSameMomentAs(rangeEnd) ||
                       (startDate.isAfter(rangeStart) && startDate.isBefore(rangeEnd));
              }
              // For 7/30/90 days: completed by updatedAt, non-completed by job_start_date
              final isCompleted = job.status == 'completed' ||
                  job.status == 'closed' ||
                  job.status == 'cancelled';
              if (isCompleted) {
                final jobDate = job.updatedAt ?? job.createdAt;
                return jobDate.isAfter(dateRange.$1!);
              }
              final cutoffDateOnly = DateTime(dateRange.$1!.year, dateRange.$1!.month, dateRange.$1!.day);
              return !startDate.isBefore(cutoffDateOnly);
            }).toList();
          }
        }
        return allJobs;
      default:
        return jobs;
    }
  }

}
