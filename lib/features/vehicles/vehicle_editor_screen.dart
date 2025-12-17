import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/vehicle.dart';
import 'package:image_picker/image_picker.dart';
import 'package:choice_lux_cars/core/services/upload_service.dart';
import 'providers/vehicles_provider.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/utils/background_pattern_utils.dart';
import 'package:choice_lux_cars/shared/widgets/system_safe_scaffold.dart';
import 'package:choice_lux_cars/features/branches/providers/branches_provider.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';

class VehicleEditorScreen extends ConsumerStatefulWidget {
  final Vehicle? vehicle;
  const VehicleEditorScreen({Key? key, this.vehicle}) : super(key: key);

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

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image upload failed: ${e.toString()}'),
            backgroundColor: Colors.red,
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
      const SnackBar(
        content: Text('Image removed'),
        backgroundColor: Colors.orange,
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
        const SnackBar(
          content: Text('Retrying image load...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  bool _isValidImageHeader(List<int> header) {
    // Check for common image file signatures
    if (header.length < 8) return false;

    // JPEG: FF D8 FF
    if (header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF)
      return true;

    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if (header[0] == 0x89 &&
        header[1] == 0x50 &&
        header[2] == 0x4E &&
        header[3] == 0x47)
      return true;

    // GIF: 47 49 46 38
    if (header[0] == 0x47 &&
        header[1] == 0x49 &&
        header[2] == 0x46 &&
        header[3] == 0x38)
      return true;

    // WebP: 52 49 46 46 ... 57 45 42 50
    if (header[0] == 0x52 &&
        header[1] == 0x49 &&
        header[2] == 0x46 &&
        header[3] == 0x46)
      return true;

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Vehicle ${isEdit ? 'updated' : 'added'} successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      } catch (e) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStatusChip(String status) {
    final isActive = status == 'Active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isActive ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Active' : 'Deactivated',
            style: TextStyle(
              color: isActive ? Colors.green : Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseCountdownIndicator() {
    final daysRemaining = licenseExpiryDate.difference(DateTime.now()).inDays;
    final isOverdue = daysRemaining < 0;
    final statusColor = isOverdue
        ? Colors.red
        : (daysRemaining < 30 ? Colors.orange : Colors.green);
    final statusText = isOverdue
        ? 'Overdue'
        : (daysRemaining == 0 ? 'Today' : '$daysRemaining days');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
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
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleMetadata() {
    if (!isEdit) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.grey[400]),
                  const SizedBox(width: 8),
                  Text(
                    'Vehicle Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[200],
                    ),
                  ),
                ],
              ),
              _buildStatusChip(status),
            ],
          ),
          const SizedBox(height: 20),
          _buildMetadataRow('Vehicle ID', '#${widget.vehicle?.id ?? 'N/A'}'),
          _buildMetadataRow(
            'Created',
            widget.vehicle?.createdAt?.toString().split(' ')[0] ?? 'N/A',
          ),
          _buildMetadataRow(
            'Last Updated',
            widget.vehicle?.updatedAt?.toString().split(' ')[0] ?? 'N/A',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[400]),
              const SizedBox(width: 8),
              Text(
                'License Status',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildLicenseCountdownIndicator(),
          // Future enhancement: _buildMetadataRow('Assigned Jobs', '0'),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey[200],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.grey[200],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPageTitle() {
    if (!isEdit)
      return Text(
        'Add Vehicle',
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      );

    return Text(
      'Edit: ${widget.vehicle?.make ?? ''} ${widget.vehicle?.model ?? ''}',
      style: Theme.of(
        context,
      ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildModernPageTitle(bool isMobile, bool isSmallMobile) {
    return Text(
      isEdit ? 'Edit Vehicle' : 'Add Vehicle',
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: ChoiceLuxTheme.platinumSilver,
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
            Icon(icon, size: 24, color: ChoiceLuxTheme.platinumSilver),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: ChoiceLuxTheme.platinumSilver,
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
                  labelStyle: TextStyle(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7)),
                  hintStyle: TextStyle(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.5)),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7)),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red.withOpacity(0.7)),
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
                  labelStyle: TextStyle(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7)),
                  hintStyle: TextStyle(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.5)),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7)),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red.withOpacity(0.7)),
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
                  labelStyle: TextStyle(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7)),
                  hintStyle: TextStyle(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.5)),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7)),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red.withOpacity(0.7)),
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
                  labelStyle: TextStyle(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7)),
                  hintStyle: TextStyle(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.5)),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7)),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red.withOpacity(0.7)),
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
            labelStyle: TextStyle(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7)),
            hintStyle: TextStyle(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.5)),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.withOpacity(0.7)),
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
                value: ['Petrol', 'Diesel', 'Hybrid', 'Electric'].contains(fuelType)
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
                  labelStyle: TextStyle(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7)),
                  hintStyle: TextStyle(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.5)),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7)),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red.withOpacity(0.7)),
                  ),
                ),
              ),
              SizedBox(height: compactGap),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: ['Active', 'Deactivated'].contains(status)
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
                  labelStyle: TextStyle(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7)),
                  hintStyle: TextStyle(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.5)),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7)),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red.withOpacity(0.7)),
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
                value: ['Petrol', 'Diesel', 'Hybrid', 'Electric'].contains(fuelType)
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
                  labelStyle: TextStyle(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7)),
                  hintStyle: TextStyle(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.5)),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7)),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red.withOpacity(0.7)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                value: ['Active', 'Deactivated'].contains(status)
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
                  labelStyle: TextStyle(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7)),
                  hintStyle: TextStyle(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.5)),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7)),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red.withOpacity(0.7)),
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
                  value: branchId,
                  decoration: InputDecoration(
                    labelText: 'Branch',
                    hintText: 'Select branch',
                    labelStyle: TextStyle(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7)),
                    hintStyle: TextStyle(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.5)),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7)),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red.withOpacity(0.7)),
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
            labelStyle: TextStyle(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7)),
            hintStyle: TextStyle(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.5)),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            suffixIcon: Icon(Icons.calendar_today, color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.withOpacity(0.7)),
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
                labelStyle: TextStyle(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7)),
                hintStyle: TextStyle(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.5)),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                suffixIcon: Icon(Icons.calendar_today, color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7)),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red.withOpacity(0.7)),
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
                border: Border.all(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
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
                  backgroundColor: ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
                  foregroundColor: ChoiceLuxTheme.platinumSilver,
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
                      backgroundColor: ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
                      foregroundColor: ChoiceLuxTheme.platinumSilver,
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
                      foregroundColor: Colors.red,
                      backgroundColor: ChoiceLuxTheme.platinumSilver.withOpacity(0.1),
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
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: isMobile ? 48 : 64,
            color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to upload',
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7),
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
      color: Colors.orange[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.link_off,
            size: isMobile ? 48 : 64,
            color: Colors.orange[600],
          ),
          const SizedBox(height: 8),
          Text(
            'Invalid Image URL',
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              color: Colors.orange[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap to upload new image',
            style: TextStyle(
              fontSize: isMobile ? 10 : 12,
              color: Colors.orange[600],
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
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
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
      color: Colors.red[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: isMobile ? 48 : 64,
            color: Colors.red[600],
          ),
          const SizedBox(height: 8),
          Text(
            'Image Load Failed',
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              color: Colors.red[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap to retry or upload new',
            style: TextStyle(
              fontSize: isMobile ? 10 : 12,
              color: Colors.red[600],
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
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
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
      color: Colors.blue[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: isMobile ? 32 : 40,
            height: isMobile ? 32 : 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Loading...',
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              color: Colors.blue[600],
            ),
          ),
          if (loadingProgress != null && loadingProgress.expectedTotalBytes != null) ...[
            const SizedBox(height: 4),
            Text(
              '${((loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!) * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: isMobile ? 10 : 12,
                color: Colors.blue[600],
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
                backgroundColor: ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
                foregroundColor: ChoiceLuxTheme.platinumSilver,
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
                foregroundColor: ChoiceLuxTheme.platinumSilver.withOpacity(0.5),
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
                  foregroundColor: ChoiceLuxTheme.platinumSilver.withOpacity(0.5),
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(160, 48),
                  backgroundColor: ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
                  foregroundColor: ChoiceLuxTheme.platinumSilver,
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
    // Mobile-first responsive breakpoints
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 400;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final isDesktop = screenWidth >= 900;
    final fieldSpacing = isMobile ? 16.0 : 20.0;

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
                    color: ChoiceLuxTheme.charcoalGray,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
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
                          Divider(color: ChoiceLuxTheme.platinumSilver.withOpacity(0.2), height: 1),
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
}
