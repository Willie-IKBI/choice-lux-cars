import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/insights/models/insights_data.dart';
import 'package:choice_lux_cars/features/insights/providers/vehicle_insights_provider.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:fl_chart/fl_chart.dart';

class VehicleInsightsTab extends ConsumerWidget {
  final TimePeriod selectedPeriod;
  final LocationFilter selectedLocation;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const VehicleInsightsTab({
    super.key,
    required this.selectedPeriod,
    required this.selectedLocation,
    this.customStartDate,
    this.customEndDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleInsightsAsync = ref.watch(vehicleInsightsProvider((
      selectedPeriod,
      selectedLocation,
      customStartDate,
      customEndDate,
    )));

    return Container(
      padding: const EdgeInsets.all(16),
      child: vehicleInsightsAsync.when(
        data: (insights) => _buildVehicleContent(insights),
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildVehicleContent(VehicleInsights insights) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1a1a1a),
                  Color(0xFF2d2d2d),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ChoiceLuxTheme.richGold.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.directions_car_outlined,
                  color: ChoiceLuxTheme.richGold,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vehicle Analytics',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${insights.totalVehicles} vehicles • ${insights.activeVehicles} active${insights.inactiveVehicles > 0 ? ' • ${insights.inactiveVehicles} inactive' : ''}${insights.underMaintenanceVehicles > 0 ? ' • ${insights.underMaintenanceVehicles} under maintenance' : ''}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Key Metrics
          _buildSectionHeader('Vehicle Performance'),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isLargeDesktop = screenWidth >= 1200;
              final isDesktop = screenWidth >= 600;
              
              // 4 columns on large desktop (all cards in one row), 2 columns on medium desktop/tablet
              final crossAxisCount = isLargeDesktop ? 4 : 2;
              final childAspectRatio = isDesktop ? 1.0 : 1.5; // Square cards on desktop, taller on mobile
              final spacing = isDesktop ? 12.0 : 16.0; // Match dashboard spacing on desktop
              
              final gridView = GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                children: [
                  _buildMetricCard(
                    'Total Vehicles',
                    insights.totalVehicles.toString(),
                    Icons.directions_car_outlined,
                    ChoiceLuxTheme.richGold,
                    context: context,
                  ),
                  _buildMetricCard(
                    'Active Vehicles',
                    insights.activeVehicles.toString(),
                    Icons.directions_car,
                    Colors.green,
                    context: context,
                  ),
                  _buildMetricCard(
                    'Avg Jobs/Vehicle',
                    insights.averageJobsPerVehicle.toStringAsFixed(1),
                    Icons.work_outline,
                    Colors.blue,
                    context: context,
                  ),
                  _buildMetricCard(
                    'Avg Revenue/Vehicle',
                    'R${insights.averageIncomePerVehicle.toStringAsFixed(0)}',
                    Icons.attach_money,
                    Colors.orange,
                    context: context,
                  ),
                  if (insights.averageUtilizationRate > 0)
                    _buildMetricCard(
                      'Avg Utilization',
                      '${insights.averageUtilizationRate.toStringAsFixed(1)}%',
                      Icons.trending_up,
                      Colors.purple,
                      context: context,
                    ),
                  if (insights.averageMileagePerVehicle > 0)
                    _buildMetricCard(
                      'Avg Mileage/Vehicle',
                      '${insights.averageMileagePerVehicle.toStringAsFixed(0)} km',
                      Icons.speed,
                      Colors.teal,
                      context: context,
                    ),
                  if (insights.averageMileagePerJob > 0)
                    _buildMetricCard(
                      'Avg Mileage/Job',
                      '${insights.averageMileagePerJob.toStringAsFixed(0)} km',
                      Icons.route,
                      Colors.cyan,
                      context: context,
                    ),
                ],
              );
              
              // Center the grid on desktop with max width constraint
              if (isDesktop) {
                // Calculate max width: for 4 columns, cap at ~800px; for 2 columns, cap at ~600px
                final maxWidth = isLargeDesktop ? 800.0 : 600.0;
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: gridView,
                  ),
                );
              }
              
              return gridView;
            },
          ),
          
          // Status Breakdown
          if (insights.inactiveVehicles > 0 || insights.underMaintenanceVehicles > 0) ...[
            const SizedBox(height: 32),
            _buildSectionHeader('Vehicle Status Breakdown'),
            const SizedBox(height: 16),
            _buildStatusBreakdown(insights),
          ],
          
          // License Expiry Alerts
          if (insights.licenseExpiringSoon.isNotEmpty) ...[
            const SizedBox(height: 32),
            _buildSectionHeader('License Expiry Alerts'),
            const SizedBox(height: 16),
            _buildLicenseAlerts(insights.licenseExpiringSoon),
          ],
          
          // Top Vehicles by Job Count
          if (insights.topVehicles.isNotEmpty) ...[
            const SizedBox(height: 32),
            _buildSectionHeader('Top Vehicles by Job Count'),
            const SizedBox(height: 16),
            _buildTopVehiclesList(insights.topVehicles, 'jobs'),
          ],
          
          // Top Vehicles by Revenue
          if (insights.topVehiclesByRevenue.isNotEmpty) ...[
            const SizedBox(height: 32),
            _buildSectionHeader('Top Vehicles by Revenue'),
            const SizedBox(height: 16),
            _buildTopVehiclesList(insights.topVehiclesByRevenue, 'revenue'),
          ],
          
          // Underutilized Vehicles
          if (insights.underutilizedVehicles.isNotEmpty) ...[
            const SizedBox(height: 32),
            _buildSectionHeader('Underutilized Vehicles'),
            const SizedBox(height: 16),
            _buildUnderutilizedVehiclesList(insights.underutilizedVehicles),
          ],
          
          // Branch Comparison
          if (insights.vehiclesByBranch.isNotEmpty) ...[
            const SizedBox(height: 32),
            _buildSectionHeader('Vehicles by Branch'),
            const SizedBox(height: 16),
            _buildBranchComparison(insights),
            const SizedBox(height: 24),
            _buildBranchComparisonChart(insights),
          ],
          
          // Utilization Chart
          if (insights.topVehicles.isNotEmpty && insights.topVehicles.any((v) => v.utilizationRate != null)) ...[
            const SizedBox(height: 32),
            _buildSectionHeader('Vehicle Utilization Chart'),
            const SizedBox(height: 16),
            _buildUtilizationChart(insights.topVehicles),
          ],
        ],
      ),
    );
  }
  
  Widget _buildStatusBreakdown(VehicleInsights insights) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatusItem('Active', insights.activeVehicles, Colors.green),
          if (insights.inactiveVehicles > 0)
            _buildStatusItem('Inactive', insights.inactiveVehicles, Colors.grey),
          if (insights.underMaintenanceVehicles > 0)
            _buildStatusItem('Maintenance', insights.underMaintenanceVehicles, Colors.orange),
        ],
      ),
    );
  }
  
  Widget _buildStatusItem(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
  
  Widget _buildLicenseAlerts(List<VehicleLicenseAlert> alerts) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
              const SizedBox(width: 8),
              Text(
                '${alerts.length} vehicle${alerts.length == 1 ? '' : 's'} with license expiring soon',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...alerts.map((alert) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${alert.vehicleName} (${alert.registration})',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: alert.daysUntilExpiry < 0 
                        ? Colors.red 
                        : alert.daysUntilExpiry <= 7 
                            ? Colors.orange 
                            : Colors.yellow.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    alert.daysUntilExpiry < 0
                        ? 'Expired ${-alert.daysUntilExpiry} day${-alert.daysUntilExpiry == 1 ? '' : 's'} ago'
                        : '${alert.daysUntilExpiry} day${alert.daysUntilExpiry == 1 ? '' : 's'} left',
                    style: TextStyle(
                      color: alert.daysUntilExpiry < 0 || alert.daysUntilExpiry <= 7
                          ? Colors.white
                          : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
  
  Widget _buildTopVehiclesList(List<TopVehicle> vehicles, String sortBy) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: vehicles.map((vehicle) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: vehicles.indexOf(vehicle) < vehicles.length - 1 ? 1 : 0,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${vehicles.indexOf(vehicle) + 1}',
                    style: TextStyle(
                      color: ChoiceLuxTheme.richGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.vehicleName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vehicle.registration,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    sortBy == 'jobs' 
                        ? '${vehicle.jobCount} jobs'
                        : 'R${vehicle.revenue.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (vehicle.utilizationRate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${vehicle.utilizationRate!.toStringAsFixed(1)}% util.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                  if (vehicle.totalMileage != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${vehicle.totalMileage!.toStringAsFixed(0)} km${vehicle.averageMileagePerJob != null ? ' • ${vehicle.averageMileagePerJob!.toStringAsFixed(0)} km/job' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }
  
  Widget _buildUnderutilizedVehiclesList(List<UnderutilizedVehicle> vehicles) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              Text(
                '${vehicles.length} underutilized vehicle${vehicles.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...vehicles.map((vehicle) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.vehicleName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${vehicle.registration}${vehicle.branchName != null ? ' • ${vehicle.branchName}' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${vehicle.jobCount} jobs',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${vehicle.utilizationRate.toStringAsFixed(1)}% util.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
  
  Widget _buildBranchComparison(VehicleInsights insights) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: insights.vehiclesByBranch.entries.map((entry) {
          final branchName = entry.key;
          final vehicleCount = entry.value;
          final utilization = insights.utilizationByBranch[branchName] ?? 0.0;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    branchName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$vehicleCount vehicles',
                    style: TextStyle(
                      color: ChoiceLuxTheme.richGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${utilization.toStringAsFixed(1)}% util.',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, {required BuildContext context}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 600;
    
    // Smaller, more compact cards for desktop
    final iconSize = isDesktop ? 20.0 : 32.0;
    final iconContainerPadding = isDesktop ? 6.0 : 12.0;
    final cardPadding = isDesktop ? const EdgeInsets.all(6.0) : const EdgeInsets.all(16.0);
    final valueFontSize = isDesktop ? 16.0 : 24.0;
    final titleFontSize = isDesktop ? 12.0 : 14.0;
    final titleSpacing = isDesktop ? 4.0 : 8.0;
    final valueSpacing = isDesktop ? 3.0 : 8.0;
    final borderRadius = isDesktop ? 16.0 : 12.0;
    
    return Container(
      padding: cardPadding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(iconContainerPadding),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(borderRadius * 0.8),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
          SizedBox(height: valueSpacing),
          Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: titleSpacing),
          Text(
            title,
            style: TextStyle(
              fontSize: titleFontSize,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ChoiceLuxTheme.richGold),
          ),
          SizedBox(height: 16),
          Text(
            'Loading vehicle insights...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load vehicle insights',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Refresh logic would go here
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ChoiceLuxTheme.richGold,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBranchComparisonChart(VehicleInsights insights) {
    final branches = insights.vehiclesByBranch.keys.toList();
    if (branches.isEmpty) return const SizedBox.shrink();
    
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: insights.vehiclesByBranch.values.reduce((a, b) => a > b ? a : b).toDouble() * 1.2,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < branches.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        branches[value.toInt()],
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.white.withOpacity(0.1),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: branches.asMap().entries.map((entry) {
            final index = entry.key;
            final branchName = entry.value;
            final vehicleCount = insights.vehiclesByBranch[branchName] ?? 0;
            
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: vehicleCount.toDouble(),
                  color: ChoiceLuxTheme.richGold,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
  
  Widget _buildUtilizationChart(List<TopVehicle> vehicles) {
    final vehiclesWithUtilization = vehicles.where((v) => v.utilizationRate != null).toList();
    if (vehiclesWithUtilization.isEmpty) return const SizedBox.shrink();
    
    // Take top 10 for readability
    final topVehicles = vehiclesWithUtilization.take(10).toList();
    
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < topVehicles.length) {
                    final vehicle = topVehicles[value.toInt()];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        vehicle.registration.length > 8 
                            ? '${vehicle.registration.substring(0, 8)}...'
                            : vehicle.registration,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 40,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}%',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.white.withOpacity(0.1),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: topVehicles.asMap().entries.map((entry) {
            final index = entry.key;
            final vehicle = entry.value;
            final utilization = vehicle.utilizationRate ?? 0.0;
            
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: utilization,
                  color: _getUtilizationColor(utilization),
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
  
  Color _getUtilizationColor(double utilization) {
    if (utilization >= 70) return Colors.green;
    if (utilization >= 40) return Colors.orange;
    return Colors.red;
  }
}
