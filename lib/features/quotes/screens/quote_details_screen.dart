import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/core/services/supabase_service.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/features/quotes/models/quote.dart';
import 'package:choice_lux_cars/features/quotes/providers/quotes_provider.dart';
import 'package:choice_lux_cars/features/quotes/services/quote_pdf_service.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:choice_lux_cars/shared/services/pdf_viewer_service.dart';

class QuoteDetailsScreen extends ConsumerStatefulWidget {
  final String quoteId;

  const QuoteDetailsScreen({super.key, required this.quoteId});

  @override
  ConsumerState<QuoteDetailsScreen> createState() => _QuoteDetailsScreenState();
}

class _QuoteDetailsScreenState extends ConsumerState<QuoteDetailsScreen> {
  bool _isEditMode = false;
  bool _isLoading = false;
  bool _isGeneratingPdf = false;
  Quote? _quote;
  Quote? _originalQuote;

  // Form controllers for edit mode
  final _formKey = GlobalKey<FormState>();
  final _passengerNameController = TextEditingController();
  final _passengerContactController = TextEditingController();
  final _pasCountController = TextEditingController();
  final _luggageController = TextEditingController();
  final _notesController = TextEditingController();
  final _quoteTitleController = TextEditingController();
  final _quoteDescriptionController = TextEditingController();

  // Form values for edit mode
  String? _selectedClientId;
  String? _selectedAgentId;
  String? _selectedVehicleId;
  String? _selectedDriverId;
  String? _selectedLocation;
  DateTime? _selectedJobDate;
  String _selectedVehicleType = '';
  String _selectedStatus = '';

  @override
  void initState() {
    super.initState();
    _loadQuote();
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
    super.dispose();
  }

  Future<void> _loadQuote() async {
    setState(() => _isLoading = true);
    try {
      final quote = await ref
          .read(quotesProvider.notifier)
          .getQuote(widget.quoteId);
      if (quote != null) {
        setState(() {
          _quote = quote;
          _originalQuote = quote;
          _initializeFormData();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading quote: $e'),
            backgroundColor: ChoiceLuxTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Get transport details total
  double get _transportTotal {
    try {
      final transportDetails = ref.read(
        quoteTransportDetailsProvider(widget.quoteId),
      );
      final list = transportDetails.value ?? [];
      return list.fold(0.0, (sum, transport) => sum + transport.amount);
    } catch (e) {
      return 0.0;
    }
  }

  void _initializeFormData() {
    if (_quote == null) return;

    _passengerNameController.text = _quote!.passengerName ?? '';
    _passengerContactController.text = _quote!.passengerContact ?? '';
    _pasCountController.text = _quote!.pasCount.toString();
    _luggageController.text = _quote!.luggage;
    _notesController.text = _quote!.notes ?? '';
    _quoteTitleController.text = _quote!.quoteTitle ?? '';
    _quoteDescriptionController.text = _quote!.quoteDescription ?? '';

    _selectedClientId = _quote!.clientId;
    _selectedAgentId = _quote!.agentId;
    _selectedVehicleId = _quote!.vehicleId;
    _selectedDriverId = _quote!.driverId;
    _selectedLocation = _quote!.location;
    _selectedJobDate = _quote!.jobDate;
    _selectedVehicleType = _quote!.vehicleType ?? '';
    _selectedStatus = _quote!.quoteStatus;
  }

  bool get _canEdit {
    final currentUser = ref.read(currentUserProfileProvider);
    if (currentUser == null) return false;

    final role = currentUser.role?.toLowerCase();
    return role == 'administrator' || role == 'manager';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 400;

    if (_isLoading) {
      return Scaffold(
        appBar: LuxuryAppBar(
          title: 'Quote Details',
          showBackButton: true,
          onBackPressed: () => context.go('/quotes'),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ChoiceLuxTheme.richGold),
          ),
        ),
      );
    }

    if (_quote == null) {
      return Scaffold(
        appBar: LuxuryAppBar(
          title: 'Quote Details',
          showBackButton: true,
          onBackPressed: () => context.go('/quotes'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: ChoiceLuxTheme.errorColor,
              ),
              const SizedBox(height: 16),
              const Text(
                'Quote not found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: ChoiceLuxTheme.softWhite,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/quotes'),
                child: const Text('Back to Quotes'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: LuxuryAppBar(
        title: 'Quote #${_quote!.id}',
        subtitle: _isEditMode ? 'Edit Quote' : 'Quote Details',
        showBackButton: true,
        onBackPressed: () =>
            _isEditMode ? _cancelEdit() : context.go('/quotes'),
        actions: [
          if (_canEdit && !_isEditMode)
            IconButton(
              onPressed: _enterEditMode,
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Quote',
            ),
          if (_isEditMode) ...[
            IconButton(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save),
              tooltip: 'Save Changes',
            ),
            IconButton(
              onPressed: _cancelEdit,
              icon: const Icon(Icons.close),
              tooltip: 'Cancel Edit',
            ),
          ],
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: ChoiceLuxTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              isSmallMobile
                  ? 12
                  : isMobile
                  ? 16
                  : 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Status and Actions
                _buildHeader(isMobile, isSmallMobile),

                const SizedBox(height: 24),

                // Main Content
                if (_isEditMode)
                  _buildEditForm(isMobile, isSmallMobile)
                else
                  _buildViewContent(isMobile, isSmallMobile),

                const SizedBox(height: 24),

                // Action Buttons
                _buildActionButtons(isMobile, isSmallMobile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile, bool isSmallMobile) {
    return Container(
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
        border: Border.all(color: _getStatusColor().withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quote #${_quote!.id}',
                      style: TextStyle(
                        fontSize: isSmallMobile
                            ? 18
                            : isMobile
                            ? 20
                            : 24,
                        fontWeight: FontWeight.w700,
                        color: ChoiceLuxTheme.richGold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _quote!.quoteTitle ?? 'Untitled Quote',
                      style: TextStyle(
                        fontSize: isSmallMobile
                            ? 14
                            : isMobile
                            ? 16
                            : 18,
                        color: ChoiceLuxTheme.softWhite,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallMobile
                      ? 8
                      : isMobile
                      ? 12
                      : 16,
                  vertical: isSmallMobile
                      ? 4
                      : isMobile
                      ? 6
                      : 8,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getStatusColor().withOpacity(0.3)),
                ),
                child: Text(
                  _quote!.statusDisplayName,
                  style: TextStyle(
                    fontSize: isSmallMobile
                        ? 12
                        : isMobile
                        ? 14
                        : 16,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: isSmallMobile
                    ? 16
                    : isMobile
                    ? 18
                    : 20,
                color: ChoiceLuxTheme.platinumSilver,
              ),
              const SizedBox(width: 8),
              Text(
                'Created: ${_formatDate(_quote!.createdAt)}',
                style: TextStyle(
                  fontSize: isSmallMobile
                      ? 12
                      : isMobile
                      ? 14
                      : 16,
                  color: ChoiceLuxTheme.platinumSilver,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_quote!.quoteAmount != null) ...[
                    Text(
                      'R ${_quote!.quoteAmount!.toStringAsFixed(2)}',
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
                  ],
                  if (_transportTotal > 0) ...[
                    Text(
                      'Transport: R ${_transportTotal.toStringAsFixed(2)}',
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
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewContent(bool isMobile, bool isSmallMobile) {
    return Column(
      children: [
        // Passenger Information
        _buildInfoSection(
          title: 'Passenger Information',
          icon: Icons.person,
          children: [
            _buildInfoRow('Name', _quote!.passengerName ?? 'Not specified'),
            _buildInfoRow(
              'Contact',
              _quote!.passengerContact ?? 'Not specified',
            ),
            _buildInfoRow('Passengers', '${_quote!.pasCount.toInt()}'),
            _buildInfoRow('Luggage', _quote!.luggage),
          ],
        ),

        const SizedBox(height: 16),

        // Trip Information
        _buildInfoSection(
          title: 'Trip Information',
          icon: Icons.route,
          children: [
            _buildInfoRow('Job Date', _formatDate(_quote!.jobDate)),
            _buildInfoRow('Location', _quote!.location ?? 'Not specified'),
            _buildInfoRow(
              'Vehicle Type',
              _quote!.vehicleType ?? 'Not specified',
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Quote Details
        _buildInfoSection(
          title: 'Quote Details',
          icon: Icons.description,
          children: [
            _buildInfoRow('Title', _quote!.quoteTitle ?? 'Not specified'),
            _buildInfoRow(
              'Description',
              _quote!.quoteDescription ?? 'Not specified',
            ),
            _buildInfoRow('Status', _quote!.statusDisplayName),
          ],
        ),

        if (_quote!.notes?.isNotEmpty == true) ...[
          const SizedBox(height: 16),
          _buildInfoSection(
            title: 'Additional Notes',
            icon: Icons.note,
            children: [_buildInfoRow('Notes', _quote!.notes!)],
          ),
        ],
      ],
    );
  }

  Widget _buildEditForm(bool isMobile, bool isSmallMobile) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Passenger Information
          _buildEditSection(
            title: 'Passenger Information',
            icon: Icons.person,
            children: [
              _buildTextField(
                controller: _passengerNameController,
                label: 'Passenger Name',
                isRequired: false,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passengerContactController,
                label: 'Contact Number',
                isRequired: false,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _pasCountController,
                label: 'Number of Passengers',
                isRequired: true,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _luggageController,
                label: 'Luggage Description',
                isRequired: true,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Quote Details
          _buildEditSection(
            title: 'Quote Details',
            icon: Icons.description,
            children: [
              _buildTextField(
                controller: _quoteTitleController,
                label: 'Quote Title',
                isRequired: false,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _quoteDescriptionController,
                label: 'Quote Description',
                isRequired: false,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _notesController,
                label: 'Additional Notes',
                isRequired: false,
                maxLines: 4,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: ChoiceLuxTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: ChoiceLuxTheme.richGold, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ChoiceLuxTheme.softWhite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildEditSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: ChoiceLuxTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: ChoiceLuxTheme.richGold, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ChoiceLuxTheme.softWhite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ChoiceLuxTheme.platinumSilver,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: ChoiceLuxTheme.softWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool isRequired,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        border: const OutlineInputBorder(),
      ),
      validator: isRequired
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label is required';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildActionButtons(bool isMobile, bool isSmallMobile) {
    return Column(
      children: [
        // Primary Actions Row 1
        Row(
          children: [
            // Show Generate PDF only if no PDF exists
            if (_quote?.quotePdf == null || _quote!.quotePdf!.isEmpty) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isGeneratingPdf ? null : _generatePdf,
                  icon: _isGeneratingPdf
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.picture_as_pdf),
                  label: Text(
                    _isGeneratingPdf ? 'Generating...' : 'Generate PDF',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ChoiceLuxTheme.richGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
            // Show Regenerate PDF only if PDF exists
            if (_quote?.quotePdf != null && _quote!.quotePdf!.isNotEmpty) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isGeneratingPdf ? null : _regeneratePdf,
                  icon: _isGeneratingPdf
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(
                    _isGeneratingPdf ? 'Regenerating...' : 'Regenerate PDF',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ChoiceLuxTheme.warningColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    context.go('/quotes/${widget.quoteId}/transport-details'),
                icon: const Icon(Icons.route),
                label: const Text('Transport Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ChoiceLuxTheme.charcoalGray,
                  foregroundColor: ChoiceLuxTheme.softWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Share Quote Button (if PDF exists)
        if (_quote?.quotePdf != null && _quote!.quotePdf!.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _shareQuote,
              icon: const Icon(Icons.share),
              label: const Text('Share Quote'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ChoiceLuxTheme.successColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

        // View PDF Button (if PDF exists)
        if (_quote?.quotePdf != null && _quote!.quotePdf!.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openPdf(_quote!.quotePdf!),
              icon: const Icon(Icons.visibility),
              label: const Text('View PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ChoiceLuxTheme.successColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],

        const SizedBox(height: 12),

        // Status Management (if can edit)
        if (_canEdit && !_isEditMode)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.charcoalGray.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Management',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ChoiceLuxTheme.softWhite,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _getValidDropdownValue(_quote!.quoteStatus),
                  decoration: const InputDecoration(
                    labelText: 'Quote Status',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'draft',
                      child: Text('Draft'),
                    ),
                    const DropdownMenuItem(value: 'open', child: Text('Open')),
                    const DropdownMenuItem(value: 'sent', child: Text('Sent')),
                    const DropdownMenuItem(
                      value: 'accepted',
                      child: Text('Accepted'),
                    ),
                    const DropdownMenuItem(
                      value: 'rejected',
                      child: Text('Rejected'),
                    ),
                    const DropdownMenuItem(
                      value: 'expired',
                      child: Text('Expired'),
                    ),
                    const DropdownMenuItem(
                      value: 'closed',
                      child: Text('Closed'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      _updateQuoteStatus(value);
                    }
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _enterEditMode() {
    setState(() => _isEditMode = true);
  }

  void _cancelEdit() {
    setState(() {
      _isEditMode = false;
      _initializeFormData(); // Reset form data
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final updatedQuote = _quote!.copyWith(
        passengerName: _passengerNameController.text.trim().isEmpty
            ? null
            : _passengerNameController.text.trim(),
        passengerContact: _passengerContactController.text.trim().isEmpty
            ? null
            : _passengerContactController.text.trim(),
        pasCount: double.parse(_pasCountController.text),
        luggage: _luggageController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        quoteTitle: _quoteTitleController.text.trim().isEmpty
            ? null
            : _quoteTitleController.text.trim(),
        quoteDescription: _quoteDescriptionController.text.trim().isEmpty
            ? null
            : _quoteDescriptionController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await ref.read(quotesProvider.notifier).updateQuote(updatedQuote);

      setState(() {
        _quote = updatedQuote;
        _isEditMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quote updated successfully'),
            backgroundColor: ChoiceLuxTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating quote: $e'),
            backgroundColor: ChoiceLuxTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateQuoteStatus(String newStatus) async {
    try {
      final updatedQuote = _quote!.copyWith(
        quoteStatus: newStatus,
        updatedAt: DateTime.now(),
      );

      await ref.read(quotesProvider.notifier).updateQuote(updatedQuote);

      setState(() => _quote = updatedQuote);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quote status updated to $newStatus'),
            backgroundColor: ChoiceLuxTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: ChoiceLuxTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _generatePdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      if (_quote == null) throw Exception('Quote not found');

      // Fetch related data for PDF
      final transportDetails = await ref
          .read(quotesProvider.notifier)
          .getQuoteTransportDetails(widget.quoteId);

      // Fetch client, agent, vehicle, and driver data
      final clientData = await SupabaseService.instance.getClient(
        _quote!.clientId,
      );
      final agentData = _quote!.agentId != null
          ? await SupabaseService.instance.getAgent(_quote!.agentId!)
          : null;
      final vehicleData = _quote!.vehicleId != null
          ? await SupabaseService.instance.getVehicle(_quote!.vehicleId!)
          : null;
      final driverData = _quote!.driverId != null
          ? await SupabaseService.instance.getUser(_quote!.driverId!)
          : null;

      // Generate PDF
      final pdfService = QuotePdfService();
      final pdfBytes = await pdfService.buildQuotePdf(
        quote: _quote!,
        transportDetails: transportDetails,
        clientData: clientData ?? {},
        agentData: agentData,
        vehicleData: vehicleData,
        driverData: driverData,
      );

      // Upload to Supabase Storage
      final path = 'quotes/quote_${_quote!.id}.pdf';
      final supabase = Supabase.instance.client;

      try {
        await supabase.storage.from('pdfdocuments').remove([
          path,
        ]); // Force delete existing
      } catch (e) {
        // File might not exist, continue
      }

      final uploadedPath = await supabase.storage
          .from('pdfdocuments')
          .uploadBinary(
            path,
            pdfBytes,
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              upsert: true,
            ),
          );

      if (uploadedPath == null || uploadedPath.isEmpty) {
        throw Exception('Failed to upload PDF');
      }

      // Get public URL
      final publicUrl = supabase.storage
          .from('pdfdocuments')
          .getPublicUrl(path);

      // Update quote with PDF URL
      final updatedQuote = _quote!.copyWith(
        quotePdf: publicUrl,
        updatedAt: DateTime.now(),
      );

      await ref.read(quotesProvider.notifier).updateQuote(updatedQuote);
      setState(() => _quote = updatedQuote);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('PDF generated and saved successfully'),
            backgroundColor: ChoiceLuxTheme.successColor,
            action: SnackBarAction(
              label: 'View PDF',
              onPressed: () => _openPdf(publicUrl),
              textColor: Colors.white,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: ChoiceLuxTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _regeneratePdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      if (_quote == null) throw Exception('Quote not found');

      // Fetch related data for PDF
      final transportDetails = await ref
          .read(quotesProvider.notifier)
          .getQuoteTransportDetails(widget.quoteId);

      // Fetch client, agent, vehicle, and driver data
      final clientData = await SupabaseService.instance.getClient(
        _quote!.clientId,
      );
      final agentData = _quote!.agentId != null
          ? await SupabaseService.instance.getAgent(_quote!.agentId!)
          : null;
      final vehicleData = _quote!.vehicleId != null
          ? await SupabaseService.instance.getVehicle(_quote!.vehicleId!)
          : null;
      final driverData = _quote!.driverId != null
          ? await SupabaseService.instance.getUser(_quote!.driverId!)
          : null;

      // Generate PDF
      final pdfService = QuotePdfService();
      final pdfBytes = await pdfService.buildQuotePdf(
        quote: _quote!,
        transportDetails: transportDetails,
        clientData: clientData ?? {},
        agentData: agentData,
        vehicleData: vehicleData,
        driverData: driverData,
      );

      // Upload to Supabase Storage (force overwrite)
      final path = 'quotes/quote_${_quote!.id}.pdf';
      final supabase = Supabase.instance.client;

      // Always remove existing file for regeneration
      try {
        await supabase.storage.from('pdfdocuments').remove([path]);
      } catch (e) {
        // File might not exist, continue
      }

      final uploadedPath = await supabase.storage
          .from('pdfdocuments')
          .uploadBinary(
            path,
            pdfBytes,
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              upsert: true,
            ),
          );

      if (uploadedPath == null || uploadedPath.isEmpty) {
        throw Exception('Failed to upload PDF');
      }

      // Get public URL
      final publicUrl = supabase.storage
          .from('pdfdocuments')
          .getPublicUrl(path);

      // Update quote with PDF URL
      final updatedQuote = _quote!.copyWith(
        quotePdf: publicUrl,
        updatedAt: DateTime.now(),
      );

      await ref.read(quotesProvider.notifier).updateQuote(updatedQuote);
      setState(() => _quote = updatedQuote);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('PDF regenerated successfully'),
            backgroundColor: ChoiceLuxTheme.successColor,
            action: SnackBarAction(
              label: 'View PDF',
              onPressed: () => _openPdf(publicUrl),
              textColor: Colors.white,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error regenerating PDF: $e'),
            backgroundColor: ChoiceLuxTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _shareQuote() async {
    if (_quote?.quotePdf == null || _quote!.quotePdf!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No PDF available to share. Please generate a PDF first.',
          ),
          backgroundColor: ChoiceLuxTheme.warningColor,
        ),
      );
      return;
    }

    try {
      final url = _quote!.quotePdf!;

      // Show share options dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Share Quote'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy, color: ChoiceLuxTheme.richGold),
                title: const Text('Copy Link'),
                onTap: () {
                  Navigator.pop(context);
                  _copyToClipboard(url);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.email,
                  color: ChoiceLuxTheme.richGold,
                ),
                title: const Text('Share via Email'),
                onTap: () {
                  Navigator.pop(context);
                  _shareViaEmail(url);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing quote: $e'),
            backgroundColor: ChoiceLuxTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _copyToClipboard(String url) async {
    try {
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link copied to clipboard'),
            backgroundColor: ChoiceLuxTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error copying to clipboard: $e'),
            backgroundColor: ChoiceLuxTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _shareViaEmail(String url) async {
    try {
      final subject =
          'Quote #${_quote!.id} - ${_quote!.quoteTitle ?? 'Untitled Quote'}';
      final body =
          '''
Hello,

Please find the quote attached: ${_quote!.quoteTitle ?? 'Untitled Quote'}

Quote Details:
- Quote ID: ${_quote!.id}
- Job Date: ${_formatDate(_quote!.jobDate)}
- Location: ${_quote!.location ?? 'Not specified'}
- Amount: ${_quote!.quoteAmount != null ? 'R ${_quote!.quoteAmount!.toStringAsFixed(2)}' : 'Not specified'}

You can view the quote here: $url

Best regards,
Choice Lux Cars
''';

      final emailUrl =
          'mailto:?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
      await launchUrlString(emailUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening email: $e'),
            backgroundColor: ChoiceLuxTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _openPdf(String url) async {
    try {
      await PdfViewerService.openPdf(
        context: context,
        pdfUrl: url,
        title: 'Quote #${_quote!.id}',
        documentType: 'quote',
        documentData: {
          'id': _quote!.id,
          'title': _quote!.quoteTitle ?? 'Untitled Quote',
          'recipientEmail': _quote!.clientId, // You might want to get actual client email
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening PDF: $e'),
            backgroundColor: ChoiceLuxTheme.errorColor,
          ),
        );
      }
    }
  }

  Color _getStatusColor() {
    switch (_quote!.quoteStatus.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'open':
        return Colors.blue;
      case 'sent':
        return Colors.orange;
      case 'accepted':
        return ChoiceLuxTheme.successColor;
      case 'rejected':
        return ChoiceLuxTheme.errorColor;
      case 'expired':
        return ChoiceLuxTheme.errorColor;
      case 'closed':
        return Colors.grey[700]!;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getValidDropdownValue(String status) {
    final validStatuses = [
      'draft',
      'open',
      'sent',
      'accepted',
      'rejected',
      'expired',
      'closed',
    ];
    final normalizedStatus = status.toLowerCase().trim();

    if (validStatuses.contains(normalizedStatus)) {
      return normalizedStatus;
    }

    // Default to draft if status is not recognized
    return 'draft';
  }
}
