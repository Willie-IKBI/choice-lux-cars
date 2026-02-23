import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/features/insights/providers/driver_detail_insights_provider.dart';
import 'package:choice_lux_cars/features/insights/widgets/star_rating_bar.dart';
import 'package:choice_lux_cars/features/jobs/models/job.dart';
import 'package:choice_lux_cars/features/jobs/widgets/job_list_card.dart';
import 'package:choice_lux_cars/features/clients/providers/clients_provider.dart';
import 'package:choice_lux_cars/features/vehicles/providers/vehicles_provider.dart';
import 'package:choice_lux_cars/features/users/providers/users_provider.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/widgets/system_safe_scaffold.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';

class DriverDetailInsightsScreen extends ConsumerWidget {
  final String driverId;
  final String driverName;

  const DriverDetailInsightsScreen({
    super.key,
    required this.driverId,
    required this.driverName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(driverDetailInsightsProvider(driverId));
    final clientsAsync = ref.watch(clientsProvider);
    final vehiclesState = ref.watch(vehiclesProvider);
    final users = ref.watch(usersProvider);
    final userProfile = ref.watch(currentUserProfileProvider);
    final userRole = userProfile?.role?.toLowerCase() ?? '';
    final canCreateVoucher = userRole == 'administrator' ||
        userRole == 'super_admin' ||
        userRole == 'manager' ||
        userRole == 'driver_manager';
    final canCreateInvoice = canCreateVoucher;

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(screenWidth);
    final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
    final isTablet = ResponsiveBreakpoints.isTablet(screenWidth);
    final isDesktop = ResponsiveBreakpoints.isDesktop(screenWidth);

    final title = driverName.trim().isNotEmpty ? driverName : 'Driver insights';

    return SystemSafeScaffold(
      appBar: LuxuryAppBar(
        title: title,
        showBackButton: true,
        onBackPressed: () => context.go('/insights'),
      ),
      body: dataAsync.when(
        data: (data) {
          final summary = data.summary;
          final jobs = data.jobs;
          final kpis = data.kpis;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: ChoiceLuxTheme.charcoalGray,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Number of jobs',
                              style: TextStyle(
                                fontSize: 14,
                                color: ChoiceLuxTheme.platinumSilver,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${summary?.totalJobsAsDriver ?? jobs.length}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: ChoiceLuxTheme.softWhite,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Average rating',
                              style: TextStyle(
                                fontSize: 14,
                                color: ChoiceLuxTheme.platinumSilver,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                StarRatingBar(
                                  rating: summary?.overallAvg,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  (summary?.last10TripCount ?? 0) > 0
                                      ? '(${summary!.last10TripCount} trips)'
                                      : 'No rating yet',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ChoiceLuxTheme.platinumSilver.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // KPI section
                Text(
                  'Performance KPIs',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ChoiceLuxTheme.softWhite,
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = ResponsiveBreakpoints.isLargeDesktop(screenWidth) ? 2 : 2;
                    final childAspectRatio = isSmallMobile ? 1.4 : (isMobile ? 1.6 : 1.8);
                    final spacing = ResponsiveTokens.getSpacing(screenWidth);
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: childAspectRatio,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      children: [
                        _buildKpiCard(
                          context: context,
                          label: 'Avg time before collecting car',
                          value: kpis.avgMinutesBeforeCollectingCar != null
                              ? '${kpis.avgMinutesBeforeCollectingCar!.round()} min before start'
                              : 'N/A',
                          icon: Icons.directions_car_outlined,
                          iconColor: Colors.blue,
                          progressValue: kpis.avgMinutesBeforeCollectingCar != null ? 1.0 : 0.0,
                        ),
                        _buildKpiCard(
                          context: context,
                          label: 'Avg time before pickup',
                          value: _formatPickupKpi(kpis.avgMinutesBeforePickup),
                          icon: Icons.access_time,
                          iconColor: Colors.green,
                          progressValue: kpis.avgMinutesBeforePickup != null ? 1.0 : 0.0,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Job list
                Text(
                  'Jobs',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ChoiceLuxTheme.softWhite,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${jobs.length} job${jobs.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: ChoiceLuxTheme.platinumSilver,
                  ),
                ),
                const SizedBox(height: 16),
                clientsAsync.when(
                  data: (clients) {
                    final vehicles = vehiclesState.value ?? [];
                    final userList = users.value ?? [];
                    if (jobs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.work_off,
                                color: ChoiceLuxTheme.platinumSilver.withOpacity(0.5),
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No jobs for this driver',
                                style: TextStyle(
                                  color: ChoiceLuxTheme.platinumSilver.withOpacity(0.8),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: jobs.length,
                      itemBuilder: (context, index) {
                        final job = jobs[index];
                        final matchingClients = clients.where((c) => c.id.toString() == job.clientId);
                        final client = matchingClients.isEmpty ? null : matchingClients.first;
                        final matchingVehicles = vehicles.where((v) => v.id.toString() == job.vehicleId);
                        final vehicle = matchingVehicles.isEmpty ? null : matchingVehicles.first;
                        final matchingDrivers = userList.where((u) => u.id == job.driverId);
                        final driver = matchingDrivers.isEmpty ? null : matchingDrivers.first;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: JobListCard(
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
                            fromRoute: 'insights-driver',
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(ChoiceLuxTheme.richGold),
                      ),
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Error loading clients: $err',
                        style: TextStyle(color: ChoiceLuxTheme.errorColor),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(ChoiceLuxTheme.richGold),
              ),
              SizedBox(height: 16),
              Text(
                'Loading driver details...',
                style: TextStyle(color: ChoiceLuxTheme.platinumSilver),
              ),
            ],
          ),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: ChoiceLuxTheme.errorColor, size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to load driver details',
                style: TextStyle(
                  color: ChoiceLuxTheme.softWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  error.toString(),
                  style: TextStyle(color: ChoiceLuxTheme.platinumSilver),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.invalidate(driverDetailInsightsProvider(driverId)),
                style: ElevatedButton.styleFrom(backgroundColor: ChoiceLuxTheme.richGold),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPickupKpi(double? avgMinutes) {
    if (avgMinutes == null) return 'N/A';
    final m = avgMinutes.round();
    if (m > 0) return '$m min early';
    if (m < 0) return '${-m} min late';
    return 'On time';
  }

  Widget _buildKpiCard({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required double progressValue,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(screenWidth);
    final cardPadding = isSmallMobile ? 10.0 : (isMobile ? 12.0 : 16.0);
    final iconSize = isSmallMobile ? 32.0 : (isMobile ? 36.0 : 40.0);
    final iconIconSize = isSmallMobile ? 18.0 : (isMobile ? 20.0 : 22.0);
    final valueFontSize = isSmallMobile ? 18.0 : (isMobile ? 20.0 : 24.0);
    final labelFontSize = isSmallMobile ? 11.0 : (isMobile ? 12.0 : 14.0);

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: iconIconSize),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: valueFontSize,
                fontWeight: FontWeight.w700,
                color: ChoiceLuxTheme.softWhite,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: labelFontSize,
              color: ChoiceLuxTheme.platinumSilver,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(1),
            ),
            child: FractionallySizedBox(
              widthFactor: progressValue.clamp(0.0, 1.0),
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
