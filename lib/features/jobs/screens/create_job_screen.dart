import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/jobs/models/job.dart';
import 'package:choice_lux_cars/features/jobs/providers/jobs_provider.dart';
import 'package:choice_lux_cars/features/clients/providers/clients_provider.dart';
import 'package:choice_lux_cars/features/vehicles/providers/vehicles_provider.dart';
import 'package:choice_lux_cars/features/users/providers/users_provider.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/shared/widgets/simple_app_bar.dart';
import 'package:uuid/uuid.dart';

class CreateJobScreen extends ConsumerStatefulWidget {
  const CreateJobScreen({super.key});

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
  
  // Form values
  String? _selectedClientId;
  String? _selectedAgentId;
  String? _selectedBranch;
  String? _selectedVehicleId;
  String? _selectedDriverId;
  DateTime? _selectedJobStartDate;
  bool _collectPayment = false;
  
  // Loading states
  bool _isLoading = false;
  bool _isSubmitting = false;
  
  // Filtered lists
  List<dynamic> _filteredClients = [];
  List<dynamic> _filteredAgents = [];
  List<dynamic> _filteredVehicles = [];
  List<dynamic> _filteredDrivers = [];
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    _passengerNameController.dispose();
    _passengerContactController.dispose();
    _pasCountController.dispose();
    _luggageCountController.dispose();
    _notesController.dispose();
    _paymentAmountController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load all data
      await Future.wait([
        ref.read(clientsProvider.notifier).fetchClients(),
        ref.read(vehiclesProvider.notifier).fetchVehicles(),
        ref.read(usersProvider.notifier).fetchUsers(),
      ]);
      
      _filteredClients = ref.read(clientsProvider);
      _filteredVehicles = ref.read(vehiclesProvider);
      _filteredDrivers = ref.read(usersProvider)
          .where((user) => user.role?.toLowerCase() == 'driver')
          .toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _onClientChanged(String? clientId) {
    setState(() {
      _selectedClientId = clientId;
      _selectedAgentId = null; // Reset agent when client changes
      
      if (clientId != null) {
        final client = ref.read(clientsProvider).firstWhere((c) => c.id == clientId);
        _filteredAgents = client.agents ?? [];
      } else {
        _filteredAgents = [];
      }
    });
  }
  
  Future<void> _selectJobStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
      
      final job = Job(
        id: const Uuid().v4(),
        clientId: _selectedClientId!,
        agentId: _selectedAgentId,
        branch: _selectedBranch!,
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
        pasCount: int.parse(_pasCountController.text),
        luggageCount: int.parse(_luggageCountController.text),
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
        collectPayment: _collectPayment,
        paymentAmount: _collectPayment && _paymentAmountController.text.isNotEmpty
            ? double.parse(_paymentAmountController.text)
            : null,
        status: 'open',
        createdBy: currentUser.id,
        createdAt: DateTime.now(),
      );
      
      await ref.read(jobsProvider.notifier).createJob(job);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job created successfully!')),
        );
        context.go('/jobs'); // Navigate to jobs list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating job: $e')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Scaffold(
      appBar: SimpleAppBar(
        title: 'Create New Job',
        subtitle: 'Step 1: Job Details',
        showBackButton: true,
        onBackPressed: () => context.go('/jobs'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection('Client & Agent Selection', [
                        _buildClientDropdown(),
                        const SizedBox(height: 16),
                        _buildAgentDropdown(),
                      ]),
                      
                      const SizedBox(height: 32),
                      
                      _buildSection('Job Details', [
                        _buildBranchDropdown(),
                        const SizedBox(height: 16),
                        _buildVehicleDropdown(),
                        const SizedBox(height: 16),
                        _buildDriverDropdown(),
                        const SizedBox(height: 16),
                        _buildJobStartDatePicker(),
                      ]),
                      
                      const SizedBox(height: 32),
                      
                      _buildSection('Passenger Details', [
                        _buildTextField(
                          controller: _passengerNameController,
                          label: 'Passenger Name',
                          hint: 'Enter passenger name (optional)',
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _passengerContactController,
                          label: 'Contact Number',
                          hint: 'Enter contact number (optional)',
                          icon: Icons.phone,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _pasCountController,
                                label: 'Number of Passengers',
                                hint: 'Enter passenger count',
                                icon: Icons.people,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter passenger count';
                                  }
                                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                                    return 'Please enter a valid number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _luggageCountController,
                                label: 'Number of Bags',
                                hint: 'Enter luggage count',
                                icon: Icons.work,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter luggage count';
                                  }
                                  if (int.tryParse(value) == null || int.parse(value) < 0) {
                                    return 'Please enter a valid number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ]),
                      
                      const SizedBox(height: 32),
                      
                      _buildSection('Payment & Notes', [
                        _buildPaymentSection(),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _notesController,
                          label: 'Notes',
                          hint: 'Enter flight details and other relevant information',
                          icon: Icons.note,
                          maxLines: 3,
                        ),
                      ]),
                      
                      const SizedBox(height: 32),
                      
                      _buildActionButtons(isMobile),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
  
  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ChoiceLuxTheme.richGold,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
  
  Widget _buildClientDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedClientId,
      decoration: const InputDecoration(
        labelText: 'Client',
        hintText: 'Select a client',
        prefixIcon: Icon(Icons.business),
        border: OutlineInputBorder(),
      ),
      items: _filteredClients.map((client) {
        return DropdownMenuItem(
          value: client.id,
          child: Text(client.companyName ?? 'Unknown Client'),
        );
      }).toList(),
      onChanged: _onClientChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a client';
        }
        return null;
      },
    );
  }
  
  Widget _buildAgentDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedAgentId,
      decoration: const InputDecoration(
        labelText: 'Agent',
        hintText: 'Select an agent',
        prefixIcon: Icon(Icons.person),
        border: OutlineInputBorder(),
      ),
      items: _filteredAgents.map((agent) {
        return DropdownMenuItem(
          value: agent.id,
          child: Text('${agent.firstName} ${agent.lastName}'),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedAgentId = value),
    );
  }
  
  Widget _buildBranchDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedBranch,
      decoration: const InputDecoration(
        labelText: 'Branch',
        hintText: 'Select a branch',
        prefixIcon: Icon(Icons.location_on),
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'Jhb', child: Text('Johannesburg (Jhb)')),
        DropdownMenuItem(value: 'Cpt', child: Text('Cape Town (Cpt)')),
        DropdownMenuItem(value: 'Dbn', child: Text('Durban (Dbn)')),
      ],
      onChanged: (value) => setState(() => _selectedBranch = value),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a branch';
        }
        return null;
      },
    );
  }
  
  Widget _buildVehicleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedVehicleId,
      decoration: const InputDecoration(
        labelText: 'Vehicle',
        hintText: 'Select a vehicle',
        prefixIcon: Icon(Icons.directions_car),
        border: OutlineInputBorder(),
      ),
      items: _filteredVehicles.map((vehicle) {
        final hasValidLicense = vehicle.licenseDiskExpiryDate != null &&
            vehicle.licenseDiskExpiryDate!.isAfter(DateTime.now());
        
        return DropdownMenuItem(
          value: vehicle.id,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${vehicle.make} ${vehicle.model} - ${vehicle.registrationNumber}',
                ),
              ),
              if (!hasValidLicense)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: ChoiceLuxTheme.errorColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'EXP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
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
  
  Widget _buildDriverDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedDriverId,
      decoration: const InputDecoration(
        labelText: 'Driver',
        hintText: 'Select a driver',
        prefixIcon: Icon(Icons.person),
        border: OutlineInputBorder(),
      ),
      items: _filteredDrivers.map((driver) {
        final hasValidLicense = driver.driversLicenseExpiryDate != null &&
            driver.driversLicenseExpiryDate!.isAfter(DateTime.now());
        final hasValidPdp = driver.pdpExpiryDate != null &&
            driver.pdpExpiryDate!.isAfter(DateTime.now());
        
        return DropdownMenuItem(
          value: driver.id,
          child: Row(
            children: [
              Expanded(
                child: Text('${driver.firstName} ${driver.lastName}'),
              ),
              if (!hasValidLicense || !hasValidPdp)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: ChoiceLuxTheme.errorColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'EXP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
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
  
  Widget _buildJobStartDatePicker() {
    return InkWell(
      onTap: _selectJobStartDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Job Start Date',
          hintText: 'Select job start date',
          prefixIcon: Icon(Icons.calendar_today),
          border: OutlineInputBorder(),
        ),
        child: Text(
          _selectedJobStartDate != null
              ? '${_selectedJobStartDate!.day}/${_selectedJobStartDate!.month}/${_selectedJobStartDate!.year}'
              : 'Select date',
          style: TextStyle(
            color: _selectedJobStartDate != null
                ? Colors.black
                : Colors.grey,
          ),
        ),
      ),
    );
  }
  
  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _collectPayment,
              onChanged: (value) => setState(() => _collectPayment = value ?? false),
            ),
            const Text('Driver needs to collect payment'),
          ],
        ),
        if (_collectPayment) ...[
          const SizedBox(height: 16),
          _buildTextField(
            controller: _paymentAmountController,
            label: 'Payment Amount',
            hint: 'Enter amount to collect',
            icon: Icons.payment,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (_collectPayment && (value == null || value.isEmpty)) {
                return 'Please enter payment amount';
              }
              if (_collectPayment && value != null && value.isNotEmpty) {
                if (double.tryParse(value) == null || double.parse(value) <= 0) {
                  return 'Please enter a valid amount';
                }
              }
              return null;
            },
          ),
        ],
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
  
  Widget _buildActionButtons(bool isMobile) {
    return Row(
      mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: _isSubmitting ? null : () => context.go('/jobs'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _createJob,
          style: ElevatedButton.styleFrom(
            backgroundColor: ChoiceLuxTheme.richGold,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Create Job'),
        ),
      ],
    );
  }
} 