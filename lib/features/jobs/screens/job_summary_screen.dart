import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/jobs/models/job.dart';
import 'package:choice_lux_cars/features/jobs/models/trip.dart';
import 'package:choice_lux_cars/features/jobs/providers/jobs_provider.dart';
import 'package:choice_lux_cars/features/clients/providers/clients_provider.dart';
import 'package:choice_lux_cars/features/vehicles/providers/vehicles_provider.dart';
import 'package:choice_lux_cars/features/users/providers/users_provider.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/features/jobs/widgets/trip_edit_modal.dart';

class JobSummaryScreen extends ConsumerStatefulWidget {
  final String jobId;
  
  const JobSummaryScreen({
    super.key,
    required this.jobId,
  });

  @override
  ConsumerState<JobSummaryScreen> createState() => _JobSummaryScreenState();
}

class _JobSummaryScreenState extends ConsumerState<JobSummaryScreen> {
  bool _isLoading = true;
  Job? _job;
  List<Trip> _trips = [];
  dynamic _client;
  dynamic _agent;
  dynamic _vehicle;
  dynamic _driver;
  
  // Mobile accordion state
  final Map<String, bool> _expandedSections = {
    'jobDetails': true,
    'clientAgent': true,
    'vehicleDriver': true,
    'payment': true,
    'trips': true,
  };
  
  @override
  void initState() {
    super.initState();
    _loadJobData();
  }
  
  Future<void> _loadJobData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load job and trips
      final jobs = ref.read(jobsProvider);
      _job = jobs.firstWhere((job) => job.id == widget.jobId);
      
      // Try to load trips, but don't fail if trips table doesn't exist
      try {
        await ref.read(tripsProvider.notifier).fetchTripsForJob(widget.jobId);
        _trips = ref.read(tripsProvider);
      } catch (e) {
        // If trips table doesn't exist, just continue with empty trips list
        print('Warning: Could not load trips: $e');
        _trips = [];
      }
      
      // Ensure all providers have loaded data
      await _ensureDataLoaded();
      
      // Get related entities
      final vehiclesState = ref.read(vehiclesProvider);
      final users = ref.read(usersProvider);
      final clients = await ref.read(clientsProvider.future);
      final vehicles = vehiclesState.vehicles;
      
      // Debug information
      print('Job Vehicle ID: ${_job!.vehicleId}');
      print('Job Driver ID: ${_job!.driverId}');
      print('Available vehicles: ${vehicles.length}');
      print('Available users: ${users.length}');
      print('Available clients: ${clients.length}');
      
      if (vehicles.isNotEmpty) {
        print('Vehicle IDs: ${vehicles.map((v) => v.id).toList()}');
      }
      if (users.isNotEmpty) {
        print('User IDs: ${users.map((u) => u.id).toList()}');
      }
      
      // Find client
      try {
        _client = clients.firstWhere((c) => c.id.toString() == _job!.clientId);
      } catch (e) {
        print('Client not found for ID: ${_job!.clientId}');
        _client = null;
      }
      
      // Find vehicle
      try {
        _vehicle = vehicles.firstWhere((v) => v.id.toString() == _job!.vehicleId);
      } catch (e) {
        print('Vehicle not found for ID: ${_job!.vehicleId}');
        _vehicle = null;
      }
      
      // Find driver
      try {
        _driver = users.firstWhere((u) => u.id == _job!.driverId);
      } catch (e) {
        print('Driver not found for ID: ${_job!.driverId}');
        _driver = null;
      }
      
      // Note: Agent lookup would need to be implemented separately
      // For now, we'll leave _agent as null
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading job data: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _ensureDataLoaded() async {
    // Ensure vehicles are loaded
    final vehiclesState = ref.read(vehiclesProvider);
    if (vehiclesState.vehicles.isEmpty) {
      print('Vehicles not loaded, fetching...');
      await ref.read(vehiclesProvider.notifier).fetchVehicles();
    }
    
    // Ensure users are loaded
    final users = ref.read(usersProvider);
    if (users.isEmpty) {
      print('Users not loaded, fetching...');
      await ref.read(usersProvider.notifier).fetchUsers();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_job == null) {
      return Scaffold(
        appBar: LuxuryAppBar(
          title: 'Job Summary',
          showBackButton: true,
          onBackPressed: () => context.go('/jobs'),
        ),
        body: const Center(
          child: Text('Job not found'),
        ),
      );
    }
    
    final totalAmount = _trips.fold(0.0, (sum, trip) => sum + trip.amount);
    final isDesktop = MediaQuery.of(context).size.width > 768;
    
    return Scaffold(
      appBar: LuxuryAppBar(
        title: 'Job Summary',
        subtitle: 'Job #${_job!.id}',
        showBackButton: true,
        onBackPressed: () => context.go('/jobs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printJobSummary(),
            tooltip: 'Print Summary',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareJobSummary(),
            tooltip: 'Share Summary',
          ),
        ],
      ),
      body: isDesktop ? _buildDesktopLayout(totalAmount) : _buildMobileLayout(totalAmount),
      floatingActionButton: isDesktop ? null : FloatingActionButton.extended(
        onPressed: () => context.go('/jobs/${widget.jobId}/edit'),
        icon: const Icon(Icons.edit),
        label: const Text('Edit Job'),
        backgroundColor: ChoiceLuxTheme.richGold,
        foregroundColor: Colors.white,
      ),
    );
  }
  
  Widget _buildDesktopLayout(double totalAmount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column - Job Details, Client & Agent, Vehicle & Driver
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildStatusCard(),
                const SizedBox(height: 24),
                _buildJobDetailsCard(),
                const SizedBox(height: 24),
                _buildClientAgentCard(),
                const SizedBox(height: 24),
                _buildVehicleDriverCard(),
                const SizedBox(height: 24),
                _buildPaymentCard(),
                if (_job!.notes != null && _job!.notes!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildNotesCard(),
                ],
              ],
            ),
          ),
        ),
        
        // Right Column - Trips Summary and Details
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildTripsSummaryCard(totalAmount),
                const SizedBox(height: 24),
                if (_trips.isNotEmpty) _buildTripsListCard(),
                const SizedBox(height: 32),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMobileLayout(double totalAmount) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildAccordionSection(
            'Job Details',
            'jobDetails',
            _buildJobDetailsContent(),
            Icons.work,
          ),
          const SizedBox(height: 16),
          _buildAccordionSection(
            'Client & Agent',
            'clientAgent',
            _buildClientAgentContent(),
            Icons.person,
          ),
          const SizedBox(height: 16),
          _buildAccordionSection(
            'Vehicle & Driver',
            'vehicleDriver',
            _buildVehicleDriverContent(),
            Icons.directions_car,
          ),
          const SizedBox(height: 16),
          _buildAccordionSection(
            'Payment',
            'payment',
            _buildPaymentContent(),
            Icons.payment,
          ),
          if (_job!.notes != null && _job!.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildAccordionSection(
              'Notes',
              'notes',
              _buildNotesContent(),
              Icons.note,
            ),
          ],
          const SizedBox(height: 16),
          _buildAccordionSection(
            'Trips Summary',
            'trips',
            _buildTripsContent(totalAmount),
            Icons.route,
          ),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }
  
  Widget _buildAccordionSection(String title, String key, Widget content, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        key: Key(key),
        initiallyExpanded: _expandedSections[key] ?? true,
        onExpansionChanged: (expanded) {
          setState(() {
            _expandedSections[key] = expanded;
          });
        },
        leading: Icon(icon, color: ChoiceLuxTheme.richGold),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: content,
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getStatusColor().withOpacity(0.1),
              _getStatusColor().withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _getStatusColor().withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.work,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStatusText(_job!.status),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(),
                    ),
                  ),
                  Text(
                    'Job #${_job!.id}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getStatusColor(),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _getStatusColor().withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                _job!.daysUntilStartText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildJobDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Job Details', Icons.work),
            const SizedBox(height: 16),
            _buildJobDetailsContent(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildJobDetailsContent() {
    return Column(
      children: [
        _buildDetailRow('Job ID', _job!.id, Icons.tag),
        _buildDetailRow('Status', _getStatusText(_job!.status), Icons.info),
        _buildDetailRow('Job Start Date', _formatDate(_job!.jobStartDate), Icons.calendar_today),
        _buildDetailRow('Order Date', _formatDate(_job!.orderDate), Icons.schedule),
        _buildDetailRow('Days Until Start', _job!.daysUntilStartText, Icons.timer),
      ],
    );
  }
  
  Widget _buildClientAgentCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Client & Agent', Icons.person),
            const SizedBox(height: 16),
            _buildClientAgentContent(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildClientAgentContent() {
    return Column(
      children: [
        _buildDetailRow('Client', _client?.companyName ?? 'Unknown', Icons.business),
        if (_agent != null)
          _buildDetailRow('Agent', _agent.agentName, Icons.person_outline),
        _buildDetailRow('Passenger Name', _job!.passengerName ?? 'Not provided', Icons.person),
        _buildDetailRow('Contact Number', _job!.passengerContact ?? 'Not provided', Icons.phone),
        if (!_job!.hasCompletePassengerDetails)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ChoiceLuxTheme.errorColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: ChoiceLuxTheme.errorColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Passenger details incomplete',
                    style: TextStyle(
                      color: ChoiceLuxTheme.errorColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  Widget _buildVehicleDriverCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Vehicle & Driver', Icons.directions_car),
            const SizedBox(height: 16),
            _buildVehicleDriverContent(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVehicleDriverContent() {
    return Column(
      children: [
        _buildDetailRow('Vehicle', '${_vehicle?.make} ${_vehicle?.model}', Icons.directions_car),
        _buildDetailRow('Registration', _vehicle?.regPlate ?? 'Unknown', Icons.confirmation_number),
        _buildDetailRow('Driver', _driver?.displayName ?? 'Unknown', Icons.person),
        _buildDetailRow('Passengers', _formatPassengerCount(_job!.pasCount), Icons.people),
        _buildDetailRow('Luggage', _formatLuggageCount(_job!.luggageCount), Icons.work),
      ],
    );
  }
  
  Widget _buildPaymentCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Payment', Icons.payment),
            const SizedBox(height: 16),
            _buildPaymentContent(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPaymentContent() {
    return Column(
      children: [
        _buildDetailRow('Collect Payment', _job!.collectPayment ? 'Yes' : 'No', Icons.payment),
        if (_job!.collectPayment && _job!.paymentAmount != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.richGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ChoiceLuxTheme.richGold.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.attach_money, color: ChoiceLuxTheme.richGold, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Amount to Collect: R${_job!.paymentAmount!.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: ChoiceLuxTheme.richGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  Widget _buildNotesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Notes', Icons.note),
            const SizedBox(height: 16),
            _buildNotesContent(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNotesContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Text(
        _job!.notes!,
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }
  
  Widget _buildTripsSummaryCard(double totalAmount) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Trips Summary', Icons.route),
            const SizedBox(height: 16),
            _buildTripsContent(totalAmount),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTripsContent(double totalAmount) {
    return Column(
      children: [
        _buildDetailRow('Total Trips', '${_trips.length}', Icons.route),
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ChoiceLuxTheme.richGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ChoiceLuxTheme.richGold.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.attach_money, color: ChoiceLuxTheme.richGold, size: 24),
              const SizedBox(width: 12),
              Text(
                'Total Amount: R${totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: ChoiceLuxTheme.richGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildTripsListCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Trip Details', Icons.list),
            const SizedBox(height: 16),
            ..._trips.asMap().entries.map((entry) {
              final index = entry.key;
              final trip = entry.value;
              return _buildTripCard(trip, index);
            }).toList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTripCard(Trip trip, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ChoiceLuxTheme.richGold,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Trip ${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ChoiceLuxTheme.richGold.withOpacity(0.3)),
                  ),
                  child: Text(
                    'R${trip.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: ChoiceLuxTheme.richGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _showTripEditModal(trip),
                  tooltip: 'Edit Trip',
                  style: IconButton.styleFrom(
                    backgroundColor: ChoiceLuxTheme.richGold.withOpacity(0.1),
                    foregroundColor: ChoiceLuxTheme.richGold,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Date & Time', trip.formattedDateTime, Icons.access_time),
            _buildDetailRow('Pick-up', trip.pickupLocation, Icons.location_on),
            _buildDetailRow('Drop-off', trip.dropoffLocation, Icons.location_off),
            if (trip.notes != null && trip.notes!.isNotEmpty)
              _buildDetailRow('Notes', trip.notes!, Icons.note),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.go('/jobs'),
            icon: const Icon(Icons.list),
            label: const Text('Back to Jobs'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.go('/jobs/${widget.jobId}/edit'),
            icon: const Icon(Icons.edit),
            label: const Text('Edit Job'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ChoiceLuxTheme.richGold,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: ChoiceLuxTheme.richGold, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ChoiceLuxTheme.richGold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getStatusColor() {
    switch (_job!.status) {
      case 'open':
        return ChoiceLuxTheme.richGold;
      case 'in_progress':
        return Colors.blue;
      case 'closed':
        return Colors.grey;
      default:
        return ChoiceLuxTheme.platinumSilver;
    }
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'open':
        return 'OPEN';
      case 'in_progress':
        return 'IN PROGRESS';
      case 'closed':
        return 'CLOSED';
      default:
        return status.toUpperCase();
    }
  }
  
  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }
  
  String _formatPassengerCount(dynamic count) {
    final intCount = int.tryParse(count.toString()) ?? 0;
    return '$intCount Passenger${intCount == 1 ? '' : 's'}';
  }
  
  String _formatLuggageCount(dynamic count) {
    final intCount = int.tryParse(count.toString()) ?? 0;
    return '$intCount Bag${intCount == 1 ? '' : 's'}';
  }
  
  void _printJobSummary() {
    // TODO: Implement print functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Print functionality coming soon')),
    );
  }
  
  void _shareJobSummary() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }

  void _showTripEditModal(Trip trip) {
    showDialog(
      context: context,
      builder: (context) => TripEditModal(
        trip: trip,
        onTripUpdated: (updatedTrip) {
          // Refresh the trips list
          _loadJobData();
        },
      ),
    );
  }
} 