import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class UploadService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Upload an image file to Supabase Storage
  /// 
  /// [file] - The image file to upload
  /// [bucket] - The storage bucket name (e.g., 'clc_images')
  /// [folder] - The folder path within the bucket (e.g., 'odometer')
  /// [fileName] - The filename to use in storage
  /// 
  /// Returns the public URL of the uploaded image
  static Future<String> uploadImage(File file, String bucket, String folder, String fileName) async {
    try {
      // Create the full path including folder
      final fullPath = '$folder/$fileName';
      
      // Upload to Supabase Storage
      await _supabase.storage
          .from(bucket)
          .upload(
            fullPath,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Get the public URL
      final publicUrl = _supabase.storage
          .from(bucket)
          .getPublicUrl(fullPath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload image bytes to Supabase Storage
  /// 
  /// [bytes] - The image bytes to upload
  /// [bucket] - The storage bucket name (e.g., 'clc_images')
  /// [folder] - The folder path within the bucket (e.g., 'odometer')
  /// [fileName] - The filename to use in storage
  /// 
  /// Returns the public URL of the uploaded image
  static Future<String> uploadImageBytes(Uint8List bytes, String bucket, String folder, String fileName) async {
    try {
      // Create the full path including folder
      final fullPath = '$folder/$fileName';
      
      // Upload to Supabase Storage
      await _supabase.storage
          .from(bucket)
          .uploadBinary(
            fullPath,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Get the public URL
      final publicUrl = _supabase.storage
          .from(bucket)
          .getPublicUrl(fullPath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload image bytes: $e');
    }
  }

  /// Upload odometer image (convenience method)
  /// 
  /// [bytes] - The image bytes to upload
  /// [fileName] - The filename to use in storage
  /// 
  /// Returns the public URL of the uploaded image
  static Future<String> uploadOdometerImage(Uint8List bytes, String fileName) async {
    return uploadImageBytes(bytes, 'clc_images', 'odometer', fileName);
  }

  /// Upload vehicle image (convenience method)
  /// 
  /// [bytes] - The image bytes to upload
  /// [fileName] - The filename to use in storage
  /// 
  /// Returns the public URL of the uploaded image
  static Future<String> uploadVehicleImage(Uint8List bytes, String fileName) async {
    return uploadImageBytes(bytes, 'clc_images', 'vehicles', fileName);
  }

  /// Upload profile image (convenience method)
  /// 
  /// [bytes] - The image bytes to upload
  /// [fileName] - The filename to use in storage
  /// 
  /// Returns the public URL of the uploaded image
  static Future<String> uploadProfileImage(Uint8List bytes, String fileName) async {
    return uploadImageBytes(bytes, 'clc_images', 'profile_images', fileName);
  }

  /// Delete an image from Supabase Storage
  /// 
  /// [bucket] - The storage bucket name
  /// [folder] - The folder path within the bucket
  /// [fileName] - The filename to delete
  static Future<void> deleteImage(String bucket, String folder, String fileName) async {
    try {
      final fullPath = '$folder/$fileName';
      await _supabase.storage
          .from(bucket)
          .remove([fullPath]);
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  /// Get a list of files in a bucket folder
  /// 
  /// [bucket] - The storage bucket name
  /// [folder] - The folder path within the bucket
  static Future<List<FileObject>> listFiles(String bucket, String folder) async {
    try {
      final response = await _supabase.storage
          .from(bucket)
          .list(path: folder);

      return response;
    } catch (e) {
      throw Exception('Failed to list files: $e');
    }
  }

  /// Generate a unique filename with timestamp
  /// 
  /// [prefix] - Optional prefix for the filename
  /// [extension] - File extension (e.g., '.jpg')
  /// 
  /// Returns a unique filename
  static String generateUniqueFileName({String? prefix, String extension = '.jpg'}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    final prefixPart = prefix != null ? '${prefix}_' : '';
    return '${prefixPart}${timestamp}_$random$extension';
  }

  /// Extract filename from a public URL
  /// 
  /// [url] - The public URL of the file
  /// 
  /// Returns the filename
  static String extractFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      return pathSegments.last;
    } catch (e) {
      throw Exception('Failed to extract filename from URL: $e');
    }
  }

  // ========================================
  // LEGACY METHODS FOR BACKWARD COMPATIBILITY
  // ========================================

  /// Pick an image from gallery or camera (legacy method)
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

  /// Upload company logo (legacy method)
  static Future<String> uploadCompanyLogo({
    required File logoFile,
    String? companyName,
  }) async {
    try {
      final String fileName = companyName != null 
          ? '${companyName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.jpg'
          : 'logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      return await uploadImage(
        logoFile,
        'clc_images',
        'logos',
        fileName,
      );
    } catch (e) {
      throw Exception('Failed to upload company logo: $e');
    }
  }

  /// Upload vehicle image with ID (legacy method)
  static Future<String> uploadVehicleImageWithId(Uint8List bytes, int? vehicleId) async {
    try {
      final fileName = 'vehicle.jpg';
      final path = vehicleId != null 
          ? '$vehicleId/$fileName'
          : 'temp/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
      return await uploadImageBytes(
        bytes,
        'clc_images',
        'vehicles',
        path,
      );
    } catch (e) {
      throw Exception('Failed to upload vehicle image: $e');
    }
  }

  /// Validate file size (legacy method)
  static bool isValidFileSize(File file, {double maxSizeMB = 5.0}) {
    final double fileSizeMB = file.lengthSync() / (1024 * 1024);
    return fileSizeMB <= maxSizeMB;
  }

  /// Ensure bucket exists (legacy method)
  static Future<void> ensureBucketExists() async {
    try {
      // Try to list files in bucket to check if it exists
      await _supabase.storage
          .from('clc_images')
          .list();
    } catch (e) {
      // Bucket doesn't exist, create it
      await _supabase.storage.createBucket('clc_images');
    }
  }
} 