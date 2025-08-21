import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/luxury_app_bar.dart';
import '../models/quote_transport_detail.dart';
import '../providers/quotes_provider.dart';
import '../models/quote.dart';

class QuoteTransportDetailsScreen extends ConsumerStatefulWidget {
  final String quoteId;

  const QuoteTransportDetailsScreen({
    super.key,
    required this.quoteId,
  });

  @override
  ConsumerState<QuoteTransportDetailsScreen> createState() => _QuoteTransportDetailsScreenState();
}

class _QuoteTransportDetailsScreenState extends ConsumerState<QuoteTransportDetailsScreen> {
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
      final quote = await ref.read(quotesProvider.notifier).getQuote(widget.quoteId);
      if (quote != null) {
        setState(() => _quote = quote);
      }

      // Load transport details
      final transportNotifier = ref.read(quoteTransportDetailsProvider(widget.quoteId).notifier);
      await transportNotifier.fetchTransportDetails();
      
      // Get the updated state
      final transportDetails = ref.read(quoteTransportDetailsProvider(widget.quoteId));
      setState(() => _transportDetails = transportDetails);
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
                  
                  // Pickup Date
                  InkWell(
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
    if (picked != null && picked != _selectedPickupDate) {
      setState(() => _selectedPickupDate = picked);
    }
  }

  Future<void> _saveTransport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPickupDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a pickup date'),
          backgroundColor: ChoiceLuxTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isAddingTransport = true);
    try {
      final transportNotifier = ref.read(quoteTransportDetailsProvider(widget.quoteId).notifier);
      
      if (_isEditMode && _editingTransport != null) {
        // Update existing transport
        final updatedTransport = _editingTransport!.copyWith(
          pickupLocation: _pickupLocationController.text.trim(),
          dropoffLocation: _dropoffLocationController.text.trim(),
          pickupDate: _selectedPickupDate!,
          amount: double.parse(_amountController.text),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
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
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
        
        await transportNotifier.addTransportDetail(newTransport);
      }

      // Refresh data
      await _loadData();
      
      Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Transport updated successfully' : 'Transport added successfully'),
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
  }

  Future<void> _deleteTransport(QuoteTransportDetail transport) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ChoiceLuxTheme.charcoalGray,
        title: const Text(
          'Delete Transport Leg',
          style: TextStyle(
            color: ChoiceLuxTheme.softWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete this transport leg? This action cannot be undone.',
          style: TextStyle(color: ChoiceLuxTheme.softWhite),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: ChoiceLuxTheme.platinumSilver),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ChoiceLuxTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final transportNotifier = ref.read(quoteTransportDetailsProvider(widget.quoteId).notifier);
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
    return _transportDetails.fold(0.0, (sum, transport) => sum + transport.amount);
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTransportDialog,
        backgroundColor: ChoiceLuxTheme.richGold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Add Transport'),
      ),
    );
  }

  Widget _buildHeader(bool isMobile, bool isSmallMobile) {
    return Container(
      margin: EdgeInsets.all(isSmallMobile ? 12 : isMobile ? 16 : 20),
      padding: EdgeInsets.all(isSmallMobile ? 16 : isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: ChoiceLuxTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallMobile ? 8 : isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.route,
                  size: isSmallMobile ? 20 : isMobile ? 24 : 28,
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
                        fontSize: isSmallMobile ? 18 : isMobile ? 20 : 24,
                        fontWeight: FontWeight.w700,
                        color: ChoiceLuxTheme.softWhite,
                      ),
                    ),
                    Text(
                      '${_transportDetails.length} transport leg${_transportDetails.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: isSmallMobile ? 12 : isMobile ? 14 : 16,
                        color: ChoiceLuxTheme.platinumSilver,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(isSmallMobile ? 12 : isMobile ? 16 : 20),
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
                        fontSize: isSmallMobile ? 16 : isMobile ? 18 : 20,
                        fontWeight: FontWeight.w700,
                        color: ChoiceLuxTheme.richGold,
                      ),
                    ),
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: isSmallMobile ? 10 : isMobile ? 11 : 12,
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.charcoalGray.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.route_outlined,
              size: 48,
              color: ChoiceLuxTheme.platinumSilver,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Transport Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: ChoiceLuxTheme.softWhite,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add transport legs to define the route and pricing',
            style: TextStyle(
              fontSize: 14,
              color: ChoiceLuxTheme.platinumSilver,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showAddTransportDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add First Transport'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ChoiceLuxTheme.richGold,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransportList(bool isMobile, bool isSmallMobile) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallMobile ? 12 : isMobile ? 16 : 20,
        vertical: 8,
      ),
      itemCount: _transportDetails.length,
      itemBuilder: (context, index) {
        final transport = _transportDetails[index];
        return _buildTransportCard(transport, index, isMobile, isSmallMobile);
      },
    );
  }

  Widget _buildTransportCard(QuoteTransportDetail transport, int index, bool isMobile, bool isSmallMobile) {
    return Container(
      margin: EdgeInsets.only(bottom: isSmallMobile ? 12 : isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: ChoiceLuxTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          // Header with leg number and actions
          Container(
            padding: EdgeInsets.all(isSmallMobile ? 12 : isMobile ? 16 : 20),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.richGold.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallMobile ? 6 : isMobile ? 8 : 10),
                  decoration: BoxDecoration(
                    color: ChoiceLuxTheme.richGold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: isSmallMobile ? 12 : isMobile ? 14 : 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Transport Leg ${index + 1}',
                    style: TextStyle(
                      fontSize: isSmallMobile ? 14 : isMobile ? 16 : 18,
                      fontWeight: FontWeight.w600,
                      color: ChoiceLuxTheme.softWhite,
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _showEditTransportDialog(transport),
                      icon: const Icon(Icons.edit, color: ChoiceLuxTheme.richGold),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      onPressed: () => _deleteTransport(transport),
                      icon: const Icon(Icons.delete, color: ChoiceLuxTheme.errorColor),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Transport details
          Padding(
            padding: EdgeInsets.all(isSmallMobile ? 12 : isMobile ? 16 : 20),
            child: Column(
              children: [
                // Route information
                Row(
                  children: [
                    Expanded(
                      child: _buildRouteInfo(
                        icon: Icons.location_on,
                        title: 'From',
                        location: transport.pickupLocation,
                        isMobile: isMobile,
                        isSmallMobile: isSmallMobile,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: ChoiceLuxTheme.richGold,
                        size: 16,
                      ),
                    ),
                    Expanded(
                      child: _buildRouteInfo(
                        icon: Icons.location_on,
                        title: 'To',
                        location: transport.dropoffLocation,
                        isMobile: isMobile,
                        isSmallMobile: isSmallMobile,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Date and amount
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: isSmallMobile ? 14 : isMobile ? 16 : 18,
                            color: ChoiceLuxTheme.platinumSilver,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${transport.pickupDate.day}/${transport.pickupDate.month}/${transport.pickupDate.year}',
                            style: TextStyle(
                              fontSize: isSmallMobile ? 12 : isMobile ? 14 : 16,
                              color: ChoiceLuxTheme.softWhite,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(isSmallMobile ? 8 : isMobile ? 10 : 12),
                      decoration: BoxDecoration(
                        color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'R ${transport.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: isSmallMobile ? 14 : isMobile ? 16 : 18,
                          fontWeight: FontWeight.w700,
                          color: ChoiceLuxTheme.richGold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Notes (if any)
                if (transport.notes?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ChoiceLuxTheme.charcoalGray.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.note,
                              size: 14,
                              color: ChoiceLuxTheme.platinumSilver,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Notes',
                              style: TextStyle(
                                fontSize: isSmallMobile ? 11 : isMobile ? 12 : 13,
                                fontWeight: FontWeight.w600,
                                color: ChoiceLuxTheme.platinumSilver,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          transport.notes!,
                          style: TextStyle(
                            fontSize: isSmallMobile ? 11 : isMobile ? 12 : 13,
                            color: ChoiceLuxTheme.softWhite,
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

  Widget _buildRouteInfo({
    required IconData icon,
    required String title,
    required String location,
    required bool isMobile,
    required bool isSmallMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: isSmallMobile ? 12 : isMobile ? 14 : 16,
              color: ChoiceLuxTheme.platinumSilver,
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: isSmallMobile ? 10 : isMobile ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: ChoiceLuxTheme.platinumSilver,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          location,
          style: TextStyle(
            fontSize: isSmallMobile ? 12 : isMobile ? 13 : 14,
            fontWeight: FontWeight.w500,
            color: ChoiceLuxTheme.softWhite,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
