import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:choice_lux_cars/core/services/upload_service.dart';
import 'package:choice_lux_cars/features/vehicles/vehicles.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/app/theme_helpers.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/utils/background_pattern_utils.dart';
import 'package:choice_lux_cars/shared/widgets/system_safe_scaffold.dart';
import 'package:choice_lux_cars/features/branches/branches.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/core/services/permission_service.dart';

class VehicleEditorScreen extends ConsumerStatefulWidget {
  final Vehicle? vehicle;
  const VehicleEditorScreen({super.key, this.vehicle});

  @override
  ConsumerState<VehicleEditorScreen> createState() =>
      _VehicleEditorScreenState();
}

class _VehicleEditorScreenState extends ConsumerState<VehicleEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late String make;
  late String model;
  late String regPlate;
  late String fuelType;
  late String status;
  late DateTime regDate;
  late DateTime licenseExpiryDate;
  String? vehicleImage;
  int? branchId; // Branch allocation for vehicle
  bool isLoading = false;
  bool showSuccessMessage = false;

  bool get isEdit => widget.vehicle != null;

  // Constants for consistent spacing
  static const double fieldSpacing = 20.0;
  static const double sectionSpacing = 32.0;
  static const double buttonSpacing = 24.0;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    make = v?.make ?? '';
    model = v?.model ?? '';
    regPlate = v?.regPlate ?? '';
    fuelType = v?.fuelType ?? 'Petrol';
    status = v?.status ?? 'Active';
    regDate = v?.regDate ?? DateTime.now();
    licenseExpiryDate = v?.licenseExpiryDate ?? DateTime.now();
    vehicleImage = v?.vehicleImage;
    branchId = v?.branchId;
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
      maxHeight: 600,
    );

    if (picked != null) {
      setState(() => isLoading = true);
      try {
        // Validate image format
        final bytes = await picked.readAsBytes();
        if (bytes.length < 10) {
          throw Exception('Invalid image file');
        }

        // Check if it's a valid image by looking at the first few bytes
        final header = bytes.take(10).toList();
        if (!_isValidImageHeader(header)) {
          throw Exception(
            'Invalid image format. Please select a valid image file (JPEG, PNG, etc.)',
          );
        }

        final url = await UploadService.uploadVehicleImageWithId(
          bytes,
          widget.vehicle?.id,
        );
        setState(() => vehicleImage = url);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image uploaded successfully!'),
            backgroundColor: context.tokens.successColor,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image upload failed: ${e.toString()}'),
            backgroundColor: context.tokens.warningColor,
            duration: const Duration(seconds: 5),
          ),
        );
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  void _removeImage() {
    setState(() => vehicleImage = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Image removed'),
        backgroundColor: context.colorScheme.primary,
      ),
    );
  }

  void _retryImageLoad() {
    if (vehicleImage != null && vehicleImage!.isNotEmpty) {
      print('=== RETRYING IMAGE LOAD ===');
      print('Image URL: $vehicleImage');
      print('===========================');
      
      // Force rebuild to retry image loading
      setState(() {});
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Retrying image load...'),
          backgroundColor: context.tokens.infoColor,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  bool _isValidImageHeader(List<int> header) {
    // Check for common image file signatures
    if (header.length < 8) return false;

    // JPEG: FF D8 FF
    if (header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF) {
      return true;
    }

    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if (header[0] == 0x89 &&
        header[1] == 0x50 &&
        header[2] == 0x4E &&
        header[3] == 0x47) {
      return true;
    }

    // GIF: 47 49 46 38
    if (header[0] == 0x47 &&
        header[1] == 0x49 &&
        header[2] == 0x46 &&
        header[3] == 0x38) {
      return true;
    }

    // WebP: 52 49 46 46 ... 57 45 42 50
    if (header[0] == 0x52 &&
        header[1] == 0x49 &&
        header[2] == 0x46 &&
        header[3] == 0x46) {
      return true;
    }

    return false;
  }

  void _save() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      setState(() => isLoading = true);

      try {
        final vehicle = Vehicle(
          id: widget.vehicle?.id,
          make: make,
          model: model,
          regPlate: regPlate,
          regDate: regDate,
          fuelType: fuelType,
          vehicleImage: vehicleImage,
          status: status,
          licenseExpiryDate: licenseExpiryDate,
          createdAt: widget.vehicle?.createdAt,
          updatedAt: DateTime.now(),
          branchId: branchId,
        );

        final notifier = ref.read(vehiclesProvider.notifier);
        if (isEdit) {
          await notifier.updateVehicle(vehicle);
        } else {
          await notifier.addVehicle(vehicle);
        }

        setState(() {
          isLoading = false;
          showSuccessMessage = true;
        });

        // Show success message and close after delay
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: context.tokens.onSuccess),
                const SizedBox(width: 8),
                Text('Vehicle ${isEdit ? 'updated' : 'added'} successfully!'),
              ],
            ),
            backgroundColor: context.tokens.successColor,
            duration: const Duration(seconds: 2),
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        }        );
      } catch (e) {
        setState(() => isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: context.tokens.warningColor,
          ),
        );
      }
    }
  }

  Widget _buildLicenseCountdownIndicator() {
    final daysRemaining = licenseExpiryDate.difference(DateTime.now()).inDays;
    final isOverdue = daysRemaining < 0;
    final statusColor = isOverdue
        ? context.tokens.warningColor
        : (daysRemaining < 30 ? context.colorScheme.primary : context.tokens.successColor);
    final statusText = isOverdue
        ? 'Overdue'
        : (daysRemaining == 0 ? 'Today' : '$daysRemaining days');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverdue ? Icons.warning : Icons.access_time,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: context.textTheme.bodySmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSectionHeader(String title, IconData icon, bool isMobile, bool isSmallMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Row(
          children: [
            Icon(icon, size: 24, color: context.tokens.textBody),
            const SizedBox(width: 12),
            Text(
              title,
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: context.tokens.textBody,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }


  Widget _buildVehicleDetailsForm(bool isMobile, bool isSmallMobile) {
    final compactGap = isSmallMobile ? 12.0 : 16.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isSmallMobile)
          Column(
            children: [
              TextFormField(
                initialValue: make,
                onChanged: (value) => make = value,
                decoration: InputDecoration(
                  labelText: 'Make',
                  hintText: 'Enter vehicle make',
                  labelStyle: context.textTheme.bodyMedium?.copyWith(
                    color: context.tokens.textBody,
                  ),
                  hintStyle: context.textTheme.bodyMedium?.copyWith(
                    color: context.tokens.textSubtle,
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.tokens.focusBorder,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.tokens.warningColor.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.tokens.warningColor.withValues(alpha: 0.8),
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) =>
                    value?.isEmpty == true ? 'Make is required' : null,
              ),
              SizedBox(height: compactGap),
              TextFormField(
                initialValue: model,
                onChanged: (value) => model = value,
                decoration: InputDecoration(
                  labelText: 'Model',
                  hintText: 'Enter vehicle model',
                  labelStyle: context.textTheme.bodyMedium?.copyWith(
                    color: context.tokens.textBody,
                  ),
                  hintStyle: context.textTheme.bodyMedium?.copyWith(
                    color: context.tokens.textSubtle,
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.tokens.focusBorder,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.tokens.warningColor.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.tokens.warningColor.withValues(alpha: 0.8),
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) =>
                    value?.isEmpty == true ? 'Model is required' : null,
              ),
            ],
          )
        else
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: make,
                onChanged: (value) => make = value,
                decoration: InputDecoration(
                  labelText: 'Make',
                  hintText: 'Enter vehicle make',
                  labelStyle: context.textTheme.bodyMedium?.copyWith(
                    color: context.tokens.textBody,
                  ),
                  hintStyle: context.textTheme.bodyMedium?.copyWith(
                    color: context.tokens.textSubtle,
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.tokens.focusBorder,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.tokens.warningColor.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.tokens.warningColor.withValues(alpha: 0.8),
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) =>
                    value?.isEmpty == true ? 'Make is required' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: model,
                onChanged: (value) => model = value,
                decoration: InputDecoration(
                  labelText: 'Model',
                  hintText: 'Enter vehicle model',
                  labelStyle: context.textTheme.bodyMedium?.copyWith(
                    color: context.tokens.textBody,
                  ),
                  hintStyle: context.textTheme.bodyMedium?.copyWith(
                    color: context.tokens.textSubtle,
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.tokens.focusBorder,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.tokens.warningColor.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.tokens.warningColor.withValues(alpha: 0.8),
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) =>
                    value?.isEmpty == true ? 'Model is required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: fieldSpacing),

        TextFormField(
          initialValue: regPlate,
          onChanged: (value) => regPlate = value,
          decoration: InputDecoration(
            labelText: 'Registration Plate',
            hintText: 'Enter registration plate',
            labelStyle: context.textTheme.bodyMedium?.copyWith(
              color: context.tokens.textBody,
            ),
            hintStyle: context.textTheme.bodyMedium?.copyWith(
              color: context.tokens.textSubtle,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: context.tokens.focusBorder,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: context.tokens.warningColor.withValues(alpha: 0.5),
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: context.tokens.warningColor.withValues(alpha: 0.8),
                width: 2,
              ),
            ),
          ),
          validator: (value) => value?.isEmpty == true
              ? 'Registration plate is required'
              : null,
        ),
        const SizedBox(height: fieldSpacing),

        if (isSmallMobile)
          Column(
            children: [
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: ['Petrol', 'Diesel', 'Hybrid', 'Electric'].contains(fuelType)
                    ? fuelType
                    : 'Petrol',
                items: const [
                  DropdownMenuItem(value: 'Petrol', child: Text('Petrol')),
                  DropdownMenuItem(value: 'Diesel', child: Text('Diesel')),
                  DropdownMenuItem(value: 'Hybrid', child: Text('Hybrid')),
                  DropdownMenuItem(value: 'Electric', child: Text('Electric')),
                ],
                onChanged: (v) => setState(() => fuelType = v ?? 'Petrol'),
                decoration: InputDecoration(
                  labelText: 'Fuel Type',
                  hintText: 'Select fuel type',
                  labelStyle: context.textTheme.bodyMedium?.copyWith(
                    color: context.tokens.textBody,
                  ),
                  hintStyle: context.textTheme.bodyMedium?.copyWith(
                    color: context.tokens.textSubtle,
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.tokens.focusBorder,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.tokens.warningColor.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.tokens.warningColor.withValues(alpha: 0.8),
                      width: 2,
                    ),
                  ),
                ),
              ),
              SizedBox(height: compactGap),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: ['Active', 'Deactivated'].contains(status)
                    ? status
                    : 'Active',
                items: const [
                  DropdownMenuItem(value: 'Active', child: Text('Active')),
                  DropdownMenuItem(value: 'Deactivated', child: Text('Deactivated')),
                ],
                onChanged: (v) => setState(() => status = v ?? 'Active'),
                decoration: InputDecoration(
                  labelText: 'Status',
                  hintText: 'Select status',
                  labelStyle: context.textTheme.bodyMedium?.copyWith(
                    color: context.tokens.textBody,
                  ),
                  hintStyle: context.textTheme.bodyMedium?.copyWith(
                    color: context.tokens.textSubtle,
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.tokens.focusBorder,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.tokens.warningColor.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.tokens.warningColor.withValues(alpha: 0.8),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          )
        else
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: ['Petrol', 'Diesel', 'Hybrid', 'Electric'].contains(fuelType)
                    ? fuelType
                    : 'Petrol',
                items: const [
                  DropdownMenuItem(value: 'Petrol', child: Text('Petrol')),
                  DropdownMenuItem(value: 'Diesel', child: Text('Diesel')),
                  DropdownMenuItem(value: 'Hybrid', child: Text('Hybrid')),
                  DropdownMenuItem(value: 'Electric', child: Text('Electric')),
                ],
                onChanged: (v) => setState(() => fuelType = v ?? 'Petrol'),
                decoration: InputDecoration(
                  labelText: 'Fuel Type',
                  hintText: 'Select fuel type',
                  labelStyle: context.textTheme.bodyMedium?.copyWith(
                    color: context.tokens.textBody,
                  ),
                  hintStyle: context.textTheme.bodyMedium?.copyWith(
                    color: context.tokens.textSubtle,
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.tokens.focusBorder,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.tokens.warningColor.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.tokens.warningColor.withValues(alpha: 0.8),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: ['Active', 'Deactivated'].contains(status)
                    ? status
                    : 'Active',
                items: const [
                  DropdownMenuItem(value: 'Active', child: Text('Active')),
                  DropdownMenuItem(value: 'Deactivated', child: Text('Deactivated')),
                ],
                onChanged: (v) => setState(() => status = v ?? 'Active'),
                decoration: InputDecoration(
                  labelText: 'Status',
                  hintText: 'Select status',
                  labelStyle: context.textTheme.bodyMedium?.copyWith(
                    color: context.tokens.textBody,
                  ),
                  hintStyle: context.textTheme.bodyMedium?.copyWith(
                    color: context.tokens.textSubtle,
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.tokens.focusBorder,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.tokens.warningColor.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.tokens.warningColor.withValues(alpha: 0.8),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: fieldSpacing),
        // Branch dropdown (only visible to admin)
        Consumer(
          builder: (context, ref, child) {
            final currentUser = ref.watch(currentUserProfileProvider);
            final isAdmin = currentUser?.isAdmin ?? false;
            final branchesAsync = ref.watch(branchesProvider);

            if (!isAdmin) {
              return const SizedBox.shrink(); // Hide branch dropdown for non-admin
            }

            return branchesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (branches) {
                return DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: branchId,
                  decoration: InputDecoration(
                    labelText: 'Branch',
                    hintText: 'Select branch',
                    labelStyle: context.textTheme.bodyMedium?.copyWith(
                      color: context.tokens.textBody,
                    ),
                    hintStyle: context.textTheme.bodyMedium?.copyWith(
                      color: context.tokens.textSubtle,
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.colorScheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.colorScheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: context.tokens.focusBorder,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: context.tokens.warningColor.withValues(alpha: 0.5),
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: context.tokens.warningColor.withValues(alpha: 0.8),
                        width: 2,
                      ),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Not Assigned'),
                    ),
                    ...branches.map((branch) {
                      return DropdownMenuItem<int>(
                        value: branch.id,
                        child: Text(branch.name),
                      );
                    }),
                  ],
                  onChanged: (value) => setState(() => branchId = value),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildRegistrationForm(bool isMobile, bool isSmallMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          readOnly: true,
          controller: TextEditingController(
            text: regDate != DateTime(2000, 1, 1)
                ? regDate.toString().split(' ')[0]
                : '',
          ),
          decoration: InputDecoration(
            labelText: 'Registration Date',
            hintText: 'Select registration date',
            labelStyle: context.textTheme.bodyMedium?.copyWith(
              color: context.tokens.textBody,
            ),
            hintStyle: context.textTheme.bodyMedium?.copyWith(
              color: context.tokens.textSubtle,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            suffixIcon: Icon(Icons.calendar_today, color: context.tokens.textBody),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: context.tokens.focusBorder,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: context.tokens.warningColor.withValues(alpha: 0.5),
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: context.tokens.warningColor.withValues(alpha: 0.8),
                width: 2,
              ),
            ),
          ),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: regDate != DateTime(2000, 1, 1)
                  ? regDate
                  : DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              setState(() => regDate = date);
            }
          },
        ),
        const SizedBox(height: fieldSpacing),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              readOnly: true,
              controller: TextEditingController(
                text: licenseExpiryDate != DateTime(2000, 1, 1)
                    ? licenseExpiryDate.toString().split(' ')[0]
                    : '',
              ),
              decoration: InputDecoration(
                labelText: 'License Expiry Date',
                hintText: 'Select expiry date',
                labelStyle: context.textTheme.bodyMedium?.copyWith(
                  color: context.tokens.textBody,
                ),
                hintStyle: context.textTheme.bodyMedium?.copyWith(
                  color: context.tokens.textSubtle,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                suffixIcon: Icon(Icons.calendar_today, color: context.tokens.textBody),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                color: context.tokens.focusBorder,
                width: 2,
              ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                color: context.tokens.warningColor.withValues(alpha: 0.5),
              ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                color: context.tokens.warningColor.withValues(alpha: 0.8),
                width: 2,
              ),
                ),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: licenseExpiryDate != DateTime(2000, 1, 1)
                      ? licenseExpiryDate
                      : DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  setState(() => licenseExpiryDate = date);
                }
              },
            ),
            const SizedBox(height: 8),
            _buildLicenseCountdownIndicator(),
          ],
        ),
      ],
    );
  }

  Widget _buildImageSection(bool isMobile, bool isSmallMobile) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: vehicleImage != null
                ? _removeImage
                : _pickAndUploadImage,
            onLongPress: vehicleImage != null
                ? _pickAndUploadImage
                : null,
            child: Container(
              width: isMobile ? 160 : 200,
              height: isMobile ? 160 : 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colorScheme.outline.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: context.colorScheme.background.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildImageWidget(isMobile),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (vehicleImage == null)
            SizedBox(
              width: isMobile ? double.infinity : null,
              child: ElevatedButton.icon(
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.upload),
                label: Text(
                  isLoading ? 'Uploading...' : 'Upload Image',
                ),
                onPressed: isLoading ? null : _pickAndUploadImage,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: context.colorScheme.surfaceVariant,
                  foregroundColor: context.tokens.textBody,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            )
          else
            Column(
              children: [
                SizedBox(
                  width: isMobile ? double.infinity : 160,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Replace'),
                    onPressed: _pickAndUploadImage,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor: context.colorScheme.surfaceVariant,
                      foregroundColor: context.tokens.textBody,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: isMobile ? double.infinity : 160,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text('Remove'),
                    onPressed: _removeImage,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      foregroundColor: context.tokens.warningColor,
                      backgroundColor: context.colorScheme.surfaceVariant.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(bool isMobile) {
    if (vehicleImage == null || vehicleImage!.isEmpty) {
      return _buildPlaceholder(isMobile);
    }
    
    // Validate URL format
    if (!_isImageUrlValid(vehicleImage!)) {
      return _buildInvalidUrlPlaceholder(isMobile);
    }
    
    return Image.network(
      vehicleImage!,
      width: isMobile ? 160 : 200,
      height: isMobile ? 160 : 200,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(isMobile, error),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoadingPlaceholder(isMobile, loadingProgress);
      },
    );
  }

  Widget _buildPlaceholder(bool isMobile) {
    return Container(
      width: isMobile ? 160 : 200,
      height: isMobile ? 160 : 200,
      color: context.colorScheme.surfaceVariant,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: isMobile ? 48 : 64,
            color: context.tokens.textBody,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to upload',
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              color: context.tokens.textBody,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvalidUrlPlaceholder(bool isMobile) {
    return Container(
      width: isMobile ? 160 : 200,
      height: isMobile ? 160 : 200,
      color: context.colorScheme.primary.withValues(alpha: 0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.link_off,
            size: isMobile ? 48 : 64,
            color: context.colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'Invalid Image URL',
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              color: context.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap to upload new image',
            style: TextStyle(
              fontSize: isMobile ? 10 : 12,
              color: context.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: isMobile ? 80 : 100,
            height: isMobile ? 28 : 32,
            child: ElevatedButton(
              onPressed: _retryImageLoad,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colorScheme.primary,
                foregroundColor: context.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  fontSize: isMobile ? 10 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPlaceholder(bool isMobile, Object error) {
    // Log the error for debugging
    print('=== IMAGE LOAD ERROR ===');
    print('Image URL: $vehicleImage');
    print('Error: $error');
    print('Error type: ${error.runtimeType}');
    print('========================');
    
    return Container(
      width: isMobile ? 160 : 200,
      height: isMobile ? 160 : 200,
      color: context.tokens.warningColor.withValues(alpha: 0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: isMobile ? 48 : 64,
            color: context.tokens.warningColor,
          ),
          const SizedBox(height: 8),
          Text(
            'Image Load Failed',
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              color: context.tokens.warningColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap to retry or upload new',
            style: TextStyle(
              fontSize: isMobile ? 10 : 12,
              color: context.tokens.warningColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: isMobile ? 80 : 100,
            height: isMobile ? 28 : 32,
            child: ElevatedButton(
              onPressed: _retryImageLoad,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.tokens.warningColor,
                foregroundColor: context.tokens.onWarning,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  fontSize: isMobile ? 10 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingPlaceholder(bool isMobile, ImageChunkEvent? loadingProgress) {
    return Container(
      width: isMobile ? 160 : 200,
      height: isMobile ? 160 : 200,
      color: context.tokens.infoColor.withValues(alpha: 0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: isMobile ? 32 : 40,
            height: isMobile ? 32 : 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(context.tokens.infoColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Loading...',
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              color: context.tokens.infoColor,
            ),
          ),
          if (loadingProgress != null && loadingProgress.expectedTotalBytes != null) ...[
            const SizedBox(height: 4),
            Text(
              '${((loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!) * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: isMobile ? 10 : 12,
                color: context.tokens.infoColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _isImageUrlValid(String url) {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasAbsolutePath) {
        print('Invalid URL format: $url');
        return false;
      }
      
      // Check if it's a supported image format
      final path = uri.path.toLowerCase();
      final supportedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
      final hasValidExtension = supportedExtensions.any((ext) => path.endsWith(ext));
      
      if (!hasValidExtension) {
        print('Unsupported image format: $path');
        return false;
      }
      
      return true;
    } catch (e) {
      print('URL validation error: $e');
      return false;
    }
  }

  Widget _buildModernActionButtons(bool isMobile, bool isSmallMobile) {
    return Column(
      children: [
        if (isMobile) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 48),
                backgroundColor: context.colorScheme.surfaceVariant,
                foregroundColor: context.tokens.textBody,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(isEdit ? 'Update Vehicle' : 'Add Vehicle'),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 48),
                foregroundColor: context.tokens.textSubtle,
              ),
              child: const Text('Cancel'),
            ),
          ),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  minimumSize: const Size(120, 48),
                  foregroundColor: context.tokens.textSubtle,
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(160, 48),
                  backgroundColor: context.colorScheme.surfaceVariant,
                  foregroundColor: context.tokens.textBody,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(isEdit ? 'Update Vehicle' : 'Add Vehicle'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(currentUserProfileProvider);
    final userRole = userProfile?.role;
    final permissionService = const PermissionService();
    
    if (!permissionService.canAccessVehicles(userRole)) {
      return _buildAccessDenied();
    }

    // Mobile-first responsive breakpoints
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 400;
    final isDesktop = screenWidth >= 900;

    return Stack(
      children: [
        // Layer 1: The background that fills the entire screen
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.colorScheme.background,
                context.colorScheme.surface,
              ],
            ),
          ),
        ),
        // Layer 2: Background pattern that covers the entire screen
        const Positioned.fill(
          child: CustomPaint(painter: BackgroundPatterns.dashboard),
        ),
        // Layer 3: The SystemSafeScaffold with a transparent background
        SystemSafeScaffold(
          backgroundColor: Colors.transparent,
          appBar: LuxuryAppBar(
            title: isEdit ? 'Edit Vehicle' : 'Add Vehicle',
            showBackButton: true,
            onBackPressed: () => Navigator.of(context).pop(),
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 800 : double.infinity,
                  ),
                  child: Card(
                    color: context.colorScheme.surface,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: context.colorScheme.outline.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Vehicle details section
                          _buildModernSectionHeader('Vehicle Details', Icons.directions_car, isMobile, isSmallMobile),

                          _buildVehicleDetailsForm(isMobile, isSmallMobile),

                          // Registration & License section
                          _buildModernSectionHeader('Registration & License', Icons.assignment, isMobile, isSmallMobile),

                          _buildRegistrationForm(isMobile, isSmallMobile),

                          // Vehicle Image section
                          _buildModernSectionHeader('Vehicle Image', Icons.photo_camera, isMobile, isSmallMobile),

                          _buildImageSection(isMobile, isSmallMobile),

                          // Action buttons with divider
                          const SizedBox(height: 32),
                          Divider(color: context.colorScheme.outline.withValues(alpha: 0.2), height: 1),
                          const SizedBox(height: 24),
                          _buildModernActionButtons(isMobile, isSmallMobile),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccessDenied() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.colorScheme.background,
                context.colorScheme.surface,
              ],
            ),
          ),
        ),
        const Positioned.fill(
          child: CustomPaint(painter: BackgroundPatterns.dashboard),
        ),
        SystemSafeScaffold(
          backgroundColor: Colors.transparent,
          appBar: LuxuryAppBar(
            title: isEdit ? 'Edit Vehicle' : 'Add Vehicle',
            showBackButton: true,
            onBackPressed: () => Navigator.of(context).pop(),
          ),
          body: const Center(
            child: Text(
              'Access denied',
              style: TextStyle(
                color: ChoiceLuxTheme.platinumSilver,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
