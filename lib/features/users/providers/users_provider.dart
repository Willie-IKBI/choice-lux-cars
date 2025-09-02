import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/users/models/user.dart';
import 'package:choice_lux_cars/features/users/data/users_repository.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

/// Notifier for managing users state using AsyncNotifier
class UsersNotifier extends AsyncNotifier<List<User>> {
  late final UsersRepository _usersRepository;

  @override
  Future<List<User>> build() async {
    _usersRepository = ref.watch(usersRepositoryProvider);
    return _fetchUsers();
  }

  /// Fetch all users from the repository
  Future<List<User>> _fetchUsers() async {
    try {
      Log.d('Fetching users...');
      
      final result = await _usersRepository.fetchUsers();
      
      if (result.isSuccess) {
        final users = result.data!;
        Log.d('Fetched ${users.length} users successfully');
        return users;
      } else {
        Log.e('Error fetching users: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error fetching users: $error');
      rethrow;
    }
  }

  /// Get drivers from the repository
  Future<List<User>> getDrivers() async {
    try {
      Log.d('Getting drivers...');
      
      final result = await _usersRepository.getDrivers();
      
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

  /// Refresh users data
  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  /// Upload PDP image
  Future<String> uploadPdpImage(dynamic file, String userId) async {
    try {
      Log.d('Uploading PDP image for user: $userId');
      
      // TODO: Implement actual upload logic
      // For now, return a placeholder URL
      Log.d('PDP image upload not implemented yet');
      return 'https://placeholder.com/pdp.jpg';
    } catch (error) {
      Log.e('Error uploading PDP image: $error');
      rethrow;
    }
  }
}

/// Notifier for managing users by role using FamilyAsyncNotifier
class UsersByRoleNotifier extends FamilyAsyncNotifier<List<User>, String> {
  late final UsersRepository _usersRepository;
  late final String role;

  @override
  Future<List<User>> build(String role) async {
    _usersRepository = ref.watch(usersRepositoryProvider);
    this.role = role;
    return _fetchUsersByRole();
  }

  /// Fetch users by role from the repository
  Future<List<User>> _fetchUsersByRole() async {
    try {
      Log.d('Fetching users by role: $role');
      
      final result = await _usersRepository.getUsersByRole(role);
      
      if (result.isSuccess) {
        final users = result.data!;
        Log.d('Fetched ${users.length} users with role $role successfully');
        return users;
      } else {
        Log.e('Error fetching users by role: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error fetching users by role: $error');
      rethrow;
    }
  }

  /// Refresh users by role data
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Notifier for managing current user profile using AsyncNotifier
class CurrentUserProfileNotifier extends AsyncNotifier<User?> {
  late final UsersRepository _usersRepository;

  @override
  Future<User?> build() async {
    _usersRepository = ref.watch(usersRepositoryProvider);
    // This would need to be updated to get the current user ID from auth
    // For now, returning null as placeholder
    return null;
  }

  /// Refresh current user profile data
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Provider for UsersNotifier using AsyncNotifierProvider
final usersProvider = AsyncNotifierProvider<UsersNotifier, List<User>>(() => UsersNotifier());

/// Provider for current user profile using AsyncNotifierProvider
final currentUserProfileProvider = AsyncNotifierProvider<CurrentUserProfileNotifier, User?>((ref) => CurrentUserProfileNotifier());

/// Provider for drivers using AsyncNotifierProvider
final driversProvider = AsyncNotifierProvider<UsersNotifier, List<User>>(() => UsersNotifier());

/// Provider for users by role using AsyncNotifierProvider.family
final usersByRoleProvider = AsyncNotifierProvider.family<UsersNotifier, List<User>, String>((role) => UsersNotifier()); 