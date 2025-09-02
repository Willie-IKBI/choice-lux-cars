import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  const CreateQuoteScreen({super.key, this.quoteId});

  @override
  ConsumerState<CreateQuoteScreen> createState() => _CreateQuoteScreenState();
}

class _CreateQuoteScreenState extends ConsumerState<CreateQuoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Controllers
  final _passengerNameController = TextEditingController();
  final _passengerContactController = TextEditingController();
  final _pasCountController = TextEditingController();
  final _luggageController = TextEditingController();
  final _notesController = TextEditingController();
  final _quoteTitleController = TextEditingController();
  final _quoteDescriptionController = TextEditingController();
  final _clientSearchController = TextEditingController();

  // Focus nodes for better mobile keyboard handling
  final _passengerNameFocus = FocusNode();
  final _passengerContactFocus = FocusNode();
  final _pasCountFocus = FocusNode();
  final _luggageFocus = FocusNode();
  final _quoteTitleFocus = FocusNode();
  final _quoteDescriptionFocus = FocusNode();
  final _notesFocus = FocusNode();

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

  // Get progress message for mobile
  String _getProgressMessage() {
    final completedFields = (_completionPercentage * 8).toInt();

    if (completedFields == 0) {
      return 'Start by selecting a client and vehicle';
    } else if (completedFields <= 2) {
      return 'Great start! Add driver and location details';
    } else if (completedFields <= 4) {
      return 'Almost there! Complete passenger information';
    } else if (completedFields <= 6) {
      return 'Nearly complete! Add final details';
    } else if (completedFields <= 7) {
      return 'Almost ready! Just a few more fields';
    } else {
      return 'Ready to create your quote!';
    }
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

    // Dispose focus nodes
    _passengerNameFocus.dispose();
    _passengerContactFocus.dispose();
    _pasCountFocus.dispose();
    _luggageFocus.dispose();
    _quoteTitleFocus.dispose();
    _quoteDescriptionFocus.dispose();
    _notesFocus.dispose();

    // Dispose scroll controller
    _scrollController.dispose();

    super.dispose();
  }

  // Scroll to submit button for mobile keyboard handling
  void _scrollToSubmitButton() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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

        final createdQuote = await ref
            .read(quotesProvider.notifier)
            .createQuote(quote);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Quote created successfully! Moving to transport details...',
              ),
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
    // Responsive breakpoints for mobile optimization
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 400;
    final isTablet = screenWidth >= 600 && screenWidth < 800;
    final isDesktop = screenWidth >= 800;
    final isLargeDesktop = screenWidth >= 1200;

    final maxWidth = _getMaxWidth(screenWidth);

    return Scaffold(
      appBar: LuxuryAppBar(
        title: widget.quoteId != null ? 'Edit Quote' : 'Create New Quote',
        subtitle: widget.quoteId != null
            ? 'Update Quote Details'
            : 'Step 1: Quote Details',
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

          return clientsAsync.when(
            data: (clients) => vehiclesState.when(
              data: (vehicles) => users.when(
                data: (usersList) => _buildForm(
                  clients,
                  vehicles,
                  usersList,
                  isMobile,
                  isSmallMobile,
                ),
                loading: () =>
                    _buildMobileLoadingState(isMobile, isSmallMobile),
                error: (error, stack) =>
                    _buildErrorState(error, isMobile, isSmallMobile),
              ),
              loading: () => _buildMobileLoadingState(isMobile, isSmallMobile),
              error: (error, stack) =>
                  _buildErrorState(error, isMobile, isSmallMobile),
            ),
            loading: () => _buildMobileLoadingState(isMobile, isSmallMobile),
            error: (error, stack) =>
                _buildErrorState(error, isMobile, isSmallMobile),
          );
        },
      ),
    );
  }

  Widget _buildForm(
    List<dynamic> clients,
    List<dynamic> vehicles,
    List<dynamic> users,
    bool isMobile,
    bool isSmallMobile,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = _getMaxWidth(screenWidth);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.all(
            isSmallMobile
                ? 12.0
                : isMobile
                ? 16.0
                : 24.0,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress indicator
                _buildMobileProgressIndicator(isMobile, isSmallMobile),
                SizedBox(
                  height: isSmallMobile
                      ? 12.0
                      : isMobile
                      ? 16.0
                      : 20.0,
                ),

                // Client Selection
                _buildClientSelection(clients, isMobile, isSmallMobile),
                SizedBox(
                  height: isSmallMobile
                      ? 12.0
                      : isMobile
                      ? 16.0
                      : 20.0,
                ),

                // Agent Selection (auto-populated from client)
                _buildAgentSelection(clients, isMobile, isSmallMobile),
                SizedBox(
                  height: isSmallMobile
                      ? 12.0
                      : isMobile
                      ? 16.0
                      : 20.0,
                ),

                // Vehicle Selection
                _buildVehicleSelection(vehicles, isMobile, isSmallMobile),
                SizedBox(
                  height: isSmallMobile
                      ? 12.0
                      : isMobile
                      ? 16.0
                      : 20.0,
                ),

                // Driver Selection
                _buildDriverSelection(users, isMobile, isSmallMobile),
                SizedBox(
                  height: isSmallMobile
                      ? 12.0
                      : isMobile
                      ? 16.0
                      : 20.0,
                ),

                // Location and Date
                _buildLocationAndDateSection(isMobile, isSmallMobile),
                SizedBox(
                  height: isSmallMobile
                      ? 12.0
                      : isMobile
                      ? 16.0
                      : 20.0,
                ),

                // Passenger Details
                _buildPassengerDetails(isMobile, isSmallMobile),
                SizedBox(
                  height: isSmallMobile
                      ? 12.0
                      : isMobile
                      ? 16.0
                      : 20.0,
                ),

                // Quote Details
                _buildQuoteDetails(isMobile, isSmallMobile),
                SizedBox(
                  height: isSmallMobile
                      ? 12.0
                      : isMobile
                      ? 16.0
                      : 20.0,
                ),

                // Notes
                _buildNotesSection(isMobile, isSmallMobile),
                SizedBox(
                  height: isSmallMobile
                      ? 20.0
                      : isMobile
                      ? 24.0
                      : 28.0,
                ),

                // Submit Button
                _buildMobileSubmitButton(isMobile, isSmallMobile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _getMaxWidth(double screenWidth) {
    // Responsive max-width calculations for optimal form display
    if (screenWidth < 400) {
      // Small mobile: full width with minimal padding
      return screenWidth - 24;
    } else if (screenWidth < 600) {
      // Mobile: full width with comfortable padding
      return screenWidth - 32;
    } else if (screenWidth < 768) {
      // Large mobile/Small tablet: 600px max for better readability
      return 600;
    } else if (screenWidth < 1024) {
      // Tablet: 700px max for optimal form width
      return 700;
    } else if (screenWidth < 1200) {
      // Small desktop: 800px max for comfortable reading
      return 800;
    } else if (screenWidth < 1440) {
      // Desktop: 900px max for optimal form layout
      return 900;
    } else {
      // Large desktop: 1000px max to prevent excessive line length
      return 1000;
    }
  }

  // Helper method to calculate optimal form field widths
  double _getFormFieldWidth(double screenWidth) {
    if (screenWidth < 600) {
      return double.infinity; // Full width on mobile
    } else if (screenWidth < 900) {
      return 280; // Fixed width for tablet
    } else {
      return 320; // Fixed width for desktop
    }
  }

  // Mobile-optimized progress indicator with enhanced features
  Widget _buildMobileProgressIndicator(bool isMobile, bool isSmallMobile) {
    final completionPercent = (_completionPercentage * 100).toInt();
    final isComplete = completionPercent == 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar with animation
        Container(
          width: double.infinity,
          height: isSmallMobile
              ? 6
              : isMobile
              ? 8
              : 10,
          decoration: BoxDecoration(
            color: ChoiceLuxTheme.charcoalGray.withOpacity(0.3),
            borderRadius: BorderRadius.circular(isSmallMobile ? 3 : 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background progress
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _completionPercentage,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isComplete
                          ? [
                              ChoiceLuxTheme.successColor,
                              ChoiceLuxTheme.successColor.withOpacity(0.8),
                            ]
                          : [
                              ChoiceLuxTheme.richGold,
                              ChoiceLuxTheme.richGold.withOpacity(0.8),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(isSmallMobile ? 3 : 4),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isComplete
                                    ? ChoiceLuxTheme.successColor
                                    : ChoiceLuxTheme.richGold)
                                .withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              // Animated shimmer effect for mobile
              if (isMobile && !isComplete && _completionPercentage > 0)
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _completionPercentage,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.3),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(
                        isSmallMobile ? 3 : 4,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: isSmallMobile ? 6 : 8),

        // Progress text with status
        Row(
          children: [
            Expanded(
              child: Text(
                isComplete
                    ? 'Form Complete! Ready to submit'
                    : '$completionPercent% Complete',
                style: TextStyle(
                  fontSize: isSmallMobile
                      ? 11
                      : isMobile
                      ? 12
                      : 14,
                  color: isComplete
                      ? ChoiceLuxTheme.successColor
                      : ChoiceLuxTheme.platinumSilver,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Status icon
            if (isComplete)
              Icon(
                Icons.check_circle,
                color: ChoiceLuxTheme.successColor,
                size: isSmallMobile
                    ? 16
                    : isMobile
                    ? 18
                    : 20,
              ),
          ],
        ),

        // Progress details for mobile
        if (isMobile && !isComplete) ...[
          SizedBox(height: isSmallMobile ? 4 : 6),
          Text(
            _getProgressMessage(),
            style: TextStyle(
              fontSize: isSmallMobile
                  ? 10
                  : isMobile
                  ? 11
                  : 12,
              color: ChoiceLuxTheme.platinumSilver.withOpacity(0.8),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  // Mobile-optimized loading state
  Widget _buildMobileLoadingState(bool isMobile, bool isSmallMobile) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(
              isSmallMobile
                  ? 16
                  : isMobile
                  ? 20
                  : 24,
            ),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.charcoalGray.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              color: ChoiceLuxTheme.richGold,
              strokeWidth: isMobile ? 2.0 : 3.0,
            ),
          ),
          SizedBox(
            height: isSmallMobile
                ? 16
                : isMobile
                ? 20
                : 24,
          ),
          Text(
            'Loading form data...',
            style: TextStyle(
              fontSize: isSmallMobile
                  ? 14
                  : isMobile
                  ? 16
                  : 18,
              fontWeight: FontWeight.w500,
              color: ChoiceLuxTheme.softWhite,
            ),
          ),
          SizedBox(
            height: isSmallMobile
                ? 8
                : isMobile
                ? 10
                : 12,
          ),
          Text(
            'Please wait while we prepare the quote form',
            style: TextStyle(
              fontSize: isSmallMobile
                  ? 12
                  : isMobile
                  ? 13
                  : 14,
              color: ChoiceLuxTheme.platinumSilver,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Mobile-optimized error state
  Widget _buildErrorState(Object error, bool isMobile, bool isSmallMobile) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(
              isSmallMobile
                  ? 20
                  : isMobile
                  ? 24
                  : 28,
            ),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.charcoalGray.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: isSmallMobile
                  ? 40
                  : isMobile
                  ? 48
                  : 56,
              color: ChoiceLuxTheme.errorColor,
            ),
          ),
          SizedBox(
            height: isSmallMobile
                ? 16
                : isMobile
                ? 20
                : 24,
          ),
          Text(
            'Error loading form data',
            style: TextStyle(
              fontSize: isSmallMobile
                  ? 16
                  : isMobile
                  ? 18
                  : 20,
              fontWeight: FontWeight.w500,
              color: ChoiceLuxTheme.softWhite,
            ),
          ),
          SizedBox(
            height: isSmallMobile
                ? 8
                : isMobile
                ? 10
                : 12,
          ),
          Text(
            error.toString(),
            style: TextStyle(
              fontSize: isSmallMobile
                  ? 12
                  : isMobile
                  ? 13
                  : 14,
              color: ChoiceLuxTheme.platinumSilver,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: isSmallMobile
                ? 16
                : isMobile
                ? 20
                : 24,
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Refresh data
              ref.invalidate(vehiclesProvider);
              ref.invalidate(clientsProvider);
            },
            icon: Icon(
              Icons.refresh,
              size: isSmallMobile
                  ? 16
                  : isMobile
                  ? 18
                  : 20,
            ),
            label: Text(
              'Retry',
              style: TextStyle(
                fontSize: isSmallMobile
                    ? 14
                    : isMobile
                    ? 16
                    : 18,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: ChoiceLuxTheme.richGold,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(
                horizontal: isSmallMobile
                    ? 16
                    : isMobile
                    ? 20
                    : 24,
                vertical: isSmallMobile
                    ? 12
                    : isMobile
                    ? 14
                    : 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Mobile-optimized client selection with search functionality
  Widget _buildClientSelection(
    List<dynamic> clients,
    bool isMobile,
    bool isSmallMobile,
  ) {
    final filteredClients = clients.where((client) {
      if (_clientSearchQuery.isEmpty) return true;
      return client.companyName.toLowerCase().contains(
        _clientSearchQuery.toLowerCase(),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Client *',
          style: TextStyle(
            fontSize: isSmallMobile
                ? 14
                : isMobile
                ? 16
                : 18,
            fontWeight: FontWeight.w600,
            color: ChoiceLuxTheme.softWhite,
          ),
        ),
        SizedBox(
          height: isSmallMobile
              ? 4
              : isMobile
              ? 6
              : 8,
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isSmallMobile ? 8 : 12),
            border: Border.all(
              color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Search input
              TextFormField(
                controller: _clientSearchController,
                onChanged: (value) {
                  setState(() {
                    _clientSearchQuery = value;
                    _showClientDropdown = true;
                  });
                },
                onTap: () {
                  setState(() {
                    _showClientDropdown = true;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search for a client...',
                  hintStyle: TextStyle(
                    color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7),
                    fontSize: isSmallMobile
                        ? 13
                        : isMobile
                        ? 14
                        : 16,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: ChoiceLuxTheme.platinumSilver,
                    size: isSmallMobile
                        ? 18
                        : isMobile
                        ? 20
                        : 24,
                  ),
                  suffixIcon: _selectedClientId != null
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            size: isSmallMobile
                                ? 18
                                : isMobile
                                ? 20
                                : 24,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedClientId = null;
                              _selectedAgentId =
                                  null; // Reset agent when client changes
                              _clientSearchController.clear();
                              _clientSearchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isSmallMobile ? 12 : 16,
                    vertical: isSmallMobile ? 12 : 16,
                  ),
                ),
                validator: (value) {
                  if (_selectedClientId == null) {
                    return 'Please select a client';
                  }
                  return null;
                },
              ),

              // Selected client display
              if (_selectedClientId != null)
                Container(
                  padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
                  decoration: BoxDecoration(
                    color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                    border: Border(
                      top: BorderSide(
                        color: ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.business,
                        color: ChoiceLuxTheme.richGold,
                        size: isSmallMobile
                            ? 18
                            : isMobile
                            ? 20
                            : 24,
                      ),
                      SizedBox(width: isSmallMobile ? 8 : 12),
                      Expanded(
                        child: Text(
                          clients
                              .firstWhere(
                                (c) => c.id.toString() == _selectedClientId,
                              )
                              .companyName,
                          style: TextStyle(
                            color: ChoiceLuxTheme.richGold,
                            fontWeight: FontWeight.w500,
                            fontSize: isSmallMobile
                                ? 13
                                : isMobile
                                ? 14
                                : 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Dropdown list
              if (_showClientDropdown && filteredClients.isNotEmpty)
                Container(
                  constraints: BoxConstraints(
                    maxHeight: isSmallMobile ? 150 : 200,
                  ),
                  decoration: BoxDecoration(
                    color: ChoiceLuxTheme.charcoalGray,
                    border: Border(
                      top: BorderSide(
                        color: ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredClients.length,
                    itemBuilder: (context, index) {
                      final client = filteredClients[index];
                      return ListTile(
                        leading: Icon(
                          Icons.business,
                          color: ChoiceLuxTheme.platinumSilver,
                          size: isSmallMobile
                              ? 18
                              : isMobile
                              ? 20
                              : 24,
                        ),
                        title: Text(
                          client.companyName,
                          style: TextStyle(
                            color: ChoiceLuxTheme.softWhite,
                            fontSize: isSmallMobile
                                ? 13
                                : isMobile
                                ? 14
                                : 16,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedClientId = client.id.toString();
                            _selectedAgentId =
                                null; // Reset agent when client changes
                            _clientSearchController.text = client.companyName;
                            _showClientDropdown = false;
                          });
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Mobile-optimized agent selection
  Widget _buildAgentSelection(
    List<dynamic> clients,
    bool isMobile,
    bool isSmallMobile,
  ) {
    if (_selectedClientId == null) {
      return Container(
        padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
        decoration: BoxDecoration(
          color: ChoiceLuxTheme.charcoalGray.withOpacity(0.5),
          borderRadius: BorderRadius.circular(isSmallMobile ? 8 : 12),
          border: Border.all(
            color: ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: ChoiceLuxTheme.platinumSilver,
              size: isSmallMobile
                  ? 18
                  : isMobile
                  ? 20
                  : 24,
            ),
            SizedBox(width: isSmallMobile ? 8 : 12),
            Expanded(
              child: Text(
                'Please select a client first to choose an agent',
                style: TextStyle(
                  color: ChoiceLuxTheme.platinumSilver,
                  fontSize: isSmallMobile
                      ? 13
                      : isMobile
                      ? 14
                      : 16,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Consumer(
      builder: (context, ref, child) {
        // Guard against null client ID
        if (_selectedClientId == null) {
          return Container(
            padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.charcoalGray.withOpacity(0.5),
              borderRadius: BorderRadius.circular(isSmallMobile ? 8 : 12),
              border: Border.all(
                color: ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: ChoiceLuxTheme.platinumSilver,
                  size: isSmallMobile
                      ? 18
                      : isMobile
                      ? 20
                      : 24,
                ),
                SizedBox(width: isSmallMobile ? 8 : 12),
                Expanded(
                  child: Text(
                    'Please select a client first to choose an agent',
                    style: TextStyle(
                      color: ChoiceLuxTheme.platinumSilver,
                                          fontSize: isSmallMobile
                        ? 13
                        : isMobile
                        ? 16
                        : 18,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final agentsAsync = ref.watch(
          agentsForClientProvider(_selectedClientId!),
        );

        return agentsAsync.when(
          data: (agents) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Agent',
                style: TextStyle(
                  fontSize: isSmallMobile
                      ? 14
                      : isMobile
                      ? 16
                      : 18,
                  fontWeight: FontWeight.w600,
                  color: ChoiceLuxTheme.softWhite,
                ),
              ),
              SizedBox(
                height: isSmallMobile
                    ? 4
                    : isMobile
                    ? 6
                    : 8,
              ),
              _buildResponsiveDropdown(
                value: _selectedAgentId,
                hintText: 'Select an agent (optional)',
                items: agents.map((agent) {
                  return DropdownMenuItem(
                    value: agent.id.toString(),
                    child: Text(
                      agent.agentName,
                      style: TextStyle(
                        fontSize: isSmallMobile
                            ? 13
                            : isMobile
                            ? 14
                            : 16,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAgentId = value;
                  });
                },
                isMobile: isMobile,
                isSmallMobile: isSmallMobile,
              ),
            ],
          ),
          loading: () => Container(
            padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.charcoalGray.withOpacity(0.5),
              borderRadius: BorderRadius.circular(isSmallMobile ? 8 : 12),
              border: Border.all(
                color: ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: isSmallMobile
                      ? 18
                      : isMobile
                      ? 20
                      : 24,
                  height: isSmallMobile
                      ? 18
                      : isMobile
                      ? 20
                      : 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ChoiceLuxTheme.richGold,
                    ),
                  ),
                ),
                SizedBox(width: isSmallMobile ? 8 : 12),
                Text(
                  'Loading agents...',
                  style: TextStyle(
                    color: ChoiceLuxTheme.platinumSilver,
                    fontSize: isSmallMobile
                        ? 13
                        : isMobile
                        ? 14
                        : 16,
                  ),
                ),
              ],
            ),
          ),
          error: (error, stack) => Container(
            padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isSmallMobile ? 8 : 12),
              border: Border.all(
                color: ChoiceLuxTheme.errorColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: ChoiceLuxTheme.errorColor,
                  size: isSmallMobile
                      ? 18
                      : isMobile
                      ? 20
                      : 24,
                ),
                SizedBox(width: isSmallMobile ? 8 : 12),
                Expanded(
                  child: Text(
                    'Error loading agents',
                    style: TextStyle(
                      color: ChoiceLuxTheme.errorColor,
                      fontSize: isSmallMobile
                          ? 13
                          : isMobile
                          ? 14
                          : 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Mobile-optimized vehicle selection
  Widget _buildVehicleSelection(
    List<dynamic> vehicles,
    bool isMobile,
    bool isSmallMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicle *',
          style: TextStyle(
            fontSize: isSmallMobile
                ? 14
                : isMobile
                ? 16
                : 18,
            fontWeight: FontWeight.w600,
            color: ChoiceLuxTheme.softWhite,
          ),
        ),
        SizedBox(
          height: isSmallMobile
              ? 4
              : isMobile
              ? 6
              : 8,
        ),
        _buildResponsiveDropdown(
          value: _selectedVehicleId,
          hintText: 'Select a vehicle',
          items: vehicles.map((vehicle) {
            final isExpired =
                vehicle.licenseExpiryDate != null &&
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
                        fontSize: isSmallMobile
                            ? 13
                            : isMobile
                            ? 14
                            : 16,
                      ),
                    ),
                  ),
                  if (isExpired)
                    Icon(
                      Icons.warning,
                      color: ChoiceLuxTheme.errorColor,
                      size: isSmallMobile
                          ? 14
                          : isMobile
                          ? 16
                          : 18,
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
                final selectedVehicle = vehicles.firstWhere(
                  (v) => v.id.toString() == value,
                );
                _selectedVehicleType =
                    '${selectedVehicle.make} ${selectedVehicle.model}';
              }
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a vehicle';
            }
            return null;
          },
          isMobile: isMobile,
          isSmallMobile: isSmallMobile,
        ),
      ],
    );
  }

  // Mobile-optimized driver selection
  Widget _buildDriverSelection(
    List<dynamic> users,
    bool isMobile,
    bool isSmallMobile,
  ) {
    // Include all users as potential drivers, excluding unassigned and deactivated
    final drivers = users
        .where(
          (user) =>
              user.status != 'deactivated' &&
              user.status != 'unassigned' &&
              user.displayName.isNotEmpty,
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Driver *',
          style: TextStyle(
            fontSize: isSmallMobile
                ? 14
                : isMobile
                ? 16
                : 18,
            fontWeight: FontWeight.w600,
            color: ChoiceLuxTheme.softWhite,
          ),
        ),
        SizedBox(
          height: isSmallMobile
              ? 4
              : isMobile
              ? 6
              : 8,
        ),
        _buildResponsiveDropdown(
          value: _selectedDriverId,
          hintText: 'Select a driver (any user)',
          items: drivers.map((driver) {
            final isPdpExpired =
                driver.pdpExp != null &&
                driver.pdpExp!.isBefore(DateTime.now());
            final isLicenseExpired =
                driver.driverLicExp != null &&
                driver.driverLicExp!.isBefore(DateTime.now());

            return DropdownMenuItem(
              value: driver.id.toString(),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver.displayName,
                          style: TextStyle(
                            color: (isPdpExpired || isLicenseExpired)
                                ? ChoiceLuxTheme.errorColor
                                : null,
                            fontSize: isSmallMobile
                                ? 13
                                : isMobile
                                ? 14
                                : 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (driver.role != null && driver.role!.isNotEmpty)
                          Text(
                            '(${driver.role})',
                            style: TextStyle(
                              color: ChoiceLuxTheme.platinumSilver.withOpacity(
                                0.7,
                              ),
                              fontSize: isSmallMobile
                                  ? 11
                                  : isMobile
                                  ? 12
                                  : 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isPdpExpired || isLicenseExpired)
                    Icon(
                      Icons.warning,
                      color: ChoiceLuxTheme.errorColor,
                      size: isSmallMobile
                          ? 14
                          : isMobile
                          ? 16
                          : 18,
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
          isMobile: isMobile,
          isSmallMobile: isSmallMobile,
        ),
      ],
    );
  }

  // Mobile-optimized location and date section
  Widget _buildLocationAndDateSection(bool isMobile, bool isSmallMobile) {
    if (isMobile) {
      // Stack vertically on mobile
      return Column(
        children: [
          _buildLocationSelection(isMobile, isSmallMobile),
          SizedBox(height: isSmallMobile ? 12 : 16),
          _buildDateSelection(isMobile, isSmallMobile),
        ],
      );
    } else {
      // Side by side on desktop
      return Row(
        children: [
          Expanded(child: _buildLocationSelection(isMobile, isSmallMobile)),
          SizedBox(width: isSmallMobile ? 12 : 16),
          Expanded(child: _buildDateSelection(isMobile, isSmallMobile)),
        ],
      );
    }
  }

  // Mobile-optimized location selection
  Widget _buildLocationSelection(bool isMobile, bool isSmallMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location *',
          style: TextStyle(
            fontSize: isSmallMobile
                ? 14
                : isMobile
                ? 16
                : 18,
            fontWeight: FontWeight.w600,
            color: ChoiceLuxTheme.softWhite,
          ),
        ),
        SizedBox(
          height: isSmallMobile
              ? 4
              : isMobile
              ? 6
              : 8,
        ),
        _buildResponsiveDropdown(
          value: _selectedLocation,
          hintText: 'Select location',
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
          isMobile: isMobile,
          isSmallMobile: isSmallMobile,
        ),
      ],
    );
  }

  // Mobile-optimized date selection
  Widget _buildDateSelection(bool isMobile, bool isSmallMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Job Date *',
          style: TextStyle(
            fontSize: isSmallMobile
                ? 14
                : isMobile
                ? 16
                : 18,
            fontWeight: FontWeight.w600,
            color: ChoiceLuxTheme.softWhite,
          ),
        ),
        SizedBox(
          height: isSmallMobile
              ? 4
              : isMobile
              ? 6
              : 8,
        ),
        InkWell(
          onTap: _selectJobDate,
          child: _buildResponsiveInputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isSmallMobile ? 8 : 12),
              ),
              hintText: 'Select job date',
              suffixIcon: Icon(
                Icons.calendar_today,
                size: isSmallMobile
                    ? 18
                    : isMobile
                    ? 20
                    : 24,
                color: ChoiceLuxTheme.platinumSilver,
              ),
            ),
            child: Text(
              _selectedJobDate != null
                  ? '${_selectedJobDate!.day}/${_selectedJobDate!.month}/${_selectedJobDate!.year}'
                  : '',
              style: TextStyle(
                color: _selectedJobDate != null
                    ? ChoiceLuxTheme.softWhite
                    : ChoiceLuxTheme.platinumSilver,
                fontSize: isSmallMobile
                    ? 13
                    : isMobile
                    ? 14
                    : 16,
              ),
            ),
            isMobile: isMobile,
            isSmallMobile: isSmallMobile,
          ),
        ),
      ],
    );
  }

  // Mobile-optimized passenger details with enhanced keyboard handling
  Widget _buildPassengerDetails(bool isMobile, bool isSmallMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Passenger Details',
          style: TextStyle(
            fontSize: isSmallMobile
                ? 14
                : isMobile
                ? 16
                : 18,
            fontWeight: FontWeight.w600,
            color: ChoiceLuxTheme.softWhite,
          ),
        ),
        SizedBox(
          height: isSmallMobile
              ? 8
              : isMobile
              ? 12
              : 16,
        ),
        if (isMobile) ...[
          // Stack vertically on mobile with enhanced keyboard flow
          _buildResponsiveTextField(
            controller: _passengerNameController,
            labelText: 'Passenger Name',
            focusNode: _passengerNameFocus,
            textInputAction: TextInputAction.next,
            isMobile: isMobile,
            isSmallMobile: isSmallMobile,
          ),
          SizedBox(
            height: isSmallMobile
                ? 8
                : isMobile
                ? 12
                : 16,
          ),
          _buildResponsiveTextField(
            controller: _passengerContactController,
            labelText: 'Contact Number',
            keyboardType: TextInputType.phone,
            focusNode: _passengerContactFocus,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            isMobile: isMobile,
            isSmallMobile: isSmallMobile,
          ),
          SizedBox(
            height: isSmallMobile
                ? 8
                : isMobile
                ? 12
                : 16,
          ),
          _buildResponsiveTextField(
            controller: _pasCountController,
            labelText: 'Number of Passengers *',
            keyboardType: TextInputType.number,
            focusNode: _pasCountFocus,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter passenger count';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
            isMobile: isMobile,
            isSmallMobile: isSmallMobile,
          ),
          SizedBox(
            height: isSmallMobile
                ? 8
                : isMobile
                ? 12
                : 16,
          ),
          _buildResponsiveTextField(
            controller: _luggageController,
            labelText: 'Luggage Description *',
            focusNode: _luggageFocus,
            textInputAction: TextInputAction.done,
            maxLength: 100,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter luggage description';
              }
              return null;
            },
            isMobile: isMobile,
            isSmallMobile: isSmallMobile,
          ),
        ] else ...[
          // Side by side on desktop with enhanced keyboard flow
          Row(
            children: [
              Expanded(
                child: _buildResponsiveTextField(
                  controller: _passengerNameController,
                  labelText: 'Passenger Name',
                  focusNode: _passengerNameFocus,
                  textInputAction: TextInputAction.next,
                  isMobile: isMobile,
                  isSmallMobile: isSmallMobile,
                ),
              ),
              SizedBox(
                width: isSmallMobile
                    ? 8
                    : isMobile
                    ? 12
                    : 16,
              ),
              Expanded(
                child: _buildResponsiveTextField(
                  controller: _passengerContactController,
                  labelText: 'Contact Number',
                  keyboardType: TextInputType.phone,
                  focusNode: _passengerContactFocus,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  isMobile: isMobile,
                  isSmallMobile: isSmallMobile,
                ),
              ),
            ],
          ),
          SizedBox(
            height: isSmallMobile
                ? 8
                : isMobile
                ? 12
                : 16,
          ),
          Row(
            children: [
              Expanded(
                child: _buildResponsiveTextField(
                  controller: _pasCountController,
                  labelText: 'Number of Passengers *',
                  keyboardType: TextInputType.number,
                  focusNode: _pasCountFocus,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter passenger count';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                  isMobile: isMobile,
                  isSmallMobile: isSmallMobile,
                ),
              ),
              SizedBox(
                width: isSmallMobile
                    ? 8
                    : isMobile
                    ? 12
                    : 16,
              ),
              Expanded(
                child: _buildResponsiveTextField(
                  controller: _luggageController,
                  labelText: 'Luggage Description *',
                  focusNode: _luggageFocus,
                  textInputAction: TextInputAction.done,
                  maxLength: 100,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter luggage description';
                    }
                    return null;
                  },
                  isMobile: isMobile,
                  isSmallMobile: isSmallMobile,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // Mobile-optimized quote details with enhanced keyboard handling
  Widget _buildQuoteDetails(bool isMobile, bool isSmallMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quote Details',
          style: TextStyle(
            fontSize: isSmallMobile
                ? 14
                : isMobile
                ? 16
                : 18,
            fontWeight: FontWeight.w600,
            color: ChoiceLuxTheme.softWhite,
          ),
        ),
        SizedBox(
          height: isSmallMobile
              ? 8
              : isMobile
              ? 12
              : 16,
        ),
        _buildResponsiveTextField(
          controller: _quoteTitleController,
          labelText: 'Quote Title',
          hintText: 'e.g., Airport Transfer - JHB to CPT',
          focusNode: _quoteTitleFocus,
          textInputAction: TextInputAction.next,
          maxLength: 50,
          isMobile: isMobile,
          isSmallMobile: isSmallMobile,
        ),
        SizedBox(
          height: isSmallMobile
              ? 8
              : isMobile
              ? 12
              : 16,
        ),
        _buildResponsiveTextField(
          controller: _quoteDescriptionController,
          labelText: 'Quote Description',
          hintText: 'Brief description of the quote',
          focusNode: _quoteDescriptionFocus,
          textInputAction: TextInputAction.next,
          maxLines: 3,
          maxLength: 200,
          isMobile: isMobile,
          isSmallMobile: isSmallMobile,
        ),
      ],
    );
  }

  // Mobile-optimized notes section with enhanced keyboard handling
  Widget _buildNotesSection(bool isMobile, bool isSmallMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Notes',
          style: TextStyle(
            fontSize: isSmallMobile
                ? 14
                : isMobile
                ? 16
                : 18,
            fontWeight: FontWeight.w600,
            color: ChoiceLuxTheme.softWhite,
          ),
        ),
        SizedBox(
          height: isSmallMobile
              ? 4
              : isMobile
              ? 6
              : 8,
        ),
        _buildResponsiveTextField(
          controller: _notesController,
          labelText: 'Notes',
          hintText: 'Flight details, special requirements, etc.',
          focusNode: _notesFocus,
          textInputAction: TextInputAction.done,
          maxLines: 4,
          maxLength: 500,
          isMobile: isMobile,
          isSmallMobile: isSmallMobile,
        ),
      ],
    );
  }

  // Mobile-optimized submit button with validation feedback
  Widget _buildMobileSubmitButton(bool isMobile, bool isSmallMobile) {
    return Column(
      children: [
        // Validation summary for mobile
        if (isMobile) _buildMobileValidationSummary(isMobile, isSmallMobile),
        SizedBox(
          height: isSmallMobile
              ? 16
              : isMobile
              ? 20
              : 24,
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _createQuote,
            style: ElevatedButton.styleFrom(
              backgroundColor: ChoiceLuxTheme.richGold,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(
                vertical: isSmallMobile
                    ? 14
                    : isMobile
                    ? 16
                    : 18,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isSmallMobile ? 8 : 12),
              ),
              minimumSize: Size(
                0,
                isSmallMobile
                    ? 44
                    : isMobile
                    ? 48
                    : 52,
              ),
            ),
            child: _isSubmitting
                ? SizedBox(
                    height: isSmallMobile
                        ? 18
                        : isMobile
                        ? 20
                        : 22,
                    width: isSmallMobile
                        ? 18
                        : isMobile
                        ? 20
                        : 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : Text(
                    isMobile
                        ? 'Create Quote & Continue'
                        : 'Create Quote & Continue to Transport Details',
                    style: TextStyle(
                      fontSize: isSmallMobile
                          ? 14
                          : isMobile
                          ? 16
                          : 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // Mobile validation summary widget
  Widget _buildMobileValidationSummary(bool isMobile, bool isSmallMobile) {
    return FormField<String>(
      builder: (FormFieldState<String> field) {
        // This will be populated by the form validation
        return const SizedBox.shrink();
      },
    );
  }

  // Mobile-specific validation helpers
  String? _validateRequiredField(
    String? value,
    String fieldName,
    bool isMobile,
  ) {
    if (value == null || value.trim().isEmpty) {
      return isMobile ? '$fieldName is required' : 'Please enter $fieldName';
    }
    return null;
  }

  String? _validateNumberField(String? value, String fieldName, bool isMobile) {
    final requiredError = _validateRequiredField(value, fieldName, isMobile);
    if (requiredError != null) return requiredError;

    if (double.tryParse(value!) == null) {
      return isMobile
          ? '$fieldName must be a valid number'
          : 'Please enter a valid number for $fieldName';
    }
    return null;
  }

  String? _validatePhoneField(String? value, String fieldName, bool isMobile) {
    if (value == null || value.trim().isEmpty) return null; // Optional field

    // Basic phone validation for South African numbers
    final phoneRegex = RegExp(r'^(\+27|0)[6-8][0-9]{8}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
      return isMobile
          ? 'Please enter a valid SA phone number'
          : 'Please enter a valid South African phone number';
    }
    return null;
  }

  String? _validateDateField(DateTime? value, String fieldName, bool isMobile) {
    if (value == null) {
      return isMobile ? '$fieldName is required' : 'Please select $fieldName';
    }

    if (value.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return isMobile
          ? '$fieldName cannot be in the past'
          : 'Please select a future date for $fieldName';
    }
    return null;
  }

  // Responsive dropdown helper with mobile validation feedback
  Widget _buildResponsiveDropdown({
    required String? value,
    required String hintText,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
    required bool isMobile,
    required bool isSmallMobile,
  }) {
    return FormField<String>(
      validator: validator,
      builder: (FormFieldState<String> field) {
        final hasError = field.hasError;
        final errorText = field.errorText;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: ChoiceLuxTheme.charcoalGray,
                borderRadius: BorderRadius.circular(isSmallMobile ? 8 : 12),
                border: Border.all(
                  color: hasError
                      ? ChoiceLuxTheme.errorColor
                      : ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
                  width: hasError ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: hasError
                        ? ChoiceLuxTheme.errorColor.withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: hasError ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonFormField<String>(
                value: value,
                isExpanded: true,
                menuMaxHeight:
                    200, // Limit dropdown menu height to prevent overflow
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(
                    color: ChoiceLuxTheme.platinumSilver.withOpacity(0.6),
                    fontSize: isSmallMobile
                        ? 13
                        : isMobile
                        ? 14
                        : 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isSmallMobile ? 12 : 16,
                    vertical: isSmallMobile ? 12 : 16,
                  ),
                  suffixIcon: hasError
                      ? Icon(
                          Icons.error_outline,
                          color: ChoiceLuxTheme.errorColor,
                          size: isSmallMobile
                              ? 18
                              : isMobile
                              ? 20
                              : 24,
                        )
                      : null,
                ),
                dropdownColor: ChoiceLuxTheme.charcoalGray,
                style: TextStyle(
                  color: ChoiceLuxTheme.softWhite,
                  fontSize: isSmallMobile
                      ? 13
                      : isMobile
                      ? 14
                      : 16,
                ),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: hasError
                      ? ChoiceLuxTheme.errorColor
                      : ChoiceLuxTheme.platinumSilver.withOpacity(0.6),
                  size: isSmallMobile
                      ? 20
                      : isMobile
                      ? 24
                      : 28,
                ),
                items: items,
                onChanged: (newValue) {
                  onChanged(newValue);
                  field.didChange(newValue);
                  field.validate();
                },
              ),
            ),
            if (hasError && errorText != null) ...[
              SizedBox(height: isSmallMobile ? 6 : 8),
              Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: ChoiceLuxTheme.errorColor,
                    size: isSmallMobile
                        ? 14
                        : isMobile
                        ? 16
                        : 18,
                  ),
                  SizedBox(width: isSmallMobile ? 6 : 8),
                  Expanded(
                    child: Text(
                      errorText,
                      style: TextStyle(
                        color: ChoiceLuxTheme.errorColor,
                        fontSize: isSmallMobile
                            ? 11
                            : isMobile
                            ? 12
                            : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  // Responsive text field helper with mobile validation feedback and enhanced keyboard handling
  Widget _buildResponsiveTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    TextInputType? keyboardType,
    int? maxLines,
    String? Function(String?)? validator,
    required bool isMobile,
    required bool isSmallMobile,
    TextInputAction? textInputAction,
    FocusNode? focusNode,
    VoidCallback? onTap,
    bool enabled = true,
    bool readOnly = false,
    int? maxLength,
    String? counterText,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return FormField<String>(
      validator: validator,
      builder: (FormFieldState<String> field) {
        final hasError = field.hasError;
        final errorText = field.errorText;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: ChoiceLuxTheme.charcoalGray,
                borderRadius: BorderRadius.circular(isSmallMobile ? 8 : 12),
                border: Border.all(
                  color: hasError
                      ? ChoiceLuxTheme.errorColor
                      : ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
                  width: hasError ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: hasError
                        ? ChoiceLuxTheme.errorColor.withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: hasError ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                maxLines: maxLines ?? 1,
                maxLength: maxLength,
                enabled: enabled,
                readOnly: readOnly,
                inputFormatters: inputFormatters,
                onTap: onTap,
                decoration: InputDecoration(
                  labelText: labelText,
                  hintText: hintText,
                  counterText: counterText,
                  labelStyle: TextStyle(
                    color: hasError
                        ? ChoiceLuxTheme.errorColor
                        : ChoiceLuxTheme.platinumSilver.withOpacity(0.8),
                    fontSize: isSmallMobile
                        ? 13
                        : isMobile
                        ? 14
                        : 16,
                  ),
                  hintStyle: TextStyle(
                    color: ChoiceLuxTheme.platinumSilver.withOpacity(0.6),
                    fontSize: isSmallMobile
                        ? 13
                        : isMobile
                        ? 14
                        : 16,
                  ),
                  counterStyle: TextStyle(
                    color: ChoiceLuxTheme.platinumSilver.withOpacity(0.6),
                    fontSize: isSmallMobile
                        ? 11
                        : isMobile
                        ? 12
                        : 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isSmallMobile ? 12 : 16,
                    vertical: isSmallMobile ? 12 : 16,
                  ),
                  suffixIcon: hasError
                      ? Icon(
                          Icons.error_outline,
                          color: ChoiceLuxTheme.errorColor,
                          size: isSmallMobile
                              ? 18
                              : isMobile
                              ? 20
                              : 24,
                        )
                      : null,
                ),
                style: TextStyle(
                  color: ChoiceLuxTheme.softWhite,
                  fontSize: isSmallMobile
                      ? 13
                      : isMobile
                      ? 14
                      : 16,
                ),
                onChanged: (value) {
                  field.didChange(value);
                  field.validate();
                },
                onFieldSubmitted: (value) {
                  // Handle field submission for better mobile flow
                  if (textInputAction == TextInputAction.next) {
                    // Focus next field
                    FocusScope.of(context).nextFocus();
                  } else if (textInputAction == TextInputAction.done) {
                    // Hide keyboard and submit form
                    FocusScope.of(context).unfocus();
                    if (isMobile) {
                      // On mobile, scroll to submit button
                      _scrollToSubmitButton();
                    }
                  }
                },
              ),
            ),
            if (hasError && errorText != null) ...[
              SizedBox(height: isSmallMobile ? 6 : 8),
              Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: ChoiceLuxTheme.errorColor,
                    size: isSmallMobile
                        ? 14
                        : isMobile
                        ? 16
                        : 18,
                  ),
                  SizedBox(width: isSmallMobile ? 6 : 8),
                  Expanded(
                    child: Text(
                      errorText,
                      style: TextStyle(
                        color: ChoiceLuxTheme.errorColor,
                        fontSize: isSmallMobile
                            ? 11
                            : isMobile
                            ? 12
                            : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  // Responsive input decorator helper with mobile validation feedback
  Widget _buildResponsiveInputDecorator({
    required InputDecoration decoration,
    required Widget child,
    required bool isMobile,
    required bool isSmallMobile,
    bool hasError = false,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: ChoiceLuxTheme.charcoalGray,
            borderRadius: BorderRadius.circular(isSmallMobile ? 8 : 12),
            border: Border.all(
              color: hasError
                  ? ChoiceLuxTheme.errorColor
                  : ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
              width: hasError ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: hasError
                    ? ChoiceLuxTheme.errorColor.withOpacity(0.3)
                    : Colors.black.withOpacity(0.1),
                blurRadius: hasError ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InputDecorator(
            decoration: decoration.copyWith(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isSmallMobile ? 12 : 16,
                vertical: isSmallMobile ? 12 : 16,
              ),
              suffixIcon: hasError
                  ? Icon(
                      Icons.error_outline,
                      color: ChoiceLuxTheme.errorColor,
                      size: isSmallMobile
                          ? 18
                          : isMobile
                          ? 20
                          : 24,
                    )
                  : decoration.suffixIcon,
            ),
            child: child,
          ),
        ),
        if (hasError && errorText != null) ...[
          SizedBox(height: isSmallMobile ? 6 : 8),
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: ChoiceLuxTheme.errorColor,
                size: isSmallMobile
                    ? 14
                    : isMobile
                    ? 16
                    : 18,
              ),
              SizedBox(width: isSmallMobile ? 6 : 8),
              Expanded(
                child: Text(
                  errorText,
                  style: TextStyle(
                    color: ChoiceLuxTheme.errorColor,
                    fontSize: isSmallMobile
                        ? 11
                        : isMobile
                        ? 12
                        : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
