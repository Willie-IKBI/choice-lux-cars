import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class UploadService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Upload an image file to Supabase Storage
  /// 
  /// [file] - The image file to upload
  /// [bucket] - The storage bucket name (e.g., 'odometer-readings')
  /// [fileName] - The filename to use in storage
  /// 
  /// Returns the public URL of the uploaded image
  static Future<String> uploadImage(File file, String bucket, String fileName) async {
    try {
      // Upload to Supabase Storage
      await _supabase.storage
          .from(bucket)
          .upload(
            fileName,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Get the public URL
      final publicUrl = _supabase.storage
          .from(bucket)
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload image bytes to Supabase Storage
  /// 
  /// [bytes] - The image bytes to upload
  /// [bucket] - The storage bucket name
  /// [fileName] - The filename to use in storage
  /// 
  /// Returns the public URL of the uploaded image
  static Future<String> uploadImageBytes(Uint8List bytes, String bucket, String fileName) async {
    try {
      // Upload to Supabase Storage
      await _supabase.storage
          .from(bucket)
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Get the public URL
      final publicUrl = _supabase.storage
          .from(bucket)
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload image bytes: $e');
    }
  }

  /// Delete an image from Supabase Storage
  /// 
  /// [bucket] - The storage bucket name
  /// [fileName] - The filename to delete
  static Future<void> deleteImage(String bucket, String fileName) async {
    try {
      await _supabase.storage
          .from(bucket)
          .remove([fileName]);
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  /// Get a list of files in a bucket
  /// 
  /// [bucket] - The storage bucket name
  /// [folder] - Optional folder path within the bucket
  static Future<List<FileObject>> listFiles(String bucket, {String? folder}) async {
    try {
      final response = await _supabase.storage
          .from(bucket)
          .list(path: folder ?? '');

      return response;
    } catch (e) {
      throw Exception('Failed to list files: $e');
    }
  }

  /// Download an image from Supabase Storage
  /// 
  /// [bucket] - The storage bucket name
  /// [fileName] - The filename to download
  /// 
  /// Returns the image bytes
  static Future<Uint8List> downloadImage(String bucket, String fileName) async {
    try {
      final response = await _supabase.storage
          .from(bucket)
          .download(fileName);

      return response;
    } catch (e) {
      throw Exception('Failed to download image: $e');
    }
  }

  /// Generate a unique filename with timestamp
  /// 
  /// [prefix] - Optional prefix for the filename
  /// [extension] - File extension (e.g., 'jpg', 'png')
  static String generateUniqueFileName({String? prefix, required String extension}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    final prefixStr = prefix != null ? '${prefix}_' : '';
    
    return '${prefixStr}${timestamp}_$random.$extension';
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
        'logos/$fileName',
      );
    } catch (e) {
      throw Exception('Failed to upload company logo: $e');
    }
  }

  /// Upload vehicle image (legacy method)
  static Future<String> uploadVehicleImage(Uint8List bytes, int? vehicleId) async {
    try {
      final fileName = 'vehicle.jpg';
      final path = vehicleId != null 
          ? 'vehicles/$vehicleId/$fileName'
          : 'vehicles/temp/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
      return await uploadImageBytes(
        bytes,
        'clc_images',
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