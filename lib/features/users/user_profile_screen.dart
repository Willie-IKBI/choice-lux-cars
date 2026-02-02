import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/core/services/supabase_service.dart';
import 'package:choice_lux_cars/core/services/upload_service.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';
import 'package:choice_lux_cars/shared/widgets/system_safe_scaffold.dart';

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

          // Refresh the user profile provider so app bar and other components see the update
          await ref.read(userProfileProvider.notifier).refreshProfile();

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
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: ChoiceLuxTheme.platinumSilver.withOpacity(0.8),
      ),
      filled: true,
      fillColor: ChoiceLuxTheme.charcoalGray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: ChoiceLuxTheme.richGold,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      errorStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        color: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(currentUserProfileProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;

    if (userProfile == null) {
      return SystemSafeScaffold(
        backgroundColor: ChoiceLuxTheme.jetBlack,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return SystemSafeScaffold(
      backgroundColor: ChoiceLuxTheme.jetBlack,
      appBar: LuxuryAppBar(
        title: 'My Profile',
        showProfile: false, // Hide profile menu since we're on profile page
        showBackButton: true,
        onBackPressed: () => context.go('/'),
      ),
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
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: isWide ? 104 : 88,
                              height: isWide ? 104 : 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ChoiceLuxTheme.charcoalGray,
                                border: Border.all(
                                  color: ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: _profileImage != null &&
                                        _profileImage!.isNotEmpty
                                    ? Image.network(
                                        _profileImage!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Center(
                                            child: Text(
                                              _displayNameController.text.isNotEmpty
                                                  ? _displayNameController.text[0]
                                                        .toUpperCase()
                                                  : '?',
                                              style: TextStyle(
                                                fontSize: 32,
                                                color: ChoiceLuxTheme.softWhite,
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : Center(
                                        child: Text(
                                          _displayNameController.text.isNotEmpty
                                              ? _displayNameController.text[0]
                                                    .toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            fontSize: 32,
                                            color: ChoiceLuxTheme.softWhite,
                                          ),
                                        ),
                                      ),
                              ),
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
                          icon: Icon(
                            Icons.camera_alt_outlined,
                            color: ChoiceLuxTheme.richGold,
                          ),
                          label: Text(
                            'Change Profile Image',
                            style: TextStyle(
                              color: ChoiceLuxTheme.richGold,
                            ),
                          ),
                          onPressed: _isUploading
                              ? null
                              : _pickAndUploadImage,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Profile Form
                    Container(
                      decoration: BoxDecoration(
                        color: ChoiceLuxTheme.charcoalGray,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section Header
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 22,
                                  color: ChoiceLuxTheme.softWhite,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'PERSONAL INFORMATION',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: ChoiceLuxTheme.softWhite,
                                        letterSpacing: 0.5,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Form Fields - Single column layout
                            TextFormField(
                              controller: _displayNameController,
                              decoration: _modernInputDecoration('FULL NAME'),
                              style: TextStyle(
                                fontSize: 15,
                                color: ChoiceLuxTheme.softWhite,
                              ),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _kinController,
                              decoration: _modernInputDecoration(
                                'EMERGENCY CONTACT (NEXT OF KIN)',
                              ),
                              style: TextStyle(
                                fontSize: 15,
                                color: ChoiceLuxTheme.softWhite,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _numberController,
                              decoration: _modernInputDecoration(
                                'CONTACT NUMBER',
                              ),
                              style: TextStyle(
                                fontSize: 15,
                                color: ChoiceLuxTheme.softWhite,
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _kinNumberController,
                              decoration: _modernInputDecoration(
                                'EMERGENCY CONTACT NUMBER',
                              ),
                              style: TextStyle(
                                fontSize: 15,
                                color: ChoiceLuxTheme.softWhite,
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _addressController,
                              decoration: _modernInputDecoration('ADDRESS'),
                              style: TextStyle(
                                fontSize: 15,
                                color: ChoiceLuxTheme.softWhite,
                              ),
                              maxLines: 3,
                            ),

                            const SizedBox(height: 24),

                            // Save Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _saveProfile,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                    : const Icon(Icons.save, size: 18),
                                label: Text(
                                  _isLoading ? 'Saving...' : 'Save Changes',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ChoiceLuxTheme.richGold,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  elevation: 0,
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
    );
  }
}
