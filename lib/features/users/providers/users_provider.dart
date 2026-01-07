import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/users/models/user.dart';
import 'package:choice_lux_cars/features/users/data/users_repository.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:image_picker/image_picker.dart';

/// Notifier for managing users state using AsyncNotifier
class UsersNotifier extends AsyncNotifier<List<User>> {
  late final UsersRepository _repo = ref.read(usersRepositoryProvider);

  @override
  Future<List<User>> build() async {
    // Fetch all users (adjust filter if needed)
    final result = await _repo.fetchUsers();
    if (result.isSuccess) {
      return result.data!;
    } else {
      throw Exception(result.error!.message);
    }
  }

  Future<void> fetchUsers() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await _repo.fetchUsers();
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
    Log.d('UsersNotifier: Updating user ${user.id} with status: ${user.status}');
    final result = await _repo.updateUser(user);
    if (result.isSuccess) {
      Log.d('UsersNotifier: User updated successfully, refreshing users list');
      await fetchUsers();
    } else {
      Log.e('UsersNotifier: Failed to update user: ${result.error?.message}');
      throw Exception(result.error?.message ?? 'Failed to update user');
    }
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
  late final UsersRepository _usersRepository;

  @override
  Future<List<User>> build(String role) async {
    _usersRepository = ref.watch(usersRepositoryProvider);
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
