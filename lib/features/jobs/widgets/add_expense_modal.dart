import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/jobs/models/expense.dart';

/// Modal bottom sheet for adding a new expense
/// 
/// Displays a form for creating an expense with slip upload.
/// Validates all required fields and calls [onSubmit] with the expense draft,
/// slip bytes, and file name when submitted.
class AddExpenseModal extends StatefulWidget {
  final int jobId;
  final String driverId;
  final void Function(Expense draft, Uint8List slipBytes, String slipFileName) onSubmit;
  final VoidCallback? onCancel;

  const AddExpenseModal({
    super.key,
    required this.jobId,
    required this.driverId,
    required this.onSubmit,
    this.onCancel,
  });

  @override
  State<AddExpenseModal> createState() => _AddExpenseModalState();
}

class _AddExpenseModalState extends State<AddExpenseModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _otherDescriptionController = TextEditingController();
  final _locationController = TextEditingController();

  String _expenseType = 'fuel';
  DateTime _expenseDate = DateTime.now();
  TimeOfDay _expenseTime = TimeOfDay.now();
  
  Uint8List? _slipBytes;
  String? _slipFileName;
  bool _isImage = false;

  String? _amountError;
  String? _otherDescriptionError;
  String? _slipError;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _otherDescriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// Pick slip from file picker (supports images and PDFs on all platforms)
  Future<void> _pickSlip() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          // Validate file size (5MB max)
          if (file.bytes!.length > 5 * 1024 * 1024) {
            setState(() {
              _slipError = 'File size must be less than 5MB';
            });
            return;
          }

          // Validate extension
          final extension = file.extension?.toLowerCase() ?? '';
          if (!['jpg', 'jpeg', 'png', 'pdf'].contains(extension)) {
            setState(() {
              _slipError = 'Only JPG, JPEG, PNG, and PDF files are allowed';
            });
            return;
          }

          setState(() {
            _slipBytes = file.bytes;
            _slipFileName = file.name;
            _isImage = ['jpg', 'jpeg', 'png'].contains(extension);
            _slipError = null;
          });
        }
      }
    } catch (e) {
      setState(() {
        _slipError = 'Failed to pick file: $e';
      });
    }
  }

  /// Remove selected slip
  void _removeSlip() {
    setState(() {
      _slipBytes = null;
      _slipFileName = null;
      _isImage = false;
      _slipError = null;
    });
  }

  /// Select date
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _expenseDate && mounted) {
      setState(() {
        _expenseDate = picked;
      });
    }
  }

  /// Select time
  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _expenseTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? Container(),
        );
      },
    );
    if (picked != null && picked != _expenseTime && mounted) {
      setState(() {
        _expenseTime = picked;
      });
    }
  }

  /// Validate form and submit
  void _submit() {
    // Clear previous errors
    setState(() {
      _amountError = null;
      _otherDescriptionError = null;
      _slipError = null;
    });

    // Validate amount
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      setState(() {
        _amountError = 'Amount is required';
      });
      return;
    }
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() {
        _amountError = 'Amount must be greater than 0';
      });
      return;
    }

    // Validate description - REQUIRED only when expenseType == 'other'
    if (_expenseType == 'other') {
      final otherDescription = _otherDescriptionController.text.trim();
      if (otherDescription.isEmpty) {
        setState(() {
          _otherDescriptionError = 'Description is required for "other" expenses';
        });
        return;
      }
    }
    // For non-other types, description is optional

    // Validate slip (required)
    if (_slipBytes == null || _slipFileName == null) {
      setState(() {
        _slipError = 'Slip upload is required';
      });
      return;
    }

    // Create combined date/time
    final combinedDateTime = DateTime(
      _expenseDate.year,
      _expenseDate.month,
      _expenseDate.day,
      _expenseTime.hour,
      _expenseTime.minute,
    );

    // Create expense draft (id, createdAt, updatedAt will be set by DB)
    final expense = Expense(
      id: 0, // Will be set by database
      jobId: widget.jobId,
      driverId: widget.driverId,
      expenseType: _expenseType,
      amount: amount,
      expDate: combinedDateTime,
      expenseDescription: _expenseType != 'other' 
          ? (_descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim())
          : null,
      otherDescription: _expenseType == 'other'
          ? _otherDescriptionController.text.trim()
          : null,
      expenseLocation: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Call onSubmit callback
    widget.onSubmit(expense, _slipBytes!, _slipFileName!);
    
    // Close modal
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeBottomPadding = bottomPadding > 0 ? bottomPadding + 20 : 32.0;

    return Container(
      decoration: const BoxDecoration(
        color: ChoiceLuxTheme.charcoalGray,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long,
                  color: ChoiceLuxTheme.richGold,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Add Expense',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: ChoiceLuxTheme.softWhite,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    widget.onCancel?.call();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(
                    Icons.close,
                    color: ChoiceLuxTheme.platinumSilver,
                  ),
                ),
              ],
            ),
          ),

          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 8,
                bottom: safeBottomPadding,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Expense Type
                    const Text(
                      'Expense Type *',
                      style: TextStyle(
                        color: ChoiceLuxTheme.softWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: ChoiceLuxTheme.charcoalGray,
                        border: Border.all(
                          color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _expenseType,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: InputBorder.none,
                        ),
                        dropdownColor: ChoiceLuxTheme.charcoalGray,
                        style: const TextStyle(
                          color: ChoiceLuxTheme.softWhite,
                          fontSize: 16,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'fuel',
                            child: Text('Fuel'),
                          ),
                          DropdownMenuItem(
                            value: 'parking',
                            child: Text('Parking'),
                          ),
                          DropdownMenuItem(
                            value: 'toll',
                            child: Text('Toll'),
                          ),
                          DropdownMenuItem(
                            value: 'other',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _expenseType = value;
                              // Clear description errors when type changes
                              _otherDescriptionError = null;
                            });
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Amount
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount (R) *',
                        labelStyle: const TextStyle(
                          color: ChoiceLuxTheme.platinumSilver,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: ChoiceLuxTheme.richGold,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.red,
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.attach_money,
                          color: ChoiceLuxTheme.platinumSilver,
                        ),
                        errorText: _amountError,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(
                        color: ChoiceLuxTheme.softWhite,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Date and Time Row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectDate,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Date *',
                                labelStyle: const TextStyle(
                                  color: ChoiceLuxTheme.platinumSilver,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.3),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.3),
                                  ),
                                ),
                                prefixIcon: const Icon(
                                  Icons.calendar_today,
                                  color: ChoiceLuxTheme.platinumSilver,
                                ),
                              ),
                              child: Text(
                                '${_expenseDate.day}/${_expenseDate.month}/${_expenseDate.year}',
                                style: const TextStyle(
                                  color: ChoiceLuxTheme.softWhite,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: _selectTime,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Time *',
                                labelStyle: const TextStyle(
                                  color: ChoiceLuxTheme.platinumSilver,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.3),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.3),
                                  ),
                                ),
                                prefixIcon: const Icon(
                                  Icons.access_time,
                                  color: ChoiceLuxTheme.platinumSilver,
                                ),
                              ),
                              child: Text(
                                _expenseTime.format(context),
                                style: const TextStyle(
                                  color: ChoiceLuxTheme.softWhite,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Description (for non-other types - optional)
                    if (_expenseType != 'other') ...[
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          labelStyle: const TextStyle(
                            color: ChoiceLuxTheme.platinumSilver,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: ChoiceLuxTheme.richGold,
                            ),
                          ),
                          prefixIcon: const Icon(
                            Icons.description,
                            color: ChoiceLuxTheme.platinumSilver,
                          ),
                        ),
                        style: const TextStyle(
                          color: ChoiceLuxTheme.softWhite,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Other Description (for 'other' type)
                    if (_expenseType == 'other') ...[
                      TextFormField(
                        controller: _otherDescriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description *',
                          labelStyle: const TextStyle(
                            color: ChoiceLuxTheme.platinumSilver,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: ChoiceLuxTheme.richGold,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.red,
                            ),
                          ),
                          prefixIcon: const Icon(
                            Icons.description,
                            color: ChoiceLuxTheme.platinumSilver,
                          ),
                          errorText: _otherDescriptionError,
                        ),
                        style: const TextStyle(
                          color: ChoiceLuxTheme.softWhite,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Location (optional)
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Location',
                        labelStyle: const TextStyle(
                          color: ChoiceLuxTheme.platinumSilver,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: ChoiceLuxTheme.richGold,
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.location_on,
                          color: ChoiceLuxTheme.platinumSilver,
                        ),
                      ),
                      style: const TextStyle(
                        color: ChoiceLuxTheme.softWhite,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Slip Upload
                    const Text(
                      'Slip/Receipt *',
                      style: TextStyle(
                        color: ChoiceLuxTheme.softWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    if (_slipBytes == null) ...[
                      // Upload button
                      InkWell(
                        onTap: _pickSlip,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ChoiceLuxTheme.charcoalGray,
                            border: Border.all(
                              color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.3),
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.upload_file,
                                color: ChoiceLuxTheme.richGold,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Upload Slip (JPG, PNG, PDF - Max 5MB)',
                                  style: TextStyle(
                                    color: ChoiceLuxTheme.softWhite,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_slipError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _slipError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ] else ...[
                      // Slip preview
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ChoiceLuxTheme.charcoalGray,
                          border: Border.all(
                            color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            if (_isImage) ...[
                              // Image thumbnail
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.memory(
                                  _slipBytes!,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ] else ...[
                              // PDF icon
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: ChoiceLuxTheme.richGold.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.picture_as_pdf,
                                  color: ChoiceLuxTheme.richGold,
                                  size: 32,
                                ),
                              ),
                            ],
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _slipFileName!,
                                    style: const TextStyle(
                                      color: ChoiceLuxTheme.softWhite,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${(_slipBytes!.length / 1024).toStringAsFixed(1)} KB',
                                    style: TextStyle(
                                      color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _removeSlip,
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              widget.onCancel?.call();
                              Navigator.of(context).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.3),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: ChoiceLuxTheme.platinumSilver,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _slipBytes == null ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ChoiceLuxTheme.richGold,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              disabledBackgroundColor: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.3),
                            ),
                            child: const Text(
                              'Add Expense',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper function to show the Add Expense Modal
void showAddExpenseModal({
  required BuildContext context,
  required int jobId,
  required String driverId,
  required void Function(Expense draft, Uint8List slipBytes, String slipFileName) onSubmit,
  VoidCallback? onCancel,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => AddExpenseModal(
      jobId: jobId,
      driverId: driverId,
      onSubmit: onSubmit,
      onCancel: onCancel,
    ),
  );
}

