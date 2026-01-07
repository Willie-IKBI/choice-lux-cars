import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/jobs/models/job.dart';
import 'package:choice_lux_cars/features/jobs/providers/jobs_provider.dart';
import 'package:choice_lux_cars/features/clients/providers/clients_provider.dart';
import 'package:choice_lux_cars/features/clients/providers/agents_provider.dart';
import 'package:choice_lux_cars/features/vehicles/providers/vehicles_provider.dart';
import 'package:choice_lux_cars/features/users/providers/users_provider.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/utils/snackbar_utils.dart';
import 'package:choice_lux_cars/shared/utils/background_pattern_utils.dart';
import 'package:choice_lux_cars/shared/widgets/system_safe_scaffold.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';

class CreateJobScreen extends ConsumerStatefulWidget {
  final String? jobId; // null for create, non-null for edit

  const CreateJobScreen({super.key, this.jobId});

  @override
  ConsumerState<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends ConsumerState<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _passengerNameController = TextEditingController();
  final _passengerContactController = TextEditingController();
  final _pasCountController = TextEditingController();
  final _luggageCountController = TextEditingController();
  final _notesController = TextEditingController();
  final _paymentAmountController = TextEditingController();
  final _clientSearchController = TextEditingController();

  // Form values
  String? _selectedClientId;
  String? _selectedAgentId;
  String? _selectedVehicleId;
  String? _selectedDriverId;
  String? _selectedLocation; // Branch location (Jhb, Cpt, Dbn)
  DateTime? _selectedJobStartDate;
  bool _collectPayment = false;

  // Loading states
  bool _isLoading = false;
  bool _isSubmitting = false;

  // Search states
  String _clientSearchQuery = '';
  bool _showClientDropdown = false;

  // Calculate completion percentage
  double get _completionPercentage {
    int completedFields = 0;
    int totalRequiredFields =
        7; // client, vehicle, driver, location, date, passenger count, luggage count

    // Required fields
    if (_selectedClientId != null) completedFields++;
    if (_selectedVehicleId != null) completedFields++;
    if (_selectedDriverId != null) completedFields++;
    if (_selectedLocation != null) completedFields++;
    if (_selectedJobStartDate != null) completedFields++;
    if (_pasCountController.text.isNotEmpty) completedFields++;
    if (_luggageCountController.text.isNotEmpty) completedFields++;

    return (completedFields / totalRequiredFields) * 100;
  }

  @override
  void initState() {
    super.initState();
    Log.d('CreateJobScreen initialized');
    _loadData();

    // If editing, load the job data
    if (widget.jobId != null) {
      _loadJobForEditing();
    }
  }

  @override
  void dispose() {
    _passengerNameController.dispose();
    _passengerContactController.dispose();
    _pasCountController.dispose();
    _luggageCountController.dispose();
    _notesController.dispose();
    _paymentAmountController.dispose();
    _clientSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      Log.d('Loading form data...');
      
      // Load all required data in parallel
      await Future.wait([
        _loadClients(),
        _loadVehicles(),
        _loadDrivers(),
        _loadLocations(),
      ]);
      
      Log.d('Form data loaded successfully');
    } catch (e) {
      Log.e('Error loading form data: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading form data: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadClients() async {
    try {
      // ClientsNotifier automatically loads clients in its build method
      // We just need to ensure it's initialized
      await ref.read(clientsProvider.future);
      Log.d('Clients loaded');
    } catch (e) {
      Log.e('Error loading clients: $e');
    }
  }

  Future<void> _loadVehicles() async {
    try {
      // VehiclesNotifier automatically loads vehicles in its build method
      // We just need to ensure it's initialized
      await ref.read(vehiclesProvider.future);
      Log.d('Vehicles loaded');
    } catch (e) {
      Log.e('Error loading vehicles: $e');
    }
  }

  Future<void> _loadDrivers() async {
    try {
      // The usersProvider automatically loads all users in its build method
      // We just need to ensure it's initialized
      await ref.read(usersProvider.future);
      Log.d('Drivers loaded');
    } catch (e) {
      Log.e('Error loading drivers: $e');
    }
  }

  Future<void> _loadLocations() async {
    // Locations are hardcoded for now
    Log.d('Locations loaded (hardcoded)');
  }

  Future<void> _loadJobForEditing() async {
    if (widget.jobId == null) return;

    setState(() => _isLoading = true);

    try {
      Log.d('Loading job for editing: ${widget.jobId}');
      
      // Try to find job in local state first
      Job? job;
      try {
        final jobsState = ref.read(jobsProvider);
        if (jobsState.hasValue) {
          job = jobsState.value!.firstWhere((j) => j.id == widget.jobId);
          Log.d('Found job in local state: ${job.id}');
        }
      } catch (e) {
        Log.d('Job not found in local state, will fetch individually');
      }

      // If not found locally, fetch from database
      if (job == null) {
        Log.d('Fetching job from database...');
        job = await ref.read(jobsProvider.notifier).fetchJobById(widget.jobId!);
        if (job == null) {
          throw Exception('Job not found in database');
        }
        Log.d('Successfully fetched job from database: ${job.id}');
      }

      // Populate form fields
      _selectedClientId = job.clientId;
      _selectedAgentId = job.agentId;
      _selectedVehicleId = job.vehicleId;
      _selectedDriverId = job.driverId;
      _selectedLocation = job.location;
      _selectedJobStartDate = job.jobStartDate;
      _collectPayment = job.collectPayment;

      _passengerNameController.text = job.passengerName ?? '';
      _passengerContactController.text = job.passengerContact ?? '';
      _pasCountController.text = job.pasCount.toString();
      _luggageCountController.text = job.luggageCount.toString();
      _notesController.text = job.notes ?? '';
      if (job.paymentAmount != null) {
        _paymentAmountController.text = job.paymentAmount!.toString();
      }

      // Populate client search controller with client name
      if (job?.clientId != null) {
        try {
          final clientsState = ref.read(clientsProvider);
          if (clientsState.hasValue) {
            final client = clientsState.value!.firstWhere((c) => c.id.toString() == job!.clientId);
            _clientSearchController.text = client.companyName;
            Log.d('Client search controller populated with: ${client.companyName}');
          }
        } catch (e) {
          Log.d('Could not populate client search controller: $e');
        }
      }

      Log.d('Form fields populated successfully');
    } catch (e) {
      Log.e('Error loading job for editing: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading job data: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onClientChanged(String? clientId) {
    setState(() {
      _selectedClientId = clientId;
      _selectedAgentId = null;
      _showClientDropdown = false;
    });
  }

  Future<void> _selectJobStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedJobStartDate ?? DateTime.now(),
      firstDate: DateTime.now(),
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

    if (picked != null) {
      setState(() {
        _selectedJobStartDate = picked;
      });
    }
  }

  Future<void> _createJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final currentUser = ref.read(currentUserProfileProvider);
      if (currentUser == null) throw Exception('User not authenticated');

      final isEditing = widget.jobId != null;

      if (isEditing) {
        // Update existing job
        Job existingJob;
        try {
          // Try to find job in local state first
          final jobsState = ref.read(jobsProvider);
          if (jobsState.hasValue) {
            existingJob = jobsState.value!.firstWhere((j) => j.id == widget.jobId);
          } else {
            throw Exception('Jobs not loaded');
          }
        } catch (e) {
          // If not found locally, fetch from database
          Log.d('Job not found in local state, fetching from database for update...');
          final fetchedJob = await ref.read(jobsProvider.notifier).fetchJobById(widget.jobId!);
          if (fetchedJob == null) {
            throw Exception('Job not found in database');
          }
          existingJob = fetchedJob;
        }

        // Check if driver is being changed
        final isDriverChanged = _selectedDriverId != existingJob.driverId;

        final updatedJob = Job(
          id: existingJob.id,
          clientId: _selectedClientId!,
          agentId: _selectedAgentId,
          vehicleId: _selectedVehicleId!,
          driverId: _selectedDriverId!,
          jobStartDate: _selectedJobStartDate!,
          orderDate: existingJob.orderDate,
          passengerName: _passengerNameController.text.trim().isEmpty
              ? null
              : _passengerNameController.text.trim(),
          passengerContact: _passengerContactController.text.trim().isEmpty
              ? null
              : _passengerContactController.text.trim(),
          pasCount: double.parse(_pasCountController.text),
          luggageCount: _luggageCountController.text,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          collectPayment: _collectPayment,
          paymentAmount: _paymentAmountController.text.isNotEmpty
              ? double.tryParse(_paymentAmountController.text)
              : existingJob.paymentAmount,
          status: existingJob.status,
          location: _selectedLocation,
          createdBy: existingJob.createdBy,
          createdAt: existingJob.createdAt,
          driverConfirmation: isDriverChanged
              ? false
              : existingJob.driverConfirmation, // Reset if driver changed
        );

        await ref.read(jobsProvider.notifier).updateJob(updatedJob);

        // Show appropriate message based on driver change
        if (mounted) {
          if (isDriverChanged) {
            SnackBarUtils.showSuccess(
              context,
              '✅ Job updated and reassigned to new driver. Driver will be notified.',
            );
          } else {
            SnackBarUtils.showSuccess(context, '✅ Job updated successfully!');
          }
          context.go('/jobs/${widget.jobId}/summary');
        }
      } else {
        // Create new job
        final job = Job(
          id: 0, // Let database auto-generate the ID
          clientId: _selectedClientId!,
          agentId: _selectedAgentId,
          vehicleId: _selectedVehicleId!,
          driverId: _selectedDriverId!,
          jobStartDate: _selectedJobStartDate!,
          orderDate: DateTime.now(),
          passengerName: _passengerNameController.text.trim().isEmpty
              ? null
              : _passengerNameController.text.trim(),
          passengerContact: _passengerContactController.text.trim().isEmpty
              ? null
              : _passengerContactController.text.trim(),
          pasCount: double.parse(_pasCountController.text),
          luggageCount: _luggageCountController.text,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          collectPayment: _collectPayment,
          paymentAmount:
              null, // Amount will be completed later in transport details
          status: 'open',
          location: _selectedLocation,
          createdBy: currentUser.id,
          createdAt: DateTime.now(),
          driverConfirmation: false, // Set to false when creating new job
        );

        final createdJob = await ref.read(jobsProvider.notifier).createJob(job);

        if (mounted) {
          // Show success message before navigation
          SnackBarUtils.showSuccess(
            context,
            'Job created successfully! Moving to transport details...',
          );

          // Use a small delay to ensure SnackBar is shown before navigation
          await Future.delayed(const Duration(milliseconds: 100));

          if (mounted && createdJob != null && createdJob['id'] != null) {
            // Navigate to trip management screen for Step 2
            context.go('/jobs/${createdJob['id']}/trip-management');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Error creating job: $e');
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveBreakpoints.isMobile(screenWidth) || ResponsiveBreakpoints.isSmallMobile(screenWidth);

    // Calculate responsive max width based on screen size
    double getMaxWidth() {
      if (screenWidth < 768)
        return screenWidth - 32; // Mobile: full width minus padding
      if (screenWidth < 1024) return 800; // Tablet: 800px max
      if (screenWidth < 1440) return 1000; // Medium desktop: 1000px max
      if (screenWidth < 1920) return 1200; // Large desktop: 1200px max
      return 1400; // Extra large: 1400px max
    }

    return Stack(
      children: [
        // Layer 1: The background that fills the entire screen
        Container(
          decoration: const BoxDecoration(
            gradient: ChoiceLuxTheme.backgroundGradient,
          ),
        ),
        // Layer 2: The Scaffold with a transparent background
        SystemSafeScaffold(
          backgroundColor: Colors.transparent, // CRITICAL
          appBar: LuxuryAppBar(
            title: widget.jobId != null ? 'Edit Job' : 'Create New Job',
            showBackButton: true,
            onBackPressed: () => widget.jobId != null
                ? context.go('/jobs/${widget.jobId}/summary')
                : context.go('/jobs'),
          ),
          body: Stack( // The body is now just the content stack
            children: [
              Positioned.fill(
                child: CustomPaint(painter: BackgroundPatterns.dashboard),
              ),
              Consumer(
                builder: (context, ref, child) {
                  final clientsAsync = ref.watch(clientsProvider);
                  final vehiclesState = ref.watch(vehiclesProvider);
                  final users = ref.watch(usersProvider);

                  // Debug logging
                  Log.d('Form build - Clients: ${clientsAsync.toString()}');
                  Log.d('Form build - Vehicles: ${vehiclesState.toString()}');
                  Log.d('Form build - Users: ${users.toString()}');

                  if (vehiclesState.isLoading || !users.hasValue) {
                    Log.d('Form showing loading indicator - Vehicles loading: ${vehiclesState.isLoading}, Users hasValue: ${users.hasValue}');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ChoiceLuxTheme.richGold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading form data...',
                            style: TextStyle(
                              color: ChoiceLuxTheme.softWhite,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Vehicles: ${vehiclesState.isLoading ? "Loading..." : "Ready"}',
                            style: TextStyle(
                              color: ChoiceLuxTheme.platinumSilver,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Users: ${users.hasValue ? "Ready" : "Loading..."}',
                            style: TextStyle(
                              color: ChoiceLuxTheme.platinumSilver,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (vehiclesState.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: ChoiceLuxTheme.errorColor,
                          ),
                          const SizedBox(height: 16),
                          Text('Error loading vehicles: ${vehiclesState.error}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () =>
                                ref.read(vehiclesProvider.notifier).fetchVehicles(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  return clientsAsync.when(
                    data: (clients) {
                      final vehicles = vehiclesState.value ?? [];
                      final allUsers =
                          users.value ?? []; // Show all users regardless of role

                      Log.d('Form rendering - Clients: ${clients.length}, Vehicles: ${vehicles.length}, Users: ${allUsers.length}');

                      return Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(isMobile ? 16 : 24),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: getMaxWidth()),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Progress indicator
                                  _buildProgressIndicator(),

                                  const SizedBox(height: 32),

                                  // Client & Agent Selection
                                  _buildFormSection(
                                    title: 'Client & Agent Selection',
                                    icon: Icons.business,
                                    children: [
                                      _buildSearchableClientDropdown(clients),
                                      const SizedBox(height: 20),
                                      _buildAgentDropdown(),
                                    ],
                                  ),

                                  const SizedBox(height: 32),

                                  // Job Details
                                  _buildFormSection(
                                    title: 'Job Details',
                                    icon: Icons.work,
                                    children: [
                                      _buildVehicleDropdown(vehicles),
                                      const SizedBox(height: 20),
                                      _buildDriverDropdown(allUsers),
                                      const SizedBox(height: 20),
                                      _buildLocationDropdown(),
                                      const SizedBox(height: 20),
                                      _buildJobStartDatePicker(),
                                    ],
                                  ),

                                  const SizedBox(height: 32),

                                  // Passenger Details
                                  _buildFormSection(
                                    title: 'Passenger Details',
                                    icon: Icons.people,
                                    children: [
                                      _buildTextField(
                                        controller: _passengerNameController,
                                        label: 'Passenger Name',
                                        hint: 'Enter passenger name (optional)',
                                        icon: Icons.person,
                                        isRequired: false,
                                      ),
                                      const SizedBox(height: 20),
                                      _buildTextField(
                                        controller: _passengerContactController,
                                        label: 'Contact Number',
                                        hint: 'Enter contact number (optional)',
                                        icon: Icons.phone,
                                        isRequired: false,
                                        keyboardType: TextInputType.phone,
                                      ),
                                      const SizedBox(height: 20),
                                      isMobile
                                          ? Column(
                                              children: [
                                                _buildTextField(
                                                  controller: _pasCountController,
                                                  label: 'Number of Passengers',
                                                  hint: 'e.g. 2',
                                                  icon: Icons.people,
                                                  keyboardType: TextInputType.number,
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'Please enter passenger count';
                                                    }
                                                    if (double.tryParse(value) ==
                                                            null ||
                                                        double.parse(value) <= 0) {
                                                      return 'Please enter a valid number';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                                const SizedBox(height: 20),
                                                _buildTextField(
                                                  controller: _luggageCountController,
                                                  label: 'Number of Bags',
                                                  hint: 'e.g. 3',
                                                  icon: Icons.work,
                                                  keyboardType: TextInputType.number,
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'Please enter luggage count';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                              ],
                                            )
                                          : Row(
                                              children: [
                                                Expanded(
                                                  child: _buildTextField(
                                                    controller: _pasCountController,
                                                    label: 'Number of Passengers',
                                                    hint: 'e.g. 2',
                                                    icon: Icons.people,
                                                    keyboardType: TextInputType.number,
                                                    validator: (value) {
                                                      if (value == null ||
                                                          value.isEmpty) {
                                                        return 'Please enter passenger count';
                                                      }
                                                      if (double.tryParse(value) ==
                                                              null ||
                                                          double.parse(value) <= 0) {
                                                        return 'Please enter a valid number';
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 20),
                                                Expanded(
                                                  child: _buildTextField(
                                                    controller: _luggageCountController,
                                                    label: 'Number of Bags',
                                                    hint: 'e.g. 3',
                                                    icon: Icons.work,
                                                    keyboardType: TextInputType.number,
                                                    validator: (value) {
                                                      if (value == null ||
                                                          value.isEmpty) {
                                                        return 'Please enter luggage count';
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ],
                                  ),

                                  const SizedBox(height: 32),

                                  // Payment & Notes
                                  _buildFormSection(
                                    title: 'Payment & Notes',
                                    icon: Icons.payment,
                                    children: [
                                      _buildPaymentSection(),
                                      const SizedBox(height: 20),
                                      _buildTextField(
                                        controller: _notesController,
                                        label: 'Notes',
                                        hint:
                                            'Enter pickup location, flight details, or other relevant information',
                                        icon: Icons.note,
                                        maxLines: 4,
                                        isRequired: false,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 32),

                                  _buildActionButtons(isMobile),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ChoiceLuxTheme.richGold,
                        ),
                      ),
                    ),
                    error: (error, stack) =>
                        Center(child: Text('Error loading clients: $error')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ChoiceLuxTheme.platinumSilver.withValues(alpha:0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ChoiceLuxTheme.richGold.withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.assignment,
                  color: ChoiceLuxTheme.richGold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Step 1 of 1: Job Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ChoiceLuxTheme.softWhite,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fill in the job information below',
                      style: TextStyle(
                        fontSize: 14,
                        color: ChoiceLuxTheme.platinumSilver,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: ChoiceLuxTheme.richGold.withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ChoiceLuxTheme.richGold.withValues(alpha:0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${_completionPercentage.toInt()}%',
                  style: TextStyle(
                    color: ChoiceLuxTheme.richGold,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.platinumSilver.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _completionPercentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: ChoiceLuxTheme.richGold,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Completion status text
          Text(
            _getCompletionStatusText(),
            style: TextStyle(
              fontSize: 12,
              color: _completionPercentage == 100
                  ? ChoiceLuxTheme.successColor
                  : ChoiceLuxTheme.platinumSilver,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getCompletionStatusText() {
    if (_completionPercentage == 0) {
      return 'Start by selecting a client';
    } else if (_completionPercentage < 50) {
      return 'Keep going! Fill in the required fields';
    } else if (_completionPercentage < 100) {
      return 'Almost there! Complete the remaining fields';
    } else {
      return widget.jobId != null
          ? 'All required fields completed! Ready to update job'
          : 'All required fields completed! Ready to create job';
    }
  }

  Widget _buildFormSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ChoiceLuxTheme.platinumSilver.withValues(alpha:0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ChoiceLuxTheme.richGold.withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: ChoiceLuxTheme.richGold, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: ChoiceLuxTheme.softWhite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSearchableClientDropdown(List<dynamic> clients) {
    final filteredClients = clients.where((client) {
      if (_clientSearchQuery.isEmpty) return true;
      return client.companyName.toLowerCase().contains(
        _clientSearchQuery.toLowerCase(),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Client *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: ChoiceLuxTheme.softWhite,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ChoiceLuxTheme.platinumSilver.withValues(alpha:0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Search input
              TextFormField(
                controller: _clientSearchController,
                onChanged: (value) {
                  setState(() {
                    _clientSearchQuery = value;
                    _showClientDropdown = true;
                  });
                },
                onTap: () {
                  setState(() {
                    _showClientDropdown = true;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search for a client...',
                  hintStyle: TextStyle(
                    color: ChoiceLuxTheme.platinumSilver.withValues(alpha:0.7),
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: ChoiceLuxTheme.platinumSilver,
                  ),
                  suffixIcon: _selectedClientId != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _selectedClientId = null;
                              _clientSearchController.clear();
                              _clientSearchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                validator: (value) {
                  if (_selectedClientId == null) {
                    return 'Please select a client';
                  }
                  return null;
                },
              ),

              // Selected client display
              if (_selectedClientId != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ChoiceLuxTheme.richGold.withValues(alpha:0.1),
                    border: Border(
                      top: BorderSide(
                        color: ChoiceLuxTheme.platinumSilver.withValues(alpha:0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.business,
                        color: ChoiceLuxTheme.richGold,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          clients
                              .firstWhere(
                                (c) => c.id.toString() == _selectedClientId,
                              )
                              .companyName,
                          style: const TextStyle(
                            color: ChoiceLuxTheme.richGold,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Dropdown list
              if (_showClientDropdown && filteredClients.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: ChoiceLuxTheme.charcoalGray,
                    border: Border(
                      top: BorderSide(
                        color: ChoiceLuxTheme.platinumSilver.withValues(alpha:0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredClients.length,
                    itemBuilder: (context, index) {
                      final client = filteredClients[index];
                      return ListTile(
                        leading: const Icon(
                          Icons.business,
                          color: ChoiceLuxTheme.platinumSilver,
                        ),
                        title: Text(
                          client.companyName,
                          style: const TextStyle(
                            color: ChoiceLuxTheme.softWhite,
                          ),
                        ),
                        onTap: () {
                          _onClientChanged(client.id.toString());
                          _clientSearchController.text = client.companyName;
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAgentDropdown() {
    if (_selectedClientId == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ChoiceLuxTheme.charcoalGray.withValues(alpha:0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ChoiceLuxTheme.platinumSilver.withValues(alpha:0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: ChoiceLuxTheme.platinumSilver,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Please select a client first to choose an agent',
                style: TextStyle(
                  color: ChoiceLuxTheme.platinumSilver,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Consumer(
      builder: (context, ref, child) {
        // Guard against null client ID
        if (_selectedClientId == null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.charcoalGray.withValues(alpha:0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ChoiceLuxTheme.platinumSilver.withValues(alpha:0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: ChoiceLuxTheme.platinumSilver,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Please select a client first to choose an agent',
                    style: TextStyle(
                      color: ChoiceLuxTheme.platinumSilver,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final agentsAsync = ref.watch(
          agentsForClientProvider(_selectedClientId!),
        );

        return agentsAsync.when(
          data: (agents) => _buildDropdownField(
            label: 'Agent',
            hint: 'Select an agent (optional)',
            icon: Icons.person,
            value: _selectedAgentId,
            items: agents
                .map(
                  (agent) => DropdownMenuItem(
                    value: agent.id.toString(),
                    child: Text(agent.agentName),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedAgentId = value),
            isRequired: false,
          ),
          loading: () => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.charcoalGray.withValues(alpha:0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ChoiceLuxTheme.platinumSilver.withValues(alpha:0.2),
                width: 1,
              ),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ChoiceLuxTheme.richGold,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Text('Loading agents...'),
              ],
            ),
          ),
          error: (error, stack) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.errorColor.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ChoiceLuxTheme.errorColor.withValues(alpha:0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: ChoiceLuxTheme.errorColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Error loading agents',
                  style: TextStyle(
                    color: ChoiceLuxTheme.errorColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVehicleDropdown(List<dynamic> vehicles) {
    // Sort vehicles by make alphabetically
    final sortedVehicles = List.from(vehicles)
      ..sort((a, b) => (a.make ?? '').compareTo(b.make ?? ''));

    return _buildDropdownField(
      label: 'Vehicle *',
      hint: 'Select a vehicle',
      icon: Icons.directions_car,
      value: _selectedVehicleId,
      items: sortedVehicles.map((vehicle) {
        final hasValidLicense =
            vehicle.licenseExpiryDate != null &&
            vehicle.licenseExpiryDate!.isAfter(DateTime.now());

        return DropdownMenuItem(
          value: vehicle.id.toString(),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${vehicle.make} ${vehicle.model} - ${vehicle.regPlate}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!hasValidLicense)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: ChoiceLuxTheme.errorColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'EXP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedVehicleId = value),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a vehicle';
        }
        return null;
      },
    );
  }

  Widget _buildDriverDropdown(List<dynamic> allUsers) {
    return _buildDropdownField(
      label: 'Driver *',
      hint: 'Select a driver',
      icon: Icons.person,
      value: _selectedDriverId,
      items: allUsers.map((user) {
        final hasValidLicense =
            user.driverLicExp != null &&
            user.driverLicExp!.isAfter(DateTime.now());
        final hasValidPdp =
            user.pdpExp != null && user.pdpExp!.isAfter(DateTime.now());

        return DropdownMenuItem(
          value: user.id.toString(),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${user.displayName} (${user.role ?? 'No Role'})',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!hasValidLicense || !hasValidPdp)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: ChoiceLuxTheme.errorColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'EXP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedDriverId = value),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a driver';
        }
        return null;
      },
    );
  }

  Widget _buildLocationDropdown() {
    return _buildDropdownField(
      label: 'Branch (Location) *',
      hint: 'Select branch location',
      icon: Icons.location_on,
      value: _selectedLocation,
      items: const [
        DropdownMenuItem(value: 'Jhb', child: Text('Johannesburg (Jhb)')),
        DropdownMenuItem(value: 'Cpt', child: Text('Cape Town (Cpt)')),
        DropdownMenuItem(value: 'Dbn', child: Text('Durban (Dbn)')),
      ],
      onChanged: (value) => setState(() => _selectedLocation = value),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a branch location';
        }
        return null;
      },
    );
  }

  Widget _buildJobStartDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Job Start Date *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: ChoiceLuxTheme.softWhite,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectJobStartDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ChoiceLuxTheme.platinumSilver.withValues(alpha:0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: ChoiceLuxTheme.platinumSilver,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedJobStartDate != null
                        ? '${_selectedJobStartDate!.day}/${_selectedJobStartDate!.month}/${_selectedJobStartDate!.year}'
                        : 'Select job start date',
                    style: TextStyle(
                      color: _selectedJobStartDate != null
                          ? ChoiceLuxTheme.softWhite
                          : ChoiceLuxTheme.platinumSilver.withValues(alpha:0.7),
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: ChoiceLuxTheme.platinumSilver,
                ),
              ],
            ),
          ),
        ),
        if (_selectedJobStartDate == null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(
              'Please select a job start date',
              style: TextStyle(color: ChoiceLuxTheme.errorColor, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ChoiceLuxTheme.softWhite,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  color: ChoiceLuxTheme.errorColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: ChoiceLuxTheme.platinumSilver.withValues(alpha:0.7),
            ),
            prefixIcon: Icon(
              icon,
              color: ChoiceLuxTheme.platinumSilver,
              size: 20,
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ChoiceLuxTheme.platinumSilver.withValues(alpha:0.3),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ChoiceLuxTheme.platinumSilver.withValues(alpha:0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ChoiceLuxTheme.richGold, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ChoiceLuxTheme.errorColor,
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ChoiceLuxTheme.softWhite,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  color: ChoiceLuxTheme.errorColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: ChoiceLuxTheme.platinumSilver.withValues(alpha:0.7),
            ),
            prefixIcon: Icon(
              icon,
              color: ChoiceLuxTheme.platinumSilver,
              size: 20,
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ChoiceLuxTheme.platinumSilver.withValues(alpha:0.3),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ChoiceLuxTheme.platinumSilver.withValues(alpha:0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ChoiceLuxTheme.richGold, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          items: items,
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    // Get current user role
    final userProfile = ref.watch(currentUserProfileProvider);
    final isDriver = userProfile?.role?.toLowerCase() == 'driver';
    
    // Hide payment section from drivers
    if (isDriver) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.payment,
              color: ChoiceLuxTheme.platinumSilver,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Payment Collection',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ChoiceLuxTheme.softWhite,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ChoiceLuxTheme.platinumSilver.withValues(alpha:0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Switch(
                    value: _collectPayment,
                    onChanged: (value) =>
                        setState(() => _collectPayment = value),
                    activeColor: ChoiceLuxTheme.richGold,
                    activeTrackColor: ChoiceLuxTheme.richGold.withValues(alpha:0.3),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Driver needs to collect payment',
                      style: TextStyle(
                        color: ChoiceLuxTheme.softWhite,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ChoiceLuxTheme.platinumSilver.withValues(alpha:0.1),
          width: 1,
        ),
      ),
      child: isMobile
          ? Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _createJob,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ChoiceLuxTheme.richGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black,
                              ),
                            ),
                          )
                        : Text(
                            widget.jobId != null ? 'Update Job' : 'Create Job',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => widget.jobId != null
                              ? context.go('/jobs/${widget.jobId}/summary')
                              : context.go('/jobs'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ChoiceLuxTheme.platinumSilver,
                      side: BorderSide(
                        color: ChoiceLuxTheme.platinumSilver.withValues(alpha:0.3),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => widget.jobId != null
                            ? context.go('/jobs/${widget.jobId}/summary')
                            : context.go('/jobs'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ChoiceLuxTheme.platinumSilver,
                    side: BorderSide(
                      color: ChoiceLuxTheme.platinumSilver.withValues(alpha:0.3),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _createJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ChoiceLuxTheme.richGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black,
                            ),
                          ),
                        )
                      : Text(
                          widget.jobId != null ? 'Update Job' : 'Create Job',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
