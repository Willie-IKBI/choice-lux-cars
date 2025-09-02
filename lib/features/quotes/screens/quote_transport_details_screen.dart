import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/features/quotes/models/quote.dart';
import 'package:choice_lux_cars/features/quotes/models/quote_transport_detail.dart';
import 'package:choice_lux_cars/features/quotes/providers/quotes_provider.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/app/theme.dart';

class QuoteTransportDetailsScreen extends ConsumerStatefulWidget {
  final String quoteId;

  const QuoteTransportDetailsScreen({super.key, required this.quoteId});

  @override
  ConsumerState<QuoteTransportDetailsScreen> createState() =>
      _QuoteTransportDetailsScreenState();
}

class _QuoteTransportDetailsScreenState
    extends ConsumerState<QuoteTransportDetailsScreen> {
  bool _isLoading = false;
  bool _isAddingTransport = false;
  Quote? _quote;
  List<QuoteTransportDetail> _transportDetails = [];

  // Form controllers for adding/editing transport
  final _formKey = GlobalKey<FormState>();
  final _pickupLocationController = TextEditingController();
  final _dropoffLocationController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _selectedPickupDate;
  TimeOfDay? _selectedPickupTime;

  // Edit mode
  QuoteTransportDetail? _editingTransport;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _pickupLocationController.dispose();
    _dropoffLocationController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load quote details
      final quote = await ref
          .read(quotesProvider.notifier)
          .getQuote(widget.quoteId);
      if (quote != null) {
        setState(() => _quote = quote);
      }

      // Load transport details
      final transportNotifier = ref.read(
        quoteTransportDetailsProvider(widget.quoteId).notifier,
      );
      await transportNotifier.fetchTransportDetails();

      // Get the updated state
      final transportDetails = ref.read(
        quoteTransportDetailsProvider(widget.quoteId),
      );
      setState(() => _transportDetails = transportDetails.value ?? []);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: ChoiceLuxTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddTransportDialog() {
    _resetForm();
    _isEditMode = false;
    _editingTransport = null;
    _showTransportDialog();
  }

  void _showEditTransportDialog(QuoteTransportDetail transport) {
    _isEditMode = true;
    _editingTransport = transport;

    // Populate form with existing data
    _pickupLocationController.text = transport.pickupLocation;
    _dropoffLocationController.text = transport.dropoffLocation;
    _amountController.text = transport.amount.toString();
    _notesController.text = transport.notes ?? '';
    _selectedPickupDate = transport.pickupDate;
    _selectedPickupTime = TimeOfDay.fromDateTime(transport.pickupDate);

    _showTransportDialog();
  }

  void _showTransportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ChoiceLuxTheme.charcoalGray,
        title: Text(
          _isEditMode ? 'Edit Transport Leg' : 'Add Transport Leg',
          style: const TextStyle(
            color: ChoiceLuxTheme.softWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pickup Location
                  TextFormField(
                    controller: _pickupLocationController,
                    decoration: const InputDecoration(
                      labelText: 'Pickup Location *',
                      border: OutlineInputBorder(),
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
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Dropoff location is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Pickup Date and Time
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Pickup Date *',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              _selectedPickupDate != null
                                  ? '${_selectedPickupDate!.day}/${_selectedPickupDate!.month}/${_selectedPickupDate!.year}'
                                  : 'Select Date',
                              style: TextStyle(
                                color: _selectedPickupDate != null
                                    ? ChoiceLuxTheme.softWhite
                                    : ChoiceLuxTheme.platinumSilver,
                              ),
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
                              labelText: 'Pickup Time *',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              _selectedPickupTime != null
                                  ? _selectedPickupTime!.format(context)
                                  : 'Select Time',
                              style: TextStyle(
                                color: _selectedPickupTime != null
                                    ? ChoiceLuxTheme.softWhite
                                    : ChoiceLuxTheme.platinumSilver,
                              ),
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
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount (R) *',
                      border: OutlineInputBorder(),
                      prefixText: 'R ',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Amount is required';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: ChoiceLuxTheme.platinumSilver),
            ),
          ),
          ElevatedButton(
            onPressed: _isAddingTransport ? null : _saveTransport,
            style: ElevatedButton.styleFrom(
              backgroundColor: ChoiceLuxTheme.richGold,
              foregroundColor: Colors.black,
            ),
            child: _isAddingTransport
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : Text(_isEditMode ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedPickupDate ?? DateTime.now(),
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
        _selectedPickupDate = picked;
        // If we have a time selected, combine it with the new date
        if (_selectedPickupTime != null) {
          _selectedPickupDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            _selectedPickupTime!.hour,
            _selectedPickupTime!.minute,
          );
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedPickupTime ?? TimeOfDay.now(),
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
        _selectedPickupTime = picked;
        // If we have a date selected, combine it with the new time
        if (_selectedPickupDate != null) {
          _selectedPickupDate = DateTime(
            _selectedPickupDate!.year,
            _selectedPickupDate!.month,
            _selectedPickupDate!.day,
            picked.hour,
            picked.minute,
          );
        }
      });
    }
  }

  Future<void> _saveTransport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPickupDate == null || _selectedPickupTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both pickup date and time'),
          backgroundColor: ChoiceLuxTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isAddingTransport = true);
    try {
      final transportNotifier = ref.read(
        quoteTransportDetailsProvider(widget.quoteId).notifier,
      );

      if (_isEditMode && _editingTransport != null) {
        // Update existing transport
        final updatedTransport = _editingTransport!.copyWith(
          pickupLocation: _pickupLocationController.text.trim(),
          dropoffLocation: _dropoffLocationController.text.trim(),
          pickupDate: _selectedPickupDate!,
          amount: double.parse(_amountController.text),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

        await transportNotifier.updateTransportDetail(updatedTransport);
      } else {
        // Add new transport
        final newTransport = QuoteTransportDetail(
          id: '', // Will be set by database
          quoteId: widget.quoteId,
          pickupDate: _selectedPickupDate!,
          pickupLocation: _pickupLocationController.text.trim(),
          dropoffLocation: _dropoffLocationController.text.trim(),
          amount: double.parse(_amountController.text),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

        await transportNotifier.addTransportDetail(newTransport);
      }

      // Refresh data
      await _loadData();

      Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Transport updated successfully'
                  : 'Transport added successfully',
            ),
            backgroundColor: ChoiceLuxTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving transport: $e'),
            backgroundColor: ChoiceLuxTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isAddingTransport = false);
    }
  }

  void _resetForm() {
    _pickupLocationController.clear();
    _dropoffLocationController.clear();
    _amountController.clear();
    _notesController.clear();
    _selectedPickupDate = null;
    _selectedPickupTime = null;
  }

  Future<void> _deleteTransport(QuoteTransportDetail transport) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ChoiceLuxTheme.charcoalGray,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ChoiceLuxTheme.errorColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: ChoiceLuxTheme.errorColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Transport Leg',
              style: TextStyle(
                color: ChoiceLuxTheme.softWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete this transport leg?',
              style: TextStyle(color: ChoiceLuxTheme.softWhite, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ChoiceLuxTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ChoiceLuxTheme.errorColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'From: ${transport.pickupLocation}',
                    style: const TextStyle(
                      color: ChoiceLuxTheme.softWhite,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'To: ${transport.dropoffLocation}',
                    style: const TextStyle(
                      color: ChoiceLuxTheme.softWhite,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Amount: R ${transport.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: ChoiceLuxTheme.richGold,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: ChoiceLuxTheme.errorColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: ChoiceLuxTheme.platinumSilver,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ChoiceLuxTheme.errorColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final transportNotifier = ref.read(
          quoteTransportDetailsProvider(widget.quoteId).notifier,
        );
        await transportNotifier.deleteTransportDetail(transport.id);
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transport deleted successfully'),
              backgroundColor: ChoiceLuxTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting transport: $e'),
              backgroundColor: ChoiceLuxTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  double get _totalAmount {
    return _transportDetails.fold(
      0.0,
      (sum, transport) => sum + transport.amount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 400;

    if (_isLoading) {
      return Scaffold(
        appBar: LuxuryAppBar(
          title: 'Transport Details',
          subtitle: 'Quote #${widget.quoteId}',
          showBackButton: true,
          onBackPressed: () => context.go('/quotes/${widget.quoteId}'),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ChoiceLuxTheme.richGold),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: LuxuryAppBar(
        title: 'Transport Details',
        subtitle: 'Quote #${widget.quoteId}',
        showBackButton: true,
        onBackPressed: () => context.go('/quotes/${widget.quoteId}'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: ChoiceLuxTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with Summary
              _buildHeader(isMobile, isSmallMobile),

              // Transport Details List
              Expanded(
                child: _transportDetails.isEmpty
                    ? _buildEmptyState()
                    : _buildTransportList(isMobile, isSmallMobile),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ChoiceLuxTheme.richGold.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _showAddTransportDialog,
          backgroundColor: ChoiceLuxTheme.richGold,
          foregroundColor: Colors.black,
          elevation: 0,
          icon: const Icon(Icons.add, size: 24),
          label: const Text(
            'Add Transport',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile, bool isSmallMobile) {
    return Container(
      margin: EdgeInsets.all(
        isSmallMobile
            ? 12
            : isMobile
            ? 16
            : 20,
      ),
      padding: EdgeInsets.all(
        isSmallMobile
            ? 16
            : isMobile
            ? 20
            : 24,
      ),
      decoration: BoxDecoration(
        gradient: ChoiceLuxTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          // Breadcrumb Navigation
          Row(
            children: [
              Icon(
                Icons.arrow_back_ios,
                size: 16,
                color: ChoiceLuxTheme.platinumSilver,
              ),
              TextButton(
                onPressed: () => context.go('/quotes/${widget.quoteId}'),
                child: Text(
                  'Back to Quote',
                  style: TextStyle(
                    color: ChoiceLuxTheme.richGold,
                    fontSize: isSmallMobile
                        ? 12
                        : isMobile
                        ? 14
                        : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),

          // Main Header Content
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  isSmallMobile
                      ? 8
                      : isMobile
                      ? 12
                      : 16,
                ),
                decoration: BoxDecoration(
                  color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.route,
                  size: isSmallMobile
                      ? 20
                      : isMobile
                      ? 24
                      : 28,
                  color: ChoiceLuxTheme.richGold,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transport Details',
                      style: TextStyle(
                        fontSize: isSmallMobile
                            ? 18
                            : isMobile
                            ? 20
                            : 24,
                        fontWeight: FontWeight.w700,
                        color: ChoiceLuxTheme.softWhite,
                      ),
                    ),
                    Text(
                      '${_transportDetails.length} transport leg${_transportDetails.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: isSmallMobile
                            ? 12
                            : isMobile
                            ? 14
                            : 16,
                        color: ChoiceLuxTheme.platinumSilver,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(
                  isSmallMobile
                      ? 12
                      : isMobile
                      ? 16
                      : 20,
                ),
                decoration: BoxDecoration(
                  color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'R ${_totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: isSmallMobile
                            ? 16
                            : isMobile
                            ? 18
                            : 20,
                        fontWeight: FontWeight.w700,
                        color: ChoiceLuxTheme.richGold,
                      ),
                    ),
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: isSmallMobile
                            ? 10
                            : isMobile
                            ? 11
                            : 12,
                        color: ChoiceLuxTheme.platinumSilver,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ChoiceLuxTheme.richGold.withOpacity(0.1),
                  ChoiceLuxTheme.charcoalGray.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: ChoiceLuxTheme.richGold.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.route_outlined,
              size: 64,
              color: ChoiceLuxTheme.richGold.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'No Transport Details',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: ChoiceLuxTheme.softWhite,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Add transport legs to define the route and pricing for this quote. Each leg represents a segment of the journey with its own pickup, dropoff, and cost.',
              style: TextStyle(
                fontSize: 16,
                color: ChoiceLuxTheme.platinumSilver,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _showAddTransportDialog,
              icon: const Icon(Icons.add, size: 24),
              label: const Text(
                'Add First Transport',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ChoiceLuxTheme.richGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransportList(bool isMobile, bool isSmallMobile) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallMobile
            ? 12
            : isMobile
            ? 16
            : 20,
        vertical: 8,
      ),
      itemCount: _transportDetails.length,
      itemBuilder: (context, index) {
        final transport = _transportDetails[index];
        return _buildTransportCard(transport, index, isMobile, isSmallMobile);
      },
    );
  }

  Widget _buildTransportCard(
    QuoteTransportDetail transport,
    int index,
    bool isMobile,
    bool isSmallMobile,
  ) {
    return Container(
      margin: EdgeInsets.only(
        bottom: isSmallMobile
            ? 12
            : isMobile
            ? 16
            : 20,
      ),
      decoration: BoxDecoration(
        gradient: ChoiceLuxTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with leg number, title, date/time, and actions
          Container(
            padding: EdgeInsets.all(
              isSmallMobile
                  ? 12
                  : isMobile
                  ? 16
                  : 20,
            ),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.richGold.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Leg number badge
                Container(
                  padding: EdgeInsets.all(
                    isSmallMobile
                        ? 8
                        : isMobile
                        ? 10
                        : 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ChoiceLuxTheme.richGold,
                        ChoiceLuxTheme.richGold.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: isSmallMobile
                          ? 14
                          : isMobile
                          ? 16
                          : 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Title and date/time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transport Leg ${index + 1}',
                        style: TextStyle(
                          fontSize: isSmallMobile
                              ? 16
                              : isMobile
                              ? 18
                              : 20,
                          fontWeight: FontWeight.w700,
                          color: ChoiceLuxTheme.softWhite,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: isSmallMobile
                                ? 12
                                : isMobile
                                ? 14
                                : 16,
                            color: ChoiceLuxTheme.platinumSilver,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${transport.pickupDate.day}/${transport.pickupDate.month}/${transport.pickupDate.year}',
                            style: TextStyle(
                              fontSize: isSmallMobile
                                  ? 11
                                  : isMobile
                                  ? 12
                                  : 13,
                              color: ChoiceLuxTheme.platinumSilver,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.access_time,
                            size: isSmallMobile
                                ? 12
                                : isMobile
                                ? 14
                                : 16,
                            color: ChoiceLuxTheme.platinumSilver,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${transport.pickupDate.hour.toString().padLeft(2, '0')}:${transport.pickupDate.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: isSmallMobile
                                  ? 11
                                  : isMobile
                                  ? 12
                                  : 13,
                              color: ChoiceLuxTheme.platinumSilver,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action buttons
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: ChoiceLuxTheme.richGold.withOpacity(0.2),
                        ),
                      ),
                      child: IconButton(
                        onPressed: () => _showEditTransportDialog(transport),
                        icon: const Icon(
                          Icons.edit,
                          color: ChoiceLuxTheme.richGold,
                          size: 18,
                        ),
                        tooltip: 'Edit Transport Leg',
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(36, 36),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: ChoiceLuxTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: ChoiceLuxTheme.errorColor.withOpacity(0.2),
                        ),
                      ),
                      child: IconButton(
                        onPressed: () => _deleteTransport(transport),
                        icon: const Icon(
                          Icons.delete,
                          color: ChoiceLuxTheme.errorColor,
                          size: 18,
                        ),
                        tooltip: 'Delete Transport Leg',
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(36, 36),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Route information
          Padding(
            padding: EdgeInsets.all(
              isSmallMobile
                  ? 12
                  : isMobile
                  ? 16
                  : 20,
            ),
            child: Column(
              children: [
                // Pickup location
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(
                    isSmallMobile
                        ? 12
                        : isMobile
                        ? 14
                        : 16,
                  ),
                  decoration: BoxDecoration(
                    color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ChoiceLuxTheme.richGold.withOpacity(0.2),
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
                          Icons.directions_car,
                          color: ChoiceLuxTheme.richGold,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'From',
                              style: TextStyle(
                                fontSize: isSmallMobile
                                    ? 11
                                    : isMobile
                                    ? 12
                                    : 13,
                                fontWeight: FontWeight.w600,
                                color: ChoiceLuxTheme.richGold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              transport.pickupLocation,
                              style: TextStyle(
                                fontSize: isSmallMobile
                                    ? 13
                                    : isMobile
                                    ? 14
                                    : 16,
                                fontWeight: FontWeight.w500,
                                color: ChoiceLuxTheme.softWhite,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow connector
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          color: ChoiceLuxTheme.platinumSilver,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),

                // Dropoff location
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(
                    isSmallMobile
                        ? 12
                        : isMobile
                        ? 14
                        : 16,
                  ),
                  decoration: BoxDecoration(
                    color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.flag,
                          color: ChoiceLuxTheme.platinumSilver,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'To',
                              style: TextStyle(
                                fontSize: isSmallMobile
                                    ? 11
                                    : isMobile
                                    ? 12
                                    : 13,
                                fontWeight: FontWeight.w600,
                                color: ChoiceLuxTheme.platinumSilver,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              transport.dropoffLocation,
                              style: TextStyle(
                                fontSize: isSmallMobile
                                    ? 13
                                    : isMobile
                                    ? 14
                                    : 16,
                                fontWeight: FontWeight.w500,
                                color: ChoiceLuxTheme.softWhite,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Amount section
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(
                    isSmallMobile
                        ? 14
                        : isMobile
                        ? 16
                        : 18,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ChoiceLuxTheme.richGold.withOpacity(0.2),
                        ChoiceLuxTheme.richGold.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ChoiceLuxTheme.richGold.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
                          Icons.attach_money,
                          color: ChoiceLuxTheme.richGold,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Amount',
                              style: TextStyle(
                                fontSize: isSmallMobile
                                    ? 11
                                    : isMobile
                                    ? 12
                                    : 13,
                                fontWeight: FontWeight.w600,
                                color: ChoiceLuxTheme.platinumSilver,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'R ${transport.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: isSmallMobile
                                    ? 18
                                    : isMobile
                                    ? 20
                                    : 22,
                                fontWeight: FontWeight.w800,
                                color: ChoiceLuxTheme.richGold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Notes section (if any)
                if (transport.notes?.isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(
                      isSmallMobile
                          ? 12
                          : isMobile
                          ? 14
                          : 16,
                    ),
                    decoration: BoxDecoration(
                      color: ChoiceLuxTheme.charcoalGray.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: ChoiceLuxTheme.platinumSilver.withOpacity(
                              0.2,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.note,
                            color: ChoiceLuxTheme.platinumSilver,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notes',
                                style: TextStyle(
                                  fontSize: isSmallMobile
                                      ? 11
                                      : isMobile
                                      ? 12
                                      : 13,
                                  fontWeight: FontWeight.w600,
                                  color: ChoiceLuxTheme.platinumSilver,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                transport.notes!,
                                style: TextStyle(
                                  fontSize: isSmallMobile
                                      ? 12
                                      : isMobile
                                      ? 13
                                      : 14,
                                  color: ChoiceLuxTheme.softWhite,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
