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
import 'package:choice_lux_cars/shared/widgets/simple_app_bar.dart';

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
      
      // Get related entities
      final vehiclesState = ref.read(vehiclesProvider);
      final users = ref.read(usersProvider);
      
      // Get clients using the FutureProvider
      final clients = await ref.read(clientsProvider.future);
      final vehicles = vehiclesState.vehicles;
      
      _client = clients.firstWhere((c) => c.id.toString() == _job!.clientId);
      _vehicle = vehicles.firstWhere((v) => v.id.toString() == _job!.vehicleId);
      _driver = users.firstWhere((u) => u.id == _job!.driverId);
      
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
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_job == null) {
      return Scaffold(
        appBar: SimpleAppBar(
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
    
    return Scaffold(
      appBar: SimpleAppBar(
        title: 'Job Summary',
        subtitle: 'Job #${_job!.id}',
        showBackButton: true,
        onBackPressed: () => context.go('/jobs'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job Status Card
            _buildStatusCard(),
            const SizedBox(height: 24),
            
            // Job Details
            _buildSection('Job Details', [
              _buildDetailRow('Job ID', _job!.id),
              _buildDetailRow('Status', _getStatusText(_job!.status)),
              _buildDetailRow('Job Start Date', _formatDate(_job!.jobStartDate)),
              _buildDetailRow('Order Date', _formatDate(_job!.orderDate)),
              _buildDetailRow('Days Until Start', _job!.daysUntilStartText),
            ]),
            
            const SizedBox(height: 24),
            
            // Client & Agent Information
            _buildSection('Client & Agent', [
              _buildDetailRow('Client', _client?.companyName ?? 'Unknown'),
              if (_agent != null)
                _buildDetailRow('Agent', _agent.agentName),
              _buildDetailRow('Passenger Name', _job!.passengerName ?? 'Not provided'),
              _buildDetailRow('Contact Number', _job!.passengerContact ?? 'Not provided'),
              if (!_job!.hasCompletePassengerDetails)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ChoiceLuxTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ChoiceLuxTheme.errorColor),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: ChoiceLuxTheme.errorColor),
                      SizedBox(width: 8),
                      Text(
                        'Passenger details incomplete',
                        style: TextStyle(
                          color: ChoiceLuxTheme.errorColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ]),
            
            const SizedBox(height: 24),
            
            // Vehicle & Driver Information
            _buildSection('Vehicle & Driver', [
              _buildDetailRow('Vehicle', '${_vehicle?.make} ${_vehicle?.model}'),
              _buildDetailRow('Registration', _vehicle?.regPlate ?? 'Unknown'),
              _buildDetailRow('Driver', _driver?.displayName ?? 'Unknown'),
              _buildDetailRow('Passengers', '${_job!.pasCount} pax'),
              _buildDetailRow('Luggage', '${_job!.luggageCount} bag${_job!.luggageCount == '1' ? '' : 's'}'),
            ]),
            
            const SizedBox(height: 24),
            
            // Payment Information
            _buildSection('Payment', [
              _buildDetailRow('Collect Payment', _job!.collectPayment ? 'Yes' : 'No'),
              if (_job!.collectPayment && _job!.paymentAmount != null)
                _buildDetailRow('Amount to Collect', 'R${_job!.paymentAmount!.toStringAsFixed(2)}'),
            ]),
            
            const SizedBox(height: 24),
            
            // Notes
            if (_job!.notes != null && _job!.notes!.isNotEmpty)
              _buildSection('Notes', [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_job!.notes!),
                ),
              ]),
            
            const SizedBox(height: 24),
            
            // Trips Summary
            _buildSection('Trips Summary', [
              _buildDetailRow('Total Trips', '${_trips.length}'),
              _buildDetailRow('Total Amount', 'R${totalAmount.toStringAsFixed(2)}'),
            ]),
            
            const SizedBox(height: 24),
            
            // Trips List
            if (_trips.isNotEmpty) ...[
              Text(
                'Trip Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ChoiceLuxTheme.richGold,
                ),
              ),
              const SizedBox(height: 16),
              ..._trips.asMap().entries.map((entry) {
                final index = entry.key;
                final trip = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: ChoiceLuxTheme.richGold,
                                borderRadius: BorderRadius.circular(12),
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
                            Text(
                              'R${trip.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: ChoiceLuxTheme.richGold,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow('Date & Time', trip.formattedDateTime),
                        _buildDetailRow('Pick-up', trip.pickupLocation),
                        _buildDetailRow('Drop-off', trip.dropoffLocation),
                        if (trip.notes != null && trip.notes!.isNotEmpty)
                          _buildDetailRow('Notes', trip.notes!),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
            
            const SizedBox(height: 32),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor()),
      ),
      child: Row(
        children: [
          Icon(
            Icons.work,
            color: _getStatusColor(),
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusText(_job!.status),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(),
                  ),
                ),
                                 Text(
                   'Job #${_job!.id}',
                   style: const TextStyle(
                     fontSize: 14,
                     color: Colors.grey,
                   ),
                 ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(),
              borderRadius: BorderRadius.circular(16),
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
    );
  }
  
  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ChoiceLuxTheme.richGold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
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
    return '${date.day}/${date.month}/${date.year}';
  }
} 