import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/utils/snackbar_utils.dart';
import 'package:choice_lux_cars/features/jobs/providers/jobs_provider.dart';
import 'package:choice_lux_cars/features/jobs/providers/trips_provider.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/core/services/supabase_service.dart';
import 'package:choice_lux_cars/features/jobs/models/job.dart';
import 'package:choice_lux_cars/features/jobs/models/trip.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';
import 'package:choice_lux_cars/shared/utils/driver_flow_utils.dart';
import 'package:choice_lux_cars/features/jobs/services/driver_flow_api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/features/jobs/widgets/add_trip_modal.dart';
import 'package:choice_lux_cars/features/jobs/widgets/trip_edit_modal.dart';
import 'package:choice_lux_cars/features/clients/data/clients_repository.dart';
import 'package:choice_lux_cars/features/vehicles/data/vehicles_repository.dart';
import 'package:choice_lux_cars/features/users/data/users_repository.dart';
import 'package:choice_lux_cars/features/jobs/data/jobs_repository.dart';
import 'package:choice_lux_cars/shared/widgets/system_safe_scaffold.dart';

extension StringExtension on String {
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

class JobSummaryScreen extends ConsumerStatefulWidget {
  final String jobId;

  const JobSummaryScreen({super.key, required this.jobId});

  @override
  ConsumerState<JobSummaryScreen> createState() => _JobSummaryScreenState();
}

class _JobSummaryScreenState extends ConsumerState<JobSummaryScreen> {
  bool _isLoading = true;
  bool _isConfirming = false; // Prevent duplicate confirmation calls
  String? _errorMessage;
  Job? _job;
  List<Trip> _trips = []; // Changed from List<Trip> to List<dynamic>
  dynamic _client;
  dynamic _agent;
  dynamic _vehicle;
  dynamic _driver;

  // Step completion times
  Map<String, dynamic>? _driverFlowData;
  List<Map<String, dynamic>> _tripProgressData = [];
  
  // Trip timeline state
  int _selectedTripIndex = 0;

  // Mobile accordion state
  final Map<String, bool> _expandedSections = {
    'jobDetails': true,
    'clientAgent': true,
    'vehicleDriver': true,
    'payment': true,
    'trips': true,
    'stepTimeline': true, // New section for step timeline
  };

  @override
  void initState() {
    super.initState();
    _loadJobData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh step data when dependencies change (e.g., returning from job progress)
    _loadStepCompletionData();
    
    // Refresh trips when screen is focused/opened
    _refreshTrips();
  }
  
  Future<void> _refreshTrips() async {
    try {
      final tripsNotifier = ref.read(tripsByJobProvider(widget.jobId).notifier);
      await tripsNotifier.refresh();
      Log.d('Trips refreshed on screen focus');
    } catch (e) {
      Log.e('Error refreshing trips on screen focus: $e');
    }
  }

  Future<void> _loadJobData() async {
    setState(() => _isLoading = true);

    try {
      // Try to find job in local state first
      final jobsState = ref.read(jobsProvider);
      Job? job;

      if (jobsState.hasValue) {
        try {
          job = jobsState.value!.firstWhere((job) => job.id == widget.jobId);
          Log.d('Found job ${widget.jobId} in local state');
        } catch (e) {
          Log.d('Job ${widget.jobId} not found in local state');
        }
      }

      if (job == null) {
        Log.d(
          'Job ${widget.jobId} not found in local state, fetching from database...',
        );
        // If not found locally, fetch from database
        final fetchedJob = await ref
            .read(jobsProvider.notifier)
            .fetchJobById(widget.jobId);
        if (fetchedJob != null) {
          job = fetchedJob;
          Log.d('Successfully fetched job ${widget.jobId} from database');
        } else {
          Log.d('Job ${widget.jobId} not found in database');
          _errorMessage = 'Job not found';
          setState(() => _isLoading = false);
          return;
        }
      }

      _job = job;

      // Initialize trips provider for this job
      Log.d('Initializing trips provider for job ${widget.jobId}...');
      try {
        // This will trigger the provider to load trips for this job
        final tripsState = ref.read(tripsByJobProvider(widget.jobId));
        Log.d('Trips provider initialized');
        Log.d('Trips state: ${tripsState.toString()}');
        Log.d('Trips state hasValue: ${tripsState.hasValue}');
        Log.d('Trips state isLoading: ${tripsState.isLoading}');
        Log.d('Trips state hasError: ${tripsState.hasError}');
        
        if (tripsState.hasValue) {
          _trips = tripsState.value!;
          Log.d('Loaded ${_trips.length} trips for job ${widget.jobId}');
          Log.d('Trip details: ${_trips.map((t) => 'ID: ${t.id}, JobID: ${t.jobId}').join(', ')}');
        } else {
          _trips = [];
          Log.d('No trips found for job ${widget.jobId}');
        }
      } catch (e) {
        Log.e('Error initializing trips provider: $e');
        _trips = [];
      }

      // Load step completion times
      await _loadStepCompletionData();

      // Load related entities from database directly
      await _loadRelatedEntities();
    } catch (e) {
      Log.e('Error loading job data: $e');
      // Store error to show in build method
      _errorMessage = 'Error loading job data: $e';
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRelatedEntities() async {
    try {
      // Load client data
      if (_job!.clientId.isNotEmpty) {
        final clientResult = await ref.read(clientsRepositoryProvider).fetchClientById(_job!.clientId);
        if (clientResult.isSuccess && clientResult.data != null) {
          _client = clientResult.data!.toJson();
        }
      }

      // Load vehicle data
      if (_job!.vehicleId.isNotEmpty) {
        final vehicleResult = await ref.read(vehiclesRepositoryProvider).fetchVehicleById(_job!.vehicleId);
        if (vehicleResult.isSuccess && vehicleResult.data != null) {
          _vehicle = vehicleResult.data!.toJson();
        }
      }

      // Load driver data
      if (_job!.driverId.isNotEmpty) {
        final driverResult = await ref.read(usersRepositoryProvider).getUserProfile(_job!.driverId);
        if (driverResult.isSuccess && driverResult.data != null) {
          _driver = driverResult.data!.toJson();
        }
      }

      Log.d('Loaded related entities:');
      Log.d('Client: ${_client != null ? 'Found' : 'Not found'}');
      Log.d('Vehicle: ${_vehicle != null ? 'Found' : 'Not found'}');
      Log.d('Driver: ${_driver != null ? 'Found' : 'Not found'}');
    } catch (e) {
      Log.e('Error loading related entities: $e');
      // Don't fail the entire load if this fails
    }
  }

  Future<void> _loadStepCompletionData() async {
    try {
      // Load driver flow data
      final driverFlowResult = await ref.read(jobsRepositoryProvider).getDriverFlowData(widget.jobId);
      if (driverFlowResult.isSuccess) {
        _driverFlowData = driverFlowResult.data;
      }

      // Load trip progress data using the service
      final tripProgressResponse = await DriverFlowApiService.getTripProgress(
        int.parse(widget.jobId),
      );

      _tripProgressData = List<Map<String, dynamic>>.from(tripProgressResponse);

      Log.d('Loaded step completion data:');
      Log.d('Driver flow: $_driverFlowData');
      Log.d('Trip progress: $_tripProgressData');
      
      // Debug odometer data specifically
      if (_driverFlowData != null) {
        Log.d('=== ODOMETER DEBUG ===');
        Log.d('odo_start_reading: ${_driverFlowData!['odo_start_reading']}');
        Log.d('job_closed_odo: ${_driverFlowData!['job_closed_odo']}');
        Log.d('Start reading type: ${_driverFlowData!['odo_start_reading'].runtimeType}');
        Log.d('End reading type: ${_driverFlowData!['job_closed_odo'].runtimeType}');
        Log.d('=====================');
      }
    } catch (e) {
      Log.e('Error loading step completion data: $e');
      // Don't fail the entire load if this fails
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch jobs provider to automatically update when job data changes
    final jobsState = ref.watch(jobsProvider);
    
    // Update local job data when jobs provider changes
    if (jobsState.hasValue && jobsState.value != null) {
      try {
        final updatedJob = jobsState.value!.firstWhere((job) => job.id.toString() == widget.jobId);
        if (updatedJob != _job) {
          _job = updatedJob;
          Log.d('Job data updated from jobs provider: ${_job?.driverConfirmation}');
        }
      } catch (e) {
        Log.d('Job ${widget.jobId} not found in jobs provider state');
      }
    }
    
    // Watch trips data to automatically update when trips change
    final tripsState = ref.watch(tripsByJobProvider(widget.jobId));
    
    // Update local trips list when trips data changes
    if (tripsState.hasValue && tripsState.value != null) {
      _trips = tripsState.value!;
    }
    
    if (_isLoading) {
      return const SystemSafeScaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return SystemSafeScaffold(
        appBar: LuxuryAppBar(
          title: 'Job Summary',
          showBackButton: true,
          onBackPressed: () => context.go('/jobs'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _loadJobData();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_job == null) {
      return SystemSafeScaffold(
        appBar: LuxuryAppBar(
          title: 'Job Summary',
          showBackButton: true,
          onBackPressed: () => context.go('/jobs'),
        ),
        body: const Center(child: Text('Job not found')),
      );
    }

    // Calculate total amount from trips
    final totalAmount = _trips.fold(0.0, (sum, trip) => sum + trip.amount);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = ResponsiveBreakpoints.isDesktop(screenWidth) || ResponsiveBreakpoints.isLargeDesktop(screenWidth);

    return Stack(
      children: [
        // Layer 1: The background that fills the entire screen (solid obsidian)
        Container(
          color: ChoiceLuxTheme.jetBlack,
        ),
        // Layer 2: The Scaffold with a transparent background
        SystemSafeScaffold(
          backgroundColor: Colors.transparent, // CRITICAL
          appBar: LuxuryAppBar(
            title: 'Job Summary',
            showBackButton: true,
            onBackPressed: () => context.go('/jobs'),
          ),
          body: isDesktop
              ? _buildDesktopLayout(totalAmount)
              : _buildMobileLayout(totalAmount),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(double totalAmount) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = ResponsiveTokens.getPadding(screenWidth);
    final spacing = ResponsiveTokens.getSpacing(screenWidth);
    
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column - Job Details, Client & Agent, Vehicle & Driver
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(padding * 1.5),
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
                const SizedBox(height: 24),
                _buildStepTimelineCard(),
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
            padding: EdgeInsets.all(padding * 1.5),
            child: Column(
              children: [
                _buildTripsSummaryCard(totalAmount),
                SizedBox(height: spacing * 2),
                if (_trips.isNotEmpty) _buildTripsListCard(),
                SizedBox(height: spacing * 2.5),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
          ],
        ),
      ),
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
          const SizedBox(height: 16),
          _buildAccordionSection(
            'Step Timeline',
            'stepTimeline',
            _buildStepTimelineContent(),
            Icons.timeline,
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
          if (_trips.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildAccordionSection(
              'Trip Details',
              'tripDetails',
              _buildTripsListContent(),
              Icons.list,
            ),
          ],
          const SizedBox(height: 24),
          _buildMobileActionButtons(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAccordionSection(
    String title,
    String key,
    Widget content,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        key: Key(key),
        initiallyExpanded: _expandedSections[key] ?? true,
        onExpansionChanged: (expanded) {
          setState(() {
            _expandedSections[key] = expanded;
          });
        },
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        backgroundColor: ChoiceLuxTheme.charcoalGray,
        collapsedBackgroundColor: ChoiceLuxTheme.charcoalGray,
        iconColor: ChoiceLuxTheme.richGold,
        collapsedIconColor: ChoiceLuxTheme.richGold,
        leading: Icon(icon, color: ChoiceLuxTheme.richGold),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
        padding: const EdgeInsets.all(20), // Reduced from 24
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getStatusColor().withValues(alpha:0.1),
              _getStatusColor().withValues(alpha:0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _getStatusColor().withValues(alpha:0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10), // Reduced from 12
              decoration: BoxDecoration(
                color: _getStatusColor(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.work, color: Colors.white, size: 24), // Reduced from 28
            ),
            const SizedBox(width: 12), // Reduced from 16
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStatusText(_job!.status),
                    style: TextStyle(
                      fontSize: 18, // Reduced from 22
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Reduced padding
              decoration: BoxDecoration(
                color: _getStatusColor(),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _getStatusColor().withValues(alpha:0.3),
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
                  fontSize: 11, // Slightly reduced font size
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobDetailsCard() {
    return Container(
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray,
        borderRadius: BorderRadius.circular(12),
      ),
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
        _buildDetailRow('Job ID', _job!.id.toString(), Icons.tag),
        _buildDetailRow('Status', _getStatusText(_job!.status), Icons.info),
        _buildDetailRow(
          'Job Start Date',
          _formatDate(_job!.jobStartDate),
          Icons.calendar_today,
        ),
        _buildDetailRow(
          'Order Date',
          _formatDate(_job!.orderDate),
          Icons.schedule,
        ),
        _buildDetailRow(
          'Days Until Start',
          _job!.daysUntilStartText,
          Icons.timer,
        ),
      ],
    );
  }

  Widget _buildClientAgentCard() {
    return Container(
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray,
        borderRadius: BorderRadius.circular(12),
      ),
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
        _buildDetailRow(
          'Client',
          _client?['company_name'] ?? 'Unknown',
          Icons.business,
        ),
        if (_agent != null)
          _buildDetailRow(
            'Agent',
            _agent['agent_name'] ?? 'Unknown',
            Icons.person_outline,
          ),
        _buildDetailRow(
          'Passenger Name',
          _job!.passengerName ?? 'Not provided',
          Icons.person,
        ),
        _buildDetailRow(
          'Contact Number',
          _job!.passengerContact ?? 'Not provided',
          Icons.phone,
        ),
        if (!_job!.hasCompletePassengerDetails)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.errorColor.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ChoiceLuxTheme.errorColor.withValues(alpha:0.3),
              ),
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
    return Container(
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray,
        borderRadius: BorderRadius.circular(12),
      ),
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
        _buildDetailRow(
          'Vehicle',
          '${_vehicle?['make'] ?? ''} ${_vehicle?['model'] ?? ''}'
                  .trim()
                  .isEmpty
              ? 'Unknown'
              : '${_vehicle?['make'] ?? ''} ${_vehicle?['model'] ?? ''}'.trim(),
          Icons.directions_car,
        ),
        _buildDetailRow(
          'Registration',
          _vehicle?['reg_plate'] ?? 'Unknown',
          Icons.confirmation_number,
        ),
        _buildDetailRow(
          'Driver',
          _driver?['display_name'] ?? 'Unknown',
          Icons.person,
        ),
        _buildDetailRow(
          'Passengers',
          _formatPassengerCount(_job!.pasCount),
          Icons.people,
        ),
        _buildDetailRow(
          'Luggage',
          _formatLuggageCount(_job!.luggageCount),
          Icons.work,
        ),
      ],
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray,
        borderRadius: BorderRadius.circular(12),
      ),
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
    // Get current user role
    final userProfile = ref.watch(currentUserProfileProvider);
    final userRole = userProfile?.role?.toLowerCase();
    final isDriver = userRole == 'driver';
    
    // Hide payment information from drivers
    if (isDriver) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Payment information not available',
            style: TextStyle(
              color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ),
      );
    }
    
    return Column(
      children: [
        _buildDetailRow(
          'Collect Payment',
          _job!.collectPayment ? 'Yes' : 'No',
          Icons.payment,
        ),
        if (_job!.collectPayment && _job!.paymentAmount != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.richGold.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ChoiceLuxTheme.richGold.withValues(alpha:0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.attach_money,
                  color: ChoiceLuxTheme.richGold,
                  size: 20,
                ),
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

  Widget _buildTripSelector() {
    if (_trips.isEmpty) return const SizedBox.shrink();
    
    // Get user role for hiding amounts
    final userProfile = ref.watch(currentUserProfileProvider);
    final isDriver = userProfile?.role?.toLowerCase() == 'driver';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade600),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Trip:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _trips.asMap().entries.map((entry) {
                final index = entry.key;
                final trip = entry.value;
                final isSelected = index == _selectedTripIndex;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTripIndex = index;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? ChoiceLuxTheme.richGold 
                            : Colors.grey.shade700,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected 
                              ? ChoiceLuxTheme.richGold 
                              : Colors.grey.shade500,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_car,
                            size: 16,
                            color: isSelected 
                                ? Colors.white 
                                : Colors.grey.shade300,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Trip ${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: isSelected 
                                  ? Colors.white 
                                  : Colors.grey.shade300,
                              fontSize: 12,
                            ),
                          ),
                          // Hide amount for drivers
                          if (!isDriver) ...[
                            const SizedBox(width: 4),
                            Text(
                              'R${trip.amount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isSelected 
                                    ? Colors.white 
                                    : ChoiceLuxTheme.richGold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTimelineCard() {
    return Container(
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader('Step Timeline', Icons.timeline),
                IconButton(
                  onPressed: () {
                    setState(() {
                      // Trigger a rebuild of the timeline
                    });
                  },
                  icon: Icon(
                    Icons.refresh,
                    color: ChoiceLuxTheme.richGold,
                  ),
                  tooltip: 'Refresh Timeline',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Trip Selector
            if (_trips.isNotEmpty) ...[
              _buildTripSelector(),
              const SizedBox(height: 16),
            ],
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _getStepTimeline(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha:0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red[600],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Error loading timeline: ${snapshot.error}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red[300],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final steps = snapshot.data ?? [];

                if (steps.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withValues(alpha:0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No steps have been completed yet. The timeline will show completed steps as the job progresses.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[300],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Progress Summary
                    if (_driverFlowData != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ChoiceLuxTheme.richGold.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: ChoiceLuxTheme.richGold.withValues(alpha:0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.analytics,
                                  color: ChoiceLuxTheme.richGold,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Overall Progress',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: ChoiceLuxTheme.richGold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Progress Bar
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Progress',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        '${_driverFlowData!['progress_percentage']?.toString() ?? '0'}%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: ChoiceLuxTheme.richGold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: (_driverFlowData!['progress_percentage'] ?? 0) / 100.0,
                                    backgroundColor: ChoiceLuxTheme.richGold.withValues(alpha:0.2),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      ChoiceLuxTheme.richGold,
                                    ),
                                    minHeight: 6,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMetricItem(
                                    'Status',
                                    _getCurrentStepDisplayName(_driverFlowData!['current_step'] ?? 'Not Started'),
                                    Icons.info_outline,
                                    ChoiceLuxTheme.infoColor,
                                  ),
                                ),
                                if (_driverFlowData!['odo_start_reading'] != null) ...[
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildMetricItem(
                                      'Start KM',
                                      '${_driverFlowData!['odo_start_reading'].toStringAsFixed(1)}',
                                      Icons.speed,
                                      Colors.green,
                                    ),
                                  ),
                                ],
                                if (_driverFlowData!['job_closed_odo'] != null) ...[
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildMetricItem(
                                      'End KM',
                                      '${_driverFlowData!['job_closed_odo'].toStringAsFixed(1)}',
                                      Icons.speed,
                                      Colors.orange,
                                    ),
                                  ),
                                ],
                                if (_driverFlowData!['odo_start_reading'] != null && 
                                    _driverFlowData!['job_closed_odo'] != null) ...[
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildMetricItem(
                                      'Total Distance',
                                      '${(_driverFlowData!['job_closed_odo'] - _driverFlowData!['odo_start_reading']).toStringAsFixed(1)} km',
                                      Icons.route,
                                      Colors.indigo,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            // Current Step Status
                            if (_driverFlowData!['current_step'] != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: ChoiceLuxTheme.infoColor.withValues(alpha:0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: ChoiceLuxTheme.infoColor.withValues(alpha:0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: ChoiceLuxTheme.infoColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Current Step: ${_getCurrentStepDisplayName(_driverFlowData!['current_step'])}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: ChoiceLuxTheme.infoColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Individual Steps
                    ...steps.map((step) => _buildStepTimelineItem(step)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTimelineItem(Map<String, dynamic> step) {
    final isTotal = step['isTotal'] == true;
    final status =
        step['status'] ??
        'completed'; // Default to completed for backward compatibility
    final isCompleted = status == 'completed';
    final isCurrent = status == 'current';
    final isUpcoming = status == 'upcoming';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isTotal
                  ? Colors.indigo.withValues(alpha:0.2)
                  : isCurrent
                  ? ChoiceLuxTheme.richGold.withValues(alpha:0.2)
                  : isCompleted
                  ? ChoiceLuxTheme.successColor.withValues(alpha:0.2)
                  : Colors.grey.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isTotal
                    ? Colors.indigo.withValues(alpha:0.5)
                    : isCurrent
                    ? ChoiceLuxTheme.richGold.withValues(alpha:0.5)
                    : isCompleted
                    ? ChoiceLuxTheme.successColor.withValues(alpha:0.5)
                    : Colors.grey.withValues(alpha:0.3),
                width: isTotal || isCurrent ? 2 : 1,
              ),
            ),
            child: Icon(
              step['icon'],
              color: isTotal
                  ? Colors.indigo
                  : isCurrent
                  ? ChoiceLuxTheme.richGold
                  : isCompleted
                  ? ChoiceLuxTheme.successColor
                  : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        step['title'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isTotal
                              ? FontWeight.w700
                              : FontWeight.bold,
                          color: isTotal
                              ? Colors.indigo
                              : isCurrent
                              ? ChoiceLuxTheme.richGold
                              : isCompleted
                              ? Colors.white
                              : Colors.grey,
                        ),
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: step['status'] == 'not_started'
                              ? ChoiceLuxTheme.infoColor
                              : ChoiceLuxTheme.richGold,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          step['status'] == 'not_started'
                              ? 'Not Started'
                              : 'In Progress',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: ChoiceLuxTheme.richGold.withValues(alpha:0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: ChoiceLuxTheme.richGold.withValues(alpha:0.5),
                          ),
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: ChoiceLuxTheme.richGold,
                          size: 16,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  step['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: isUpcoming
                        ? Colors.grey.withValues(alpha:0.7)
                        : isCompleted
                        ? Colors.white.withValues(alpha:0.9)
                        : Colors.white.withValues(alpha:0.8),
                  ),
                ),
                if (step['address'] != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? ChoiceLuxTheme.richGold.withValues(alpha:0.1)
                          : Colors.blue.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isCurrent
                            ? ChoiceLuxTheme.richGold.withValues(alpha:0.3)
                            : Colors.blue.withValues(alpha:0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: isCurrent
                              ? ChoiceLuxTheme.richGold
                              : Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            step['address']!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isCurrent
                                  ? ChoiceLuxTheme.richGold
                                  : Colors.blue[300],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (step['tripAmount'] != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ChoiceLuxTheme.richGold.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: ChoiceLuxTheme.richGold.withValues(alpha:0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.attach_money,
                          size: 12,
                          color: ChoiceLuxTheme.richGold,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          step['tripAmount']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ChoiceLuxTheme.richGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (step['tripDate'] != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.green.withValues(alpha:0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 12,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          step['tripDate']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (step['startOdometer'] != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ChoiceLuxTheme.successColor.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: ChoiceLuxTheme.successColor.withValues(alpha:0.3),
                      ),
                    ),
                    child: Text(
                      step['startOdometer']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ChoiceLuxTheme.successColor,
                      ),
                    ),
                  ),
                if (step['odometer'] != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isTotal
                          ? Colors.indigo.withValues(alpha:0.1)
                          : Colors.grey.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isTotal
                            ? Colors.indigo.withValues(alpha:0.3)
                            : Colors.grey.withValues(alpha:0.3),
                      ),
                    ),
                    child: Text(
                      step['odometer']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isTotal ? Colors.indigo : Colors.white,
                      ),
                    ),
                  ),
                if (step['endOdometer'] != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha:0.3),
                      ),
                    ),
                    child: Text(
                      step['endOdometer']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[300],
                      ),
                    ),
                  ),
                if (step['totalDistance'] != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ChoiceLuxTheme.richGold.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: ChoiceLuxTheme.richGold.withValues(alpha:0.3),
                      ),
                    ),
                    child: Text(
                      step['totalDistance']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ChoiceLuxTheme.richGold,
                      ),
                    ),
                  ),
                if (isCurrent && step['progressPercentage'] != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${step['progressPercentage'].toInt()}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ChoiceLuxTheme.richGold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: step['progressPercentage'] / 100.0,
                          backgroundColor: ChoiceLuxTheme.richGold.withValues(alpha:
                            0.2,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ChoiceLuxTheme.richGold,
                          ),
                          minHeight: 4,
                        ),
                      ],
                    ),
                  ),
                if (step['completedAt'] != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ChoiceLuxTheme.successColor.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: ChoiceLuxTheme.successColor.withValues(alpha:0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: ChoiceLuxTheme.successColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Completed on: ${_formatDateTime(step['completedAt'])}',
                          style: TextStyle(
                            fontSize: 12, 
                            color: ChoiceLuxTheme.successColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray,
        borderRadius: BorderRadius.circular(12),
      ),
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

  Widget _buildStepTimelineContent() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getStepTimeline(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha:0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error loading timeline: ${snapshot.error}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final steps = snapshot.data ?? [];

        if (steps.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withValues(alpha:0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No steps have been completed yet. The timeline will show completed steps as the job progresses.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: steps.map((step) {
            return _buildStepTimelineItem(step);
          }).toList(),
        );
      },
    );
  }

  Widget _buildNotesContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha:0.2)),
      ),
      child: Text(
        _job!.notes!,
        style: const TextStyle(fontSize: 14, height: 1.5),
      ),
    );
  }

  Widget _buildTripsSummaryCard(double totalAmount) {
    return Container(
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray,
        borderRadius: BorderRadius.circular(12),
      ),
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
    // Get user role for hiding amounts
    final userProfile = ref.watch(currentUserProfileProvider);
    final isDriver = userProfile?.role?.toLowerCase() == 'driver';
    
    return Column(
      children: [
        _buildDetailRow('Total Trips', '${_trips.length}', Icons.route),
        if (!isDriver)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.richGold.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ChoiceLuxTheme.richGold.withValues(alpha:0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.attach_money,
                  color: ChoiceLuxTheme.richGold,
                  size: 24,
                ),
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

  Widget _buildTripsListContent() {
    // Get user role for hiding amounts
    final userProfile = ref.watch(currentUserProfileProvider);
    final isDriver = userProfile?.role?.toLowerCase() == 'driver';
    
    return Column(
      children: _trips.asMap().entries.map((entry) {
        final index = entry.key;
        final trip = entry.value;
        return _buildTripCard(trip, index);
      }).toList(),
    );
  }

  Widget _buildTripsListCard() {
    return Container(
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray,
        borderRadius: BorderRadius.circular(12),
      ),
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
    // Get user role for hiding amounts
    final userProfile = ref.watch(currentUserProfileProvider);
    final isDriver = userProfile?.role?.toLowerCase() == 'driver';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha:0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha:0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: ChoiceLuxTheme.richGold.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ChoiceLuxTheme.richGold.withValues(alpha:0.3),
                    ),
                  ),
                  child: Text(
                    // Hide amount for drivers
                    isDriver 
                        ? 'Trip ${index + 1}' 
                        : 'R${(trip.amount ?? 0.0).toStringAsFixed(2)}',
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
                    backgroundColor: ChoiceLuxTheme.richGold.withValues(alpha:0.1),
                    foregroundColor: ChoiceLuxTheme.richGold,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Date & Time',
              trip.formattedDateTime ?? 'Not set',
              Icons.access_time,
            ),
            _buildDetailRow(
              'Pick-up',
              trip.pickupLocation ?? 'Not set',
              Icons.location_on,
            ),
            _buildDetailRow(
              'Drop-off',
              trip.dropoffLocation ?? 'Not set',
              Icons.location_off,
            ),
            if (trip.notes != null && trip.notes!.isNotEmpty)
              _buildDetailRow('Notes', trip.notes!, Icons.note),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final currentUser = ref.read(currentUserProfileProvider);
    final isAssignedDriver = _job?.driverId == currentUser?.id;
    final isConfirmed =
        _job?.isConfirmed == true || _job?.driverConfirmation == true;
    final needsConfirmation = isAssignedDriver && !isConfirmed;
    final canEdit =
        currentUser?.role?.toLowerCase() == 'administrator' ||
        currentUser?.role?.toLowerCase() == 'super_admin' ||
        currentUser?.role?.toLowerCase() == 'manager';

    return Column(
      children: [
        Row(
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            if (needsConfirmation) ...[
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isConfirming ? null : _confirmJob,
                  icon: _isConfirming
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(_isConfirming ? 'Confirming...' : 'Confirm Job'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ] else if (isAssignedDriver && isConfirmed) ...[
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: null, // Disabled after confirmation
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Job Confirmed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey, // Different color for confirmed state
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ] else if (canEdit) ...[
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        // Trip Management Buttons
        if (canEdit) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/trip-management/${widget.jobId}'),
                  icon: const Icon(Icons.list_alt),
                  label: const Text('View All Trips'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showAddTripModal,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Another Trip'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ChoiceLuxTheme.infoColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMobileActionButtons() {
    final currentUser = ref.read(currentUserProfileProvider);
    final isAssignedDriver = _job?.driverId == currentUser?.id;
    final isConfirmed =
        _job?.isConfirmed == true || _job?.driverConfirmation == true;
    final needsConfirmation = isAssignedDriver && !isConfirmed;
    final canEdit =
        currentUser?.role?.toLowerCase() == 'administrator' ||
        currentUser?.role?.toLowerCase() == 'super_admin' ||
        currentUser?.role?.toLowerCase() == 'manager';

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.go('/jobs'),
            icon: const Icon(Icons.list),
            label: const Text('Back to Jobs'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        if (needsConfirmation) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isConfirming ? null : _confirmJob,
              icon: _isConfirming
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check_circle),
              label: Text(_isConfirming ? 'Confirming...' : 'Confirm Job'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ] else if (isAssignedDriver && isConfirmed) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: null, // Disabled after confirmation
              icon: const Icon(Icons.check_circle),
              label: const Text('Job Confirmed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey, // Different color for confirmed state
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ] else if (canEdit) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/jobs/${widget.jobId}/edit'),
              icon: const Icon(Icons.edit),
              label: const Text('Edit Job'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ChoiceLuxTheme.richGold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
        // Trip Management Buttons
        if (canEdit) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/trip-management/${widget.jobId}'),
              icon: const Icon(Icons.list_alt),
              label: const Text('View All Trips'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showAddTripModal,
              icon: const Icon(Icons.add),
              label: const Text('Add Another Trip'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ChoiceLuxTheme.infoColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmJob() async {
    Log.d('=== JOB SUMMARY SCREEN: _confirmJob() called ===');
    Log.d('Job ID: ${_job!.id}');
    Log.d('Job Status: ${_job!.status}');
    Log.d('Is Confirmed: ${_job!.isConfirmed}');
    Log.d('Driver Confirmation: ${_job!.driverConfirmation}');

    // Prevent duplicate calls
    if (_isConfirming) {
      Log.d('Job confirmation already in progress, skipping duplicate call');
      return;
    }

    setState(() => _isConfirming = true);

    try {
      // Show loading state
      if (!mounted) {
        Log.d('Widget not mounted, returning early');
        return;
      }

      Log.d('Calling jobsProvider.confirmJob...');
      // Confirm the job using the single source of truth
      await ref.read(jobsProvider.notifier).confirmJob(widget.jobId);
      Log.d('jobsProvider.confirmJob completed successfully');

      // Note: No need to refresh jobs as confirmJob already does optimistic update

      // Check if widget is still mounted before showing success message and navigating
      if (!mounted) {
        Log.d('Widget not mounted after confirmation, returning early');
        return;
      }

      Log.d('Showing success message...');
      // Show success message
      SnackBarUtils.showSuccess(context, '✅ Job confirmed successfully!');

      Log.d('Waiting 500ms before navigation...');
      // Wait a moment for the SnackBar to show, then navigate
      await Future.delayed(const Duration(milliseconds: 500));

      // Check again if widget is still mounted before navigating
      if (!mounted) {
        Log.d('Widget not mounted before navigation, returning early');
        return;
      }

      Log.d('Navigating to /jobs...');
      // Navigate back to jobs management after confirmation
      context.go('/jobs');
      Log.d('Navigation completed');
    } catch (e) {
      Log.e('Error in _confirmJob: $e');
      // Check if widget is still mounted before showing error
      if (!mounted) {
        Log.d('Widget not mounted for error display, returning early');
        return;
      }

      SnackBarUtils.showError(context, '❌ Failed to confirm job: $e');
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      }
    }
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
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (_job!.status) {
      case 'assigned':
        return ChoiceLuxTheme.richGold;
      case 'started':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'ready_to_close':
        return Colors.purple;
      case 'completed':
        return ChoiceLuxTheme.successColor;
      case 'cancelled':
        return ChoiceLuxTheme.errorColor;
      default:
        return ChoiceLuxTheme.platinumSilver;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'assigned':
        return 'ASSIGNED';
      case 'started':
        return 'STARTED';
      case 'in_progress':
        return 'IN PROGRESS';
      case 'ready_to_close':
        return 'READY TO CLOSE';
      case 'completed':
        return 'COMPLETED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return status.toUpperCase();
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
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

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'Not completed';

    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _formatTripDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<List<Map<String, dynamic>>> _getStepTimeline() async {
    final steps = <Map<String, dynamic>>[];

    // Get odometer readings
    final startOdo = _driverFlowData?['odo_start_reading'] ?? 0.0;
    final endOdo = _driverFlowData?['job_closed_odo'] ?? 0.0;
    final totalKm = endOdo - startOdo;
    final progressPercentage = _driverFlowData?['progress_percentage'] ?? 0.0;

    // Define all possible steps in order
    final allSteps = [
      'vehicle_collection',
      'pickup_arrival',
      'passenger_onboard',
      'dropoff_arrival',
      'trip_complete',
      'vehicle_return',
    ];

    // Get current step from driver flow data
    final currentStepId = _driverFlowData?['current_step']?.toString();

    // Get selected trip data
    Trip? selectedTrip;
    if (_trips.isNotEmpty && _selectedTripIndex < _trips.length) {
      selectedTrip = _trips[_selectedTripIndex];
    }

    // Use trip-specific addresses if available, otherwise fall back to job addresses
    Map<String, String?> addresses = {};
    if (selectedTrip != null) {
      addresses = {
        'pickup': selectedTrip.pickupLocation,
        'dropoff': selectedTrip.dropoffLocation,
      };
    } else {
      // Fallback to job addresses
      try {
        addresses = await DriverFlowApiService.getJobAddresses(
          int.parse(widget.jobId),
        );
      } catch (e) {
        Log.e('Could not load job addresses: $e');
      }
    }

    // Process each step
    for (final stepId in allSteps) {
      final stepTitle = DriverFlowUtils.getStepTitle(stepId);
      final stepDescription = DriverFlowUtils.getStepDescription(stepId);
      final stepIcon = DriverFlowUtils.getStepIcon(stepId);

      // Determine step status
      bool isCompleted = false;
      bool isCurrent = false;
      String? completedAt; // Changed from DateTime? to String? to match database types

      // Check if this is the current step
      if (currentStepId != null && currentStepId.isNotEmpty) {
        isCurrent = stepId == currentStepId;
      } else {
        // No current step means job hasn't started - first step (vehicle_collection) is current
        isCurrent = stepId == 'vehicle_collection';
      }

      // Check completion status for each step
      switch (stepId) {
        case 'vehicle_collection':
          isCompleted = _driverFlowData?['vehicle_collected'] == true;
          completedAt = _driverFlowData?['vehicle_collected_at'];
          break;
        case 'pickup_arrival':
          isCompleted = _driverFlowData?['current_step'] == 'pickup_arrival' ||
                       _driverFlowData?['current_step'] == 'passenger_pickup' ||
                       _driverFlowData?['current_step'] == 'passenger_onboard' ||
                       _driverFlowData?['current_step'] == 'dropoff_arrival' ||
                       _driverFlowData?['current_step'] == 'trip_complete' ||
                       _driverFlowData?['current_step'] == 'vehicle_return' ||
                       _driverFlowData?['current_step'] == 'completed';
          completedAt = _driverFlowData?['pickup_arrive_time'];
          break;
        case 'passenger_onboard':
          isCompleted = _driverFlowData?['current_step'] == 'passenger_onboard' ||
                       _driverFlowData?['current_step'] == 'dropoff_arrival' ||
                       _driverFlowData?['current_step'] == 'trip_complete' ||
                       _driverFlowData?['current_step'] == 'vehicle_return' ||
                       _driverFlowData?['current_step'] == 'completed';
          completedAt = _driverFlowData?['last_activity_at'];
          break;
        case 'dropoff_arrival':
          isCompleted = _driverFlowData?['current_step'] == 'dropoff_arrival' ||
                       _driverFlowData?['current_step'] == 'trip_complete' ||
                       _driverFlowData?['current_step'] == 'vehicle_return' ||
                       _driverFlowData?['current_step'] == 'completed';
          completedAt = _driverFlowData?['last_activity_at'];
          break;
        case 'trip_complete':
          isCompleted = _driverFlowData?['current_step'] == 'trip_complete' ||
                       _driverFlowData?['current_step'] == 'vehicle_return' ||
                       _driverFlowData?['current_step'] == 'completed';
          completedAt = _driverFlowData?['last_activity_at'];
          break;
        case 'vehicle_return':
          isCompleted = _driverFlowData?['job_closed_time'] != null;
          completedAt = _driverFlowData?['job_closed_time'];
          break;
      }

      // Add step to timeline with appropriate styling
      if (isCompleted) {
        // Completed step
        final stepData = {
          'title': stepTitle,
          'description': stepDescription,
          'completedAt': completedAt,
          'icon': stepIcon,
          'color': ChoiceLuxTheme.successColor,
          'status': 'completed',
        };

        // Add odometer info for vehicle steps
        if (stepId == 'vehicle_collection' && startOdo > 0) {
          stepData['startOdometer'] = 'Start: ${startOdo.toStringAsFixed(1)} km';
        } else if (stepId == 'vehicle_return' && endOdo > 0) {
          stepData['endOdometer'] = 'End: ${endOdo.toStringAsFixed(1)} km';
          // Also show total distance if we have both readings
          if (startOdo > 0 && endOdo > startOdo) {
            final totalKm = endOdo - startOdo;
            stepData['totalDistance'] = 'Total: ${totalKm.toStringAsFixed(1)} km';
          }
        }

        steps.add(stepData);
      } else if (isCurrent) {
        // Current step
        // Get the correct address based on step type
        String? stepAddress;
        if (stepId == 'pickup_arrival') {
          stepAddress = addresses['pickup'];
        } else if (stepId == 'dropoff_arrival') {
          stepAddress = addresses['dropoff'];
        }
        
        final stepData = {
          'title': DriverFlowUtils.getStepTitleWithAddress(
            stepId,
            stepAddress,
          ),
          'description': stepDescription,
          'completedAt': null,
          'icon': stepIcon,
          'color': currentStepId == null
              ? ChoiceLuxTheme.infoColor
              : ChoiceLuxTheme.richGold,
          'status': currentStepId == null ? 'not_started' : 'current',
          'progressPercentage': progressPercentage,
        };

        // Add address info for location steps
        if (stepId == 'pickup_arrival' && addresses['pickup'] != null) {
          stepData['address'] = addresses['pickup'];
        } else if (stepId == 'dropoff_arrival' &&
            addresses['dropoff'] != null) {
          stepData['address'] = addresses['dropoff'];
        }
        
        // Add trip-specific information
        if (selectedTrip != null) {
          if (stepId == 'trip_complete') {
            stepData['tripDate'] = _formatTripDate(selectedTrip.pickupDate);
          }
        }

        steps.add(stepData);
      } else {
        // Upcoming step
        // Get the correct address based on step type
        String? stepAddress;
        if (stepId == 'pickup_arrival') {
          stepAddress = addresses['pickup'];
        } else if (stepId == 'dropoff_arrival') {
          stepAddress = addresses['dropoff'];
        }
        
        final stepData = {
          'title': DriverFlowUtils.getStepTitleWithAddress(
            stepId,
            stepAddress,
          ),
          'description': stepDescription,
          'completedAt': null,
          'icon': stepIcon,
          'color': Colors.grey,
          'status': 'upcoming',
        };

        // Add address info for location steps
        if (stepId == 'pickup_arrival' && addresses['pickup'] != null) {
          stepData['address'] = addresses['pickup'];
        } else if (stepId == 'dropoff_arrival' &&
            addresses['dropoff'] != null) {
          stepData['address'] = addresses['dropoff'];
        }
        
        // Add trip-specific information
        if (selectedTrip != null) {
          if (stepId == 'trip_complete') {
            stepData['tripDate'] = _formatTripDate(selectedTrip.pickupDate);
          }
        }

        steps.add(stepData);
      }
    }

    // Add total kilometers traveled if we have both odometer readings
    if (startOdo > 0 && endOdo > 0 && totalKm > 0) {
      steps.add({
        'title': 'Total Distance Traveled',
        'description': 'Total kilometers covered during this job',
        'completedAt': null,
        'icon': Icons.speed,
        'color': Colors.indigo,
        'odometer': 'Total: ${totalKm.toStringAsFixed(1)} km',
        'status': 'completed',
        'isTotal': true,
      });
    }

    return steps;
  }

  void _printJobSummary() {
    // Basic print functionality - could be enhanced with PDF generation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Printing job summary for ${_job?.jobNumber ?? 'Unknown Job'}'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  void _shareJobSummary() {
    // Basic share functionality - could be enhanced with actual sharing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing job summary for ${_job?.jobNumber ?? 'Unknown Job'}'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  void _showTripEditModal(Trip trip) {
    showDialog(
      context: context,
      builder: (context) => TripEditModal(
        trip: trip,
        jobId: widget.jobId,
        onTripUpdated: (updatedTrip) async {
          // Refresh the trips list after successful trip update
          ref.invalidate(tripsByJobProvider(widget.jobId));
          
          // Force refresh the trips provider
          try {
            final tripsNotifier = ref.read(tripsByJobProvider(widget.jobId).notifier);
            await tripsNotifier.refresh();
            Log.d('Trips refreshed after updating trip');
          } catch (e) {
            Log.e('Error refreshing trips: $e');
          }
          
          // Show success message
          SnackBarUtils.showSuccess(
            context,
            'Trip updated successfully!',
          );
        },
      ),
    );
  }

  void _showAddTripModal() {
    showDialog(
      context: context,
      builder: (context) => AddTripModal(
        jobId: widget.jobId,
        onTripAdded: (trip) async {
          // Refresh the trips list after successful trip creation
          ref.invalidate(tripsByJobProvider(widget.jobId));
          
          // Force refresh the trips provider
          try {
            final tripsNotifier = ref.read(tripsByJobProvider(widget.jobId).notifier);
            await tripsNotifier.refresh();
            Log.d('Trips refreshed after adding new trip');
          } catch (e) {
            Log.e('Error refreshing trips: $e');
          }
          
          // Show success message
          SnackBarUtils.showSuccess(
            context,
            'Trip added successfully!',
          );
        },
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha:0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentStepDisplayName(String stepId) {
    switch (stepId) {
      case 'vehicle_collection':
        return 'Vehicle Collection';
      case 'pickup_arrival':
        return 'Arrive at Pickup';
      case 'passenger_pickup':
        return 'Passenger Pickup';
      case 'passenger_onboard':
        return 'Passenger Onboard';
      case 'dropoff_arrival':
        return 'Arrive at Dropoff';
      case 'trip_complete':
        return 'Trip Complete';
      case 'vehicle_return':
        return 'Vehicle Return';
      case 'completed':
        return 'Job Completed';
      default:
        return stepId.replaceAll('_', ' ').toTitleCase();
    }
  }
}
