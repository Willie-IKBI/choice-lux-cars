import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class OdometerCaptureWidget extends StatefulWidget {
  final Function(double reading, String imagePath) onOdometerCaptured;
  final String? title;
  final String? description;
  final double? initialReading;

  const OdometerCaptureWidget({
    Key? key,
    required this.onOdometerCaptured,
    this.title,
    this.description,
    this.initialReading,
  }) : super(key: key);

  @override
  State<OdometerCaptureWidget> createState() => _OdometerCaptureWidgetState();
}

class _OdometerCaptureWidgetState extends State<OdometerCaptureWidget> {
  final TextEditingController _readingController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _capturedImage;
  bool _isCapturing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialReading != null) {
      _readingController.text = widget.initialReading!.toString();
    }
  }

  @override
  void dispose() {
    _readingController.dispose();
    super.dispose();
  }

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
                Icon(Icons.speed, color: Colors.orange[700], size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title ?? 'Odometer Reading',
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

            // Odometer reading input
            TextField(
              controller: _readingController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Odometer Reading (km)',
                hintText: 'Enter current odometer reading',
                prefixIcon: const Icon(Icons.speed),
                border: const OutlineInputBorder(),
                suffixText: 'km',
              ),
            ),

            const SizedBox(height: 16),

            // Image capture section
            if (_capturedImage != null) ...[
              _buildImagePreview(),
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

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isCapturing ? null : _captureImage,
                    icon: _isCapturing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt),
                    label: Text(
                      _isCapturing ? 'Capturing...' : 'Capture Image',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _canSubmit() ? _submitOdometer : null,
                    icon: const Icon(Icons.check),
                    label: const Text('Submit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
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
                'Image Captured',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: _removeImage,
                tooltip: 'Remove image',
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              _capturedImage!,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  bool _canSubmit() {
    final reading = double.tryParse(_readingController.text);
    return reading != null && reading > 0 && _capturedImage != null;
  }

  Future<void> _captureImage() async {
    setState(() {
      _isCapturing = true;
      _errorMessage = null;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        setState(() {
          _capturedImage = File(image.path);
          _isCapturing = false;
        });
      } else {
        setState(() {
          _isCapturing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to capture image: $e';
        _isCapturing = false;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _capturedImage = null;
    });
  }

  void _submitOdometer() {
    if (!_canSubmit()) return;

    final reading = double.parse(_readingController.text);
    final imagePath = _capturedImage!.path;

    widget.onOdometerCaptured(reading, imagePath);
  }
}

class OdometerDisplayWidget extends StatelessWidget {
  final double reading;
  final String? imagePath;
  final String? title;

  const OdometerDisplayWidget({
    Key? key,
    required this.reading,
    this.imagePath,
    this.title,
  }) : super(key: key);

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
                Icon(Icons.speed, color: Colors.orange[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  '${reading.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            if (imagePath != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(imagePath!),
                  height: 80,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
