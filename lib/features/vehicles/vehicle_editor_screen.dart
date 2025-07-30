import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/vehicle.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/upload_service.dart';
import 'providers/vehicles_provider.dart';
import '../../shared/widgets/simple_app_bar.dart';

class VehicleEditorScreen extends ConsumerStatefulWidget {
  final Vehicle? vehicle;
  const VehicleEditorScreen({Key? key, this.vehicle}) : super(key: key);

  @override
  ConsumerState<VehicleEditorScreen> createState() => _VehicleEditorScreenState();
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
          throw Exception('Invalid image format. Please select a valid image file (JPEG, PNG, etc.)');
        }
        
        final url = await UploadService.uploadVehicleImage(bytes, widget.vehicle?.id);
        setState(() => vehicleImage = url);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully!'), backgroundColor: Colors.green),
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
      const SnackBar(content: Text('Image removed'), backgroundColor: Colors.orange),
    );
  }

  bool _isValidImageHeader(List<int> header) {
    // Check for common image file signatures
    if (header.length < 8) return false;
    
    // JPEG: FF D8 FF
    if (header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF) return true;
    
    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if (header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47) return true;
    
    // GIF: 47 49 46 38
    if (header[0] == 0x47 && header[1] == 0x49 && header[2] == 0x46 && header[3] == 0x38) return true;
    
    // WebP: 52 49 46 46 ... 57 45 42 50
    if (header[0] == 0x52 && header[1] == 0x49 && header[2] == 0x46 && header[3] == 0x46) return true;
    
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
        color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
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
    final statusColor = isOverdue ? Colors.red : (daysRemaining < 30 ? Colors.orange : Colors.green);
    final statusText = isOverdue ? 'Overdue' : (daysRemaining == 0 ? 'Today' : '$daysRemaining days');

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
          _buildMetadataRow('Created', widget.vehicle?.createdAt?.toString().split(' ')[0] ?? 'N/A'),
          _buildMetadataRow('Last Updated', widget.vehicle?.updatedAt?.toString().split(' ')[0] ?? 'N/A'),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[400]),
              const SizedBox(width: 8),
              Text(
                'License Status',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
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
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
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
    if (!isEdit) return Text(
      'Add Vehicle',
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
    
    return Text(
      'Edit: ${widget.vehicle?.make ?? ''} ${widget.vehicle?.model ?? ''}',
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet = MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width <= 900;
    
    final content = SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status badge (only for desktop)
            if (isDesktop) ...[
              Row(
                children: [
                  Expanded(child: _buildPageTitle()),
                ],
              ),
              const SizedBox(height: 32),
            ],
            
            // Vehicle details section
            _buildSectionHeader('Vehicle Details'),
            
            // Make and Model row
            if (isMobile) ...[
              TextFormField(
                initialValue: make,
                onChanged: (value) => make = value,
                decoration: const InputDecoration(
                  labelText: 'Make',
                  hintText: 'Enter vehicle make',
                ),
                validator: (value) => value?.isEmpty == true ? 'Make is required' : null,
              ),
              const SizedBox(height: fieldSpacing),
              TextFormField(
                initialValue: model,
                onChanged: (value) => model = value,
                decoration: const InputDecoration(
                  labelText: 'Model',
                  hintText: 'Enter vehicle model',
                ),
                validator: (value) => value?.isEmpty == true ? 'Model is required' : null,
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: make,
                      onChanged: (value) => make = value,
                      decoration: const InputDecoration(
                        labelText: 'Make',
                        hintText: 'Enter vehicle make',
                      ),
                      validator: (value) => value?.isEmpty == true ? 'Make is required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      initialValue: model,
                      onChanged: (value) => model = value,
                      decoration: const InputDecoration(
                        labelText: 'Model',
                        hintText: 'Enter vehicle model',
                      ),
                      validator: (value) => value?.isEmpty == true ? 'Model is required' : null,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: fieldSpacing),
            
            // Registration plate
            TextFormField(
              initialValue: regPlate,
              onChanged: (value) => regPlate = value,
              decoration: const InputDecoration(
                labelText: 'Registration Plate',
                hintText: 'Enter registration plate',
              ),
              validator: (value) => value?.isEmpty == true ? 'Registration plate is required' : null,
            ),
            const SizedBox(height: fieldSpacing),
            
            // Fuel type and status row - full width dropdowns
            if (isMobile) ...[
              DropdownButtonFormField<String>(
                value: ['Petrol', 'Diesel', 'Hybrid', 'Electric'].contains(fuelType) ? fuelType : 'Petrol',
                items: const [
                  DropdownMenuItem(value: 'Petrol', child: Text('Petrol')),
                  DropdownMenuItem(value: 'Diesel', child: Text('Diesel')),
                  DropdownMenuItem(value: 'Hybrid', child: Text('Hybrid')),
                  DropdownMenuItem(value: 'Electric', child: Text('Electric')),
                ],
                onChanged: (v) => setState(() => fuelType = v ?? 'Petrol'),
                decoration: const InputDecoration(
                  labelText: 'Fuel Type',
                  hintText: 'Select fuel type',
                ),
              ),
              const SizedBox(height: fieldSpacing),
              DropdownButtonFormField<String>(
                value: ['Active', 'Deactivated'].contains(status) ? status : 'Active',
                items: const [
                  DropdownMenuItem(value: 'Active', child: Text('Active')),
                  DropdownMenuItem(value: 'Deactivated', child: Text('Deactivated')),
                ],
                onChanged: (v) => setState(() => status = v ?? 'Active'),
                decoration: const InputDecoration(
                  labelText: 'Status',
                  hintText: 'Select status',
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: ['Petrol', 'Diesel', 'Hybrid', 'Electric'].contains(fuelType) ? fuelType : 'Petrol',
                      items: const [
                        DropdownMenuItem(value: 'Petrol', child: Text('Petrol')),
                        DropdownMenuItem(value: 'Diesel', child: Text('Diesel')),
                        DropdownMenuItem(value: 'Hybrid', child: Text('Hybrid')),
                        DropdownMenuItem(value: 'Electric', child: Text('Electric')),
                      ],
                      onChanged: (v) => setState(() => fuelType = v ?? 'Petrol'),
                      decoration: const InputDecoration(
                        labelText: 'Fuel Type',
                        hintText: 'Select fuel type',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: ['Active', 'Deactivated'].contains(status) ? status : 'Active',
                      items: const [
                        DropdownMenuItem(value: 'Active', child: Text('Active')),
                        DropdownMenuItem(value: 'Deactivated', child: Text('Deactivated')),
                      ],
                      onChanged: (v) => setState(() => status = v ?? 'Active'),
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        hintText: 'Select status',
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            // Dates section
            _buildSectionHeader('Registration & License'),
            
            // Registration and license dates row
            if (isMobile) ...[
              TextFormField(
                readOnly: true,
                controller: TextEditingController(
                  text: regDate != DateTime(2000, 1, 1) ? regDate.toString().split(' ')[0] : '',
                ),
                decoration: const InputDecoration(
                  labelText: 'Registration Date',
                  hintText: 'Select registration date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: regDate != DateTime(2000, 1, 1) ? regDate : DateTime.now(),
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
                      text: licenseExpiryDate != DateTime(2000, 1, 1) ? licenseExpiryDate.toString().split(' ')[0] : '',
                    ),
                    decoration: const InputDecoration(
                      labelText: 'License Expiry Date',
                      hintText: 'Select expiry date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: licenseExpiryDate != DateTime(2000, 1, 1) ? licenseExpiryDate : DateTime.now(),
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
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: regDate != DateTime(2000, 1, 1) ? regDate.toString().split(' ')[0] : '',
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Registration Date',
                        hintText: 'Select registration date',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: regDate != DateTime(2000, 1, 1) ? regDate : DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setState(() => regDate = date);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          readOnly: true,
                          controller: TextEditingController(
                            text: licenseExpiryDate != DateTime(2000, 1, 1) ? licenseExpiryDate.toString().split(' ')[0] : '',
                          ),
                          decoration: const InputDecoration(
                            labelText: 'License Expiry Date',
                            hintText: 'Select expiry date',
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: licenseExpiryDate != DateTime(2000, 1, 1) ? licenseExpiryDate : DateTime.now(),
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
                  ),
                ],
              ),
            ],
            
            // Image upload section
            _buildSectionHeader('Vehicle Image'),
            
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: vehicleImage != null ? _removeImage : _pickAndUploadImage,
                    onLongPress: vehicleImage != null ? _pickAndUploadImage : null,
                    child: Container(
                      width: isMobile ? 160 : 200,
                      height: isMobile ? 160 : 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[700]!),
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
                        child: vehicleImage != null
                            ? Stack(
                                children: [
                                  Image.network(
                                    vehicleImage!,
                                    width: isMobile ? 160 : 200,
                                    height: isMobile ? 160 : 200,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: isMobile ? 160 : 200,
                                      height: isMobile ? 160 : 200,
                                      color: Colors.grey[300],
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.error, size: 32, color: Colors.red[400]),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Image Error',
                                            style: TextStyle(fontSize: 14, color: Colors.red[400]),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Container(
                                width: isMobile ? 160 : 200,
                                height: isMobile ? 160 : 200,
                                color: Colors.grey[300],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate, size: isMobile ? 48 : 64, color: Colors.grey[600]),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to upload',
                                      style: TextStyle(fontSize: isMobile ? 12 : 14, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (vehicleImage == null)
                    SizedBox(
                      width: isMobile ? double.infinity : null,
                      child: ElevatedButton.icon(
                        icon: isLoading ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ) : const Icon(Icons.upload),
                        label: Text(isLoading ? 'Uploading...' : 'Upload Image'),
                        onPressed: isLoading ? null : _pickAndUploadImage,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 48),
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
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            
            // Action buttons with divider
            const SizedBox(height: 32),
            Divider(color: Colors.grey[800], height: 1),
            const SizedBox(height: 24),
            if (isMobile) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 48),
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
                    foregroundColor: Colors.grey[400],
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
                      foregroundColor: Colors.grey[400],
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(160, 48),
                    ),
                    child: Text(isEdit ? 'Update Vehicle' : 'Add Vehicle'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
    
    // Responsive layout based on screen size
    if (isDesktop) {
      // Desktop: Side sheet on the right with better balance
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Row(
          children: [
            // Left side - vehicle metadata and info
            Expanded(
              flex: 2,
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.directions_car,
                          size: 32,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Vehicle Management',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.grey[200],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Edit vehicle details in the panel',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildVehicleMetadata(),
                  ],
                ),
              ),
            ),
            // Vertical divider
            Container(
              width: 1,
              color: Colors.grey[800],
            ),
            // Right side - form panel (wider)
            Expanded(
              flex: 3,
              child: Material(
                elevation: 8,
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: content,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (isTablet) {
      // Tablet: Centered modal with backdrop
      return Scaffold(
        backgroundColor: Colors.black.withOpacity(0.5),
        body: Center(
          child: Material(
            elevation: 16,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 700,
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: content,
              ),
            ),
          ),
        ),
      );
    } else {
      // Mobile: Full screen
      return Scaffold(
        appBar: SimpleAppBar(
          title: isEdit ? 'Edit Vehicle' : 'Add Vehicle',
          subtitle: isEdit ? 'Update vehicle details' : 'Create new vehicle',
          showBackButton: true,
          onBackPressed: () => Navigator.of(context).pop(),
          actions: [
            if (isEdit) ...[
              _buildStatusChip(status),
              const SizedBox(width: 8),
            ],
          ],
        ),
        body: content,
      );
    }
  }
} 