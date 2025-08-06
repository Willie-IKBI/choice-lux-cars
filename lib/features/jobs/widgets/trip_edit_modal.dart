import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/jobs/models/trip.dart';
import 'package:choice_lux_cars/features/jobs/providers/jobs_provider.dart';

class TripEditModal extends ConsumerStatefulWidget {
  final Trip trip;
  final Function(Trip) onTripUpdated;

  const TripEditModal({
    super.key,
    required this.trip,
    required this.onTripUpdated,
  });

  @override
  ConsumerState<TripEditModal> createState() => _TripEditModalState();
}

class _TripEditModalState extends ConsumerState<TripEditModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _pickupLocationController;
  late TextEditingController _dropoffLocationController;
  late TextEditingController _notesController;
  late TextEditingController _amountController;
  late DateTime _pickupDate;
  late TimeOfDay _pickupTime;
  late DateTime? _clientPickupTime;
  late DateTime? _clientDropoffTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pickupLocationController = TextEditingController(text: widget.trip.pickupLocation);
    _dropoffLocationController = TextEditingController(text: widget.trip.dropoffLocation);
    _notesController = TextEditingController(text: widget.trip.notes ?? '');
    _amountController = TextEditingController(text: widget.trip.amount.toString());
    _pickupDate = widget.trip.pickupDate;
    _pickupTime = TimeOfDay.fromDateTime(widget.trip.pickupDate);
    _clientPickupTime = widget.trip.clientPickupTime;
    _clientDropoffTime = widget.trip.clientDropoffTime;
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
    if (picked != null && picked != _pickupDate) {
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
    if (picked != null && picked != _pickupTime) {
      setState(() {
        _pickupTime = picked;
      });
    }
  }

  Future<void> _selectClientPickupTime(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _clientPickupTime ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (timePicked != null) {
        setState(() {
          _clientPickupTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            timePicked.hour,
            timePicked.minute,
          );
        });
      }
    }
  }

  Future<void> _selectClientDropoffTime(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _clientDropoffTime ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (timePicked != null) {
        setState(() {
          _clientDropoffTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            timePicked.hour,
            timePicked.minute,
          );
        });
      }
    }
  }

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Combine date and time
      final combinedDateTime = DateTime(
        _pickupDate.year,
        _pickupDate.month,
        _pickupDate.day,
        _pickupTime.hour,
        _pickupTime.minute,
      );

      final updatedTrip = widget.trip.copyWith(
        pickupDate: combinedDateTime,
        pickupLocation: _pickupLocationController.text.trim(),
        dropoffLocation: _dropoffLocationController.text.trim(),
        clientPickupTime: _clientPickupTime,
        clientDropoffTime: _clientDropoffTime,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        amount: double.tryParse(_amountController.text) ?? 0.0,
      );

      await ref.read(tripsProvider.notifier).updateTrip(updatedTrip);
      
      if (mounted) {
        widget.onTripUpdated(updatedTrip);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating trip: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.edit, color: ChoiceLuxTheme.richGold, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Edit Trip',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ChoiceLuxTheme.richGold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Pickup Date & Time
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pickup Date', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, color: ChoiceLuxTheme.richGold),
                                const SizedBox(width: 8),
                                Text('${_pickupDate.day}/${_pickupDate.month}/${_pickupDate.year}'),
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
                        const Text('Pickup Time', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectTime(context),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, color: ChoiceLuxTheme.richGold),
                                const SizedBox(width: 8),
                                Text('${_pickupTime.hour.toString().padLeft(2, '0')}:${_pickupTime.minute.toString().padLeft(2, '0')}'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

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

              // Amount
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (R) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Amount is required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Client Pickup Time
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Client Pickup Time (Optional)', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectClientPickupTime(context),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, color: ChoiceLuxTheme.richGold),
                                const SizedBox(width: 8),
                                Text(_clientPickupTime != null 
                                  ? '${_clientPickupTime!.day}/${_clientPickupTime!.month}/${_clientPickupTime!.year} ${_clientPickupTime!.hour.toString().padLeft(2, '0')}:${_clientPickupTime!.minute.toString().padLeft(2, '0')}'
                                  : 'Not set'),
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
                        const Text('Client Dropoff Time (Optional)', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectClientDropoffTime(context),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, color: ChoiceLuxTheme.richGold),
                                const SizedBox(width: 8),
                                Text(_clientDropoffTime != null 
                                  ? '${_clientDropoffTime!.day}/${_clientDropoffTime!.month}/${_clientDropoffTime!.year} ${_clientDropoffTime!.hour.toString().padLeft(2, '0')}:${_clientDropoffTime!.minute.toString().padLeft(2, '0')}'
                                  : 'Not set'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
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
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Update Trip'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 