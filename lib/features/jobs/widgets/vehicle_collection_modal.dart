import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/core/services/upload_service.dart';
import 'package:choice_lux_cars/shared/utils/sa_time_utils.dart';

class VehicleCollectionModal extends StatefulWidget {
  final Future<void> Function({
    required double odometerReading,
    required String odometerImageUrl,
    required double gpsLat,
    required double gpsLng,
    required double gpsAccuracy,
    String? vehicleCollectedAtTimestamp,
  })
  onConfirm;

  final VoidCallback onCancel;

  const VehicleCollectionModal({
    Key? key,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<VehicleCollectionModal> createState() => _VehicleCollectionModalState();
}

class _VehicleCollectionModalState extends State<VehicleCollectionModal> {
  final TextEditingController _odometerController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isLoading = false;
  bool _isCapturingLocation = false;
  Position? _currentPosition;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _captureLocation();
  }

  @override
  void dispose() {
    _odometerController.dispose();
    super.dispose();
  }

  Future<void> _captureLocation() async {
    setState(() {
      _isCapturingLocation = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position with retry logic
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _currentPosition = position;
        _isCapturingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationError = e.toString();
        _isCapturingLocation = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80, // Optimize image quality
        maxWidth: 1920, // Reasonable max width
        maxHeight: 1080, // Reasonable max height
      );

      if (image != null) {
        if (kIsWeb) {
          // For web platform, read as bytes
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImage = null;
          });
        } else {
          // For mobile platform, use File
          setState(() {
            _selectedImage = File(image.path);
            _selectedImageBytes = null;
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to capture image: $e');
    }
  }

  Future<void> _retakePhoto() async {
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
    });
    await _pickImage();
  }

  Future<void> _confirmVehicleCollection() async {
    // Validate inputs
    if (_selectedImage == null && _selectedImageBytes == null) {
      _showErrorSnackBar('Please capture an odometer image');
      return;
    }

    if (_odometerController.text.isEmpty) {
      _showErrorSnackBar('Please enter the odometer reading');
      return;
    }

    final odometerReading = double.tryParse(_odometerController.text);
    if (odometerReading == null) {
      _showErrorSnackBar('Please enter a valid odometer reading');
      return;
    }

    if (_currentPosition == null) {
      _showErrorSnackBar('GPS location is required. Please try again.');
      return;
    }

    // Capture timestamp at user action time (when button is clicked)
    // This ensures accurate timestamp regardless of upload/API delay
    final actionTimestamp = SATimeUtils.getCurrentSATimeISO();

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload image to Supabase Storage
      String imageUrl;
      if (kIsWeb && _selectedImageBytes != null) {
        // For web platform, upload bytes
        imageUrl = await UploadService.uploadOdometerImage(
          _selectedImageBytes!,
          'odometer_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      } else if (_selectedImage != null) {
        // For mobile platform, upload file
        imageUrl = await UploadService.uploadImage(
          _selectedImage!,
          'clc_images',
          'odometer',
          'odometer_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      } else {
        throw Exception('No image data available');
      }

      // Call the confirmation callback with captured timestamp
      // Don't close modal here - let the callback handle closing after processing completes
      await widget.onConfirm(
        odometerReading: odometerReading,
        odometerImageUrl: imageUrl,
        gpsLat: _currentPosition!.latitude,
        gpsLng: _currentPosition!.longitude,
        gpsAccuracy: _currentPosition!.accuracy,
        vehicleCollectedAtTimestamp: actionTimestamp, // Pass captured timestamp
      );

      // Modal will be closed by the callback after processing completes
      // Don't close here to avoid race conditions
    } catch (e) {
      _showErrorSnackBar('Failed to upload image: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ChoiceLuxTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Compact dialog for very small screens
  Widget _buildCompactDialog(BuildContext context, double screenHeight, double screenWidth) {
    return Stack(
      children: [
        Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
        width: screenWidth * 0.95,
        height: screenHeight * 0.95,
        decoration: BoxDecoration(
          gradient: ChoiceLuxTheme.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ChoiceLuxTheme.richGold.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Compact Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ChoiceLuxTheme.richGold.withOpacity(0.1),
                    ChoiceLuxTheme.richGold.withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ChoiceLuxTheme.richGold,
                          ChoiceLuxTheme.richGold.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.directions_car_rounded,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vehicle Collection',
                          style: TextStyle(
                            color: ChoiceLuxTheme.softWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Capture odometer reading and location',
                          style: TextStyle(
                            color: ChoiceLuxTheme.platinumSilver,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildImageSection(true), // Force small screen layout
                      const SizedBox(height: 12),
                      _buildOdometerInputSection(),
                      const SizedBox(height: 12),
                      _buildGpsStatusSection(),
                    ],
                  ),
                ),
              ),
            ),
            
            // Compact Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ChoiceLuxTheme.jetBlack.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildLuxuryButton(
                      onPressed: widget.onCancel,
                      label: 'Cancel',
                      isPrimary: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLuxuryButton(
                      onPressed: _isLoading ? null : _confirmVehicleCollection,
                      label: _isLoading ? 'Processing...' : 'Start Job',
                      isPrimary: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
      // Loading overlay when processing
      if (_isLoading)
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.7),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ChoiceLuxTheme.richGold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Processing...',
                    style: TextStyle(
                      color: ChoiceLuxTheme.softWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    
    // Error boundary for very small screens
    if (isVerySmallScreen) {
      return _buildCompactDialog(context, screenHeight, screenWidth);
    }
    
    return Stack(
      children: [
        Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: screenHeight * 0.9, // Responsive height
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
                gradient: ChoiceLuxTheme.cardGradient,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ChoiceLuxTheme.richGold.withOpacity(0.1),
                      ChoiceLuxTheme.richGold.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ChoiceLuxTheme.richGold,
                            ChoiceLuxTheme.richGold.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.directions_car_rounded,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vehicle Collection',
                            style: TextStyle(
                              color: ChoiceLuxTheme.softWhite,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Capture odometer reading and location',
                            style: TextStyle(
                              color: ChoiceLuxTheme.platinumSilver,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                  ),

                  // Content - Make scrollable
                  Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    child: Column(
                      children: [
                        // Odometer Image Section
                        _buildImageSection(isSmallScreen),
                        SizedBox(height: isSmallScreen ? 16 : 20),

                        // Odometer Reading Section
                        _buildOdometerInputSection(),
                        SizedBox(height: isSmallScreen ? 16 : 20),

                        // GPS Status Section
                        _buildGpsStatusSection(),
                      ],
                    ),
                  ),
                ),
                  ),

                  // Action Buttons - Optimized padding
                  Container(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                decoration: BoxDecoration(
                  color: ChoiceLuxTheme.jetBlack.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildLuxuryButton(
                        onPressed: widget.onCancel,
                        label: 'Cancel',
                        isPrimary: false,
                        isCompact: isSmallScreen,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 12 : 16),
                    Expanded(
                      child: _buildLuxuryButton(
                        onPressed: _isLoading
                            ? null
                            : _confirmVehicleCollection,
                        label: _isLoading ? 'Processing...' : 'Start Job',
                        isPrimary: true,
                        isCompact: isSmallScreen,
                      ),
                    ),
                  ],
                ),
              ),
                ],
              ),
            ),
          ),
        ),
        // Loading overlay when processing
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ChoiceLuxTheme.richGold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Processing...',
                      style: TextStyle(
                        color: ChoiceLuxTheme.softWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    ],
    );
  }

  Widget _buildImageSection(bool isSmallScreen) {
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = isSmallScreen 
        ? (screenHeight * 0.25).clamp(120.0, 180.0) // Responsive height
        : 200.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.camera_alt_rounded,
              color: ChoiceLuxTheme.richGold,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Odometer Image',
              style: TextStyle(
                color: ChoiceLuxTheme.softWhite,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: imageHeight,
          decoration: BoxDecoration(
            color: ChoiceLuxTheme.jetBlack.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: (_selectedImage != null || _selectedImageBytes != null)
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: kIsWeb && _selectedImageBytes != null
                          ? Image.memory(
                              _selectedImageBytes!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              _selectedImage!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: ChoiceLuxTheme.richGold,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: Colors.black,
                            size: 20,
                          ),
                          onPressed: _retakePhoto,
                          style: IconButton.styleFrom(
                            padding: const EdgeInsets.all(8),
                            minimumSize: const Size(32, 32),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 48,
                        color: ChoiceLuxTheme.platinumSilver,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tap to capture odometer',
                        style: TextStyle(
                          color: ChoiceLuxTheme.platinumSilver,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: _buildLuxuryButton(
            onPressed: _pickImage,
            label: (_selectedImage != null || _selectedImageBytes != null)
                ? 'Retake Photo'
                : 'Capture Photo',
            isPrimary: false,
          ),
        ),
      ],
    );
  }

  Widget _buildOdometerInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.speed_rounded,
              color: ChoiceLuxTheme.richGold,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Odometer Reading',
              style: TextStyle(
                color: ChoiceLuxTheme.softWhite,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _odometerController,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            color: ChoiceLuxTheme.softWhite,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Enter odometer reading (e.g., 12345.6)',
            hintStyle: TextStyle(
              color: ChoiceLuxTheme.platinumSilver.withOpacity(0.7),
              fontSize: 14,
            ),
            filled: true,
            fillColor: ChoiceLuxTheme.jetBlack.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ChoiceLuxTheme.richGold, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGpsStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.location_on_rounded,
              color: ChoiceLuxTheme.richGold,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'GPS Location',
              style: TextStyle(
                color: ChoiceLuxTheme.softWhite,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ChoiceLuxTheme.jetBlack.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ChoiceLuxTheme.platinumSilver.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              if (_isCapturingLocation)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ChoiceLuxTheme.richGold,
                    ),
                  ),
                )
              else if (_currentPosition != null)
                const Icon(
                  Icons.check_circle_rounded,
                  color: ChoiceLuxTheme.successColor,
                  size: 20,
                )
              else
                const Icon(
                  Icons.error_outline_rounded,
                  color: ChoiceLuxTheme.errorColor,
                  size: 20,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isCapturingLocation
                          ? 'Capturing location...'
                          : _currentPosition != null
                          ? 'Location captured successfully'
                          : 'Location capture failed',
                      style: TextStyle(
                        color: _isCapturingLocation
                            ? ChoiceLuxTheme.platinumSilver
                            : _currentPosition != null
                            ? ChoiceLuxTheme.successColor
                            : ChoiceLuxTheme.errorColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_locationError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _locationError!,
                        style: TextStyle(
                          color: ChoiceLuxTheme.errorColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!_isCapturingLocation && _currentPosition == null)
                TextButton(
                  onPressed: _captureLocation,
                  child: Text(
                    'Retry',
                    style: TextStyle(
                      color: ChoiceLuxTheme.richGold,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLuxuryButton({
    VoidCallback? onPressed,
    required String label,
    required bool isPrimary,
    bool isCompact = false,
  }) {
    if (isPrimary) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ChoiceLuxTheme.richGold,
              ChoiceLuxTheme.richGold.withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: ChoiceLuxTheme.richGold.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.symmetric(
                vertical: isCompact ? 12 : 14,
                horizontal: isCompact ? 8 : 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.black,
                fontSize: isCompact ? 14 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: ChoiceLuxTheme.charcoalGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ChoiceLuxTheme.richGold.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.symmetric(
              vertical: isCompact ? 12 : 14,
              horizontal: isCompact ? 8 : 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: ChoiceLuxTheme.richGold,
              fontSize: isCompact ? 14 : 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
  }
}
