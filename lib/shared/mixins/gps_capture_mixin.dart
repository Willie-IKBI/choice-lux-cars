import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// Mixin that provides GPS location capture with permission handling.
/// Use with `State<T>` classes that need to capture the user's current location.
mixin GpsCaptureMixin<T extends StatefulWidget> on State<T> {
  bool isCapturingLocation = false;
  Position? currentPosition;
  String? locationError;

  Future<void> captureLocation() async {
    setState(() {
      isCapturingLocation = true;
      locationError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
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
        throw Exception(
          'Location permissions are permanently denied. Please enable them in settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        currentPosition = position;
        isCapturingLocation = false;
      });
    } catch (e) {
      setState(() {
        locationError = e.toString();
        isCapturingLocation = false;
      });
    }
  }
}
