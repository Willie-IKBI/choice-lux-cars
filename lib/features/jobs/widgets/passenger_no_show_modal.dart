import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:choice_lux_cars/app/theme.dart';

class PassengerNoShowModal extends StatefulWidget {
  final Function({
    required String comment,
    required double gpsLat,
    required double gpsLng,
    required double gpsAccuracy,
  })
  onConfirm;
  final VoidCallback onCancel;

  const PassengerNoShowModal({
    Key? key,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<PassengerNoShowModal> createState() => _PassengerNoShowModalState();
}

class _PassengerNoShowModalState extends State<PassengerNoShowModal> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
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
    _commentController.dispose();
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

  Future<void> _confirmNoShow() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_currentPosition == null) {
      _showErrorSnackBar('GPS location is required. Please try again.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Call the confirmation callback
      widget.onConfirm(
        comment: _commentController.text.trim(),
        gpsLat: _currentPosition!.latitude,
        gpsLng: _currentPosition!.longitude,
        gpsAccuracy: _currentPosition!.accuracy,
      );

      Navigator.of(context).pop();
    } catch (e) {
      _showErrorSnackBar('Failed to mark passenger as no-show: $e');
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
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
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ChoiceLuxTheme.errorColor.withOpacity(0.2),
                        ChoiceLuxTheme.errorColor.withOpacity(0.1),
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
                          color: ChoiceLuxTheme.errorColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_off_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Passenger No-Show',
                              style: TextStyle(
                                color: ChoiceLuxTheme.softWhite,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Mark passenger as no-show',
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

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Warning Message
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ChoiceLuxTheme.errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ChoiceLuxTheme.errorColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: ChoiceLuxTheme.errorColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Mark passenger as no-show? You'll still need to return the vehicle to close the job.",
                                style: TextStyle(
                                  color: ChoiceLuxTheme.platinumSilver,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Comment Field
                      TextFormField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          labelText: 'Comment *',
                          hintText: 'Explain why the passenger did not show up...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: ChoiceLuxTheme.platinumSilver.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: ChoiceLuxTheme.richGold,
                              width: 2,
                            ),
                          ),
                          labelStyle: TextStyle(
                            color: ChoiceLuxTheme.platinumSilver,
                          ),
                          hintStyle: TextStyle(
                            color: ChoiceLuxTheme.platinumSilver.withOpacity(0.5),
                          ),
                          filled: true,
                          fillColor: ChoiceLuxTheme.jetBlack.withOpacity(0.3),
                        ),
                        style: const TextStyle(
                          color: ChoiceLuxTheme.softWhite,
                        ),
                        maxLines: 4,
                        maxLength: 500,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Comment is required';
                          }
                          if (value.trim().length < 10) {
                            return 'Please provide a more detailed comment (at least 10 characters)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // GPS Status Section
                      _buildGpsStatusSection(),
                    ],
                  ),
                ),

                // Action Buttons
                Container(
                  padding: const EdgeInsets.all(24),
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
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildLuxuryButton(
                          onPressed: _isLoading ? null : _confirmNoShow,
                          label: _isLoading ? 'Marking...' : 'Mark as No-Show',
                          isPrimary: true,
                          isWarning: true,
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
    required VoidCallback? onPressed,
    required String label,
    required bool isPrimary,
    bool isWarning = false,
  }) {
    if (isPrimary) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isWarning
                ? [
                    ChoiceLuxTheme.errorColor,
                    ChoiceLuxTheme.errorColor.withOpacity(0.9),
                  ]
                : [
                    ChoiceLuxTheme.richGold,
                    ChoiceLuxTheme.richGold.withOpacity(0.9),
                  ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (isWarning ? ChoiceLuxTheme.errorColor : ChoiceLuxTheme.richGold)
                  .withOpacity(0.3),
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
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isWarning ? Colors.white : Colors.black,
              fontSize: 16,
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
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: ChoiceLuxTheme.richGold,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
  }
}
