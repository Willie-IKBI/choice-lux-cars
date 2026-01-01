import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class GpsCaptureWidget extends StatefulWidget {
  final Function(Position) onLocationCaptured;
  final String? title;
  final String? description;

  const GpsCaptureWidget({
    super.key,
    required this.onLocationCaptured,
    this.title,
    this.description,
  });

  @override
  State<GpsCaptureWidget> createState() => _GpsCaptureWidgetState();
}

class _GpsCaptureWidgetState extends State<GpsCaptureWidget> {
  bool _isCapturing = false;
  Position? _currentPosition;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue[700], size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title ?? 'GPS Location',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (widget.description != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.description!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 16),
            if (_currentPosition != null) ...[
              _buildLocationInfo(),
              const SizedBox(height: 16),
            ],
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCapturing ? null : _captureLocation,
                icon: _isCapturing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(_isCapturing ? 'Capturing...' : 'Capture Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Location Captured',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            'Latitude',
            _currentPosition!.latitude.toStringAsFixed(6),
          ),
          _buildInfoRow(
            'Longitude',
            _currentPosition!.longitude.toStringAsFixed(6),
          ),
          _buildInfoRow(
            'Accuracy',
            '${_currentPosition!.accuracy.toStringAsFixed(1)}m',
          ),
          _buildInfoRow(
            'Timestamp',
            _formatTimestamp(_currentPosition!.timestamp),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'N/A';
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }

  Future<void> _captureLocation() async {
    setState(() {
      _isCapturing = true;
      _errorMessage = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable GPS.');
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permissions are permanently denied. Please enable in settings.',
        );
      }

      // Get current position with high accuracy
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _currentPosition = position;
        _isCapturing = false;
      });

      // Call the callback with the captured location
      widget.onLocationCaptured(position);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isCapturing = false;
      });
    }
  }
}

class LocationDisplayWidget extends StatelessWidget {
  final Position position;
  final String? title;

  const LocationDisplayWidget({super.key, required this.position, this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.gps_fixed, color: Colors.green[600], size: 16),
                const SizedBox(width: 8),
                Text(
                  'Accuracy: ${position.accuracy.toStringAsFixed(1)}m',
                  style: TextStyle(color: Colors.green[700], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
