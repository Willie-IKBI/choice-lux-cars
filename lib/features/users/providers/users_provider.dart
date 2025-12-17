import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/users/models/user.dart';
import 'package:choice_lux_cars/features/users/data/users_repository.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:image_picker/image_picker.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';

/// Notifier for managing users state using AsyncNotifier
class UsersNotifier extends AsyncNotifier<List<User>> {
  /// Get the users repository
  UsersRepository get _repo => ref.read(usersRepositoryProvider);

  @override
  Future<List<User>> build() async {
    // Watch current user to get branchId for filtering
    final currentUser = ref.watch(currentUserProfileProvider);
    final branchId = currentUser?.branchId;
    
    // Fetch users filtered by branch (admin sees all, non-admin sees only their branch)
    final result = await _repo.fetchUsers(branchId: branchId);
    if (result.isSuccess) {
      return result.data!;
    } else {
      throw Exception(result.error!.message);
    }
  }

  Future<void> fetchUsers() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // Get current user branchId for filtering
      final currentUser = ref.read(currentUserProfileProvider);
      final branchId = currentUser?.branchId;
      
      final result = await _repo.fetchUsers(branchId: branchId);
      if (result.isSuccess) {
        return result.data!;
      } else {
        throw Exception(result.error!.message);
      }
    });
  }

  Future<void> deactivateUser(String userId) async {
    await _repo.deactivateUser(userId);
    await fetchUsers();
  }

  Future<void> updateUser(User user) async {
    // Check if role is being changed - only super_admin can change roles
    final currentUser = ref.read(currentUserProfileProvider);
    final isSuperAdmin = currentUser != null && 
        currentUser.role != null && 
        currentUser.role!.toLowerCase() == 'super_admin';
    
    // Get existing user to check if role changed
    final existingUsers = state.value ?? [];
    final existingUser = existingUsers.firstWhere(
      (u) => u.id == user.id,
      orElse: () => user,
    );
    
    // If role is being changed and user is not super_admin, throw error
    if (existingUser.role != user.role && !isSuperAdmin) {
      throw Exception('Only Super Administrators can assign or change user roles');
    }
    
    await _repo.updateUser(user);
    await fetchUsers();
  }

  Future<String> uploadProfileImage(XFile file, String userId) async {
    final result = await _repo.uploadProfileImage(file, userId);
    if (result.isSuccess) {
      await fetchUsers();
      return result.data!;
    } else {
      throw Exception(result.error!.message);
    }
  }

  Future<String> uploadDriverLicenseImage(XFile file, String userId) async {
    final result = await _repo.uploadDriverLicenseImage(file, userId);
    if (result.isSuccess) {
      await fetchUsers();
      return result.data!;
    } else {
      throw Exception(result.error!.message);
    }
  }

  Future<String> uploadPdpImage(XFile file, String userId) async {
    final result = await _repo.uploadPdpImage(file, userId);
    if (result.isSuccess) {
      await fetchUsers();
      return result.data!;
    } else {
      throw Exception(result.error!.message);
    }
  }

  /// Get drivers from the repository
  Future<List<User>> getDrivers() async {
    try {
      Log.d('Getting drivers...');
      final result = await _repo.getDrivers();
      if (result.isSuccess) {
        final drivers = result.data!;
        Log.d('Fetched ${drivers.length} drivers successfully');
        return drivers;
      } else {
        Log.e('Error getting drivers: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error getting drivers: $error');
      rethrow;
    }
  }

  /// Get users by role from the repository
  Future<List<User>> getUsersByRole(String role) async {
    try {
      Log.d('Getting users by role: $role');
      final result = await _repo.getUsersByRole(role);
      if (result.isSuccess) {
        final users = result.data!;
        Log.d('Fetched ${users.length} users with role $role successfully');
        return users;
      } else {
        Log.e('Error getting users by role: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error getting users by role: $error');
      rethrow;
    }
  }

  /// Refresh users data
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Notifier for managing users by role using FamilyAsyncNotifier
class UsersByRoleNotifier extends FamilyAsyncNotifier<List<User>, String> {
  /// Get the users repository
  UsersRepository get _usersRepository => ref.read(usersRepositoryProvider);

  @override
  Future<List<User>> build(String role) async {
    return _fetchUsersByRole(role);
  }

  /// Fetch users by role from the repository
  Future<List<User>> _fetchUsersByRole(String role) async {
    try {
      Log.d('Fetching users by role: $role');
      final result = await _usersRepository.getUsersByRole(role);
      if (result.isSuccess) {
        final users = result.data!;
        Log.d('Fetched ${users.length} users with role $role successfully');
        return users;
      } else {
        Log.e('Error getting users by role: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error getting users by role: $error');
      rethrow;
    }
  }

  /// Refresh users by role data
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Provider for UsersNotifier using AsyncNotifierProvider
final usersProvider = AsyncNotifierProvider<UsersNotifier, List<User>>(UsersNotifier.new);

/// Provider for drivers using AsyncNotifierProvider
final driversProvider = AsyncNotifierProvider<UsersNotifier, List<User>>(UsersNotifier.new);

/// Provider for users by role using AsyncNotifierProvider.family
final usersByRoleProvider = AsyncNotifierProvider.family<UsersByRoleNotifier, List<User>, String>(
  UsersByRoleNotifier.new,
);
