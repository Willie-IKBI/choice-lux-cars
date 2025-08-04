import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/jobs/providers/jobs_provider.dart';
import 'package:choice_lux_cars/features/jobs/models/job.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
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
    final isMobile = MediaQuery.of(context).size.width < 768;

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
               job.branch.toLowerCase().contains(searchLower);
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
              onPressed: () => context.go('/jobs/create'),
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
          // Filters and Search
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
            ),
            child: Column(
              children: [
                // Filter buttons
                Row(
                  children: [
                    _buildFilterButton('open', 'Open Jobs'),
                    const SizedBox(width: 8),
                    _buildFilterButton('in_progress', 'In Progress'),
                    const SizedBox(width: 8),
                    _buildFilterButton('closed', 'Closed Jobs'),
                    const SizedBox(width: 8),
                    _buildFilterButton('all', 'All Jobs'),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Search bar
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _currentPage = 1; // Reset to first page when searching
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search jobs by passenger name, client, or branch...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // Jobs count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${filteredJobs.length} job${filteredJobs.length != 1 ? 's' : ''} found',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
                if (_currentFilter != 'all')
                  Text(
                    'Showing $_currentFilter jobs',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),

          // Jobs grid
          Expanded(
            child: paginatedJobs.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.work_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No jobs found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters or create a new job',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ResponsiveGrid(
                    items: paginatedJobs.map((job) => JobCard(job: job)).toList(),
                    onItemTap: (index) {
                      final job = paginatedJobs[index];
                      context.go('/jobs/${job.id}');
                    },
                  ),
          ),

          // Pagination
          if (totalPages > 1)
            PaginationWidget(
              currentPage: _currentPage,
              totalPages: totalPages,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String filter, String label) {
    final isActive = _currentFilter == filter;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _currentFilter = filter;
          _currentPage = 1; // Reset to first page when changing filter
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? ChoiceLuxTheme.richGold : Colors.grey.withOpacity(0.1),
        foregroundColor: isActive ? Colors.white : Colors.black87,
        elevation: isActive ? 2 : 0,
      ),
      child: Text(label),
    );
  }

  List<Job> _filterJobs(List<Job> jobs) {
    switch (_currentFilter) {
      case 'open':
        return jobs.where((job) => job.isOpen).toList();
      case 'in_progress':
        return jobs.where((job) => job.isInProgress).toList();
      case 'closed':
        return jobs.where((job) => job.isClosed).toList();
      case 'all':
      default:
        return jobs;
    }
  }
} 