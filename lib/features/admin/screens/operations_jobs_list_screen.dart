import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/admin/services/operations_dashboard_service.dart';
import 'package:choice_lux_cars/features/jobs/data/jobs_repository.dart';
import 'package:choice_lux_cars/features/jobs/models/job.dart';
import 'package:choice_lux_cars/features/jobs/widgets/job_card.dart';
import 'package:choice_lux_cars/features/clients/providers/clients_provider.dart';
import 'package:choice_lux_cars/features/clients/models/client.dart';
import 'package:choice_lux_cars/features/vehicles/providers/vehicles_provider.dart';
import 'package:choice_lux_cars/features/vehicles/models/vehicle.dart';
import 'package:choice_lux_cars/features/users/providers/users_provider.dart';
import 'package:choice_lux_cars/features/users/models/user.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/widgets/system_safe_scaffold.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';

/// Lists today's jobs for one operations KPI category (no filters).
/// Back navigates to Operations Dashboard.
class OperationsJobsListScreen extends ConsumerStatefulWidget {
  /// One of: total, completed, in_progress, waiting_arrived, problem
  final String category;
  /// Display title for the app bar (e.g. "Completed", "In progress")
  final String title;

  const OperationsJobsListScreen({
    super.key,
    required this.category,
    required this.title,
  });

  @override
  ConsumerState<OperationsJobsListScreen> createState() => _OperationsJobsListScreenState();
}

class _OperationsJobsListScreenState extends ConsumerState<OperationsJobsListScreen> {
  List<Job> _jobs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ids = await OperationsDashboardService.getTodayJobIdsByCategory(widget.category);
      if (ids.isEmpty) {
        setState(() {
          _jobs = [];
          _loading = false;
        });
        return;
      }
      final repo = ref.read(jobsRepositoryProvider);
      final result = await repo.fetchJobsByIds(ids);
      if (result.isSuccess) {
        setState(() {
          _jobs = result.data ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = result.error?.toString() ?? 'Failed to load jobs';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);
    final vehiclesState = ref.watch(vehiclesProvider);
    final users = ref.watch(usersProvider);
    final userProfile = ref.watch(currentUserProfileProvider);

    final clientsMap = <String, Client>{};
    final vehiclesMap = <String, Vehicle>{};
    final usersMap = <String, User>{};

    if (clientsAsync.hasValue && clientsAsync.value != null) {
      for (final c in clientsAsync.value!) {
        clientsMap[c.id.toString()] = c;
      }
    }
    if (vehiclesState.hasValue && vehiclesState.value != null) {
      for (final v in vehiclesState.value!) {
        vehiclesMap[v.id.toString()] = v;
      }
    }
    if (users.hasValue && users.value != null) {
      for (final u in users.value!) {
        usersMap[u.id] = u;
      }
    }

    final canCreateVoucher = _canCreateVoucher(userProfile?.role);
    final canCreateInvoice = canCreateVoucher;

    final width = MediaQuery.of(context).size.width;
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(width);
    final isMobile = ResponsiveBreakpoints.isMobile(width);
    final isTablet = ResponsiveBreakpoints.isTablet(width);
    final isDesktop = ResponsiveBreakpoints.isDesktop(width);
    final padding = ResponsiveTokens.getPadding(width);
    final spacing = ResponsiveTokens.getSpacing(width);

    return Container(
      color: ChoiceLuxTheme.jetBlack,
      child: SystemSafeScaffold(
        backgroundColor: Colors.transparent,
        appBar: LuxuryAppBar(
          title: widget.title,
          subtitle: '${_jobs.length} job${_jobs.length == 1 ? '' : 's'}',
          showBackButton: true,
          onBackPressed: () => context.go('/admin/operations'),
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          color: ChoiceLuxTheme.richGold,
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: ChoiceLuxTheme.richGold))
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: ChoiceLuxTheme.errorColor),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              style: TextStyle(color: ChoiceLuxTheme.platinumSilver, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: _load,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _jobs.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.assignment_outlined, size: 48, color: ChoiceLuxTheme.platinumSilver),
                                const SizedBox(height: 16),
                                Text(
                                  'No jobs in this category for today',
                                  style: TextStyle(color: ChoiceLuxTheme.softWhite, fontSize: 16, fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: padding, vertical: spacing),
                          itemCount: _jobs.length,
                          itemBuilder: (context, index) {
                            final job = _jobs[index];
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
                                fromRoute: 'operations',
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }

  bool _canCreateVoucher(String? role) {
    final r = role?.toLowerCase();
    return r == 'administrator' || r == 'super_admin' || r == 'manager' || r == 'driver_manager' || r == 'drivermanager';
  }
}
