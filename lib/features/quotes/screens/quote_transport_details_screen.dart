import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/features/quotes/models/quote.dart';
import 'package:choice_lux_cars/features/quotes/models/quote_transport_detail.dart';
import 'package:choice_lux_cars/features/quotes/providers/quotes_provider.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/utils/background_pattern_utils.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/shared/utils/sa_time_utils.dart';
import 'package:intl/intl.dart';

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
      Log.d('Loading data for quote: ${widget.quoteId}');
      
      // Load quote details
      final quote = await ref
          .read(quotesProvider.notifier)
          .getQuote(widget.quoteId);
      if (quote != null) {
        setState(() => _quote = quote);
      }

      // Force refresh transport details provider
      final transportNotifier = ref.read(
        quoteTransportDetailsProvider(widget.quoteId).notifier,
      );
      
      // Invalidate and refresh the provider
      await transportNotifier.refresh();
      
      // Wait a moment for the provider to update
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Get the updated state
      final transportDetailsAsync = ref.read(
        quoteTransportDetailsProvider(widget.quoteId),
      );
      
      transportDetailsAsync.when(
        data: (data) {
          Log.d('Loaded ${data.length} transport details');
          setState(() => _transportDetails = data);
        },
        loading: () {
          Log.d('Transport details still loading...');
          setState(() => _transportDetails = []);
        },
        error: (error, stack) {
          Log.e('Error loading transport details: $error');
          setState(() => _transportDetails = []);
        },
      );
    } catch (e) {
      Log.e('Error loading data: $e');
      setState(() => _transportDetails = []);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: ChoiceLuxTheme.errorColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
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

  void _showAddTransportDialog() {
    _isEditMode = false;
    _editingTransport = null;
    _resetForm(); // Reset form after setting mode
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
      builder: (context) => _TransportDialog(
        isEditMode: _isEditMode,
        editingTransport: _editingTransport,
        quoteId: widget.quoteId,
        onSave: _saveTransportFromDialog,
      ),
    );
  }

  Future<void> _saveTransportFromDialog(QuoteTransportDetail transportDetail) async {
    // Close the dialog first
    Navigator.of(context).pop();
    
    // Then save the transport
    setState(() => _isAddingTransport = true);
    try {
      final transportNotifier = ref.read(
        quoteTransportDetailsProvider(widget.quoteId).notifier,
      );

      if (_isEditMode && _editingTransport != null) {
        await transportNotifier.updateTransportDetail(transportDetail);
      } else {
        await transportNotifier.addTransportDetail(transportDetail);
      }

      // Force refresh the provider and reload data
      await transportNotifier.refresh();
      await _loadData();

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
        Log.e('Error saving transport: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving transport: ${e.toString()}'),
            backgroundColor: ChoiceLuxTheme.errorColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() => _isAddingTransport = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: LuxuryAppBar(
        title: 'Transport Details',
        subtitle: 'Quote #${widget.quoteId}',
        showBackButton: true,
        onBackPressed: () => context.go('/quotes/${widget.quoteId}'),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: ChoiceLuxTheme.backgroundGradient,
            ),
          ),
          // Background pattern
          CustomPaint(
            painter: BackgroundPatterns.dashboard,
            size: Size.infinite,
          ),
          // Main content
          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ChoiceLuxTheme.richGold,
                      ),
                    ),
                  )
                : _buildContent(),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildContent() {
    if (_transportDetails.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Total Amount Summary
        _buildTotalAmountCard(),
        
        const SizedBox(height: 16),
        
        // Transport Details List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _transportDetails.length,
            itemBuilder: (context, index) {
              final transport = _transportDetails[index];
              return _buildTransportCard(transport);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTotalAmountCard() {
    final totalAmount = _transportDetails.fold(0.0, (sum, transport) => sum + transport.amount);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ChoiceLuxTheme.richGold.withOpacity(0.1),
            ChoiceLuxTheme.richGold.withOpacity(0.05),
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
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.richGold,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long,
              color: Colors.black,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Quote Amount',
                  style: TextStyle(
                    color: ChoiceLuxTheme.platinumSilver,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'R${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: ChoiceLuxTheme.richGold,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.richGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_transportDetails.length} Trip${_transportDetails.length == 1 ? '' : 's'}',
              style: const TextStyle(
                color: ChoiceLuxTheme.richGold,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
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
          Icon(
            Icons.local_shipping_outlined,
            size: 64,
            color: ChoiceLuxTheme.platinumSilver,
          ),
          const SizedBox(height: 16),
          Text(
            'No transport details yet',
            style: TextStyle(
              fontSize: 18,
              color: ChoiceLuxTheme.platinumSilver,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add transport legs for this quote',
            style: TextStyle(
              fontSize: 14,
              color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransportCard(QuoteTransportDetail transport) {
    final index = _transportDetails.indexOf(transport);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive breakpoints for mobile optimization
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 600;
        final isSmallMobile = screenWidth < 400;
        
        // Responsive sizing
        final cardPadding = isSmallMobile ? 12.0 : isMobile ? 16.0 : 20.0;
        final spacing = isSmallMobile ? 8.0 : isMobile ? 12.0 : 16.0;
        final cornerRadius = isMobile ? 12.0 : 16.0;
        final iconSize = isSmallMobile ? 16.0 : isMobile ? 18.0 : 20.0;
        final titleSize = isSmallMobile ? 14.0 : isMobile ? 16.0 : 18.0;
        final subtitleSize = isSmallMobile ? 12.0 : isMobile ? 13.0 : 14.0;
        
        return Card(
          margin: EdgeInsets.only(bottom: spacing),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.1),
          color: ChoiceLuxTheme.charcoalGray.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cornerRadius),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(cornerRadius),
              border: Border.all(
                color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Trip Badge and Actions
                  _buildCardHeader(transport, index, spacing, iconSize),
                  
                  SizedBox(height: spacing),
                  
                  // Route Information
                  _buildRouteInfo(transport, titleSize, spacing),
                  
                  SizedBox(height: spacing * 0.75),
                  
                  // Date and Time Section
                  _buildDateTimeSection(transport, spacing, iconSize, subtitleSize),
                  
                  SizedBox(height: spacing * 0.75),
                  
                  // Amount Section
                  _buildAmountSection(transport, spacing, subtitleSize),
                  
                  // Notes Section (if exists)
                  if (transport.notes != null && transport.notes!.isNotEmpty) ...[
                    SizedBox(height: spacing * 0.75),
                    _buildNotesSection(transport, spacing, subtitleSize),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardHeader(QuoteTransportDetail transport, int index, double spacing, double iconSize) {
    return Row(
      children: [
        // Trip Sequence Badge
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: spacing * 0.75,
            vertical: spacing * 0.5,
          ),
          decoration: BoxDecoration(
            color: ChoiceLuxTheme.richGold,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            'Trip ${index + 1}',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        
        const Spacer(),
        
        // Action Menu
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: ChoiceLuxTheme.platinumSilver,
            size: iconSize,
          ),
          onSelected: (value) {
            if (value == 'edit') {
              _showEditTransportDialog(transport);
            } else if (value == 'delete') {
              _deleteTransport(transport);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 16, color: ChoiceLuxTheme.platinumSilver),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 16, color: ChoiceLuxTheme.errorColor),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRouteInfo(QuoteTransportDetail transport, double titleSize, double spacing) {
    return Container(
      padding: EdgeInsets.all(spacing * 0.75),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Pickup Location
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.radio_button_checked,
                      size: 12,
                      color: ChoiceLuxTheme.successColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'From',
                      style: TextStyle(
                        color: ChoiceLuxTheme.platinumSilver,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  transport.pickupLocation,
                  style: TextStyle(
                    color: ChoiceLuxTheme.softWhite,
                    fontSize: titleSize * 0.9,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          
          // Arrow
          Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing * 0.5),
            child: Icon(
              Icons.arrow_forward,
              color: ChoiceLuxTheme.richGold,
              size: 20,
            ),
          ),
          
          // Dropoff Location
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 12,
                      color: ChoiceLuxTheme.errorColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'To',
                      style: TextStyle(
                        color: ChoiceLuxTheme.platinumSilver,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  transport.dropoffLocation,
                  style: TextStyle(
                    color: ChoiceLuxTheme.softWhite,
                    fontSize: titleSize * 0.9,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection(QuoteTransportDetail transport, double spacing, double iconSize, double subtitleSize) {
    return Row(
      children: [
        // Date
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing * 0.75,
              vertical: spacing * 0.5,
            ),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.richGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: iconSize * 0.8,
                  color: ChoiceLuxTheme.richGold,
                ),
                SizedBox(width: spacing * 0.5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date',
                        style: TextStyle(
                          color: ChoiceLuxTheme.platinumSilver,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy').format(transport.pickupDate),
                        style: TextStyle(
                          color: ChoiceLuxTheme.softWhite,
                          fontSize: subtitleSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(width: spacing * 0.5),
        
        // Time
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing * 0.75,
              vertical: spacing * 0.5,
            ),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.richGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: iconSize * 0.8,
                  color: ChoiceLuxTheme.richGold,
                ),
                SizedBox(width: spacing * 0.5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time',
                        style: TextStyle(
                          color: ChoiceLuxTheme.platinumSilver,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm').format(transport.pickupDate),
                        style: TextStyle(
                          color: ChoiceLuxTheme.softWhite,
                          fontSize: subtitleSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountSection(QuoteTransportDetail transport, double spacing, double subtitleSize) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing * 0.75,
        vertical: spacing * 0.5,
      ),
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.richGold.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ChoiceLuxTheme.richGold.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.attach_money,
            size: 18,
            color: ChoiceLuxTheme.richGold,
          ),
          SizedBox(width: spacing * 0.5),
          Text(
            'Amount',
            style: TextStyle(
              color: ChoiceLuxTheme.platinumSilver,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            'R${transport.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: ChoiceLuxTheme.richGold,
              fontSize: subtitleSize + 2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(QuoteTransportDetail transport, double spacing, double subtitleSize) {
    return Container(
      padding: EdgeInsets.all(spacing * 0.75),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.note,
                size: 14,
                color: ChoiceLuxTheme.platinumSilver,
              ),
              SizedBox(width: spacing * 0.5),
              Text(
                'Notes',
                style: TextStyle(
                  color: ChoiceLuxTheme.platinumSilver,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            transport.notes!,
            style: TextStyle(
              color: ChoiceLuxTheme.softWhite,
              fontSize: subtitleSize,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _isAddingTransport ? null : _showAddTransportDialog,
      backgroundColor: ChoiceLuxTheme.richGold,
      foregroundColor: Colors.black,
      child: _isAddingTransport
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            )
          : const Icon(Icons.add),
    );
  }

  Future<void> _deleteTransport(QuoteTransportDetail transport) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ChoiceLuxTheme.charcoalGray,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Transport',
          style: TextStyle(color: ChoiceLuxTheme.softWhite),
        ),
        content: const Text(
          'Are you sure you want to delete this transport leg?',
          style: TextStyle(color: ChoiceLuxTheme.platinumSilver),
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
      setState(() => _isLoading = true);
      try {
        final transportNotifier = ref.read(
          quoteTransportDetailsProvider(widget.quoteId).notifier,
        );
        await transportNotifier.deleteTransportDetail(transport.id);
        
        // Force refresh the provider and reload data
        await transportNotifier.refresh();
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
          Log.e('Error deleting transport: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting transport: ${e.toString()}'),
              backgroundColor: ChoiceLuxTheme.errorColor,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _TransportDialog extends StatefulWidget {
  final bool isEditMode;
  final QuoteTransportDetail? editingTransport;
  final String quoteId;
  final Function(QuoteTransportDetail) onSave;

  const _TransportDialog({
    required this.isEditMode,
    required this.editingTransport,
    required this.quoteId,
    required this.onSave,
  });

  @override
  State<_TransportDialog> createState() => _TransportDialogState();
}

class _TransportDialogState extends State<_TransportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pickupLocationController = TextEditingController();
  final _dropoffLocationController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime? _selectedPickupDate;
  TimeOfDay? _selectedPickupTime;
  bool _isAddingTransport = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode && widget.editingTransport != null) {
      _populateForm();
    }
  }

  void _populateForm() {
    final transport = widget.editingTransport!;
    _pickupLocationController.text = transport.pickupLocation;
    _dropoffLocationController.text = transport.dropoffLocation;
    _amountController.text = transport.amount.toString();
    _notesController.text = transport.notes ?? '';
    _selectedPickupDate = transport.pickupDate;
    _selectedPickupTime = TimeOfDay.fromDateTime(transport.pickupDate);
  }

  @override
  void dispose() {
    _pickupLocationController.dispose();
    _dropoffLocationController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ChoiceLuxTheme.charcoalGray,
      title: Text(
        widget.isEditMode ? 'Edit Transport Leg' : 'Add Transport Leg',
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

                // Date and Time Row
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
                  decoration: const InputDecoration(
                    labelText: 'Amount (R) *',
                    border: OutlineInputBorder(),
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

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
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
              : Text(widget.isEditMode ? 'Update' : 'Add'),
        ),
      ],
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
        // If we have a time selected, combine it with the new date
        if (_selectedPickupTime != null) {
          _selectedPickupDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            _selectedPickupTime!.hour,
            _selectedPickupTime!.minute,
          );
        } else {
          // Store just the date part if no time is selected
          _selectedPickupDate = DateTime(picked.year, picked.month, picked.day);
        }
      });
      Log.d('Date selected: $_selectedPickupDate');
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
        } else {
          // If no date is selected, use today's date with the selected time
          final now = DateTime.now();
          _selectedPickupDate = DateTime(
            now.year,
            now.month,
            now.day,
            picked.hour,
            picked.minute,
          );
        }
      });
      Log.d('Time selected: $_selectedPickupTime, Combined date: $_selectedPickupDate');
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
      final transportDetail = QuoteTransportDetail(
        id: widget.isEditMode && widget.editingTransport != null 
            ? widget.editingTransport!.id 
            : '',
        quoteId: widget.quoteId,
        pickupDate: _selectedPickupDate!,
        pickupLocation: _pickupLocationController.text.trim(),
        dropoffLocation: _dropoffLocationController.text.trim(),
        amount: double.parse(_amountController.text),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      widget.onSave(transportDetail);
    } catch (e) {
      if (mounted) {
        Log.e('Error creating transport detail: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating transport detail: ${e.toString()}'),
            backgroundColor: ChoiceLuxTheme.errorColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() => _isAddingTransport = false);
    }
  }
}
