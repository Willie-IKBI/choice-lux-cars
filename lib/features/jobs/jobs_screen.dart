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
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';
import 'package:choice_lux_cars/shared/widgets/pagination_widget.dart';
import 'package:choice_lux_cars/shared/widgets/dashboard_card.dart';
import 'package:choice_lux_cars/features/jobs/widgets/job_card.dart';

class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> with WidgetsBindingObserver {
  String _currentFilter = 'open'; // open, closed, in_progress, all
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 12;

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
    // Responsive breakpoints for mobile optimization
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 400;
    final isTablet = screenWidth >= 600 && screenWidth < 800;
    final isDesktop = screenWidth >= 800;
    final isLargeDesktop = screenWidth >= 1200;
    
    final jobs = ref.watch(jobsProvider);
    final canCreateJobs = ref.watch(jobsProvider.notifier).canCreateJobs;
    final currentUser = ref.watch(currentUserProfileProvider);
    
    // Load related data
    final vehiclesState = ref.watch(vehiclesProvider);
    final users = ref.watch(usersProvider);
    final clientsAsync = ref.watch(clientsProvider);

    // Filter jobs based on current filter
    List<Job> filteredJobs = _filterJobs(jobs);
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredJobs = filteredJobs.where((job) {
        final passengerName = job.passengerName?.toLowerCase() ?? '';
        final clientName = job.clientId.toLowerCase(); // You might want to get actual client name
        final searchLower = _searchQuery.toLowerCase();
        return passengerName.contains(searchLower) || 
               clientName.contains(searchLower) ||
               job.id.toLowerCase().contains(searchLower);
      }).toList();
    }

    // Pagination
    final totalPages = (filteredJobs.length / _itemsPerPage).ceil();
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    final paginatedJobs = filteredJobs.sublist(
      startIndex, 
      endIndex > filteredJobs.length ? filteredJobs.length : endIndex
    );

    return Scaffold(
      appBar: LuxuryAppBar(
        title: 'Jobs',
        subtitle: 'Manage transportation jobs',
        showBackButton: true,
        onBackPressed: () => context.go('/'),
        onSignOut: () async {
          await ref.read(authProvider.notifier).signOut();
        },
        actions: [
          if (canCreateJobs)
            ElevatedButton.icon(
              onPressed: () {
                print('Create Job button clicked - navigating to /jobs/create');
                context.go('/jobs/create');
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Job'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ChoiceLuxTheme.richGold,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
      drawer: const LuxuryDrawer(),
      body: Column(
        children: [
          // Sticky Header with Filters and Search
          Container(
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.charcoalGray,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Filter section - responsive design (bottom sheet for mobile, horizontal buttons for desktop)
                if (isMobile) 
                  _buildMobileFilterSection(isSmallMobile)
                else
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallMobile ? 12 : isMobile ? 16 : 20,
                      vertical: isSmallMobile ? 8 : isMobile ? 12 : 16,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterButton('open', 'Open Jobs', Icons.folder_open, isMobile, isSmallMobile),
                          SizedBox(width: isSmallMobile ? 8 : isMobile ? 12 : 16),
                          _buildFilterButton('in_progress', 'In Progress', Icons.sync, isMobile, isSmallMobile),
                          SizedBox(width: isSmallMobile ? 8 : isMobile ? 12 : 16),
                          _buildFilterButton('completed', 'Completed', Icons.check_circle, isMobile, isSmallMobile),
                          SizedBox(width: isSmallMobile ? 8 : isMobile ? 12 : 16),
                          _buildFilterButton('all', 'All Jobs', Icons.list, isMobile, isSmallMobile),
                        ],
                      ),
                    ),
                  ),
                
                // Search bar with improved styling - responsive design
                Container(
                  padding: EdgeInsets.fromLTRB(
                    isSmallMobile ? 12 : isMobile ? 16 : 20,
                    0,
                    isSmallMobile ? 12 : isMobile ? 16 : 20,
                    isSmallMobile ? 12 : isMobile ? 16 : 20,
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _currentPage = 1; // Reset to first page when searching
                      });
                    },
                    decoration: InputDecoration(
                      hintText: isSmallMobile 
                          ? 'Search jobs...' 
                          : isMobile 
                              ? 'Search jobs by passenger, client...' 
                              : 'Search jobs by passenger name, client, or job ID...',
                      hintStyle: TextStyle(
                        color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7),
                        fontSize: isSmallMobile ? 12 : isMobile ? 13 : 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: ChoiceLuxTheme.platinumSilver,
                        size: isSmallMobile ? 18 : isMobile ? 20 : 24,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1F1F1F),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(isSmallMobile ? 8 : isMobile ? 10 : 12),
                        borderSide: BorderSide(
                          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(isSmallMobile ? 8 : isMobile ? 10 : 12),
                        borderSide: BorderSide(
                          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(isSmallMobile ? 8 : isMobile ? 10 : 12),
                        borderSide: BorderSide(
                          color: ChoiceLuxTheme.richGold,
                          width: 2,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isSmallMobile ? 12 : isMobile ? 14 : 16,
                        vertical: isSmallMobile ? 10 : isMobile ? 12 : 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Jobs count with improved styling - responsive design
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallMobile ? 12 : isMobile ? 16 : 20,
              vertical: isSmallMobile ? 8 : isMobile ? 12 : 16,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: isSmallMobile ? 14 : isMobile ? 16 : 18,
                  color: ChoiceLuxTheme.platinumSilver,
                ),
                SizedBox(width: isSmallMobile ? 6 : isMobile ? 8 : 10),
                Text(
                  '${filteredJobs.length} job${filteredJobs.length != 1 ? 's' : ''} found',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: ChoiceLuxTheme.platinumSilver,
                    fontSize: isSmallMobile ? 12 : isMobile ? 13 : 14,
                  ),
                ),
                const Spacer(),
                if (_currentFilter != 'all')
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallMobile ? 6 : isMobile ? 8 : 10,
                      vertical: isSmallMobile ? 3 : isMobile ? 4 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(isSmallMobile ? 6 : isMobile ? 8 : 10),
                      border: Border.all(
                        color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      isSmallMobile 
                          ? '$_currentFilter' 
                          : 'Filtered: $_currentFilter',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: ChoiceLuxTheme.richGold,
                        fontSize: isSmallMobile ? 10 : isMobile ? 11 : 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Jobs grid with improved empty state and pull-to-refresh
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (mounted) {
                  await ref.read(jobsProvider.notifier).fetchJobs();
                }
              },
              color: ChoiceLuxTheme.richGold,
              backgroundColor: ChoiceLuxTheme.charcoalGray,
              child: paginatedJobs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: ChoiceLuxTheme.charcoalGray,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.work_outline,
                                  size: 48,
                                  color: ChoiceLuxTheme.platinumSilver,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No jobs found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: ChoiceLuxTheme.softWhite,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try adjusting your filters or create a new job',
                                  style: TextStyle(
                                    color: ChoiceLuxTheme.platinumSilver,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : clientsAsync.when(
                    data: (clients) => isMobile 
                        ? ListView.builder( // Mobile: ListView
                            padding: EdgeInsets.all(isSmallMobile ? 6 : isMobile ? 8 : 12),
                            itemCount: paginatedJobs.length,
                            itemBuilder: (context, index) {
                              final job = paginatedJobs[index];
                              // Find related data
                              Client? client;
                              Vehicle? vehicle;
                              User? driver;
                              
                              try {
                                client = clients.firstWhere(
                                  (c) => c.id.toString() == job.clientId,
                                );
                              } catch (e) {
                                client = null;
                              }
                              
                              try {
                                vehicle = vehiclesState.vehicles.firstWhere(
                                  (v) => v.id.toString() == job.vehicleId,
                                );
                              } catch (e) {
                                vehicle = null;
                              }
                              
                              try {
                                driver = users.firstWhere(
                                  (u) => u.id == job.driverId,
                                );
                              } catch (e) {
                                driver = null;
                              }
                              
                              return JobCard(
                                job: job,
                                client: client,
                                vehicle: vehicle,
                                driver: driver,
                              );
                            },
                          )
                        : ResponsiveGrid( // Desktop: Keep existing grid
                            children: paginatedJobs.map((job) {
                              // Find related data
                              Client? client;
                              Vehicle? vehicle;
                              User? driver;
                              
                              try {
                                client = clients.firstWhere(
                                  (c) => c.id.toString() == job.clientId,
                                );
                              } catch (e) {
                                client = null;
                              }
                              
                              try {
                                vehicle = vehiclesState.vehicles.firstWhere(
                                  (v) => v.id.toString() == job.vehicleId,
                                );
                              } catch (e) {
                                vehicle = null;
                              }
                              
                              try {
                                driver = users.firstWhere(
                                  (u) => u.id == job.driverId,
                                );
                              } catch (e) {
                                driver = null;
                              }
                              
                              return JobCard(
                                job: job,
                                client: client,
                                vehicle: vehicle,
                                driver: driver,
                              );
                            }).toList(),
                          ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                      child: Text('Error loading clients: $error'),
                    ),
                  ),
                ),
          ),

          // Pagination with improved styling
          if (totalPages > 1)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ChoiceLuxTheme.charcoalGray,
                border: Border(
                  top: BorderSide(
                    color: ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: PaginationWidget(
                currentPage: _currentPage,
                totalPages: totalPages,
                totalItems: filteredJobs.length,
                itemsPerPage: _itemsPerPage,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String filter, String label, IconData icon, bool isMobile, bool isSmallMobile) {
    final isActive = _currentFilter == filter;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: isActive ? [
          BoxShadow(
            color: ChoiceLuxTheme.richGold.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _currentFilter = filter;
            _currentPage = 1; // Reset to first page when changing filter
          });
        },
        icon: Icon(
          icon,
          size: isSmallMobile ? 14 : isMobile ? 16 : 18,
        ),
        label: Text(
          isSmallMobile && label.length > 8 
              ? label.split(' ').first 
              : label,
          style: TextStyle(
            fontSize: isSmallMobile ? 10 : isMobile ? 12 : 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive 
              ? ChoiceLuxTheme.richGold 
              : ChoiceLuxTheme.charcoalGray,
          foregroundColor: isActive 
              ? Colors.black 
              : ChoiceLuxTheme.platinumSilver,
          elevation: isActive ? 2 : 0,
          padding: EdgeInsets.symmetric(
            horizontal: isSmallMobile ? 8 : isMobile ? 12 : 16,
            vertical: isSmallMobile ? 6 : isMobile ? 8 : 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmallMobile ? 8 : isMobile ? 10 : 12),
            side: isActive 
                ? BorderSide.none
                : BorderSide(
                    color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3),
                    width: 1,
                  ),
          ),
        ),
      ),
    );
  }

  List<Job> _filterJobs(List<Job> jobs) {
    switch (_currentFilter) {
      case 'open':
        return jobs.where((job) => job.isOpen).toList(); // Use the isOpen property instead of status == 'open'
      case 'in_progress':
        return jobs.where((job) => job.isInProgress).toList();
      case 'completed':
        return jobs.where((job) => job.isClosed).toList(); // This will include both 'closed' and 'completed' statuses
      case 'all':
      default:
        return jobs;
    }
  }

  // Mobile-specific filter section with bottom sheet
  Widget _buildMobileFilterSection(bool isSmallMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallMobile ? 12 : 16,
        vertical: isSmallMobile ? 8 : 12,
      ),
      child: Row(
        children: [
          // Current filter indicator
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallMobile ? 8 : 12,
                vertical: isSmallMobile ? 8 : 10,
              ),
              decoration: BoxDecoration(
                color: ChoiceLuxTheme.charcoalGray.withOpacity(0.3),
                borderRadius: BorderRadius.circular(isSmallMobile ? 8 : 10),
                border: Border.all(
                  color: ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getFilterIcon(_currentFilter),
                    size: isSmallMobile ? 16 : 18,
                    color: ChoiceLuxTheme.richGold,
                  ),
                  SizedBox(width: isSmallMobile ? 6 : 8),
                  Expanded(
                    child: Text(
                      _getFilterLabel(_currentFilter),
                      style: TextStyle(
                        fontSize: isSmallMobile ? 12 : 14,
                        fontWeight: FontWeight.w600,
                        color: ChoiceLuxTheme.softWhite,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: isSmallMobile ? 16 : 18,
                    color: ChoiceLuxTheme.platinumSilver,
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(width: isSmallMobile ? 8 : 12),
          
          // Filter button
          Container(
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.richGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isSmallMobile ? 8 : 10),
              border: Border.all(
                color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showMobileFilterBottomSheet(isSmallMobile),
                borderRadius: BorderRadius.circular(isSmallMobile ? 8 : 10),
                child: Padding(
                  padding: EdgeInsets.all(isSmallMobile ? 8 : 10),
                  child: Icon(
                    Icons.tune,
                    size: isSmallMobile ? 18 : 20,
                    color: ChoiceLuxTheme.richGold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show mobile filter bottom sheet
  void _showMobileFilterBottomSheet(bool isSmallMobile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildFilterBottomSheet(isSmallMobile),
    );
  }

  // Build filter bottom sheet
  Widget _buildFilterBottomSheet(bool isSmallMobile) {
    return Container(
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isSmallMobile ? 16 : 20),
          topRight: Radius.circular(isSmallMobile ? 16 : 20),
        ),
        border: Border.all(
          color: ChoiceLuxTheme.richGold.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: isSmallMobile ? 8 : 12),
              width: isSmallMobile ? 32 : 40,
              height: 4,
              decoration: BoxDecoration(
                color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: EdgeInsets.all(isSmallMobile ? 16 : 20),
              child: Row(
                children: [
                  Icon(
                    Icons.tune,
                    size: isSmallMobile ? 20 : 24,
                    color: ChoiceLuxTheme.richGold,
                  ),
                  SizedBox(width: isSmallMobile ? 8 : 12),
                  Text(
                    'Filter Jobs',
                    style: TextStyle(
                      fontSize: isSmallMobile ? 16 : 18,
                      fontWeight: FontWeight.w600,
                      color: ChoiceLuxTheme.softWhite,
                    ),
                  ),
                  const Spacer(),
                  if (_currentFilter != 'all')
                    TextButton(
                      onPressed: () {
                        setState(() => _currentFilter = 'all');
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: isSmallMobile ? 12 : 14,
                          color: ChoiceLuxTheme.richGold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Filter options
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isSmallMobile ? 16 : 20),
              child: Column(
                children: [
                  _buildMobileFilterOption('all', 'All Jobs', Icons.list, isSmallMobile),
                  SizedBox(height: isSmallMobile ? 8 : 12),
                  _buildMobileFilterOption('open', 'Open Jobs', Icons.folder_open, isSmallMobile),
                  SizedBox(height: isSmallMobile ? 8 : 12),
                  _buildMobileFilterOption('in_progress', 'In Progress', Icons.sync, isSmallMobile),
                  SizedBox(height: isSmallMobile ? 8 : 12),
                  _buildMobileFilterOption('completed', 'Completed', Icons.check_circle, isSmallMobile),
                ],
              ),
            ),
            
            SizedBox(height: isSmallMobile ? 16 : 20),
          ],
        ),
      ),
    );
  }

  // Build mobile filter option
  Widget _buildMobileFilterOption(String filter, String label, IconData icon, bool isSmallMobile) {
    final isSelected = _currentFilter == filter;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isSelected ? ChoiceLuxTheme.richGold.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(isSmallMobile ? 8 : 10),
        border: Border.all(
          color: isSelected 
            ? ChoiceLuxTheme.richGold.withOpacity(0.3)
            : ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _currentFilter = filter);
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(isSmallMobile ? 8 : 10),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallMobile ? 12 : 16,
              vertical: isSmallMobile ? 12 : 16,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: isSmallMobile ? 18 : 20,
                  color: isSelected ? ChoiceLuxTheme.richGold : ChoiceLuxTheme.platinumSilver,
                ),
                SizedBox(width: isSmallMobile ? 12 : 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: isSmallMobile ? 14 : 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? ChoiceLuxTheme.richGold : ChoiceLuxTheme.softWhite,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check,
                    size: isSmallMobile ? 16 : 18,
                    color: ChoiceLuxTheme.richGold,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper methods for filter display
  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'open':
        return Icons.folder_open;
      case 'in_progress':
        return Icons.sync;
      case 'completed':
        return Icons.check_circle;
      case 'all':
      default:
        return Icons.list;
    }
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'open':
        return 'Open Jobs';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'all':
      default:
        return 'All Jobs';
    }
  }
} 