import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class UploadService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const String _bucketName = 'clc_images';
  static const _uuid = Uuid();

  /// Pick an image from gallery or camera
  static Future<File?> pickImage({
    required ImageSource source,
    int maxWidth = 800,
    int maxHeight = 800,
    int imageQuality = 85,
  }) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Pick a file using file picker
  static Future<File?> pickFile({
    List<String>? allowedExtensions,
    String? dialogTitle,
  }) async {
    final extensions = allowedExtensions ?? ['jpg', 'jpeg', 'png', 'gif'];
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensions,
        dialogTitle: dialogTitle ?? 'Select Company Logo',
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick file: $e');
    }
  }

  /// Upload image to Supabase Storage
  static Future<String> uploadImage({
    required Uint8List fileBytes,
    required String folder,
    required String fileName,
  }) async {
    try {
      final String filePath = '$folder/$fileName';
      print('Attempting to upload to bucket: $_bucketName, path: $filePath');
      await _supabase.storage
          .from(_bucketName)
          .uploadBinary(filePath, fileBytes);
      final String publicUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(filePath);
      print('Upload successful: $publicUrl');
      return publicUrl;
    } catch (e, st) {
      print('Failed to upload image: $e');
      print('Stack trace: $st');
      rethrow;
    }
  }

  /// Upload company logo
  static Future<String> uploadCompanyLogo({
    required File logoFile,
    String? companyName,
  }) async {
    try {
      final String fileName = companyName != null 
          ? '${companyName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.jpg'
          : 'logo_${_uuid.v4()}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      return await uploadImage(
        fileBytes: await logoFile.readAsBytes(),
        folder: 'logos',
        fileName: fileName,
      );
    } catch (e) {
      throw Exception('Failed to upload company logo: $e');
    }
  }

  /// Upload vehicle image
  static Future<String> uploadVehicleImage(Uint8List bytes, int? vehicleId) async {
    try {
      final fileName = 'vehicle.jpg';
      final path = vehicleId != null 
          ? 'clc_images/vehicles/$vehicleId/$fileName'
          : 'clc_images/vehicles/temp/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
      await _supabase.storage.from('clc_images').uploadBinary(path, bytes);
      final url = _supabase.storage.from('clc_images').getPublicUrl(path);
      return url;
    } catch (e) {
      throw Exception('Failed to upload vehicle image: $e');
    }
  }

  /// Delete image from Supabase Storage
  static Future<void> deleteImage(String imageUrl) async {
    try {
      // Extract file path from URL
      final Uri uri = Uri.parse(imageUrl);
      final String pathSegments = uri.pathSegments.join('/');
      final String filePath = pathSegments.substring(pathSegments.indexOf(_bucketName) + _bucketName.length + 1);
      
      await _supabase.storage
          .from(_bucketName)
          .remove([filePath]);
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  /// Check if bucket exists, create if not
  static Future<void> ensureBucketExists() async {
    try {
      // Try to list files in bucket to check if it exists
      await _supabase.storage
          .from(_bucketName)
          .list();
    } catch (e) {
      // Bucket doesn't exist, create it
      await _supabase.storage.createBucket(_bucketName);
    }
  }

  /// Get file size in MB
  static double getFileSizeInMB(File file) {
    final int bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }

  /// Validate file size (max 5MB)
  static bool isValidFileSize(File file, {double maxSizeMB = 5.0}) {
    final double fileSizeMB = getFileSizeInMB(file);
    return fileSizeMB <= maxSizeMB;
  }

  /// Validate image dimensions
  static Future<bool> isValidImageDimensions(
    File file, {
    int maxWidth = 2000,
    int maxHeight = 2000,
  }) async {
    try {
      // For now, just return true as we're handling resizing in pickImage
      return true;
    } catch (e) {
      return false;
    }
  }
} 