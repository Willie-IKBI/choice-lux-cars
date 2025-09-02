import 'package:flutter/material.dart';
import '../services/driver_flow_api_service.dart';
import '../widgets/job_monitoring_card.dart';
import '../widgets/driver_activity_card.dart';
import '../widgets/active_jobs_summary.dart';
import '../models/job.dart';
import 'job_progress_screen.dart';
import '../../../shared/widgets/luxury_app_bar.dart';
import '../../../app/theme.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminMonitoringScreen extends ConsumerStatefulWidget {
  const AdminMonitoringScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminMonitoringScreen> createState() =>
      _AdminMonitoringScreenState();
}

class _AdminMonitoringScreenState extends ConsumerState<AdminMonitoringScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _isRefreshing = false;
  List<Map<String, dynamic>> _activeJobs = [];
  List<Map<String, dynamic>> _driverActivity = [];
  Map<String, dynamic> _summary = {};

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      // Load active jobs
      final activeJobs =
          await DriverFlowApiService.getActiveJobsForMonitoring();

      // Load driver activity
      final driverActivity =
          await DriverFlowApiService.getDriverActivitySummary();

      // Calculate summary
      final summary = _calculateSummary(activeJobs, driverActivity);

      setState(() {
        _activeJobs = activeJobs;
        _driverActivity = driverActivity;
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load monitoring data: $e');
    }
  }

  Future<void> _refreshData() async {
    try {
      setState(() => _isRefreshing = true);
      await _loadData();
      _showSuccessSnackBar('Data refreshed successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to refresh data: $e');
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  Map<String, dynamic> _calculateSummary(
    List<Map<String, dynamic>> activeJobs,
    List<Map<String, dynamic>> driverActivity,
  ) {
    int totalActiveJobs = activeJobs.length;
    int veryRecentJobs = activeJobs
        .where((job) => job['activity_recency'] == 'very_recent')
        .length;
    int recentJobs = activeJobs
        .where((job) => job['activity_recency'] == 'recent')
        .length;
    int staleJobs = activeJobs
        .where((job) => job['activity_recency'] == 'stale')
        .length;

    int activeDrivers = driverActivity
        .where((driver) => driver['driver_status'] == 'active')
        .length;
    int recentDrivers = driverActivity
        .where((driver) => driver['driver_status'] == 'recent')
        .length;
    int inactiveDrivers = driverActivity
        .where((driver) => driver['driver_status'] == 'inactive')
        .length;

    return {
      'total_active_jobs': totalActiveJobs,
      'very_recent_jobs': veryRecentJobs,
      'recent_jobs': recentJobs,
      'stale_jobs': staleJobs,
      'active_drivers': activeDrivers,
      'recent_drivers': recentDrivers,
      'inactive_drivers': inactiveDrivers,
      'total_drivers': driverActivity.length,
    };
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LuxuryAppBar(
        title: 'Job Monitoring',
        subtitle: 'Real-time job and driver tracking',
        showBackButton: true,
        onBackPressed: () => context.go('/'),
        onSignOut: () async {
          await ref.read(authProvider.notifier).signOut();
        },
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ChoiceLuxTheme.richGold,
                      ),
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
            onPressed: _isRefreshing ? null : _refreshData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Custom TabBar with luxury styling
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ChoiceLuxTheme.jetBlack.withOpacity(0.95),
                  ChoiceLuxTheme.jetBlack.withOpacity(0.90),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: ChoiceLuxTheme.richGold,
              labelColor: ChoiceLuxTheme.richGold,
              unselectedLabelColor: ChoiceLuxTheme.platinumSilver,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Summary', icon: Icon(Icons.dashboard_rounded)),
                Tab(text: 'Active Jobs', icon: Icon(Icons.work_rounded)),
                Tab(text: 'Drivers', icon: Icon(Icons.people_rounded)),
              ],
            ),
          ),
          // TabBarView content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _refreshData,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSummaryTab(),
                        _buildActiveJobsTab(),
                        _buildDriversTab(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ActiveJobsSummary(summary: _summary),
          const SizedBox(height: 24),

          // Quick Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Active Jobs',
                  _summary['total_active_jobs']?.toString() ?? '0',
                  Icons.work,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Active Drivers',
                  _summary['active_drivers']?.toString() ?? '0',
                  Icons.person,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Recent Activity',
                  _summary['very_recent_jobs']?.toString() ?? '0',
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Stale Jobs',
                  _summary['stale_jobs']?.toString() ?? '0',
                  Icons.warning,
                  Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Recent Activity Timeline
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._activeJobs
                      .take(5)
                      .map((job) => _buildActivityItem(job))
                      .toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveJobsTab() {
    if (_activeJobs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Active Jobs',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'All drivers are currently available',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      itemCount: _activeJobs.length,
      itemBuilder: (context, index) {
        final job = _activeJobs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: JobMonitoringCard(job: job, onTap: () => _showJobDetails(job)),
        );
      },
    );
  }

  Widget _buildDriversTab() {
    if (_driverActivity.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Driver Data',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'No driver activity information available',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      itemCount: _driverActivity.length,
      itemBuilder: (context, index) {
        final driver = _driverActivity[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: DriverActivityCard(
            driver: driver,
            onTap: () => _showDriverDetails(driver),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> job) {
    final recency = job['activity_recency'] ?? 'unknown';
    final driverName = job['driver_name'] ?? 'Unknown Driver';
    final currentStep = job['current_step'] ?? 'Unknown Step';
    final lastActivity = job['last_activity_at'];

    Color statusColor;
    IconData statusIcon;

    switch (recency) {
      case 'very_recent':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'recent':
        statusColor = Colors.blue;
        statusIcon = Icons.info;
        break;
      case 'stale':
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Step: $currentStep',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (lastActivity != null)
                  Text(
                    'Last activity: ${_formatTimestamp(lastActivity)}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  void _showJobDetails(Map<String, dynamic> job) {
    // Navigate to job details screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JobProgressScreen(
          jobId: int.parse(job['job_id']),
          job: Job.fromMap(job),
        ),
      ),
    );
  }

  void _showDriverDetails(Map<String, dynamic> driver) {
    // Show driver details modal or navigate to driver details screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Driver: ${driver['driver_name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phone: ${driver['driver_phone'] ?? 'N/A'}'),
            Text('Status: ${driver['driver_status']}'),
            Text('Assigned Jobs: ${driver['assigned_jobs']}'),
            Text('Active Jobs: ${driver['active_jobs']}'),
            Text(
              'Last Activity: ${_formatTimestamp(driver['last_activity'] ?? '')}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
