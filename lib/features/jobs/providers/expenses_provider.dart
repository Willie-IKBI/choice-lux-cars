import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:choice_lux_cars/features/jobs/models/expense.dart';
import 'package:choice_lux_cars/core/supabase/supabase_client_provider.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

/// Notifier for expenses by job. Fetches from expenses table and supports retry slip upload.
class ExpensesForJobNotifier extends FamilyAsyncNotifier<List<Expense>, int> {
  @override
  Future<List<Expense>> build(int jobId) async {
    return _fetchExpensesForJob(jobId);
  }

  Future<List<Expense>> _fetchExpensesForJob(int jobId) async {
    try {
      Log.d('Fetching expenses for job: $jobId');

      final supabase = ref.watch(supabaseClientProvider);
      final response = await supabase
          .from('expenses')
          .select()
          .eq('job_id', jobId)
          .order('created_at', ascending: false);

      final list = response as List<dynamic>;
      final expenses = list
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList();

      Log.d('Fetched ${expenses.length} expenses for job: $jobId');
      return expenses;
    } catch (e) {
      Log.e('Error fetching expenses for job $jobId: $e');
      rethrow;
    }
  }

  /// Retry uploading slip image for an expense that was created without one.
  Future<void> retrySlipUpload({
    required int expenseId,
    required List<int> slipBytes,
    required String slipFileName,
  }) async {
    try {
      final supabase = ref.watch(supabaseClientProvider);
      final storagePath =
          'expenses/$arg/${DateTime.now().millisecondsSinceEpoch}_$slipFileName';

      await supabase.storage
          .from('expense-slips')
          .uploadBinary(storagePath, Uint8List.fromList(slipBytes));

      final publicUrl =
          supabase.storage.from('expense-slips').getPublicUrl(storagePath);

      await supabase
          .from('expenses')
          .update({
            'slip_image': publicUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', expenseId);

      await refresh();
    } catch (e) {
      Log.e('Error retrying slip upload: $e');
      rethrow;
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Provider for expenses by job. Use expensesForJobProvider(jobId).
final expensesForJobProvider =
    AsyncNotifierProvider.family<ExpensesForJobNotifier, List<Expense>, int>(
  ExpensesForJobNotifier.new,
);
