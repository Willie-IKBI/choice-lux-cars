import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/core/services/upload_service.dart';
import 'package:choice_lux_cars/shared/mixins/gps_capture_mixin.dart';

class PickupArrivalModal extends StatefulWidget {
  final Future<void> Function({
    required double gpsLat,
    required double gpsLng,
    required double gpsAccuracy,
    required String arrivalImageUrl,
  }) onConfirm;

  final VoidCallback onCancel;

  const PickupArrivalModal({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<PickupArrivalModal> createState() => _PickupArrivalModalState();
}

class _PickupArrivalModalState extends State<PickupArrivalModal> with GpsCaptureMixin {
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    captureLocation();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          if (!kIsWeb) {
            _selectedImage = File(image.path);
          }
        });
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

  Future<void> _confirmArrival() async {
    if (_selectedImageBytes == null) {
      _showErrorSnackBar('Please capture a photo of the pickup location');
      return;
    }

    if (currentPosition == null) {
      _showErrorSnackBar('GPS location is required. Please try again.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final imageUrl = await UploadService.uploadArrivalImage(
        _selectedImageBytes!,
        'pickup_arrival_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await widget.onConfirm(
        gpsLat: currentPosition!.latitude,
        gpsLng: currentPosition!.longitude,
        gpsAccuracy: currentPosition!.accuracy,
        arrivalImageUrl: imageUrl,
      );
    } catch (e) {
      _showErrorSnackBar('Failed to upload image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                color: ChoiceLuxTheme.richGold.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ChoiceLuxTheme.richGold.withValues(alpha: 0.1),
                        ChoiceLuxTheme.richGold.withValues(alpha: 0.05),
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
                              ChoiceLuxTheme.richGold.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
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
                              'Arrive at Pickup',
                              style: TextStyle(
                                color: ChoiceLuxTheme.softWhite,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Capture location photo to confirm arrival',
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
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildImageSection(true),
                          const SizedBox(height: 12),
                          _buildGpsStatusSection(),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ChoiceLuxTheme.jetBlack.withValues(alpha: 0.3),
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
                          onPressed: _isLoading ? null : _confirmArrival,
                          label: _isLoading ? 'Uploading...' : 'Confirm Arrival',
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
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.85),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ChoiceLuxTheme.richGold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Uploading photo...',
                      style: TextStyle(
                        color: ChoiceLuxTheme.softWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please wait',
                      style: TextStyle(
                        color: ChoiceLuxTheme.platinumSilver,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
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
              maxHeight: screenHeight * 0.9,
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
                gradient: ChoiceLuxTheme.cardGradient,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: ChoiceLuxTheme.richGold.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ChoiceLuxTheme.richGold.withValues(alpha: 0.1),
                          ChoiceLuxTheme.richGold.withValues(alpha: 0.05),
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
                                ChoiceLuxTheme.richGold.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
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
                                'Arrive at Pickup',
                                style: TextStyle(
                                  color: ChoiceLuxTheme.softWhite,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Capture location photo to confirm arrival',
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
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                        child: Column(
                          children: [
                            _buildImageSection(isSmallScreen),
                            SizedBox(height: isSmallScreen ? 16 : 20),
                            _buildGpsStatusSection(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    decoration: BoxDecoration(
                      color: ChoiceLuxTheme.jetBlack.withValues(alpha: 0.3),
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
                            onPressed: _isLoading ? null : _confirmArrival,
                            label: _isLoading ? 'Uploading...' : 'Confirm Arrival',
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
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.85),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ChoiceLuxTheme.richGold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Uploading photo...',
                      style: TextStyle(
                        color: ChoiceLuxTheme.softWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please wait',
                      style: TextStyle(
                        color: ChoiceLuxTheme.platinumSilver,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
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
        ? (screenHeight * 0.3).clamp(150.0, 220.0)
        : 240.0;

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
              'Location Photo',
              style: TextStyle(
                color: ChoiceLuxTheme.softWhite,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: ChoiceLuxTheme.errorColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Required',
                style: TextStyle(
                  color: ChoiceLuxTheme.errorColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Take a photo of the pickup location to verify your arrival',
          style: TextStyle(
            color: ChoiceLuxTheme.platinumSilver,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: imageHeight,
          decoration: BoxDecoration(
            color: ChoiceLuxTheme.jetBlack.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedImageBytes != null
                  ? ChoiceLuxTheme.successColor.withValues(alpha: 0.5)
                  : ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.2),
              width: _selectedImageBytes != null ? 2 : 1,
            ),
          ),
          child: _selectedImageBytes != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _selectedImageBytes!,
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
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: ChoiceLuxTheme.successColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Photo captured',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ChoiceLuxTheme.richGold.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: ChoiceLuxTheme.richGold.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt_outlined,
                            size: 40,
                            color: ChoiceLuxTheme.richGold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tap to capture photo',
                          style: TextStyle(
                            color: ChoiceLuxTheme.softWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Photo of the pickup location is required',
                          style: TextStyle(
                            color: ChoiceLuxTheme.platinumSilver,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        if (_selectedImageBytes == null) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: _buildLuxuryButton(
              onPressed: _pickImage,
              label: 'Open Camera',
              isPrimary: false,
            ),
          ),
        ],
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
            color: ChoiceLuxTheme.jetBlack.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: currentPosition != null
                  ? ChoiceLuxTheme.successColor.withValues(alpha: 0.3)
                  : ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              if (isCapturingLocation)
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
              else if (currentPosition != null)
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
                      isCapturingLocation
                          ? 'Capturing location...'
                          : currentPosition != null
                              ? 'Location captured successfully'
                              : 'Location capture failed',
                      style: TextStyle(
                        color: isCapturingLocation
                            ? ChoiceLuxTheme.platinumSilver
                            : currentPosition != null
                                ? ChoiceLuxTheme.successColor
                                : ChoiceLuxTheme.errorColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (currentPosition != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Accuracy: ${currentPosition!.accuracy.toStringAsFixed(0)}m',
                        style: TextStyle(
                          color: ChoiceLuxTheme.platinumSilver,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                    if (locationError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        locationError!,
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
              if (!isCapturingLocation && currentPosition == null)
                TextButton(
                  onPressed: captureLocation,
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
              ChoiceLuxTheme.richGold.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: ChoiceLuxTheme.richGold.withValues(alpha: 0.3),
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
            color: ChoiceLuxTheme.richGold.withValues(alpha: 0.3),
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
