import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import 'package:choice_lux_cars/core/services/supabase_service.dart';
import 'package:choice_lux_cars/core/services/upload_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

final usersProvider = StateNotifierProvider<UsersNotifier, List<User>>((ref) => UsersNotifier());

class UsersNotifier extends StateNotifier<List<User>> {
  UsersNotifier() : super([]) {
    fetchUsers();
  }

  // Fetch all users from Supabase
  Future<void> fetchUsers() async {
    final userMaps = await SupabaseService.instance.getUsers();
    state = userMaps.map((map) => User.fromMap(map)).toList();
  }

  Future<void> updateUser(User user) async {
    await SupabaseService.instance.updateUser(userId: user.id, data: user.toMap());
    await fetchUsers();
  }

  Future<void> deactivateUser(String userId) async {
    await SupabaseService.instance.deactivateUser(userId);
    await fetchUsers();
  }

  Future<void> reactivateUser(String userId) async {
    await SupabaseService.instance.reactivateUser(userId);
    await fetchUsers();
  }

  Future<String?> uploadProfileImage(XFile imageFile, String userId) async {
    // Upload to Supabase Storage under /profiles/{userId}/profile.jpg
    final bytes = await imageFile.readAsBytes();
    final url = await UploadService.uploadImage(
      fileBytes: bytes,
      folder: 'profiles/$userId',
      fileName: 'profile.jpg',
    );
    // Update user profileImage field
    await SupabaseService.instance.updateUser(userId: userId, data: {'profile_image': url});
    await fetchUsers();
    return url;
  }

  Future<String?> uploadDriverLicenseImage(XFile xfile, String userId) async {
    final bytes = await xfile.readAsBytes();
    final url = await UploadService.uploadImage(
      fileBytes: bytes,
      folder: 'driver_lic/$userId',
      fileName: 'license.jpg',
    );
    await SupabaseService.instance.updateUser(userId: userId, data: {'driver_licence': url});
    await fetchUsers();
    return url;
  }

  Future<String?> uploadPdpImage(XFile xfile, String userId) async {
    final bytes = await xfile.readAsBytes();
    final url = await UploadService.uploadImage(
      fileBytes: bytes,
      folder: 'pdp_lic/$userId',
      fileName: 'pdp.jpg',
    );
    await SupabaseService.instance.updateUser(userId: userId, data: {'pdp': url});
    await fetchUsers();
    return url;
  }
} 