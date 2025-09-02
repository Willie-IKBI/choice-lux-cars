import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// GPS capture mixin to eliminate duplicate GPS capture functions
mixin GpsCaptureMixin<T extends StatefulWidget> on State<T> {
  bool _isCapturingLocation = false;
  Position? _currentPosition;
  String? _locationError;

  bool get isCapturingLocation => _isCapturingLocation;
  Position? get currentPosition => _currentPosition;
  String? get locationError => _locationError;

  /// Capture current location with error handling
  Future<void> captureLocation() async {
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

  /// Get safe GPS accuracy value (prevents overflow)
  double? getSafeGpsAccuracy(double? gpsAccuracy) {
    if (gpsAccuracy == null) return null;

    if (gpsAccuracy > 999.99) {
      return 999.99; // Max value for precision 5, scale 2
    } else {
      return double.parse(gpsAccuracy.toStringAsFixed(2));
    }
  }

  /// Check if GPS is available
  bool get isGpsAvailable => _currentPosition != null && _locationError == null;

  /// Get formatted GPS coordinates
  String get formattedGpsCoordinates {
    if (_currentPosition == null) return 'Not available';
    return '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}';
  }

  /// Get GPS accuracy text
  String get gpsAccuracyText {
    if (_currentPosition == null) return 'Not available';
    return '±${_currentPosition!.accuracy.toStringAsFixed(1)}m';
  }

  /// Reset GPS state
  void resetGpsState() {
    setState(() {
      _currentPosition = null;
      _locationError = null;
      _isCapturingLocation = false;
    });
  }
}
