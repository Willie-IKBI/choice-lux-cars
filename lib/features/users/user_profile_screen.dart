import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/core/services/supabase_service.dart';
import 'package:choice_lux_cars/core/services/upload_service.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_drawer.dart';
import 'package:choice_lux_cars/shared/utils/background_pattern_utils.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _numberController;
  late TextEditingController _addressController;
  late TextEditingController _kinController;
  late TextEditingController _kinNumberController;

  String? _profileImage;
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _numberController = TextEditingController();
    _addressController = TextEditingController();
    _kinController = TextEditingController();
    _kinNumberController = TextEditingController();

    // Load user data after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _numberController.dispose();
    _addressController.dispose();
    _kinController.dispose();
    _kinNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final userProfile = ref.read(currentUserProfileProvider);
    if (userProfile != null) {
      // Get full user data from Supabase
      final userData = await SupabaseService.instance.getProfile(
        userProfile.id,
      );
      if (userData != null) {
        setState(() {
          _displayNameController.text = userData['display_name'] ?? '';
          _numberController.text = userData['number'] ?? '';
          _addressController.text = userData['address'] ?? '';
          _kinController.text = userData['kin'] ?? '';
          _kinNumberController.text = userData['kin_number'] ?? '';
          _profileImage = userData['profile_image'];
        });
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() => _isUploading = true);

      try {
        final bytes = await picked.readAsBytes();
        final userProfile = ref.read(currentUserProfileProvider);
        if (userProfile != null) {
          final url = await UploadService.uploadImageBytes(
            bytes,
            'clc_images',
            'profiles',
            '${userProfile.id}/profile.jpg',
          );

          // Update profile image in database
          await SupabaseService.instance.updateProfile(
            userId: userProfile.id,
            data: {'profile_image': url},
          );

          setState(() {
            _profileImage = url;
            _isUploading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile image updated successfully'),
              ),
            );
          }
        }
      } catch (error) {
        setState(() => _isUploading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload image: $error')),
          );
        }
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userProfile = ref.read(currentUserProfileProvider);
      if (userProfile != null) {
        await SupabaseService.instance.updateProfile(
          userId: userProfile.id,
          data: {
            'display_name': _displayNameController.text.trim(),
            'number': _numberController.text.trim(),
            'address': _addressController.text.trim(),
            'kin': _kinController.text.trim(),
            'kin_number': _kinNumberController.text.trim(),
          },
        );

        // Refresh user profile
        await ref.read(userProfileProvider.notifier).updateProfile({});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $error')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  InputDecoration _modernInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ChoiceLuxTheme.richGold, width: 2),
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(currentUserProfileProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isWide = MediaQuery.of(context).size.width > 900;

    if (userProfile == null) {
      return Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: ChoiceLuxTheme.backgroundGradient,
            ),
          ),
          const Positioned.fill(
            child: CustomPaint(painter: BackgroundPatterns.dashboard),
          ),
          const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: ChoiceLuxTheme.backgroundGradient,
          ),
        ),
        const Positioned.fill(
          child: CustomPaint(painter: BackgroundPatterns.dashboard),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: LuxuryAppBar(
            title: 'My Profile',
            showProfile: false, // Hide profile menu since we're on profile page
            showBackButton: true,
            onBackPressed: () => context.go('/'),
          ),
          drawer: isMobile ? const LuxuryDrawer() : null,
          body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Image Section
                    Card(
                      margin: const EdgeInsets.only(bottom: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      elevation: 4,
                      shadowColor: Colors.black.withValues(alpha: 0.08),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 16,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                CircleAvatar(
                                  radius: isWide ? 52 : 44,
                                  backgroundColor: Colors.grey[800],
                                  backgroundImage:
                                      _profileImage != null &&
                                          _profileImage!.isNotEmpty
                                      ? NetworkImage(_profileImage!)
                                      : null,
                                  child:
                                      _profileImage == null ||
                                          _profileImage!.isEmpty
                                      ? Text(
                                          _displayNameController.text.isNotEmpty
                                              ? _displayNameController.text[0]
                                                    .toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            fontSize: 32,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),
                                if (_isUploading)
                                  const Positioned.fill(
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              icon: const Icon(Icons.camera_alt_outlined),
                              label: const Text('Change Profile Image'),
                              onPressed: _isUploading
                                  ? null
                                  : _pickAndUploadImage,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Profile Form
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      elevation: 4,
                      shadowColor: Colors.black.withValues(alpha: 0.08),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section Header
                            Row(
                              children: [
                                const Icon(
                                  Icons.person,
                                  size: 22,
                                  color: ChoiceLuxTheme.richGold,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Personal Information',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                        color: ChoiceLuxTheme.softWhite,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Form Fields
                            if (isWide) ...[
                              // Two column layout for wide screens
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        TextFormField(
                                          controller: _displayNameController,
                                          decoration: _modernInputDecoration(
                                            'Full Name',
                                          ),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: ChoiceLuxTheme.softWhite,
                                          ),
                                          validator: (val) =>
                                              val == null || val.isEmpty
                                              ? 'Required'
                                              : null,
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: _numberController,
                                          decoration: _modernInputDecoration(
                                            'Contact Number',
                                          ),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: ChoiceLuxTheme.softWhite,
                                          ),
                                          keyboardType: TextInputType.phone,
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: _addressController,
                                          decoration: _modernInputDecoration(
                                            'Address',
                                          ),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: ChoiceLuxTheme.softWhite,
                                          ),
                                          maxLines: 3,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        TextFormField(
                                          controller: _kinController,
                                          decoration: _modernInputDecoration(
                                            'Emergency Contact (Next of Kin)',
                                          ),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: ChoiceLuxTheme.softWhite,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: _kinNumberController,
                                          decoration: _modernInputDecoration(
                                            'Emergency Contact Number',
                                          ),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: ChoiceLuxTheme.softWhite,
                                          ),
                                          keyboardType: TextInputType.phone,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              // Single column layout for mobile/tablet
                              TextFormField(
                                controller: _displayNameController,
                                decoration: _modernInputDecoration('Full Name'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: ChoiceLuxTheme.softWhite,
                                ),
                                validator: (val) => val == null || val.isEmpty
                                    ? 'Required'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _numberController,
                                decoration: _modernInputDecoration(
                                  'Contact Number',
                                ),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: ChoiceLuxTheme.softWhite,
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _addressController,
                                decoration: _modernInputDecoration('Address'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: ChoiceLuxTheme.softWhite,
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _kinController,
                                decoration: _modernInputDecoration(
                                  'Emergency Contact (Next of Kin)',
                                ),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: ChoiceLuxTheme.softWhite,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _kinNumberController,
                                decoration: _modernInputDecoration(
                                  'Emergency Contact Number',
                                ),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: ChoiceLuxTheme.softWhite,
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                            ],

                            const SizedBox(height: 32),

                            // Save Button
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _isLoading ? null : _saveProfile,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.save),
                                label: Text(
                                  _isLoading ? 'Saving...' : 'Save Changes',
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: ChoiceLuxTheme.richGold,
                                  foregroundColor: ChoiceLuxTheme.jetBlack,
                                  padding: const EdgeInsets.symmetric(
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
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      ],
    );
  }
}
