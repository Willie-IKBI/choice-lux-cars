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
import 'package:choice_lux_cars/shared/utils/background_pattern_utils.dart';

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
  String _dateRangeFilter = '90'; // 'yesterday', 'today', 'tomorrow', '7', '30', '90', 'all' - for closed jobs
  String? _openJobsDateFilter; // 'yesterday', 'today', 'tomorrow', or null (all)

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
      
      // Check if user can create jobs based on role (moved from notifier to avoid LateInitializationError)
      final userProfileForPermissions = ref.watch(currentUserProfileProvider);
      final userRoleForPermissions = userProfileForPermissions?.role?.toLowerCase();
      final canCreateJobs = userRoleForPermissions == 'administrator' ||
          userRoleForPermissions == 'super_admin' ||
          userRoleForPermissions == 'manager' ||
          userRoleForPermissions == 'driver_manager' ||
          userRoleForPermissions == 'drivermanager';

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

      // Apply filters (only if jobs are loaded)
      final allJobs = jobs.value ?? [];
      List<Job> filteredJobs = allJobs;
      
      // Only apply filters if we have data (avoid filtering empty list during loading)
      if (allJobs.isNotEmpty) {
        filteredJobs = _filterJobs(allJobs);
        Log.d('Filtered jobs: ${filteredJobs.length} (filter: $_currentFilter)');
      }

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
          // Layer 1: The background that fills the entire screen
          Container(
            decoration: const BoxDecoration(
              gradient: ChoiceLuxTheme.backgroundGradient,
            ),
          ),
          // Layer 2: Background pattern that covers the entire screen
          Positioned.fill(
            child: CustomPaint(painter: BackgroundPatterns.dashboard),
          ),
          // Layer 3: The SystemSafeScaffold with proper system UI handling
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
                      // Show loading state while jobs are being fetched
                      // Show jobs immediately when loaded, don't block on clients/vehicles/users
                      // Related data will be looked up from Maps (O(1) access)
                      jobs.when(
                        data: (_) => paginatedJobs.isEmpty
                            ? _buildEmptyState(
                                isSmallMobile,
                                isMobile,
                                isTablet,
                                isDesktop,
                              )
                            : _buildJobsList(
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
                    'Tomorrow',
                    'tomorrow',
                    Icons.arrow_forward,
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
  // Performance optimization: Uses Maps for O(1) lookups instead of O(n) firstWhere
  Widget _buildJobsList(
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

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: spacing),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];

        // Performance optimization: O(1) Map lookups instead of O(n) firstWhere
        final client = job.clientId != null ? clientsMap[job.clientId] : null;
        final vehicle = job.vehicleId != null ? vehiclesMap[job.vehicleId] : null;
        final driver = job.driverId != null ? usersMap[job.driverId] : null;

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
    bool isTablet,
    bool isDesktop,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
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
        // Reset open jobs date filter when switching away from open jobs
        if (filter != 'open') {
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
    final spacing = ResponsiveTokens.getSpacing(
      MediaQuery.of(context).size.width,
    );

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
        final end = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
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
        final end = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
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
        
        // Apply date range filter
        if (_dateRangeFilter == 'all') {
          // No filtering needed - show all closed jobs
        } else {
          final dateRange = _getClosedJobsDateRange(_dateRangeFilter);
          if (dateRange.$1 != null && dateRange.$2 != null) {
            closed = closed.where((job) {
              final jobDate = job.updatedAt ?? job.createdAt;
              
              // For yesterday/today/tomorrow: exact day match (compare dates only, ignore time)
              if (_dateRangeFilter == 'yesterday' || 
                  _dateRangeFilter == 'today' || 
                  _dateRangeFilter == 'tomorrow') {
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
        // All jobs, but apply date filter to completed/closed/cancelled jobs
        if (_dateRangeFilter == 'all') {
          return jobs; // Show all jobs
        } else {
          final dateRange = _getClosedJobsDateRange(_dateRangeFilter);
          if (dateRange.$1 != null && dateRange.$2 != null) {
            return jobs.where((job) {
              final isCompleted = job.status == 'completed' ||
                  job.status == 'closed' ||
                  job.status == 'cancelled';
              if (isCompleted) {
                final jobDate = job.updatedAt ?? job.createdAt;
                
                // For yesterday/today/tomorrow: exact day match (compare dates only, ignore time)
                if (_dateRangeFilter == 'yesterday' || 
                    _dateRangeFilter == 'today' || 
                    _dateRangeFilter == 'tomorrow') {
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
                  return jobDateOnly.isAtSameMomentAs(rangeStart) ||
                         jobDateOnly.isAtSameMomentAs(rangeEnd) ||
                         (jobDateOnly.isAfter(rangeStart) && jobDateOnly.isBefore(rangeEnd));
                } else {
                  // For 7/30/90 days: after cutoffDate (time-aware)
                  return jobDate.isAfter(dateRange.$1!);
                }
              }
              return true; // Include all non-completed jobs
            }).toList();
          }
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
