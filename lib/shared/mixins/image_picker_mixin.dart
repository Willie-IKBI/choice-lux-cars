import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:choice_lux_cars/core/services/upload_service.dart';

/// Image picker mixin to eliminate duplicate image picker functions
mixin ImagePickerMixin<T extends StatefulWidget> on State<T> {
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isUploading = false;
  String? _uploadError;

  File? get selectedImage => _selectedImage;
  Uint8List? get selectedImageBytes => _selectedImageBytes;
  bool get isUploading => _isUploading;
  String? get uploadError => _uploadError;

  /// Pick image from camera
  Future<void> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80, // Optimize image quality
        maxWidth: 1920, // Reasonable max width
        maxHeight: 1080, // Reasonable max height
      );

      if (image != null) {
        if (kIsWeb) {
          // Handle web platform
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImage = null;
            _uploadError = null;
          });
        } else {
          // Handle mobile platform
          setState(() {
            _selectedImage = File(image.path);
            _selectedImageBytes = null;
            _uploadError = null;
          });
        }
      }
    } catch (e) {
      setState(() {
        _uploadError = 'Failed to capture image: $e';
      });
    }
  }

  /// Pick image from gallery
  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImage = null;
            _uploadError = null;
          });
        } else {
          setState(() {
            _selectedImage = File(image.path);
            _selectedImageBytes = null;
            _uploadError = null;
          });
        }
      }
    } catch (e) {
      setState(() {
        _uploadError = 'Failed to pick image: $e';
      });
    }
  }

  /// Upload image to storage
  Future<String?> uploadImage({
    required String bucket,
    required String folder,
    required String fileName,
  }) async {
    if (_selectedImage == null && _selectedImageBytes == null) {
      setState(() {
        _uploadError = 'No image selected';
      });
      return null;
    }

    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    try {
      String imageUrl;

      if (kIsWeb && _selectedImageBytes != null) {
        // Upload bytes for web
        imageUrl = await UploadService.uploadImageBytes(
          _selectedImageBytes!,
          bucket,
          folder,
          fileName,
        );
      } else if (_selectedImage != null) {
        // Upload file for mobile
        imageUrl = await UploadService.uploadImage(
          _selectedImage!,
          bucket,
          folder,
          fileName,
        );
      } else {
        throw Exception('No valid image data');
      }

      setState(() {
        _isUploading = false;
      });

      return imageUrl;
    } catch (e) {
      setState(() {
        _uploadError = 'Failed to upload image: $e';
        _isUploading = false;
      });
      return null;
    }
  }

  /// Clear selected image
  void clearSelectedImage() {
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
      _uploadError = null;
    });
  }

  /// Reset upload state
  void resetUploadState() {
    setState(() {
      _isUploading = false;
      _uploadError = null;
    });
  }

  /// Check if image is selected
  bool get hasSelectedImage =>
      _selectedImage != null || _selectedImageBytes != null;

  /// Get image widget for display
  Widget get imageWidget {
    if (_selectedImage != null) {
      return Image.file(
        _selectedImage!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (_selectedImageBytes != null) {
      return Image.memory(
        _selectedImageBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.camera_alt, size: 48, color: Colors.grey),
        ),
      );
    }
  }
}
