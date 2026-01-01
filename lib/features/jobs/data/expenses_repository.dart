import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:choice_lux_cars/core/supabase/supabase_client_provider.dart';
import 'package:choice_lux_cars/features/jobs/models/expense.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/core/types/result.dart';
import 'package:choice_lux_cars/core/errors/app_exception.dart';

/// Repository for expenses table operations
/// 
/// Handles all data access for expense tracking and approval.
/// Respects RLS policies (drivers/managers can SELECT for their jobs).
class ExpensesRepository {
  final SupabaseClient _supabase;

  ExpensesRepository(this._supabase);

  /// Fetch all expenses for a job, ordered by created_at ASC
  Future<Result<List<Expense>>> getExpensesForJob(int jobId) async {
    try {
      Log.d('Fetching expenses for job: $jobId');

      final response = await _supabase
          .from('expenses')
          .select()
          .eq('job_id', jobId)
          .order('created_at', ascending: true);

      Log.d('Fetched ${response.length} expenses for job $jobId');

      final expenses = response
          .map((json) => Expense.fromJson(json))
          .toList();

      return Result.success(expenses);
    } catch (error) {
      Log.e('Error fetching expenses for job $jobId: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Approve all unapproved expenses for a job via RPC
  /// 
  /// Calls public.approve_job_expenses(p_job_id) which:
  /// - Requires job_status = 'completed'
  /// - Requires caller is job manager OR admin
  /// - Approves all expenses where approved_by IS NULL
  /// - Returns (approved_count, approved_total)
  Future<Result<ExpenseApprovalResult>> approveJobExpenses(int jobId) async {
    try {
      Log.d('Approving expenses for job: $jobId via RPC');

      final response = await _supabase.rpc(
        'approve_job_expenses',
        params: {'p_job_id': jobId},
      );

      if (response == null) {
        Log.e('RPC returned null response');
        return Result.failure(UnknownException('Approval failed: No response from server'));
      }

      // RPC returns a record with (approved_count, approved_total)
      // Supabase returns it as a List with one Map
      Map<String, dynamic> resultMap;
      if (response is List && response.isNotEmpty) {
        resultMap = response.first as Map<String, dynamic>;
      } else if (response is Map) {
        resultMap = response as Map<String, dynamic>;
      } else {
        Log.e('Unexpected RPC response format: $response');
        return Result.failure(UnknownException('Approval failed: Unexpected response format'));
      }

      Log.d('RPC response: $resultMap');

      final result = ExpenseApprovalResult.fromMap(resultMap);
      Log.d('Approved ${result.approvedCount} expenses totaling ${result.approvedTotal}');

      return Result.success(result);
    } catch (error) {
      Log.e('Error approving expenses for job $jobId: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Map Supabase errors to appropriate AppException types
  Result<T> _mapSupabaseError<T>(dynamic error) {
    if (error is AuthException) {
      return Result.failure(AuthException(error.message));
    } else if (error is PostgrestException) {
      final message = error.message.toLowerCase();

      // Check if it's a network-related error
      if (message.contains('network') ||
          message.contains('timeout') ||
          message.contains('connection')) {
        return Result.failure(NetworkException(error.message));
      }

      // Check if it's an auth-related error
      if (message.contains('jwt') ||
          message.contains('unauthorized') ||
          message.contains('forbidden') ||
          message.contains('not authorized')) {
        return Result.failure(AuthException(error.message));
      }

      // Check if it's a validation/business rule error
      if (message.contains('job not found') ||
          message.contains('job not completed') ||
          message.contains('no unapproved expenses')) {
        return Result.failure(ValidationException(error.message));
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

/// Provider for ExpensesRepository
final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ExpensesRepository(supabase);
});

