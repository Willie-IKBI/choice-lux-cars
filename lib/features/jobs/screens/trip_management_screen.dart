import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/app/theme.dart';

import 'package:choice_lux_cars/features/jobs/models/trip.dart';
import 'package:choice_lux_cars/features/jobs/providers/jobs_provider.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';


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
      _selectedTripDateTime = trip.pickupDate;
      _pickUpAddressController.text = trip.pickupLocation;
      _dropOffAddressController.text = trip.dropoffLocation;
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
         id: _editingTrip?.id ?? '',
         jobId: widget.jobId,
        pickupDate: _selectedTripDateTime!,
        pickupLocation: _pickUpAddressController.text.trim(),
        dropoffLocation: _dropOffAddressController.text.trim(),
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
        amount: double.parse(_amountController.text),
        status: _editingTrip?.status,
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
            backgroundColor: ChoiceLuxTheme.richGold,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        );
        _cancelEditing();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving trip: $e'),
            backgroundColor: ChoiceLuxTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
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
            SnackBar(
              content: const Text('Trip deleted successfully!'),
              backgroundColor: ChoiceLuxTheme.richGold,
              behavior: SnackBarBehavior.floating,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting trip: $e'),
              backgroundColor: ChoiceLuxTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          );
        }
      }
    }
  }
  
  Future<void> _confirmTrips() async {
    final trips = ref.read(tripsProvider);
    if (trips.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one trip before confirming'),
          backgroundColor: ChoiceLuxTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
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
      try {
        // Calculate total amount from all trips
        final totalAmount = trips.fold(0.0, (sum, trip) => sum + trip.amount);
        
        // Update the job with the total payment amount
        await ref.read(jobsProvider.notifier).updateJobPaymentAmount(widget.jobId, totalAmount);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Trips confirmed! Total amount: R${totalAmount.toStringAsFixed(2)}'),
              backgroundColor: ChoiceLuxTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          );
          
          // Navigate to job summary screen
          context.go('/jobs/${widget.jobId}/summary');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error confirming trips: $e'),
              backgroundColor: ChoiceLuxTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          );
        }
      }
    }
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ChoiceLuxTheme.softWhite,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7),
            ),
            prefixIcon: Icon(
              icon,
              color: ChoiceLuxTheme.richGold,
              size: 20,
            ),
            filled: true,
            fillColor: const Color(0xFF0A0A0A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ChoiceLuxTheme.richGold,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildEnhancedDateTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date & Time',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ChoiceLuxTheme.softWhite,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectTripDateTime,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: ChoiceLuxTheme.richGold,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedTripDateTime != null
                        ? '${_selectedTripDateTime!.day}/${_selectedTripDateTime!.month}/${_selectedTripDateTime!.year} at ${_selectedTripDateTime!.hour.toString().padLeft(2, '0')}:${_selectedTripDateTime!.minute.toString().padLeft(2, '0')}'
                        : 'Select date and time',
                    style: TextStyle(
                      color: _selectedTripDateTime != null
                          ? ChoiceLuxTheme.softWhite
                          : ChoiceLuxTheme.platinumSilver.withOpacity(0.7),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: ChoiceLuxTheme.platinumSilver,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTripDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: ChoiceLuxTheme.platinumSilver),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: ChoiceLuxTheme.platinumSilver,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: ChoiceLuxTheme.softWhite,
            ),
          ),
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final trips = ref.watch(tripsProvider);
    final totalAmount = ref.watch(tripsProvider.notifier).totalAmount;
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    // Calculate completion percentage based on trips
    final completionPercentage = trips.isEmpty ? 0 : 100;
    final completionMessage = trips.isEmpty 
        ? 'Add at least one trip to complete this step'
        : 'All trips added successfully!';
    
    return Scaffold(
      appBar: LuxuryAppBar(
        title: 'Trip Management',
        subtitle: 'Step 2: Transport Details',
        showBackButton: true,
        onBackPressed: () => context.go('/jobs'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Enhanced Progress indicator for Step 2
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ChoiceLuxTheme.charcoalGray,
                          ChoiceLuxTheme.charcoalGray.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ChoiceLuxTheme.richGold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.route,
                            color: ChoiceLuxTheme.richGold,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Step 2: Transport Details',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: ChoiceLuxTheme.softWhite,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                completionMessage,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: ChoiceLuxTheme.platinumSilver,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                ChoiceLuxTheme.richGold,
                                ChoiceLuxTheme.richGold.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '${completionPercentage}%',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Enhanced Trips Overview Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ChoiceLuxTheme.richGold.withOpacity(0.1),
                          ChoiceLuxTheme.richGold.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: ChoiceLuxTheme.richGold.withOpacity(0.2),
                      ),
                    ),
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${trips.length} Trip${trips.length != 1 ? 's' : ''}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: ChoiceLuxTheme.softWhite,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total Amount: R${totalAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: ChoiceLuxTheme.richGold,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                ChoiceLuxTheme.richGold,
                                ChoiceLuxTheme.richGold.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _startAddingTrip,
                            icon: const Icon(Icons.add, size: 20),
                            label: const Text('Add Trip', style: TextStyle(fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Collapsible Add Trip Form
                  if (_isAddingTrip) ...[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Form header
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _editingTrip != null ? Icons.edit : Icons.add,
                                  color: ChoiceLuxTheme.richGold,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _editingTrip != null ? 'Edit Trip' : 'Add New Trip',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: ChoiceLuxTheme.softWhite,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: _cancelEditing,
                                  icon: const Icon(Icons.close, color: ChoiceLuxTheme.platinumSilver),
                                ),
                              ],
                            ),
                          ),
                          // Form content with better spacing
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Date & Time picker with enhanced styling
                                  _buildEnhancedDateTimePicker(),
                                  const SizedBox(height: 24),
                                  
                                  // Address fields in a row for desktop
                                  Row(
                                    children: [
                                      Expanded(child: _buildEnhancedTextField(
                                        controller: _pickUpAddressController,
                                        label: 'Pick-up Address',
                                        hint: 'Enter pick-up address',
                                        icon: Icons.location_on,
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return 'Please enter pick-up address';
                                          }
                                          return null;
                                        },
                                      )),
                                      const SizedBox(width: 16),
                                      Expanded(child: _buildEnhancedTextField(
                                        controller: _dropOffAddressController,
                                        label: 'Drop-off Address',
                                        hint: 'Enter drop-off address',
                                        icon: Icons.location_on,
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return 'Please enter drop-off address';
                                          }
                                          return null;
                                        },
                                      )),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Notes and Amount in a row
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: _buildEnhancedTextField(
                                          controller: _notesController,
                                          label: 'Notes',
                                          hint: 'Enter trip notes (optional)',
                                          icon: Icons.note,
                                          maxLines: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 1,
                                        child: _buildEnhancedTextField(
                                          controller: _amountController,
                                          label: 'Amount',
                                          hint: 'Enter amount',
                                          icon: Icons.payment,
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
                                  const SizedBox(height: 24),
                                  
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
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(12)),
                                          ),
                                        ),
                                        child: _isSubmitting
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
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
                      ),
                    ),
                  ],
                  
                  // Enhanced Trips List
                  trips.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Icon(
                                  Icons.route,
                                  size: 64,
                                  color: ChoiceLuxTheme.richGold.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'No trips added yet',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: ChoiceLuxTheme.softWhite,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Click "Add Trip" to create your first transport entry',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: ChoiceLuxTheme.platinumSilver,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              ElevatedButton.icon(
                                onPressed: _startAddingTrip,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Your First Trip'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ChoiceLuxTheme.richGold,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            // Trip cards with enhanced styling
                            ...trips.asMap().entries.map((entry) {
                              final index = entry.key;
                              final trip = entry.value;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A1A),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF4A4A4A),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // Trip header with route summary
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: ChoiceLuxTheme.richGold.withOpacity(0.05),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(16),
                                          topRight: Radius.circular(16),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // Trip number badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: ChoiceLuxTheme.richGold,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'Trip ${index + 1}',
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          // Route summary
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${trip.pickupLocation.split(',').first} to ${trip.dropoffLocation.split(',').first}',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                    color: ChoiceLuxTheme.softWhite,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  trip.formattedDateTime,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: ChoiceLuxTheme.platinumSilver,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Amount display
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'R${trip.amount.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w700,
                                                  color: ChoiceLuxTheme.richGold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Amount',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: ChoiceLuxTheme.platinumSilver,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Trip details
                                    Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        children: [
                                                                                     // Pick-up and Drop-off locations
                                           isMobile
                                               ? Column(
                                                   children: [
                                                     Column(
                                                       crossAxisAlignment: CrossAxisAlignment.start,
                                                       children: [
                                                         Row(
                                                           children: [
                                                             Icon(
                                                               Icons.location_on,
                                                               size: 16,
                                                               color: ChoiceLuxTheme.richGold,
                                                             ),
                                                             const SizedBox(width: 8),
                                                             Text(
                                                               'Pick-up',
                                                               style: TextStyle(
                                                                 fontSize: 12,
                                                                 fontWeight: FontWeight.w600,
                                                                 color: ChoiceLuxTheme.platinumSilver,
                                                               ),
                                                             ),
                                                           ],
                                                         ),
                                                         const SizedBox(height: 4),
                                                         Text(
                                                           trip.pickupLocation,
                                                           style: const TextStyle(
                                                             fontSize: 14,
                                                             color: ChoiceLuxTheme.softWhite,
                                                           ),
                                                         ),
                                                       ],
                                                     ),
                                                     const SizedBox(height: 16),
                                                     Column(
                                                       crossAxisAlignment: CrossAxisAlignment.start,
                                                       children: [
                                                         Row(
                                                           children: [
                                                             Icon(
                                                               Icons.location_on,
                                                               size: 16,
                                                               color: ChoiceLuxTheme.richGold,
                                                             ),
                                                             const SizedBox(width: 8),
                                                             Text(
                                                               'Drop-off',
                                                               style: TextStyle(
                                                                 fontSize: 12,
                                                                 fontWeight: FontWeight.w600,
                                                                 color: ChoiceLuxTheme.platinumSilver,
                                                               ),
                                                             ),
                                                           ],
                                                         ),
                                                         const SizedBox(height: 4),
                                                         Text(
                                                           trip.dropoffLocation,
                                                           style: const TextStyle(
                                                             fontSize: 14,
                                                             color: ChoiceLuxTheme.softWhite,
                                                           ),
                                                         ),
                                                       ],
                                                     ),
                                                   ],
                                                 )
                                               : Row(
                                                   children: [
                                                     Expanded(
                                                       child: Column(
                                                         crossAxisAlignment: CrossAxisAlignment.start,
                                                         children: [
                                                           Row(
                                                             children: [
                                                               Icon(
                                                                 Icons.location_on,
                                                                 size: 16,
                                                                 color: ChoiceLuxTheme.richGold,
                                                               ),
                                                               const SizedBox(width: 8),
                                                               Text(
                                                                 'Pick-up',
                                                                 style: TextStyle(
                                                                   fontSize: 12,
                                                                   fontWeight: FontWeight.w600,
                                                                   color: ChoiceLuxTheme.platinumSilver,
                                                                 ),
                                                               ),
                                                             ],
                                                           ),
                                                           const SizedBox(height: 4),
                                                           Text(
                                                             trip.pickupLocation,
                                                             style: const TextStyle(
                                                               fontSize: 14,
                                                               color: ChoiceLuxTheme.softWhite,
                                                             ),
                                                           ),
                                                         ],
                                                       ),
                                                     ),
                                                     const SizedBox(width: 20),
                                                     Expanded(
                                                       child: Column(
                                                         crossAxisAlignment: CrossAxisAlignment.start,
                                                         children: [
                                                           Row(
                                                             children: [
                                                               Icon(
                                                                 Icons.location_on,
                                                                 size: 16,
                                                                 color: ChoiceLuxTheme.richGold,
                                                               ),
                                                               const SizedBox(width: 8),
                                                               Text(
                                                                 'Drop-off',
                                                                 style: TextStyle(
                                                                   fontSize: 12,
                                                                   fontWeight: FontWeight.w600,
                                                                   color: ChoiceLuxTheme.platinumSilver,
                                                                 ),
                                                               ),
                                                             ],
                                                           ),
                                                           const SizedBox(height: 4),
                                                           Text(
                                                             trip.dropoffLocation,
                                                             style: const TextStyle(
                                                               fontSize: 14,
                                                               color: ChoiceLuxTheme.softWhite,
                                                             ),
                                                           ),
                                                         ],
                                                       ),
                                                     ),
                                                   ],
                                                 ),
                                          // Notes section (if exists)
                                          if (trip.notes != null && trip.notes!.isNotEmpty) ...[
                                            const SizedBox(height: 16),
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0F0F0F),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
                                                ),
                                              ),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Icon(
                                                    Icons.note,
                                                    size: 16,
                                                    color: ChoiceLuxTheme.platinumSilver,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      trip.notes!,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: ChoiceLuxTheme.platinumSilver,
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
                                    // Action buttons
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F0F0F),
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(16),
                                          bottomRight: Radius.circular(16),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () => _startEditingTrip(trip),
                                            icon: const Icon(Icons.edit, size: 16),
                                            label: const Text('Edit'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: ChoiceLuxTheme.richGold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton.icon(
                                            onPressed: () => _deleteTrip(trip),
                                            icon: const Icon(Icons.delete, size: 16),
                                            label: const Text('Delete'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: ChoiceLuxTheme.errorColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            // Divider before total amount
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 32),
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    ChoiceLuxTheme.richGold.withOpacity(0.3),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                  
                  // Enhanced Bottom Action Bar
                  if (trips.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF4A4A4A),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Total amount header
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: ChoiceLuxTheme.richGold.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet,
                                    color: ChoiceLuxTheme.richGold,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Total Amount',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: ChoiceLuxTheme.softWhite,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${trips.length} Trip${trips.length != 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: ChoiceLuxTheme.platinumSilver,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                                                     // Total amount and action buttons
                           Padding(
                             padding: const EdgeInsets.all(24),
                             child: isMobile
                                 ? Column(
                                     children: [
                                       Column(
                                         crossAxisAlignment: CrossAxisAlignment.center,
                                         children: [
                                           Text(
                                             'Total Value',
                                             style: TextStyle(
                                               fontSize: 14,
                                               color: ChoiceLuxTheme.platinumSilver,
                                               fontWeight: FontWeight.w500,
                                             ),
                                           ),
                                           const SizedBox(height: 8),
                                           Text(
                                             'R${totalAmount.toStringAsFixed(2)}',
                                             style: TextStyle(
                                               fontSize: 28,
                                               fontWeight: FontWeight.w700,
                                               color: ChoiceLuxTheme.richGold,
                                             ),
                                           ),
                                         ],
                                       ),
                                       const SizedBox(height: 20),
                                       SizedBox(
                                         width: double.infinity,
                                         child: ElevatedButton.icon(
                                           onPressed: _confirmTrips,
                                           icon: const Icon(Icons.check_circle, size: 20),
                                           label: const Text(
                                             'Confirm All Trips',
                                             style: TextStyle(
                                               fontSize: 16,
                                               fontWeight: FontWeight.w600,
                                             ),
                                           ),
                                           style: ElevatedButton.styleFrom(
                                             backgroundColor: ChoiceLuxTheme.richGold,
                                             foregroundColor: Colors.black,
                                             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                             shape: const RoundedRectangleBorder(
                                               borderRadius: BorderRadius.all(Radius.circular(12)),
                                             ),
                                             elevation: 4,
                                             shadowColor: ChoiceLuxTheme.richGold.withOpacity(0.3),
                                           ),
                                         ),
                                       ),
                                     ],
                                   )
                                 : Row(
                                     children: [
                                       Expanded(
                                         child: Column(
                                           crossAxisAlignment: CrossAxisAlignment.start,
                                           children: [
                                             Text(
                                               'Total Value',
                                               style: TextStyle(
                                                 fontSize: 14,
                                                 color: ChoiceLuxTheme.platinumSilver,
                                                 fontWeight: FontWeight.w500,
                                               ),
                                             ),
                                             const SizedBox(height: 8),
                                             Text(
                                               'R${totalAmount.toStringAsFixed(2)}',
                                               style: TextStyle(
                                                 fontSize: 28,
                                                 fontWeight: FontWeight.w700,
                                                 color: ChoiceLuxTheme.richGold,
                                               ),
                                             ),
                                           ],
                                         ),
                                       ),
                                       ElevatedButton.icon(
                                         onPressed: _confirmTrips,
                                         icon: const Icon(Icons.check_circle, size: 20),
                                         label: const Text(
                                           'Confirm All Trips',
                                           style: TextStyle(
                                             fontSize: 16,
                                             fontWeight: FontWeight.w600,
                                           ),
                                         ),
                                         style: ElevatedButton.styleFrom(
                                           backgroundColor: ChoiceLuxTheme.richGold,
                                           foregroundColor: Colors.black,
                                           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                           shape: const RoundedRectangleBorder(
                                             borderRadius: BorderRadius.all(Radius.circular(12)),
                                           ),
                                           elevation: 4,
                                           shadowColor: ChoiceLuxTheme.richGold.withOpacity(0.3),
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
            ),
    );
  }
}