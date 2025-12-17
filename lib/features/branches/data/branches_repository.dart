import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:choice_lux_cars/core/supabase/supabase_client_provider.dart';
import 'package:choice_lux_cars/features/branches/models/branch.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/core/types/result.dart';
import 'package:choice_lux_cars/core/errors/app_exception.dart';

/// Repository for branch-related data operations
///
/// Encapsulates all Supabase queries and returns domain models.
/// This layer separates data access from business logic.
class BranchesRepository {
  final SupabaseClient _supabase;

  BranchesRepository(this._supabase);

  /// Fetch all branches from the database
  Future<Result<List<Branch>>> fetchBranches() async {
    try {
      Log.d('Fetching branches from database');

      final response = await _supabase
          .from('branches')
          .select()
          .order('name', ascending: true);

      Log.d('Fetched ${response.length} branches from database');

      final branches = response.map((json) => Branch.fromJson(json)).toList();
      return Result.success(branches);
    } catch (error) {
      Log.e('Error fetching branches: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Fetch a single branch by ID
  Future<Result<Branch?>> fetchBranchById(int branchId) async {
    try {
      Log.d('Fetching branch by ID: $branchId');

      final response = await _supabase
          .from('branches')
          .select()
          .eq('id', branchId)
          .maybeSingle();

      if (response != null) {
        Log.d('Branch found: ${response['name']}');
        return Result.success(Branch.fromJson(response));
      } else {
        Log.d('Branch not found');
        return const Result.success(null);
      }
    } catch (error) {
      Log.e('Error fetching branch by ID: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Fetch a single branch by code
  Future<Result<Branch?>> fetchBranchByCode(String code) async {
    try {
      Log.d('Fetching branch by code: $code');

      final response = await _supabase
          .from('branches')
          .select()
          .eq('code', code)
          .maybeSingle();

      if (response != null) {
        Log.d('Branch found: ${response['name']}');
        return Result.success(Branch.fromJson(response));
      } else {
        Log.d('Branch not found');
        return const Result.success(null);
      }
    } catch (error) {
      Log.e('Error fetching branch by code: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Map Supabase errors to app exceptions
  Result<T> _mapSupabaseError<T>(dynamic error) {
    if (error is PostgrestException) {
      Log.e('Postgrest error: ${error.message}');
      return Result.failure(
        UnknownException('Database error: ${error.message}'),
      );
    } else if (error is AuthException) {
      Log.e('Auth error: ${error.message}');
      return Result.failure(
        UnknownException('Authentication error: ${error.message}'),
      );
    } else {
      Log.e('Unknown error: $error');
      return Result.failure(
        UnknownException('An unexpected error occurred: $error'),
      );
    }
  }
}

/// Provider for BranchesRepository
final branchesRepositoryProvider = Provider<BranchesRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return BranchesRepository(supabase);
});

