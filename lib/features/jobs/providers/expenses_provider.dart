import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/jobs/models/expense.dart';
import 'package:choice_lux_cars/features/jobs/data/expenses_repository.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

/// Notifier for managing expenses state for a specific job
class ExpensesNotifier extends FamilyAsyncNotifier<List<Expense>, int> {
  ExpensesRepository get _repository => ref.read(expensesRepositoryProvider);

  @override
  Future<List<Expense>> build(int jobId) async {
    return _fetchExpensesForJob(jobId);
  }

  /// Fetch expenses for the job
  Future<List<Expense>> _fetchExpensesForJob(int jobId) async {
    try {
      Log.d('Fetching expenses for job: $jobId');
      final result = await _repository.getExpensesForJob(jobId);

      if (result.isSuccess) {
        final expenses = result.data!;
        Log.d('Fetched ${expenses.length} expenses for job $jobId');
        return expenses;
      } else {
        Log.e('Error fetching expenses: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error in _fetchExpensesForJob: $error');
      rethrow;
    }
  }

  /// Refresh expenses data
  Future<void> refresh() async {
    final jobId = arg;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchExpensesForJob(jobId));
  }

  /// Approve all unapproved expenses for the job
  /// 
  /// Calls RPC approve_job_expenses and then refreshes the list.
  /// Returns the approval result with count and total.
  Future<ExpenseApprovalResult> approveAll() async {
    try {
      final jobId = arg;
      Log.d('Approving all expenses for job: $jobId');

      final result = await _repository.approveJobExpenses(jobId);

      if (result.isSuccess) {
        final approvalResult = result.data!;
        Log.d('Approved ${approvalResult.approvedCount} expenses totaling ${approvalResult.approvedTotal}');
        // Refresh to get updated data (including approved_by and approved_at)
        await refresh();
        return approvalResult;
      } else {
        Log.e('Error approving expenses: ${result.error!.message}');
        throw result.error!;
      }
    } catch (error) {
      Log.e('Error in approveAll: $error');
      rethrow;
    }
  }
}

/// Provider for expenses list (read-only)
/// 
/// Usage: ref.watch(expensesForJobProvider(jobId))
final expensesForJobProvider = AsyncNotifierProvider.family<
    ExpensesNotifier,
    List<Expense>,
    int>(
  ExpensesNotifier.new,
);

/// Provider for expense approval controller (with actions)
/// 
/// Usage: ref.read(expenseApprovalControllerProvider(jobId).notifier).approveAll()
final expenseApprovalControllerProvider = expensesForJobProvider;

