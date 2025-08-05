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

class _JobsScreenState extends ConsumerState<JobsScreen> {
  String _currentFilter = 'open'; // open, closed, in_progress, all
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 12;

  @override
  Widget build(BuildContext context) {
    final jobs = ref.watch(jobsProvider);
    final canCreateJobs = ref.watch(jobsProvider.notifier).canCreateJobs;
    final currentUser = ref.watch(currentUserProfileProvider);
    final isMobile = MediaQuery.of(context).size.width < 768;
    
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
                // Filter tabs with icons
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterButton('open', 'Open Jobs', Icons.folder_open),
                        const SizedBox(width: 12),
                        _buildFilterButton('in_progress', 'In Progress', Icons.sync),
                        const SizedBox(width: 12),
                        _buildFilterButton('completed', 'Completed', Icons.check_circle),
                        const SizedBox(width: 12),
                        _buildFilterButton('all', 'All Jobs', Icons.list),
                      ],
                    ),
                  ),
                ),
                
                // Search bar with improved styling
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _currentPage = 1; // Reset to first page when searching
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search jobs by passenger name, client, or job ID...',
                      hintStyle: TextStyle(
                        color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: ChoiceLuxTheme.platinumSilver,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1F1F1F),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: ChoiceLuxTheme.richGold,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Jobs count with improved styling
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: ChoiceLuxTheme.platinumSilver,
                ),
                const SizedBox(width: 8),
                Text(
                  '${filteredJobs.length} job${filteredJobs.length != 1 ? 's' : ''} found',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: ChoiceLuxTheme.platinumSilver,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                if (_currentFilter != 'all')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Filtered: $_currentFilter',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: ChoiceLuxTheme.richGold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Jobs grid with improved empty state
          Expanded(
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
                    data: (clients) => ResponsiveGrid(
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

  Widget _buildFilterButton(String filter, String label, IconData icon) {
    final isActive = _currentFilter == filter;
    final isMobile = MediaQuery.of(context).size.width < 768;
    
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
          size: isMobile ? 16 : 18,
        ),
        label: Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
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
          padding: isMobile 
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
        return jobs.where((job) => job.isOpen).toList();
      case 'in_progress':
        return jobs.where((job) => job.isInProgress).toList();
      case 'completed':
        return jobs.where((job) => job.isClosed).toList(); // This will include both 'closed' and 'completed' statuses
      case 'all':
      default:
        return jobs;
    }
  }
} 