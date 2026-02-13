import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/jobs/services/driver_flow_api_service.dart';

/// Map widget showing all GPS stops for a job from trip_progress.
/// Displays pickup and dropoff coordinates captured when the driver arrived at each location.
class JobStopsMapWidget extends StatefulWidget {
  final String jobId;

  const JobStopsMapWidget({super.key, required this.jobId});

  @override
  State<JobStopsMapWidget> createState() => _JobStopsMapWidgetState();
}

class _JobStopsMapWidgetState extends State<JobStopsMapWidget> {
  Completer<GoogleMapController> _mapController = Completer();
  Set<Marker> _markers = {};
  LatLng? _initialPosition;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStops();
  }

  Future<void> _loadStops() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final jobIdInt = int.tryParse(widget.jobId) ?? 0;
      if (jobIdInt == 0) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Invalid job ID';
        });
        return;
      }

      final tripProgress = await DriverFlowApiService.getTripProgress(jobIdInt);

      final stops = <_MapStop>[];
      for (var i = 0; i < tripProgress.length; i++) {
        final trip = tripProgress[i];
        final tripIndex = trip['trip_index'] as int? ?? i;

        final pickupLat = _parseDouble(trip['pickup_gps_lat']);
        final pickupLng = _parseDouble(trip['pickup_gps_lng']);
        final dropoffLat = _parseDouble(trip['dropoff_gps_lat']);
        final dropoffLng = _parseDouble(trip['dropoff_gps_lng']);

        if (pickupLat != null && pickupLng != null) {
          stops.add(_MapStop(
            tripIndex: tripIndex,
            type: 'pickup',
            label: 'Trip ${tripIndex + 1} Pickup',
            position: LatLng(pickupLat, pickupLng),
          ));
        }
        if (dropoffLat != null && dropoffLng != null) {
          stops.add(_MapStop(
            tripIndex: tripIndex,
            type: 'dropoff',
            label: 'Trip ${tripIndex + 1} Dropoff',
            position: LatLng(dropoffLat, dropoffLng),
          ));
        }
      }

      if (stops.isEmpty) {
        setState(() {
          _isLoading = false;
          _markers = {};
          _initialPosition = null;
        });
        return;
      }

      final markers = <Marker>{};
      for (var i = 0; i < stops.length; i++) {
        final stop = stops[i];
        markers.add(
          Marker(
            markerId: MarkerId('stop_$i'),
            position: stop.position,
            infoWindow: InfoWindow(title: stop.label),
            icon: stop.type == 'pickup'
                ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
                : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          ),
        );
      }

      LatLng initial;
      if (stops.length == 1) {
        initial = stops.first.position;
      } else {
        double minLat = stops.first.position.latitude;
        double maxLat = stops.first.position.latitude;
        double minLng = stops.first.position.longitude;
        double maxLng = stops.first.position.longitude;
        for (final stop in stops) {
          if (stop.position.latitude < minLat) minLat = stop.position.latitude;
          if (stop.position.latitude > maxLat) maxLat = stop.position.latitude;
          if (stop.position.longitude < minLng) minLng = stop.position.longitude;
          if (stop.position.longitude > maxLng) maxLng = stop.position.longitude;
        }
        initial = LatLng(
          (minLat + maxLat) / 2,
          (minLng + maxLng) / 2,
        );
      }

      if (mounted) {
        setState(() {
          _markers = markers;
          _initialPosition = initial;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: ChoiceLuxTheme.charcoalGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ChoiceLuxTheme.richGold),
          ),
        ),
      );
    }

    if (_hasError) {
      return Container(
        height: 250,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ChoiceLuxTheme.charcoalGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: ChoiceLuxTheme.errorColor, size: 40),
              const SizedBox(height: 12),
              Text(
                'Error loading map',
                style: TextStyle(color: ChoiceLuxTheme.softWhite, fontWeight: FontWeight.bold),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 4),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: ChoiceLuxTheme.softWhite.withOpacity(0.7), fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (_initialPosition == null || _markers.isEmpty) {
      return Container(
        height: 250,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ChoiceLuxTheme.charcoalGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, color: ChoiceLuxTheme.softWhite.withOpacity(0.5), size: 48),
              const SizedBox(height: 12),
              Text(
                'No GPS coordinates recorded for this job',
                style: TextStyle(
                  color: ChoiceLuxTheme.softWhite.withOpacity(0.8),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Coordinates are captured when the driver arrives at pickup and dropoff locations.',
                style: TextStyle(
                  color: ChoiceLuxTheme.softWhite.withOpacity(0.6),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _initialPosition!,
            zoom: _markers.length == 1 ? 14 : 12,
          ),
          markers: _markers,
          mapType: MapType.normal,
          onMapCreated: (controller) {
            if (!_mapController.isCompleted) {
              _mapController.complete(controller);
            }
          },
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
        ),
      ),
    );
  }
}

class _MapStop {
  final int tripIndex;
  final String type;
  final String label;
  final LatLng position;

  _MapStop({
    required this.tripIndex,
    required this.type,
    required this.label,
    required this.position,
  });
}
