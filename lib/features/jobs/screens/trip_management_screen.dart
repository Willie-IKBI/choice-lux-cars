import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/jobs/models/job.dart';
import 'package:choice_lux_cars/features/jobs/models/trip.dart';
import 'package:choice_lux_cars/features/jobs/providers/jobs_provider.dart';
import 'package:choice_lux_cars/shared/widgets/simple_app_bar.dart';
import 'package:uuid/uuid.dart';

class TripManagementScreen extends ConsumerStatefulWidget {
  final String jobId;
  
  const TripManagementScreen({
    super.key,
    required this.jobId,
  });

  @override
  ConsumerState<TripManagementScreen> createState() => _TripManagementScreenState();
}

class _TripManagementScreenState extends ConsumerState<TripManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for new trip form
  final _pickUpAddressController = TextEditingController();
  final _dropOffAddressController = TextEditingController();
  final _notesController = TextEditingController();
  final _amountController = TextEditingController();
  
  // Form values
  DateTime? _selectedTripDateTime;
  bool _isAddingTrip = false;
  bool _isLoading = false;
  bool _isSubmitting = false;
  
  // Editing state
  Trip? _editingTrip;
  
  @override
  void initState() {
    super.initState();
    _loadTrips();
  }
  
  @override
  void dispose() {
    _pickUpAddressController.dispose();
    _dropOffAddressController.dispose();
    _notesController.dispose();
    _amountController.dispose();
    super.dispose();
  }
  
  Future<void> _loadTrips() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(tripsProvider.notifier).fetchTripsForJob(widget.jobId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading trips: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _selectTripDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      
      if (pickedTime != null) {
        setState(() {
          _selectedTripDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }
  
  void _startAddingTrip() {
    setState(() {
      _isAddingTrip = true;
      _editingTrip = null;
      _clearForm();
    });
  }
  
  void _startEditingTrip(Trip trip) {
    setState(() {
      _isAddingTrip = true;
      _editingTrip = trip;
      _selectedTripDateTime = trip.tripDateTime;
      _pickUpAddressController.text = trip.pickUpAddress;
      _dropOffAddressController.text = trip.dropOffAddress;
      _notesController.text = trip.notes ?? '';
      _amountController.text = trip.amount.toString();
    });
  }
  
  void _cancelEditing() {
    setState(() {
      _isAddingTrip = false;
      _editingTrip = null;
      _clearForm();
    });
  }
  
  void _clearForm() {
    _selectedTripDateTime = null;
    _pickUpAddressController.clear();
    _dropOffAddressController.clear();
    _notesController.clear();
    _amountController.clear();
  }
  
  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final trip = Trip(
        id: _editingTrip?.id ?? const Uuid().v4(),
        jobId: widget.jobId,
        tripDateTime: _selectedTripDateTime!,
        pickUpAddress: _pickUpAddressController.text.trim(),
        dropOffAddress: _dropOffAddressController.text.trim(),
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
        amount: double.parse(_amountController.text),
        createdAt: _editingTrip?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      if (_editingTrip != null) {
        await ref.read(tripsProvider.notifier).updateTrip(trip);
      } else {
        await ref.read(tripsProvider.notifier).addTrip(trip);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_editingTrip != null 
                ? 'Trip updated successfully!' 
                : 'Trip added successfully!'),
          ),
        );
        _cancelEditing();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving trip: $e')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
  
  Future<void> _deleteTrip(Trip trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: Text('Are you sure you want to delete this trip?\n\n${trip.shortSummary}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: ChoiceLuxTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await ref.read(tripsProvider.notifier).deleteTrip(trip.id, widget.jobId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trip deleted successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting trip: $e')),
          );
        }
      }
    }
  }
  
  Future<void> _confirmTrips() async {
    final trips = ref.read(tripsProvider);
    if (trips.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one trip before confirming')),
      );
      return;
    }
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Trips'),
        content: Text('Are you sure you want to confirm all ${trips.length} trips for this job?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ChoiceLuxTheme.richGold,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      // Navigate to job summary screen
      context.go('/jobs/${widget.jobId}/summary');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final trips = ref.watch(tripsProvider);
    final totalAmount = ref.watch(tripsProvider.notifier).totalAmount;
    
    return Scaffold(
      appBar: SimpleAppBar(
        title: 'Trip Management',
        subtitle: 'Step 2: Transport Details',
        showBackButton: true,
        onBackPressed: () => context.go('/jobs'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header with trip count and total amount
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                    border: Border(
                      bottom: BorderSide(
                        color: ChoiceLuxTheme.richGold.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${trips.length} Trip${trips.length != 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Total Amount: R${totalAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                color: ChoiceLuxTheme.richGold,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _startAddingTrip,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Trip'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ChoiceLuxTheme.richGold,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Trip form (when adding/editing)
                if (_isAddingTrip) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.withOpacity(0.3)),
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _editingTrip != null ? 'Edit Trip' : 'Add New Trip',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Date and time picker
                          InkWell(
                            onTap: _selectTripDateTime,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date & Time',
                                hintText: 'Select date and time',
                                prefixIcon: Icon(Icons.schedule),
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _selectedTripDateTime != null
                                    ? '${_selectedTripDateTime!.day}/${_selectedTripDateTime!.month}/${_selectedTripDateTime!.year} at ${_selectedTripDateTime!.hour.toString().padLeft(2, '0')}:${_selectedTripDateTime!.minute.toString().padLeft(2, '0')}'
                                    : 'Select date and time',
                                style: TextStyle(
                                  color: _selectedTripDateTime != null
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Addresses
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _pickUpAddressController,
                                  decoration: const InputDecoration(
                                    labelText: 'Pick-up Address',
                                    hintText: 'Enter pick-up address',
                                    prefixIcon: Icon(Icons.location_on),
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter pick-up address';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _dropOffAddressController,
                                  decoration: const InputDecoration(
                                    labelText: 'Drop-off Address',
                                    hintText: 'Enter drop-off address',
                                    prefixIcon: Icon(Icons.location_on),
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter drop-off address';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Notes and amount
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _notesController,
                                  decoration: const InputDecoration(
                                    labelText: 'Notes',
                                    hintText: 'Enter trip notes (optional)',
                                    prefixIcon: Icon(Icons.note),
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _amountController,
                                  decoration: const InputDecoration(
                                    labelText: 'Amount',
                                    hintText: 'Enter amount',
                                    prefixIcon: Icon(Icons.payment),
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter amount';
                                    }
                                    if (double.tryParse(value) == null || double.parse(value) <= 0) {
                                      return 'Please enter a valid amount';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Action buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: _isSubmitting ? null : _cancelEditing,
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: _isSubmitting ? null : _saveTrip,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ChoiceLuxTheme.richGold,
                                  foregroundColor: Colors.white,
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
                                    : Text(_editingTrip != null ? 'Update Trip' : 'Add Trip'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                
                // Trips list
                Expanded(
                  child: trips.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.route,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No trips added yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Click "Add Trip" to get started',
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: trips.length,
                          itemBuilder: (context, index) {
                            final trip = trips[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(
                                  trip.shortSummary,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Text('Pick-up: ${trip.pickUpAddress}'),
                                    Text('Drop-off: ${trip.dropOffAddress}'),
                                    if (trip.notes != null && trip.notes!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Notes: ${trip.notes}',
                                        style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Text(
                                      'Amount: R${trip.amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: ChoiceLuxTheme.richGold,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'edit':
                                        _startEditingTrip(trip);
                                        break;
                                      case 'delete':
                                        _deleteTrip(trip);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                
                // Bottom action bar
                if (trips.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey.withOpacity(0.3)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Total: R${totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _confirmTrips,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ChoiceLuxTheme.richGold,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                          child: const Text('Confirm All Trips'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
} 