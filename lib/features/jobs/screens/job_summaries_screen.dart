import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/features/jobs/data/jobs_repository.dart';
import 'package:choice_lux_cars/features/jobs/models/job.dart';
import 'package:choice_lux_cars/features/clients/providers/clients_provider.dart';
import 'package:choice_lux_cars/features/users/providers/users_provider.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/widgets/system_safe_scaffold.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';

class JobSummariesScreen extends ConsumerStatefulWidget {
  const JobSummariesScreen({super.key});

  @override
  ConsumerState<JobSummariesScreen> createState() => _JobSummariesScreenState();
}

class _JobSummariesScreenState extends ConsumerState<JobSummariesScreen> {
  final _jobNumberController = TextEditingController();
  int _currentPage = 1;
  final int _itemsPerPage = 20;
  List<Job> _jobs = [];
  int _totalJobs = 0;
  bool _hasMore = false;
  bool _isLoading = false;
  String? _error;

  String _datePreset = 'thisMonth';
  String _statusFilter = 'all';
  String _locationFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  @override
  void dispose() {
    _jobNumberController.dispose();
    super.dispose();
  }

  (DateTime, DateTime) _getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_datePreset) {
      case 'today':
        return (today, today.add(const Duration(days: 1)));
      case 'thisWeek':
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return (weekStart, weekStart.add(const Duration(days: 7)));
      case 'thisMonth':
        return (DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 1));
      case 'thisYear':
        return (DateTime(now.year, 1, 1), DateTime(now.year + 1, 1, 1));
      default:
        return (today, today.add(const Duration(days: 1)));
    }
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(jobsRepositoryProvider);
      final dateRange = _getDateRange();

      String? location;
      if (_locationFilter != 'all') {
        location = _locationFilter;
      }

      final offset = (_currentPage - 1) * _itemsPerPage;

      final result = await repository.searchJobsForSummaries(
        jobNumber: _jobNumberController.text.trim().isEmpty ? null : _jobNumberController.text.trim(),
        startDate: dateRange.$1,
        endDate: dateRange.$2,
        status: _statusFilter,
        location: location,
        limit: _itemsPerPage,
        offset: offset,
      );

      if (result.isSuccess) {
        final data = result.data as Map<String, dynamic>;
        setState(() {
          _jobs = data['jobs'] as List<Job>;
          _totalJobs = data['total'] as int;
          _hasMore = data['hasMore'] as bool? ?? false;
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

  void _onSearch() {
    setState(() => _currentPage = 1);
    _loadJobs();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);

    final clientsAsync = ref.watch(clientsProvider);
    final users = ref.watch(usersProvider);

    return SystemSafeScaffold(
      appBar: LuxuryAppBar(
        title: 'Job Summaries',
        subtitle: 'Search and view job details',
        showBackButton: true,
        onBackPressed: () => context.go('/'),
        onSignOut: () async {
          await ref.read(authProvider.notifier).signOut();
        },
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.softWhite.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(color: ChoiceLuxTheme.softWhite.withOpacity(0.1)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Job number search
                TextField(
                  controller: _jobNumberController,
                  decoration: InputDecoration(
                    hintText: 'Job number',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: ChoiceLuxTheme.charcoalGray,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: const TextStyle(color: ChoiceLuxTheme.softWhite),
                  onSubmitted: (_) => _onSearch(),
                ),
                const SizedBox(height: 12),
                // Filters row
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildDropdown(
                      value: _datePreset,
                      items: const [
                        ('today', 'Today'),
                        ('thisWeek', 'This Week'),
                        ('thisMonth', 'This Month'),
                        ('thisYear', 'This Year'),
                      ],
                      onChanged: (v) => setState(() {
                        _datePreset = v!;
                        _currentPage = 1;
                        _loadJobs();
                      }),
                    ),
                    _buildDropdown(
                      value: _statusFilter,
                      items: const [
                        ('all', 'All Status'),
                        ('open', 'Open'),
                        ('completed', 'Completed'),
                        ('cancelled', 'Cancelled'),
                      ],
                      onChanged: (v) => setState(() {
                        _statusFilter = v!;
                        _currentPage = 1;
                        _loadJobs();
                      }),
                    ),
                    _buildDropdown(
                      value: _locationFilter,
                      items: const [
                        ('all', 'All Locations'),
                        ('Jhb', 'Jhb'),
                        ('Cpt', 'Cpt'),
                        ('Dbn', 'Dbn'),
                      ],
                      onChanged: (v) => setState(() {
                        _locationFilter = v!;
                        _currentPage = 1;
                        _loadJobs();
                      }),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _onSearch,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      label: const Text('Search'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ChoiceLuxTheme.richGold,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ),
                if (_totalJobs > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    _hasMore
                        ? '$_totalJobs+ jobs found'
                        : '$_totalJobs job${_totalJobs == 1 ? '' : 's'} found',
                    style: TextStyle(
                      color: ChoiceLuxTheme.softWhite.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Jobs list
          Expanded(
            child: _isLoading && _jobs.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(ChoiceLuxTheme.richGold),
                    ),
                  )
                : _error != null
                    ? _buildErrorState()
                    : _jobs.isEmpty
                        ? _buildEmptyState()
                        : _buildJobsList(clientsAsync, users, isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<(String, String)> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: value,
        underline: const SizedBox.shrink(),
        dropdownColor: ChoiceLuxTheme.charcoalGray,
        style: const TextStyle(color: ChoiceLuxTheme.softWhite),
        items: items.map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: ChoiceLuxTheme.errorColor, size: 48),
          const SizedBox(height: 16),
          Text(
            'Error loading jobs',
            style: TextStyle(color: ChoiceLuxTheme.softWhite, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error!,
              style: TextStyle(color: ChoiceLuxTheme.softWhite.withOpacity(0.8)),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadJobs,
            style: ElevatedButton.styleFrom(backgroundColor: ChoiceLuxTheme.richGold),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, color: ChoiceLuxTheme.softWhite.withOpacity(0.5), size: 64),
          const SizedBox(height: 16),
          Text(
            'No jobs found',
            style: TextStyle(color: ChoiceLuxTheme.softWhite.withOpacity(0.8), fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(color: ChoiceLuxTheme.softWhite.withOpacity(0.6), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsList(
    AsyncValue clientsAsync,
    AsyncValue users,
    bool isMobile,
  ) {
    return clientsAsync.when(
      data: (clients) {
        final usersList = users.value ?? [];

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _jobs.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= _jobs.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() => _currentPage++);
                      _loadJobs();
                    },
                    child: const Text('Load more'),
                  ),
                ),
              );
            }

            final job = _jobs[index];
            dynamic client;
            try {
              client = clients.firstWhere((c) => c.id.toString() == job.clientId);
            } catch (_) {
              client = clients.isNotEmpty ? clients.first : null;
            }
            final clientName = client?.companyName ?? 'Unknown';
            dynamic driver;
            try {
              driver = usersList.firstWhere((u) => u.id == job.driverId);
            } catch (_) {
              driver = usersList.isNotEmpty ? usersList.first : null;
            }
            final driverName = driver?.displayName ?? 'Unassigned';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: ChoiceLuxTheme.charcoalGray,
              child: InkWell(
                onTap: () => context.go('/jobs/${job.id}/summary?from=job-summaries'),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            job.jobNumber ?? 'JOB-${job.id}',
                            style: const TextStyle(
                              color: ChoiceLuxTheme.richGold,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(job.status).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              job.status.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(job.status),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.arrow_forward_ios, size: 14, color: ChoiceLuxTheme.softWhite.withOpacity(0.5)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        job.passengerName ?? 'No passenger',
                        style: const TextStyle(
                          color: ChoiceLuxTheme.softWhite,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$clientName • $driverName',
                        style: TextStyle(
                          color: ChoiceLuxTheme.softWhite.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(job.jobStartDate),
                        style: TextStyle(
                          color: ChoiceLuxTheme.softWhite.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(ChoiceLuxTheme.richGold),
        ),
      ),
      error: (_, __) => _buildErrorState(),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'in_progress':
      case 'started':
      case 'ready_to_close':
        return Colors.orange;
      default:
        return ChoiceLuxTheme.infoColor;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
