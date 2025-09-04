import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/clients/models/agent.dart';
import 'package:choice_lux_cars/features/clients/providers/agents_provider.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/utils/background_pattern_utils.dart';

class AddEditAgentScreen extends ConsumerStatefulWidget {
  final String clientId;
  final Agent? agent; // null for add, non-null for edit

  const AddEditAgentScreen({super.key, required this.clientId, this.agent});

  @override
  ConsumerState<AddEditAgentScreen> createState() => _AddEditAgentScreenState();
}

class _AddEditAgentScreenState extends ConsumerState<AddEditAgentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _agentNameController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactNumberController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.agent != null) {
      // Edit mode - populate fields
      _agentNameController.text = widget.agent!.agentName;
      _contactEmailController.text = widget.agent!.contactEmail;
      _contactNumberController.text = widget.agent!.contactNumber;
    }
  }

  @override
  void dispose() {
    _agentNameController.dispose();
    _contactEmailController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.agent != null;

    return Stack(
      children: [
        // Layer 1: The background that fills the entire screen
        Container(
          decoration: const BoxDecoration(
            gradient: ChoiceLuxTheme.backgroundGradient,
          ),
        ),
        // Layer 2: Background pattern that covers the entire screen
        Positioned.fill(
          child: CustomPaint(painter: BackgroundPatterns.dashboard),
        ),
        // Layer 3: The Scaffold with a transparent background
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: LuxuryAppBar(
            title: isEditMode ? 'Edit Agent' : 'Add Agent',
            subtitle: isEditMode ? 'Update agent details' : 'Create new agent',
            showBackButton: true,
            onBackPressed: () => context.pop(),
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;

                return Column(
                  children: [
                    // Form Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: _buildForm(isMobile),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(bool isMobile) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Agent Avatar Section
          _buildAvatarSection(isMobile),

          const SizedBox(height: 24),

          // Agent Information
          _buildSectionTitle('Agent Information', isMobile),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _agentNameController,
            label: 'Agent Name',
            hint: 'Enter agent name',
            icon: Icons.person,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Agent name is required';
              }
              return null;
            },
            isMobile: isMobile,
          ),

          const SizedBox(height: 16),

          const SizedBox(height: 24),

          // Contact Information
          _buildSectionTitle('Contact Information', isMobile),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _contactEmailController,
            label: 'Email Address',
            hint: 'Enter email address',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
            isMobile: isMobile,
          ),

          const SizedBox(height: 16),

          _buildTextField(
            controller: _contactNumberController,
            label: 'Phone Number',
            hint: 'Enter phone number',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Phone number is required';
              }
              return null;
            },
            isMobile: isMobile,
          ),

          const SizedBox(height: 32),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveAgent,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isLoading ? 'Saving...' : 'Save Agent'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ChoiceLuxTheme.richGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildAvatarSection(bool isMobile) {
    return Center(
      child: Column(
        children: [
          // Agent Avatar
          Container(
            width: isMobile ? 100 : 120,
            height: isMobile ? 100 : 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(60),
              color: ChoiceLuxTheme.richGold.withOpacity(0.1),
              border: Border.all(
                color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.person,
              color: ChoiceLuxTheme.richGold,
              size: isMobile ? 40 : 48,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Agent Profile',
            style: TextStyle(
              color: ChoiceLuxTheme.platinumSilver,
              fontSize: isMobile ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isMobile) {
    return Text(
      title,
      style: TextStyle(
        fontSize: isMobile ? 16 : 18,
        fontWeight: FontWeight.bold,
        color: ChoiceLuxTheme.richGold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    required bool isMobile,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        color: ChoiceLuxTheme.softWhite,
        fontSize: isMobile ? 14 : 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: ChoiceLuxTheme.platinumSilver),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ChoiceLuxTheme.platinumSilver),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ChoiceLuxTheme.platinumSilver),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: ChoiceLuxTheme.richGold,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ChoiceLuxTheme.errorColor),
        ),
        filled: true,
        fillColor: ChoiceLuxTheme.charcoalGray,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isMobile ? 12 : 16,
        ),
        labelStyle: TextStyle(
          color: ChoiceLuxTheme.platinumSilver,
          fontSize: isMobile ? 14 : 16,
        ),
        hintStyle: TextStyle(
          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7),
          fontSize: isMobile ? 14 : 16,
        ),
      ),
    );
  }

  Future<void> _saveAgent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final agent = Agent(
        id: widget.agent?.id,
        agentName: _agentNameController.text.trim(),
        contactEmail: _contactEmailController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        clientKey: int.parse(widget.clientId),
        isDeleted: false, // New agents are not deleted
      );

      if (widget.agent == null) {
        // Add new agent
        await ref
            .read(agentsNotifierProvider(widget.clientId).notifier)
            .addAgent(agent);
      } else {
        // Update existing agent
        await ref
            .read(agentsNotifierProvider(widget.clientId).notifier)
            .updateAgent(agent);
      }

      // Force a refresh to ensure the UI updates with the latest data
      await ref
          .read(agentsNotifierProvider(widget.clientId).notifier)
          .refresh();

      // Navigate back immediately after successful operation
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.toString()}'),
            backgroundColor: ChoiceLuxTheme.errorColor,
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
}
