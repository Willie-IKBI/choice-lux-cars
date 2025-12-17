import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/branches/models/branch.dart';
import 'package:choice_lux_cars/features/branches/data/branches_repository.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

/// Notifier for managing branches state using AsyncNotifier
class BranchesNotifier extends AsyncNotifier<List<Branch>> {
  BranchesRepository get _branchesRepository => ref.watch(branchesRepositoryProvider);

  @override
  Future<List<Branch>> build() async {
    return _fetchBranches();
  }

  /// Fetch all branches from the repository
  Future<List<Branch>> _fetchBranches() async {
    try {
      Log.d('Fetching branches...');

      final result = await _branchesRepository.fetchBranches();

      if (result.isSuccess) {
        final branches = result.data!;
        Log.d('Fetched ${branches.length} branches successfully');
        return branches;
      } else {
        Log.e('Error fetching branches: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error fetching branches: $error');
      rethrow;
    }
  }

  /// Refresh branches data
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Notifier for managing single branch using FamilyAsyncNotifier
class SingleBranchNotifier extends FamilyAsyncNotifier<Branch?, int> {
  BranchesRepository get _branchesRepository => ref.watch(branchesRepositoryProvider);

  @override
  Future<Branch?> build(int branchId) async {
    return _fetchBranchById(branchId);
  }

  /// Fetch branch by ID
  Future<Branch?> _fetchBranchById(int branchId) async {
    try {
      Log.d('Fetching branch by ID: $branchId');

      final result = await _branchesRepository.fetchBranchById(branchId);

      if (result.isSuccess) {
        Log.d('Fetched branch successfully: ${result.data?.name}');
        return result.data;
      } else {
        Log.e('Error fetching branch by ID: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error fetching branch by ID: $error');
      rethrow;
    }
  }

  /// Refresh branch data
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Provider for BranchesNotifier using AsyncNotifierProvider
/// Caches branches data for efficient access across the app
final branchesProvider = AsyncNotifierProvider<BranchesNotifier, List<Branch>>(
  () => BranchesNotifier(),
);

/// Provider for single branch using AsyncNotifierProvider.family
final branchProvider =
    AsyncNotifierProvider.family<SingleBranchNotifier, Branch?, int>(
      SingleBranchNotifier.new,
    );

