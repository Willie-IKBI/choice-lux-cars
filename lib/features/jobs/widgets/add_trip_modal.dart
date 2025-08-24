import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/jobs/models/trip.dart';
import 'package:choice_lux_cars/features/jobs/providers/jobs_provider.dart';

class AddTripModal extends ConsumerStatefulWidget {
  final String jobId;
  final Function(Trip) onTripAdded;

  const AddTripModal({
    super.key,
    required this.jobId,
    required this.onTripAdded,
  });

  @override
  ConsumerState<AddTripModal> createState() => _AddTripModalState();
}

class _AddTripModalState extends ConsumerState<AddTripModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _pickupLocationController;
  late TextEditingController _dropoffLocationController;
  late TextEditingController _notesController;
  late TextEditingController _amountController;
  late DateTime _pickupDate;
  late TimeOfDay _pickupTime;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pickupLocationController = TextEditingController();
    _dropoffLocationController = TextEditingController();
    _notesController = TextEditingController();
    _amountController = TextEditingController();
    _pickupDate = DateTime.now();
    _pickupTime = TimeOfDay.now();
  }

  @override
  void dispose() {
    _pickupLocationController.dispose();
    _dropoffLocationController.dispose();
    _notesController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _pickupDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _pickupDate && mounted) {
      setState(() {
        _pickupDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _pickupTime,
    );
    if (picked != null && picked != _pickupTime && mounted) {
      setState(() {
        _pickupTime = picked;
      });
    }
  }



  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final combinedDateTime = DateTime(
        _pickupDate.year,
        _pickupDate.month,
        _pickupDate.day,
        _pickupTime.hour,
        _pickupTime.minute,
      );

      final newTrip = Trip(
        id: '', // Will be set by the database
        jobId: widget.jobId,
        pickupDate: combinedDateTime,
        pickupLocation: _pickupLocationController.text.trim(),
        dropoffLocation: _dropoffLocationController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        amount: double.tryParse(_amountController.text) ?? 0.0,
      );

      await ref.read(tripsProvider.notifier).addTrip(newTrip);

      if (mounted) {
        Navigator.of(context).pop();
        widget.onTripAdded(newTrip);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Trip added successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to add trip: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ChoiceLuxTheme.richGold,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_location, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Add New Trip',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pickup Location
                      TextFormField(
                        controller: _pickupLocationController,
                        decoration: const InputDecoration(
                          labelText: 'Pickup Location *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Pickup location is required';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Dropoff Location
                      TextFormField(
                        controller: _dropoffLocationController,
                        decoration: const InputDecoration(
                          labelText: 'Dropoff Location *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_off),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Dropoff location is required';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Date and Time Row
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Date *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  '${_pickupDate.day}/${_pickupDate.month}/${_pickupDate.year}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectTime(context),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Time *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.access_time),
                                ),
                                child: Text(
                                  _pickupTime.format(context),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                                             // Amount
                       TextFormField(
                         controller: _amountController,
                         decoration: const InputDecoration(
                           labelText: 'Amount (R)',
                           border: OutlineInputBorder(),
                           prefixIcon: Icon(Icons.attach_money),
                         ),
                         keyboardType: TextInputType.number,
                       ),
                      
                      const SizedBox(height: 16),
                      
                      // Notes
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 3,
                      ),
                      
                      
                    ],
                  ),
                ),
              ),
            ),
            
            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveTrip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ChoiceLuxTheme.richGold,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Add Trip'),
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
