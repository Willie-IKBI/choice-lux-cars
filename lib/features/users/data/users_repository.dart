import 'dart:typed_data';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    hide User, AuthException;
import 'package:image_picker/image_picker.dart';
import 'package:choice_lux_cars/core/supabase/supabase_client_provider.dart';
import 'package:choice_lux_cars/features/users/models/user.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/core/types/result.dart';
import 'package:choice_lux_cars/core/errors/app_exception.dart';
import 'package:choice_lux_cars/core/services/upload_service.dart';

/// Repository for user-related data operations
///
/// Encapsulates all Supabase queries and returns domain models.
/// This layer separates data access from business logic.
class UsersRepository {
  final SupabaseClient _supabase;

  UsersRepository(this._supabase);

  /// Fetch all users from the database
  Future<Result<List<User>>> fetchUsers() async {
    try {
      Log.d('Fetching users from database');

      final response = await _supabase
          .from('profiles')
          .select()
          .order('display_name', ascending: true);

      Log.d('Fetched ${response.length} users from database');

      final users = response.map((json) => User.fromJson(json)).toList();
      return Result.success(users);
    } catch (error) {
      Log.e('Error fetching users: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Get user profile by ID
  Future<Result<User?>> getUserProfile(String userId) async {
    try {
      Log.d('Fetching user profile: $userId');

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        Log.d('User profile found: ${response['display_name']}');
        return Result.success(User.fromJson(response));
      } else {
        Log.d('User profile not found: $userId');
        return const Result.success(null);
      }
    } catch (error) {
      Log.e('Error fetching user profile: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Update user profile
  Future<Result<void>> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      Log.d('Updating user profile: $userId');

      await _supabase.from('profiles').update(data).eq('id', userId);

      Log.d('User profile updated successfully');
      return const Result.success(null);
    } catch (error) {
      Log.e('Error updating user profile: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Get users by role
  Future<Result<List<User>>> getUsersByRole(String role) async {
    try {
      Log.d('Fetching users with role: $role');

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('role', role)
          .order('display_name', ascending: true);

      Log.d('Fetched ${response.length} users with role: $role');

      final users = response.map((json) => User.fromJson(json)).toList();
      return Result.success(users);
    } catch (error) {
      Log.e('Error fetching users by role: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Get drivers (users with driver role)
  Future<Result<List<User>>> getDrivers() async {
    try {
      Log.d('Fetching drivers from database');

      final response = await _supabase
          .from('profiles')
          .select()
          .inFilter('role', ['driver', 'driver_manager'])
          .order('display_name', ascending: true);

      Log.d('Fetched ${response.length} drivers from database');

      final drivers = response.map((json) => User.fromJson(json)).toList();
      return Result.success(drivers);
    } catch (error) {
      Log.e('Error fetching drivers: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Search users by name
  Future<Result<List<User>>> searchUsers(String query) async {
    try {
      Log.d('Searching users with query: $query');

      final response = await _supabase
          .from('profiles')
          .select()
          .or('display_name.ilike.%$query%,user_email.ilike.%$query%')
          .order('display_name', ascending: true);

      Log.d('Found ${response.length} users matching query: $query');

      final users = response.map((json) => User.fromJson(json)).toList();
      return Result.success(users);
    } catch (error) {
      Log.e('Error searching users: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Deactivate user
  Future<Result<void>> deactivateUser(String userId) async {
    try {
      Log.d('Deactivating user: $userId');

      await _supabase
          .from('profiles')
          .update({'status': 'deactivated'})
          .eq('id', userId);

      Log.d('User deactivated successfully');
      return const Result.success(null);
    } catch (error) {
      Log.e('Error deactivating user: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Activate user
  Future<Result<void>> activateUser(String userId) async {
    try {
      Log.d('Activating user: $userId');

      await _supabase
          .from('profiles')
          .update({'status': 'active'})
          .eq('id', userId);

      Log.d('User activated successfully');
      return const Result.success(null);
    } catch (error) {
      Log.e('Error activating user: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Update user
  Future<Result<void>> updateUser(User user) async {
    try {
      Log.d('Updating user: ${user.id}');

      final data = user.toJson();
      // Remove id and user_email from update data
      // id is the primary key and cannot be updated
      // user_email is tied to auth system and shouldn't be updated here
      data.remove('id');
      data.remove('user_email');
      
      await _supabase
          .from('profiles')
          .update(data)
          .eq('id', user.id);

      Log.d('User updated successfully');
      return const Result.success(null);
    } catch (error) {
      Log.e('Error updating user: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Upload profile image
  Future<Result<String>> uploadProfileImage(dynamic file, String userId) async {
    try {
      Log.d('Uploading profile image for user: $userId');

      // Read file bytes
      Uint8List bytes;
      if (file is XFile) {
        bytes = await file.readAsBytes();
      } else if (file is File) {
        bytes = await file.readAsBytes();
      } else {
        throw Exception('Unsupported file type');
      }

      // Upload to Supabase Storage
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final url = await UploadService.uploadImageBytes(
        bytes,
        'clc_images',
        'profiles',
        '$userId/$fileName',
      );

      // Update user profile in database
      await _supabase
          .from('profiles')
          .update({'profile_image': url})
          .eq('id', userId);

      Log.d('Profile image uploaded successfully: $url');
      return Result.success(url);
    } catch (error) {
      Log.e('Error uploading profile image: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Upload driver license image
  Future<Result<String>> uploadDriverLicenseImage(dynamic file, String userId) async {
    try {
      Log.d('Uploading driver license image for user: $userId');

      // Read file bytes
      Uint8List bytes;
      if (file is XFile) {
        bytes = await file.readAsBytes();
      } else if (file is File) {
        bytes = await file.readAsBytes();
      } else {
        throw Exception('Unsupported file type');
      }

      // Upload to Supabase Storage
      final fileName = 'driver_license_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final url = await UploadService.uploadImageBytes(
        bytes,
        'clc_images',
        'driver_licenses',
        '$userId/$fileName',
      );

      // Update user profile in database
      await _supabase
          .from('profiles')
          .update({'driver_licence': url})
          .eq('id', userId);

      Log.d('Driver license image uploaded successfully: $url');
      return Result.success(url);
    } catch (error) {
      Log.e('Error uploading driver license image: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Upload PDP image
  Future<Result<String>> uploadPdpImage(dynamic file, String userId) async {
    try {
      Log.d('Uploading PDP image for user: $userId');

      // Read file bytes
      Uint8List bytes;
      if (file is XFile) {
        bytes = await file.readAsBytes();
      } else if (file is File) {
        bytes = await file.readAsBytes();
      } else {
        throw Exception('Unsupported file type');
      }

      // Upload to Supabase Storage
      final fileName = 'pdp_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final url = await UploadService.uploadImageBytes(
        bytes,
        'clc_images',
        'pdp_documents',
        '$userId/$fileName',
      );

      // Update user profile in database
      await _supabase
          .from('profiles')
          .update({'pdp': url})
          .eq('id', userId);

      Log.d('PDP image uploaded successfully: $url');
      return Result.success(url);
    } catch (error) {
      Log.e('Error uploading PDP image: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Map Supabase errors to appropriate AppException types
  Result<T> _mapSupabaseError<T>(dynamic error) {
    if (error is AuthException) {
      return Result.failure(AuthException(error.message));
    } else if (error is PostgrestException) {
      // Check if it's a network-related error
      if (error.message.contains('network') ||
          error.message.contains('timeout') ||
          error.message.contains('connection')) {
        return Result.failure(NetworkException(error.message));
      }
      // Check if it's an auth-related error
      if (error.message.contains('JWT') ||
          error.message.contains('unauthorized') ||
          error.message.contains('forbidden')) {
        return Result.failure(AuthException(error.message));
      }
      return Result.failure(UnknownException(error.message));
    } else if (error is StorageException) {
      if (error.message.contains('network') ||
          error.message.contains('timeout')) {
        return Result.failure(NetworkException(error.message));
      }
      return Result.failure(UnknownException(error.message));
    } else {
      return Result.failure(UnknownException(error.toString()));
    }
  }
}

/// Provider for UsersRepository
final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return UsersRepository(supabase);
});
