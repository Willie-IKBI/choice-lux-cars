import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/quotes/models/quote.dart';
import 'package:choice_lux_cars/features/quotes/providers/quotes_provider.dart';
import 'package:choice_lux_cars/features/clients/providers/clients_provider.dart';
import 'package:choice_lux_cars/features/clients/providers/agents_provider.dart';
import 'package:choice_lux_cars/features/vehicles/providers/vehicles_provider.dart';
import 'package:choice_lux_cars/features/users/providers/users_provider.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';

class CreateQuoteScreen extends ConsumerStatefulWidget {
  final String? quoteId; // null for create, non-null for edit
  
  const CreateQuoteScreen({
    super.key,
    this.quoteId,
  });

  @override
  ConsumerState<CreateQuoteScreen> createState() => _CreateQuoteScreenState();
}

class _CreateQuoteScreenState extends ConsumerState<CreateQuoteScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _passengerNameController = TextEditingController();
  final _passengerContactController = TextEditingController();
  final _pasCountController = TextEditingController();
  final _luggageController = TextEditingController();
  final _notesController = TextEditingController();
  final _quoteTitleController = TextEditingController();
  final _quoteDescriptionController = TextEditingController();
  final _clientSearchController = TextEditingController();
  
  // Form values
  String? _selectedClientId;
  String? _selectedAgentId;
  String? _selectedVehicleId;
  String? _selectedDriverId;
  String? _selectedLocation; // Branch location (Jhb, Cpt, Dbn)
  DateTime? _selectedJobDate;
  String _selectedVehicleType = '';
  
  // Loading states
  bool _isLoading = false;
  bool _isSubmitting = false;
  
  // Search states
  String _clientSearchQuery = '';
  bool _showClientDropdown = false;

  // Calculate completion percentage
  double get _completionPercentage {
    int completedFields = 0;
    int totalFields = 8; // Required fields for quote creation
    
    if (_selectedClientId != null) completedFields++;
    if (_selectedVehicleId != null) completedFields++;
    if (_selectedDriverId != null) completedFields++;
    if (_selectedLocation != null) completedFields++;
    if (_selectedJobDate != null) completedFields++;
    if (_pasCountController.text.isNotEmpty) completedFields++;
    if (_luggageController.text.isNotEmpty) completedFields++;
    if (_selectedVehicleType.isNotEmpty) completedFields++;
    
    return completedFields / totalFields;
  }

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.quoteId != null) {
      // TODO: Load existing quote data for editing
      // This will be implemented when we add quote editing functionality
    }
  }

  @override
  void dispose() {
    _passengerNameController.dispose();
    _passengerContactController.dispose();
    _pasCountController.dispose();
    _luggageController.dispose();
    _notesController.dispose();
    _quoteTitleController.dispose();
    _quoteDescriptionController.dispose();
    _clientSearchController.dispose();
    super.dispose();
  }

  Future<void> _selectJobDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedJobDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _selectedJobDate = picked;
      });
    }
  }
  
  Future<void> _createQuote() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final currentUser = ref.read(currentUserProfileProvider);
      if (currentUser == null) throw Exception('User not authenticated');
      
      final isEditing = widget.quoteId != null;
      
      if (isEditing) {
        // TODO: Update existing quote
        // This will be implemented when we add quote editing functionality
      } else {
        // Create new quote
        final quote = Quote(
          id: '', // Let database auto-generate the ID
          clientId: _selectedClientId!,
          agentId: _selectedAgentId,
          vehicleId: _selectedVehicleId!,
          driverId: _selectedDriverId!,
          jobDate: _selectedJobDate!,
          vehicleType: _selectedVehicleType,
          quoteStatus: 'draft',
          pasCount: double.parse(_pasCountController.text),
          luggage: _luggageController.text.trim(),
          passengerName: _passengerNameController.text.trim().isEmpty 
              ? null 
              : _passengerNameController.text.trim(),
          passengerContact: _passengerContactController.text.trim().isEmpty 
              ? null 
              : _passengerContactController.text.trim(),
          notes: _notesController.text.trim().isEmpty 
              ? null 
              : _notesController.text.trim(),
          quotePdf: null, // Will be generated later
          quoteDate: DateTime.now(),
          quoteAmount: null, // Will be calculated from transport details
          quoteTitle: _quoteTitleController.text.trim().isEmpty 
              ? null 
              : _quoteTitleController.text.trim(),
          quoteDescription: _quoteDescriptionController.text.trim().isEmpty 
              ? null 
              : _quoteDescriptionController.text.trim(),
          location: _selectedLocation,
          // createdBy: currentUser.id, // Remove created_by field as it doesn't exist in database
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        final createdQuote = await ref.read(quotesProvider.notifier).createQuote(quote);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quote created successfully! Moving to transport details...'),
              backgroundColor: ChoiceLuxTheme.successColor,
            ),
          );
          // Navigate to transport details screen for Step 2
          context.go('/quotes/${createdQuote['id']}/transport-details');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating quote: $e'),
            backgroundColor: ChoiceLuxTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get responsive breakpoint
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = _getMaxWidth(screenWidth);
    
    return Scaffold(
      appBar: LuxuryAppBar(
        title: widget.quoteId != null ? 'Edit Quote' : 'Create New Quote',
        subtitle: widget.quoteId != null ? 'Update Quote Details' : 'Step 1: Quote Details',
        showBackButton: true,
        onBackPressed: () => widget.quoteId != null 
            ? context.go('/quotes/${widget.quoteId}/summary')
            : context.go('/quotes'),
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final clientsAsync = ref.watch(clientsProvider);
          final vehiclesState = ref.watch(vehiclesProvider);
          final users = ref.watch(usersProvider);
          
          if (vehiclesState.isLoading || users.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(ChoiceLuxTheme.richGold),
              ),
            );
          }
          
          if (vehiclesState.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: ChoiceLuxTheme.errorColor),
                  const SizedBox(height: 16),
                  Text('Error loading vehicles: ${vehiclesState.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(vehiclesProvider.notifier).fetchVehicles(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          return clientsAsync.when(
            data: (clients) => _buildForm(clients, vehiclesState.vehicles, users),
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(ChoiceLuxTheme.richGold),
              ),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: ChoiceLuxTheme.errorColor),
                  const SizedBox(height: 16),
                  Text('Error loading clients: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(clientsNotifierProvider.notifier).refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm(List<dynamic> clients, List<dynamic> vehicles, List<dynamic> users) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress indicator
                Container(
                  width: double.infinity,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _completionPercentage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: ChoiceLuxTheme.richGold,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_completionPercentage * 100).toInt()}% Complete',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),

                // Client Selection
                _buildClientSelection(clients),
                const SizedBox(height: 24),

                // Agent Selection (auto-populated from client)
                _buildAgentSelection(clients),
                const SizedBox(height: 24),

                // Vehicle Selection
                _buildVehicleSelection(vehicles),
                const SizedBox(height: 24),

                // Driver Selection
                _buildDriverSelection(users),
                const SizedBox(height: 24),

                // Location and Date
                Row(
                  children: [
                    Expanded(child: _buildLocationSelection()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDateSelection()),
                  ],
                ),
                const SizedBox(height: 24),

                // Passenger Details
                _buildPassengerDetails(),
                const SizedBox(height: 24),

                // Quote Details
                _buildQuoteDetails(),
                const SizedBox(height: 24),

                // Notes
                _buildNotesSection(),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _createQuote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ChoiceLuxTheme.richGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Create Quote & Continue to Transport Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClientSelection(List<dynamic> clients) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Client *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedClientId,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            hintText: 'Select a client',
          ),
          items: clients.map((client) {
            return DropdownMenuItem(
              value: client.id.toString(),
              child: Text(client.companyName ?? 'Unknown Client'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedClientId = value;
              _selectedAgentId = null; // Reset agent when client changes
            });
            
            // Auto-select first agent for this client
            if (value != null) {
              final selectedClient = clients.firstWhere((c) => c.id.toString() == value);
              if (selectedClient.agents != null && selectedClient.agents.isNotEmpty) {
                setState(() {
                  _selectedAgentId = selectedClient.agents.first.id.toString();
                });
              }
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a client';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAgentSelection(List<dynamic> clients) {
    if (_selectedClientId == null || clients.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final selectedClient = clients.firstWhere(
      (client) => client.id.toString() == _selectedClientId,
      orElse: () => clients.first,
    );
    
    final agents = selectedClient?.agents ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Agent',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedAgentId,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            hintText: 'Select an agent (optional)',
          ),
          items: agents.map((agent) {
            return DropdownMenuItem(
              value: agent.id.toString(),
              child: Text(agent.agentName ?? 'Unknown Agent'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedAgentId = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildVehicleSelection(List<dynamic> vehicles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vehicle *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedVehicleId,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            hintText: 'Select a vehicle',
          ),
          items: vehicles.map((vehicle) {
            final isExpired = vehicle.licenseExpiryDate != null && 
                vehicle.licenseExpiryDate.isBefore(DateTime.now());
            
            return DropdownMenuItem(
              value: vehicle.id.toString(),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${vehicle.make} ${vehicle.model} (${vehicle.regPlate})',
                      style: TextStyle(
                        color: isExpired ? ChoiceLuxTheme.errorColor : null,
                      ),
                    ),
                  ),
                  if (isExpired)
                    const Icon(
                      Icons.warning,
                      color: ChoiceLuxTheme.errorColor,
                      size: 16,
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedVehicleId = value;
              // Auto-set vehicle type
              if (value != null) {
                final selectedVehicle = vehicles.firstWhere((v) => v.id.toString() == value);
                _selectedVehicleType = '${selectedVehicle.make} ${selectedVehicle.model}';
              }
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a vehicle';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDriverSelection(List<dynamic> users) {
    final drivers = users.where((user) => 
        user.role?.toLowerCase() == 'driver' && 
        user.status == 'active'
    ).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Driver *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedDriverId,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            hintText: 'Select a driver',
          ),
          items: drivers.map((driver) {
                         final isPdpExpired = driver.pdpExpDate != null && 
                 DateTime.parse(driver.pdpExpDate).isBefore(DateTime.now());
                         final isLicenseExpired = driver.trafExpDate != null && 
                 DateTime.parse(driver.trafExpDate).isBefore(DateTime.now());
            
            return DropdownMenuItem(
              value: driver.id.toString(),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${driver.displayName}',
                      style: TextStyle(
                        color: (isPdpExpired || isLicenseExpired) ? ChoiceLuxTheme.errorColor : null,
                      ),
                    ),
                  ),
                  if (isPdpExpired || isLicenseExpired)
                    const Icon(
                      Icons.warning,
                      color: ChoiceLuxTheme.errorColor,
                      size: 16,
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedDriverId = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a driver';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLocationSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedLocation,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            hintText: 'Select location',
          ),
          items: const [
            DropdownMenuItem(value: 'Jhb', child: Text('Johannesburg (Jhb)')),
            DropdownMenuItem(value: 'Cpt', child: Text('Cape Town (Cpt)')),
            DropdownMenuItem(value: 'Dbn', child: Text('Durban (Dbn)')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedLocation = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a location';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Job Date *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectJobDate,
          child: InputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: 'Select job date',
              suffixIcon: const Icon(Icons.calendar_today),
            ),
            child: Text(
              _selectedJobDate != null
                  ? '${_selectedJobDate!.day}/${_selectedJobDate!.month}/${_selectedJobDate!.year}'
                  : '',
              style: TextStyle(
                color: _selectedJobDate != null ? Colors.black : Colors.grey[500],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPassengerDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Passenger Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _passengerNameController,
                decoration: const InputDecoration(
                  labelText: 'Passenger Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _passengerContactController,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _pasCountController,
                decoration: const InputDecoration(
                  labelText: 'Number of Passengers *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter passenger count';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _luggageController,
                decoration: const InputDecoration(
                  labelText: 'Luggage Description *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter luggage description';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuoteDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quote Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _quoteTitleController,
          decoration: const InputDecoration(
            labelText: 'Quote Title',
            border: OutlineInputBorder(),
            hintText: 'e.g., Airport Transfer - JHB to CPT',
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _quoteDescriptionController,
          decoration: const InputDecoration(
            labelText: 'Quote Description',
            border: OutlineInputBorder(),
            hintText: 'Brief description of the quote',
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Notes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notes',
            border: OutlineInputBorder(),
            hintText: 'Flight details, special requirements, etc.',
          ),
          maxLines: 4,
        ),
      ],
    );
  }

  double _getMaxWidth(double screenWidth) {
    if (screenWidth < 600) {
      return screenWidth - 32; // Mobile: full width minus padding
    } else if (screenWidth < 900) {
      return 600; // Tablet: 600px max
    } else if (screenWidth < 1200) {
      return 800; // Small desktop: 800px max
    } else {
      return 1000; // Large desktop: 1000px max
    }
  }
}
