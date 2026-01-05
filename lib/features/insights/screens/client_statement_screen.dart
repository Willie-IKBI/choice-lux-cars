import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/insights/models/client_statement_data.dart';
import 'package:choice_lux_cars/features/insights/providers/client_statement_provider.dart';
import 'package:choice_lux_cars/shared/widgets/system_safe_scaffold.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';

class ClientStatementScreen extends ConsumerStatefulWidget {
  final String clientId;
  final String? clientName;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const ClientStatementScreen({
    super.key,
    required this.clientId,
    this.clientName,
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  ConsumerState<ClientStatementScreen> createState() => _ClientStatementScreenState();
}

class _ClientStatementScreenState extends ConsumerState<ClientStatementScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate ?? DateTime.now().subtract(const Duration(days: 30));
    _endDate = widget.initialEndDate ?? DateTime.now();
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: ChoiceLuxTheme.richGold,
              onPrimary: Colors.black,
              surface: ChoiceLuxTheme.charcoalGray,
              onSurface: ChoiceLuxTheme.softWhite,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: ChoiceLuxTheme.richGold,
              onPrimary: Colors.black,
              surface: ChoiceLuxTheme.charcoalGray,
              onSurface: ChoiceLuxTheme.softWhite,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(screenWidth);

    final statementAsync = ref.watch(
      clientStatementProvider(
        ClientStatementParams(
          clientId: widget.clientId,
          startDate: _startDate,
          endDate: _endDate,
        ),
      ),
    );

    return SystemSafeScaffold(
      backgroundColor: ChoiceLuxTheme.jetBlack,
      appBar: LuxuryAppBar(
        title: widget.clientName ?? 'Client Statement',
        showBackButton: true,
        onBackPressed: () => context.pop(),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              // TODO: Implement print functionality
            },
            tooltip: 'Print',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // TODO: Implement export functionality
            },
            tooltip: 'Export',
          ),
        ],
      ),
      body: SafeArea(
        child: statementAsync.when(
          data: (statement) => _buildStatementContent(context, statement, isMobile, isSmallMobile),
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(error.toString()),
        ),
      ),
    );
  }

  Widget _buildStatementContent(
    BuildContext context,
    ClientStatementData statement,
    bool isMobile,
    bool isSmallMobile,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallMobile ? 12 : (isMobile ? 16 : 24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Range Selector
          _buildDateRangeSelector(isMobile, isSmallMobile),
          const SizedBox(height: 24),

          // Summary Cards
          _buildSummaryCards(statement, isMobile, isSmallMobile),
          const SizedBox(height: 24),

          // Jobs Table/List
          _buildSectionHeader('Job Details'),
          const SizedBox(height: 16),
          if (statement.jobs.isEmpty)
            _buildEmptyState()
          else if (isMobile)
            _buildJobsList(statement.jobs, isSmallMobile)
          else
            _buildJobsTable(statement.jobs),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector(bool isMobile, bool isSmallMobile) {
    return Container(
      padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
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
                  'Start Date',
                  style: TextStyle(
                    fontSize: isSmallMobile ? 12 : 14,
                    color: ChoiceLuxTheme.platinumSilver,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectStartDate,
                  child: Container(
                    padding: EdgeInsets.all(isSmallMobile ? 10 : 12),
                    decoration: BoxDecoration(
                      color: ChoiceLuxTheme.jetBlack,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: isSmallMobile ? 16 : 18,
                          color: ChoiceLuxTheme.richGold,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _dateFormat.format(_startDate),
                          style: TextStyle(
                            fontSize: isSmallMobile ? 13 : 14,
                            color: ChoiceLuxTheme.softWhite,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'End Date',
                  style: TextStyle(
                    fontSize: isSmallMobile ? 12 : 14,
                    color: ChoiceLuxTheme.platinumSilver,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectEndDate,
                  child: Container(
                    padding: EdgeInsets.all(isSmallMobile ? 10 : 12),
                    decoration: BoxDecoration(
                      color: ChoiceLuxTheme.jetBlack,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: isSmallMobile ? 16 : 18,
                          color: ChoiceLuxTheme.richGold,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _dateFormat.format(_endDate),
                          style: TextStyle(
                            fontSize: isSmallMobile ? 13 : 14,
                            color: ChoiceLuxTheme.softWhite,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(ClientStatementData statement, bool isMobile, bool isSmallMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isLargeDesktop = ResponsiveBreakpoints.isLargeDesktop(screenWidth);
        final crossAxisCount = isLargeDesktop ? 4 : 2;
        final spacing = ResponsiveTokens.getSpacing(screenWidth);
        final childAspectRatio = isSmallMobile ? 1.4 : (isMobile ? 1.6 : 1.8);

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          children: [
            _buildSummaryCard(
              'Total Revenue',
              'R${statement.totalRevenue.toStringAsFixed(2)}',
              Icons.attach_money,
              Colors.green,
            ),
            _buildSummaryCard(
              'Total Jobs',
              statement.totalJobs.toString(),
              Icons.work,
              Colors.blue,
            ),
            _buildSummaryCard(
              'Outstanding',
              'R${statement.outstandingAmount.toStringAsFixed(2)}',
              Icons.warning,
              Colors.orange,
            ),
            _buildSummaryCard(
              'Collected',
              'R${statement.collectedAmount.toStringAsFixed(2)}',
              Icons.check_circle,
              Colors.green,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ChoiceLuxTheme.softWhite,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: ChoiceLuxTheme.platinumSilver,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: ChoiceLuxTheme.softWhite,
      ),
    );
  }

  Widget _buildJobsTable(List<ClientStatementJob> jobs) {
    return Container(
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(
            ChoiceLuxTheme.jetBlack.withOpacity(0.5),
          ),
          dataRowMinHeight: 48,
          dataRowMaxHeight: 72,
          columns: const [
            DataColumn(label: Text('Job #', style: TextStyle(color: ChoiceLuxTheme.softWhite))),
            DataColumn(label: Text('Date', style: TextStyle(color: ChoiceLuxTheme.softWhite))),
            DataColumn(label: Text('Pickup → Dropoff', style: TextStyle(color: ChoiceLuxTheme.softWhite))),
            DataColumn(label: Text('Vehicle', style: TextStyle(color: ChoiceLuxTheme.softWhite))),
            DataColumn(label: Text('Status', style: TextStyle(color: ChoiceLuxTheme.softWhite))),
            DataColumn(label: Text('Amount', style: TextStyle(color: ChoiceLuxTheme.softWhite))),
            DataColumn(label: Text('Payment', style: TextStyle(color: ChoiceLuxTheme.softWhite))),
          ],
          rows: jobs.map((job) {
            return DataRow(
              cells: [
                DataCell(Text(
                  job.jobNumber ?? job.jobId,
                  style: const TextStyle(color: ChoiceLuxTheme.softWhite),
                )),
                DataCell(Text(
                  _dateFormat.format(job.jobDate),
                  style: const TextStyle(color: ChoiceLuxTheme.softWhite),
                )),
                DataCell(Text(
                  '${job.pickupLocation} → ${job.dropoffLocation}',
                  style: const TextStyle(color: ChoiceLuxTheme.softWhite),
                )),
                DataCell(Text(
                  job.vehicleRegPlate ?? '${job.vehicleMake ?? ''} ${job.vehicleModel ?? ''}'.trim(),
                  style: const TextStyle(color: ChoiceLuxTheme.softWhite),
                )),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(job.jobStatus).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    job.jobStatus.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(job.jobStatus),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )),
                DataCell(Text(
                  'R${job.amount.toStringAsFixed(2)}',
                  style: const TextStyle(color: ChoiceLuxTheme.softWhite),
                )),
                DataCell(Icon(
                  job.paymentCollected ? Icons.check_circle : Icons.pending,
                  color: job.paymentCollected ? Colors.green : Colors.orange,
                  size: 20,
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildJobsList(List<ClientStatementJob> jobs, bool isSmallMobile) {
    return Column(
      children: jobs.map((job) => _buildJobCard(job, isSmallMobile)).toList(),
    );
  }

  Widget _buildJobCard(ClientStatementJob job, bool isSmallMobile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Job #${job.jobNumber ?? job.jobId}',
                style: TextStyle(
                  fontSize: isSmallMobile ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: ChoiceLuxTheme.softWhite,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(job.jobStatus).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  job.jobStatus.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(job.jobStatus),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _dateFormat.format(job.jobDate),
            style: TextStyle(
              fontSize: isSmallMobile ? 12 : 13,
              color: ChoiceLuxTheme.platinumSilver,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: ChoiceLuxTheme.richGold),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${job.pickupLocation} → ${job.dropoffLocation}',
                  style: TextStyle(
                    fontSize: isSmallMobile ? 12 : 13,
                    color: ChoiceLuxTheme.softWhite,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (job.vehicleRegPlate != null || job.vehicleMake != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.directions_car, size: 16, color: ChoiceLuxTheme.richGold),
                const SizedBox(width: 4),
                Text(
                  job.vehicleRegPlate ?? '${job.vehicleMake ?? ''} ${job.vehicleModel ?? ''}'.trim(),
                  style: TextStyle(
                    fontSize: isSmallMobile ? 12 : 13,
                    color: ChoiceLuxTheme.softWhite,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'R${job.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: isSmallMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: ChoiceLuxTheme.richGold,
                ),
              ),
              Row(
                children: [
                  Icon(
                    job.paymentCollected ? Icons.check_circle : Icons.pending,
                    color: job.paymentCollected ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    job.paymentCollected ? 'Paid' : 'Pending',
                    style: TextStyle(
                      fontSize: isSmallMobile ? 12 : 13,
                      color: job.paymentCollected ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
      case 'in progress':
        return Colors.blue;
      case 'assigned':
        return Colors.orange;
      case 'open':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return ChoiceLuxTheme.platinumSilver;
    }
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: ChoiceLuxTheme.platinumSilver.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No jobs found for this period',
              style: TextStyle(
                fontSize: 16,
                color: ChoiceLuxTheme.platinumSilver,
              ),
            ),
          ],
        ),
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
            'Loading statement...',
            style: TextStyle(color: ChoiceLuxTheme.softWhite),
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
            'Failed to load statement',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ChoiceLuxTheme.softWhite,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: ChoiceLuxTheme.platinumSilver,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

