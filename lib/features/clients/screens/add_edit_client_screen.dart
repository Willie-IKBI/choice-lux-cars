import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/clients/models/client.dart';
import 'package:choice_lux_cars/features/clients/providers/clients_provider.dart';
import 'package:choice_lux_cars/core/services/upload_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/utils/background_pattern_utils.dart';

class AddEditClientScreen extends ConsumerStatefulWidget {
  final Client? client; // null for add, non-null for edit

  const AddEditClientScreen({super.key, this.client});

  @override
  ConsumerState<AddEditClientScreen> createState() =>
      _AddEditClientScreenState();
}

class _AddEditClientScreenState extends ConsumerState<AddEditClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _websiteAddressController = TextEditingController();
  final _companyRegistrationNumberController = TextEditingController();
  final _vatNumberController = TextEditingController();
  final _billingAddressController = TextEditingController();

  bool _isLoading = false;
  String? _companyLogoUrl;
  bool _isLogoUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.client != null) {
      // Edit mode - populate fields
      _companyNameController.text = widget.client!.companyName;
      _contactPersonController.text = widget.client!.contactPerson;
      _contactNumberController.text = widget.client!.contactNumber;
      _contactEmailController.text = widget.client!.contactEmail;
      _websiteAddressController.text = widget.client!.websiteAddress ?? '';
      _companyRegistrationNumberController.text = widget.client!.companyRegistrationNumber ?? '';
      _vatNumberController.text = widget.client!.vatNumber ?? '';
      _billingAddressController.text = widget.client!.billingAddress ?? '';
      _companyLogoUrl = widget.client!.companyLogo;
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _contactPersonController.dispose();
    _contactNumberController.dispose();
    _contactEmailController.dispose();
    _websiteAddressController.dispose();
    _companyRegistrationNumberController.dispose();
    _vatNumberController.dispose();
    _billingAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.client != null;

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
            title: isEditMode ? 'Edit Client' : 'Add Client',
            subtitle: isEditMode ? 'Update client details' : 'Create new client',
            showBackButton: true,
            onBackPressed: () => context.go('/clients'),
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
          // Company Logo Section
          _buildLogoSection(isMobile),

          const SizedBox(height: 24),

          // Company Information
          _buildSectionTitle('Company Information', isMobile),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _companyNameController,
            label: 'Company Name',
            hint: 'Enter company name',
            icon: Icons.business,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Company name is required';
              }
              return null;
            },
            isMobile: isMobile,
          ),

          const SizedBox(height: 16),

          // Contact Information
          _buildSectionTitle('Contact Information', isMobile),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _contactPersonController,
            label: 'Contact Person',
            hint: 'Enter contact person name',
            icon: Icons.person,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Contact person is required';
              }
              return null;
            },
            isMobile: isMobile,
          ),

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

          const SizedBox(height: 24),

          // Additional Company Information
          _buildSectionTitle('Additional Information', isMobile),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _websiteAddressController,
            label: 'Website Address',
            hint: 'Enter website URL (optional)',
            icon: Icons.language,
            keyboardType: TextInputType.url,
            validator: (value) {
              // Optional field - no validation required
              return null;
            },
            isMobile: isMobile,
          ),

          const SizedBox(height: 16),

          _buildTextField(
            controller: _companyRegistrationNumberController,
            label: 'Company Registration Number',
            hint: 'Enter company registration number (optional)',
            icon: Icons.business_center,
            validator: (value) {
              // Optional field - no validation required
              return null;
            },
            isMobile: isMobile,
          ),

          const SizedBox(height: 16),

          _buildTextField(
            controller: _vatNumberController,
            label: 'VAT Number',
            hint: 'Enter VAT number (optional)',
            icon: Icons.receipt_long,
            validator: (value) {
              // Optional field - no validation required
              return null;
            },
            isMobile: isMobile,
          ),

          const SizedBox(height: 16),

          _buildTextField(
            controller: _billingAddressController,
            label: 'Billing Address',
            hint: 'Enter billing address for invoices (optional)',
            icon: Icons.location_on,
            keyboardType: TextInputType.multiline,
            maxLines: 3,
            validator: (value) {
              // Optional field - no validation required
              return null;
            },
            isMobile: isMobile,
          ),

          const SizedBox(height: 32),

          // Save Button (Mobile)
          if (isMobile) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveClient,
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
                label: Text(_isLoading ? 'Saving...' : 'Save Client'),
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

          // Save Button (Desktop)
          if (!isMobile) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveClient,
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
                  label: Text(_isLoading ? 'Saving...' : 'Save Client'),
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
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogoSection(bool isMobile) {
    return Center(
      child: Column(
        children: [
          // Logo Display/Upload
          GestureDetector(
            onTap: _isLogoUploading ? null : _uploadLogo,
            child: Container(
              width: isMobile ? 120 : 150,
              height: isMobile ? 120 : 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: ChoiceLuxTheme.richGold.withOpacity(0.1),
                border: Border.all(
                  color: _isLogoUploading
                      ? ChoiceLuxTheme.richGold.withOpacity(0.6)
                      : ChoiceLuxTheme.richGold.withOpacity(0.3),
                  width: _isLogoUploading ? 3 : 2,
                ),
              ),
              child: _isLogoUploading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: ChoiceLuxTheme.richGold,
                            strokeWidth: 2,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Uploading...',
                            style: TextStyle(
                              color: ChoiceLuxTheme.richGold,
                              fontSize: isMobile ? 10 : 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _companyLogoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        child: Image.network(
                          _companyLogoUrl!,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildLogoPlaceholder(),
                        ),
                      ),
                    )
                  : _buildLogoPlaceholder(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isLogoUploading
                ? 'Uploading logo...'
                : _companyLogoUrl != null
                ? 'Tap to change logo'
                : 'Tap to upload company logo',
            style: TextStyle(
              color: _isLogoUploading
                  ? ChoiceLuxTheme.richGold
                  : ChoiceLuxTheme.platinumSilver,
              fontSize: isMobile ? 12 : 14,
              fontWeight: _isLogoUploading
                  ? FontWeight.w500
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo, color: ChoiceLuxTheme.richGold, size: 32),
        const SizedBox(height: 4),
        Text(
          'Add Logo',
          style: TextStyle(
            color: ChoiceLuxTheme.richGold,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
    int? maxLines,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
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

  Future<void> _uploadLogo() async {
    try {
      setState(() {
        _isLogoUploading = true;
      });

      // For web, skip source selection and use file picker directly
      File? imageFile;
      if (kIsWeb) {
        imageFile = await UploadService.pickImage(
          source: ImageSource.gallery, // This will be ignored on web
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );
      } else {
        // Show source selection dialog for mobile
        final ImageSource? source = await _showImageSourceDialog();
        if (source == null) {
          setState(() {
            _isLogoUploading = false;
          });
          return;
        }

        // Pick image
        imageFile = await UploadService.pickImage(
          source: source,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );
      }

      if (imageFile == null) {
        setState(() {
          _isLogoUploading = false;
        });
        return;
      }

      // Validate file size
      if (kIsWeb) {
        // For web, validate bytes size (5MB = 5 * 1024 * 1024 bytes)
        if (UploadService.webImageBytes != null && UploadService.webImageBytes!.length > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File size must be less than 5MB'),
                backgroundColor: ChoiceLuxTheme.errorColor,
              ),
            );
          }
          setState(() {
            _isLogoUploading = false;
          });
          return;
        }
      } else {
        // For mobile, validate file size
        if (!UploadService.isValidFileSize(imageFile, maxSizeMB: 5.0)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File size must be less than 5MB'),
                backgroundColor: ChoiceLuxTheme.errorColor,
              ),
            );
          }
          setState(() {
            _isLogoUploading = false;
          });
          return;
        }
      }

      // Ensure bucket exists
      await UploadService.ensureBucketExists();

      // Upload logo
      final String logoUrl = await UploadService.uploadCompanyLogo(
        logoFile: imageFile,
        companyName: _companyNameController.text.trim().isNotEmpty
            ? _companyNameController.text.trim()
            : null,
      );

      setState(() {
        _companyLogoUrl = logoUrl;
        _isLogoUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logo uploaded successfully!'),
            backgroundColor: ChoiceLuxTheme.successColor,
          ),
        );
      }
    } catch (error) {
      setState(() {
        _isLogoUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading logo: ${error.toString()}'),
            backgroundColor: ChoiceLuxTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ChoiceLuxTheme.charcoalGray,
        title: Text(
          'Select Image Source',
          style: TextStyle(
            color: ChoiceLuxTheme.softWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: ChoiceLuxTheme.richGold,
              ),
              title: Text(
                'Gallery',
                style: TextStyle(color: ChoiceLuxTheme.softWhite),
              ),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: ChoiceLuxTheme.richGold,
              ),
              title: Text(
                'Camera',
                style: TextStyle(color: ChoiceLuxTheme.softWhite),
              ),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: ChoiceLuxTheme.platinumSilver),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final client = Client(
        id: widget.client?.id,
        companyName: _companyNameController.text.trim(),
        contactPerson: _contactPersonController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        contactEmail: _contactEmailController.text.trim(),
        companyLogo: _companyLogoUrl,
        websiteAddress: _websiteAddressController.text.trim().isEmpty ? null : _websiteAddressController.text.trim(),
        companyRegistrationNumber: _companyRegistrationNumberController.text.trim().isEmpty ? null : _companyRegistrationNumberController.text.trim(),
        vatNumber: _vatNumberController.text.trim().isEmpty ? null : _vatNumberController.text.trim(),
        billingAddress: _billingAddressController.text.trim().isEmpty ? null : _billingAddressController.text.trim(),
      );


      if (widget.client == null) {
        // Add new client
        await ref.read(clientsProvider.notifier).addClient(client);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Client added successfully!'),
              backgroundColor: ChoiceLuxTheme.successColor,
            ),
          );
        }
      } else {
        // Update existing client
        await ref.read(clientsProvider.notifier).updateClient(client);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Client updated successfully!'),
              backgroundColor: ChoiceLuxTheme.successColor,
            ),
          );
        }
      }

      if (mounted) {
        if (widget.client == null) {
          // New client - go to clients list
          context.go('/clients');
        } else {
          // Edit client - go back to client detail screen
          context.go('/clients/${widget.client!.id}');
        }
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
