import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/widgets/system_safe_scaffold.dart';
import 'package:choice_lux_cars/features/admin/models/ops_today_summary.dart';
import 'package:choice_lux_cars/features/admin/models/ops_driver_option.dart';
import 'package:choice_lux_cars/features/admin/services/operations_dashboard_service.dart';
import 'package:choice_lux_cars/features/admin/services/admin_jobs_service.dart';
import 'package:choice_lux_cars/features/admin/widgets/ops_kpi_tile.dart';
import 'package:choice_lux_cars/features/admin/widgets/ops_section_card.dart';
import 'package:choice_lux_cars/features/admin/widgets/ops_alert_row.dart';
import 'package:choice_lux_cars/features/admin/widgets/ops_driver_row.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/features/jobs/services/driver_flow_api_service.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';

/// Ops breakpoints: mobile < 600, tablet 600–1024, desktop >= 1024
class _OpsBreakpoints {
  static bool isMobile(double width) => width < 600;
  static bool isTablet(double width) => width >= 600 && width < 1024;
  static bool isDesktop(double width) => width >= 1024;
}

/// Admin-only Operations Dashboard – premium card-based layout, KPI tiles, alerts, driver workload.
class OperationsDashboardScreen extends ConsumerStatefulWidget {
  const OperationsDashboardScreen({super.key});

  @override
  ConsumerState<OperationsDashboardScreen> createState() => _OperationsDashboardScreenState();
}

class _OperationsDashboardScreenState extends ConsumerState<OperationsDashboardScreen> {
  static const double _maxContentWidth = 1200;
  static const double _sectionSpacing = 24;

  bool _loading = true;
  OpsTodaySummary? _summary;
  String? _error;
  DateTime? _lastUpdated;
  int? _closingJobId;
  int? _assigningJobId;
  String? _alertFilter; // client-side: All, Stuck, Unassigned, Missing Agent, Vehicle Return

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
      final summary = await OperationsDashboardService.getTodaySummary();
      if (mounted) {
        setState(() {
          _summary = summary;
          _loading = false;
          _lastUpdated = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<OpsAlertItem> get _filteredAlerts {
    if (_summary == null) return [];
    final list = _summary!.alerts;
    if (_alertFilter == null || _alertFilter == 'All') return list;
    return list.where((a) {
      switch (_alertFilter!) {
        case 'Stuck':
          return a.reason.toLowerCase().contains('stuck');
        case 'Unassigned':
          return a.reason == 'Unassigned job';
        case 'Missing Agent':
          return a.reason == 'Missing agent assignment';
        case 'Vehicle Return':
          return a.reason.toLowerCase().contains('vehicle') || a.reason.toLowerCase().contains('return');
        default:
          return true;
      }
    }).toList();
  }

  Future<void> _closeAlertJob(OpsAlertItem item) async {
    final userId = ref.read(currentUserProfileProvider)?.id;
    if (userId == null) return;
    final commentController = TextEditingController();
    final comment = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close job (admin)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Closing this job will mark it and all trips as completed. A comment is required for reporting.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: 'Comment (required)',
                hintText: 'e.g. Closed by admin – vehicle returned off-app',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final t = commentController.text.trim();
              if (t.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Please enter a comment.'), backgroundColor: ChoiceLuxTheme.errorColor),
                );
                return;
              }
              Navigator.of(ctx).pop(t);
            },
            child: const Text('Close job'),
          ),
        ],
      ),
    );
    if (comment == null || comment.isEmpty || !mounted) return;
    setState(() => _closingJobId = item.jobId);
    try {
      await DriverFlowApiService.closeJobByAdmin(
        item.jobId,
        closedByUserId: userId,
        comment: comment,
      );
      if (!mounted) return;
      setState(() => _closingJobId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Job #${item.jobId} closed'), backgroundColor: ChoiceLuxTheme.successColor),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _closingJobId = null);
      final msg = e is Exception ? e.toString().replaceFirst('Exception: ', '') : '$e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: ChoiceLuxTheme.errorColor),
      );
    }
  }

  Future<void> _launchCall(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open phone app'), backgroundColor: ChoiceLuxTheme.errorColor),
        );
      }
    }
  }

  Future<void> _launchWhatsApp(String number) async {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    final uri = Uri.parse('https://wa.me/$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp'), backgroundColor: ChoiceLuxTheme.errorColor),
        );
      }
    }
  }

  Future<void> _showAssignDriverDialog(OpsAlertItem item) async {
    final userId = ref.read(currentUserProfileProvider)?.id;
    if (userId == null) return;
    final drivers = await AdminJobsService.getEligibleDrivers();
    if (!mounted) return;
    if (drivers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No eligible drivers'), backgroundColor: ChoiceLuxTheme.errorColor),
      );
      return;
    }
    OpsDriverOption selected = drivers.first;
    final result = await showDialog<OpsDriverOption>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Assign driver'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<OpsDriverOption>(
                    value: selected,
                    decoration: const InputDecoration(labelText: 'Driver'),
                    items: drivers.map((d) => DropdownMenuItem(value: d, child: Text(d.displayName))).toList(),
                    onChanged: (d) => setDialogState(() => selected = d!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(selected),
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _assigningJobId = item.jobId);
    try {
      await AdminJobsService.assignDriver(item.jobId, result.id, assignedByUserId: userId);
      if (!mounted) return;
      setState(() => _assigningJobId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver assigned'), backgroundColor: ChoiceLuxTheme.successColor),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _assigningJobId = null);
      final msg = e is Exception ? e.toString().replaceFirst('Exception: ', '') : '$e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: ChoiceLuxTheme.errorColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final padding = ResponsiveTokens.getPadding(width);
    final spacing = ResponsiveTokens.getSpacing(width);
    final userProfile = ref.watch(currentUserProfileProvider);
    final role = userProfile?.role?.toLowerCase();
    final isAdmin = role == 'administrator' || role == 'super_admin';
    final isMobile = _OpsBreakpoints.isMobile(width);
    final isDesktop = _OpsBreakpoints.isDesktop(width);

    return SystemSafeScaffold(
      appBar: LuxuryAppBar(
        title: 'Operations Dashboard',
        showBackButton: true,
        onBackPressed: () => context.go('/'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: ChoiceLuxTheme.richGold))
          : _error != null
              ? _buildErrorState(padding, spacing)
              : _summary!.total == 0
                  ? _buildEmptyState(padding, spacing)
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: ChoiceLuxTheme.richGold,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? padding * 2 : padding,
                          vertical: padding,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: _maxContentWidth),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildPageHeader(width, padding, spacing, isDesktop),
                                SizedBox(height: _sectionSpacing),
                                _buildKpiSection(context, width, padding, spacing),
                                SizedBox(height: _sectionSpacing),
                                _buildAlertsSection(width, padding, spacing, isAdmin, isMobile),
                                SizedBox(height: _sectionSpacing),
                                _buildDriverSection(width, padding, spacing, isAdmin, isMobile),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
    );
  }

  Widget _buildPageHeader(double width, double padding, double spacing, bool isDesktop) {
    final lastUpdatedStr = _lastUpdated != null
        ? '${_lastUpdated!.hour.toString().padLeft(2, '0')}:${_lastUpdated!.minute.toString().padLeft(2, '0')}'
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Operations Dashboard',
                    style: TextStyle(
                      color: ChoiceLuxTheme.softWhite,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: spacing * 0.5),
                  Text(
                    'Live view of today\'s workload',
                    style: TextStyle(
                      color: ChoiceLuxTheme.platinumSilver.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isDesktop) ...[
              if (lastUpdatedStr != null) ...[
                Padding(
                  padding: EdgeInsets.only(right: spacing),
                  child: Text(
                    'Last updated: $lastUpdatedStr',
                    style: TextStyle(
                      color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              IconButton(
                icon: Icon(Icons.refresh, color: ChoiceLuxTheme.richGold),
                onPressed: _loading ? null : _load,
                tooltip: 'Refresh',
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildKpiSection(BuildContext context, double width, double padding, double spacing) {
    final crossAxisCount = _OpsBreakpoints.isMobile(width)
        ? 2
        : _OpsBreakpoints.isTablet(width)
            ? 3
            : 5;
    final tiles = <Widget>[
      OpsKpiTile(
        label: 'Total',
        value: _summary!.total.toString(),
        icon: Icons.assignment_outlined,
        iconColor: ChoiceLuxTheme.infoColor,
        isProblem: false,
        onTap: () => context.push(Uri(path: '/admin/operations/jobs', queryParameters: {'category': 'total', 'title': 'Total'}).toString()),
      ),
      OpsKpiTile(
        label: 'Completed',
        value: _summary!.completed.toString(),
        icon: Icons.check_circle_outline,
        iconColor: ChoiceLuxTheme.successColor,
        isProblem: false,
        onTap: () => context.push(Uri(path: '/admin/operations/jobs', queryParameters: {'category': 'completed', 'title': 'Completed'}).toString()),
      ),
      OpsKpiTile(
        label: 'In progress',
        value: _summary!.inProgress.toString(),
        icon: Icons.hourglass_empty,
        iconColor: ChoiceLuxTheme.orange,
        isProblem: false,
        onTap: () => context.push(Uri(path: '/admin/operations/jobs', queryParameters: {'category': 'in_progress', 'title': 'In progress'}).toString()),
      ),
      OpsKpiTile(
        label: 'Waiting / Arrived',
        value: _summary!.waitingArrived.toString(),
        icon: Icons.location_on_outlined,
        iconColor: ChoiceLuxTheme.richGold,
        isProblem: false,
        onTap: () => context.push(Uri(path: '/admin/operations/jobs', queryParameters: {'category': 'waiting_arrived', 'title': 'Waiting / Arrived'}).toString()),
      ),
      OpsKpiTile(
        label: 'Problem',
        value: _summary!.problem.toString(),
        icon: Icons.warning_amber_outlined,
        iconColor: ChoiceLuxTheme.errorColor,
        isProblem: true,
        onTap: () => context.push(Uri(path: '/admin/operations/jobs', queryParameters: {'category': 'problem', 'title': 'Problem'}).toString()),
      ),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      childAspectRatio: _OpsBreakpoints.isDesktop(width) ? 1.0 : 1.2,
      children: tiles,
    );
  }

  Widget _buildAlertsSection(double width, double padding, double spacing, bool isAdmin, bool isMobile) {
    final filtered = _filteredAlerts;
    return OpsSectionCard(
      title: 'Alerts',
      count: _summary!.alerts.length,
      filterChipLabels: const ['All', 'Stuck', 'Unassigned', 'Missing Agent', 'Vehicle Return'],
      selectedFilterLabel: _alertFilter ?? 'All',
      onFilterChanged: (label) => setState(() => _alertFilter = label),
      child: filtered.isEmpty
          ? Padding(
              padding: EdgeInsets.symmetric(vertical: spacing * 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, size: 40, color: ChoiceLuxTheme.platinumSilver),
                  SizedBox(height: spacing),
                  Text(
                    filtered.length == _summary!.alerts.length ? 'No alerts' : 'No matching alerts',
                    style: TextStyle(
                      color: ChoiceLuxTheme.softWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: spacing * 0.5),
                  Text(
                    'Problem jobs (e.g. stuck or vehicle returned not closed) will appear here.',
                    style: TextStyle(color: ChoiceLuxTheme.platinumSilver, fontSize: 14),
                  ),
                ],
              ),
            )
          : Padding(
              padding: EdgeInsets.only(top: spacing),
              child: Column(
                children: filtered
                    .map(
                      (item) => OpsAlertRow(
                        item: item,
                        isAdmin: isAdmin,
                        useOverflowMenu: isMobile,
                        assigning: _assigningJobId == item.jobId,
                        closing: _closingJobId == item.jobId,
                        onAssign: () => _showAssignDriverDialog(item),
                        onClose: item.requiresClose ? () => _closeAlertJob(item) : null,
                        onView: () => context.push('/jobs/${item.jobId}/summary?from=operations'),
                      ),
                    )
                    .toList(),
              ),
            ),
    );
  }

  Widget _buildDriverSection(double width, double padding, double spacing, bool isAdmin, bool isMobile) {
    return OpsSectionCard(
      title: 'Driver workload',
      count: _summary!.drivers.length,
      child: _summary!.drivers.isEmpty
          ? Padding(
              padding: EdgeInsets.symmetric(vertical: spacing * 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.people_outline, size: 40, color: ChoiceLuxTheme.platinumSilver),
                  SizedBox(height: spacing),
                  Text(
                    'No drivers with jobs today',
                    style: TextStyle(
                      color: ChoiceLuxTheme.softWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: spacing * 0.5),
                  Text(
                    'Drivers with today\'s jobs will appear here.',
                    style: TextStyle(color: ChoiceLuxTheme.platinumSilver, fontSize: 14),
                  ),
                ],
              ),
            )
          : Padding(
              padding: EdgeInsets.only(top: spacing),
              child: isMobile
                  ? Column(
                      children: _summary!.drivers
                          .map(
                            (d) => OpsDriverRow(
                              driver: d,
                              isAdmin: isAdmin,
                              isMobile: true,
                              onCall: d.phoneNumber != null ? () => _launchCall(d.phoneNumber!) : null,
                              onWhatsApp: d.phoneNumber != null ? () => _launchWhatsApp(d.phoneNumber!) : null,
                            ),
                          )
                          .toList(),
                    )
                  : Padding(
                      padding: EdgeInsets.symmetric(horizontal: spacing * 1.5),
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(1),
                          3: FlexColumnWidth(1),
                          4: FlexColumnWidth(2),
                        },
                        children: [
                          _buildDriverTableHeaderRow(spacing),
                          ..._summary!.drivers.map(
                            (d) => OpsDriverRow(
                              driver: d,
                              isAdmin: isAdmin,
                              isMobile: false,
                              onCall: d.phoneNumber != null ? () => _launchCall(d.phoneNumber!) : null,
                              onWhatsApp: d.phoneNumber != null ? () => _launchWhatsApp(d.phoneNumber!) : null,
                            ).buildTableRow(context),
                          ),
                        ],
                      ),
                    ),
            ),
    );
  }

  TableRow _buildDriverTableHeaderRow(double spacing) {
    final textStyle = TextStyle(
      color: ChoiceLuxTheme.platinumSilver.withOpacity(0.8),
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );
    return TableRow(
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: spacing * 0.75),
            child: Text('Driver', style: textStyle),
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: spacing * 0.75),
            child: Text('Jobs today', style: textStyle, textAlign: TextAlign.center),
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: spacing * 0.75),
            child: Center(child: Text('State', style: textStyle)),
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: spacing * 0.75),
            child: Text('Long wait', style: textStyle, textAlign: TextAlign.center),
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: spacing * 0.75),
            child: Row(
              children: [
                Expanded(child: Text('Active job', style: textStyle)),
                SizedBox(width: spacing),
                SizedBox(width: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(double padding, double spacing) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: ChoiceLuxTheme.errorColor),
            SizedBox(height: spacing),
            Text(
              'Failed to load today summary',
              style: TextStyle(color: ChoiceLuxTheme.softWhite, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing * 0.5),
            Text(
              _error!,
              style: TextStyle(color: ChoiceLuxTheme.platinumSilver, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: spacing * 2),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(double padding, double spacing) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.today_outlined, size: 64, color: ChoiceLuxTheme.platinumSilver),
            SizedBox(height: spacing * 2),
            Text(
              'No jobs today',
              style: TextStyle(
                color: ChoiceLuxTheme.softWhite,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: spacing * 0.5),
            Text(
              'Jobs with today\'s date will appear here.',
              style: TextStyle(color: ChoiceLuxTheme.platinumSilver, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
