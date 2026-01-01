import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/jobs/models/expense.dart';
import 'package:choice_lux_cars/features/jobs/providers/expenses_provider.dart';
import 'package:choice_lux_cars/features/jobs/services/expense_approval_service.dart';
import 'package:choice_lux_cars/features/jobs/models/job.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/utils/snackbar_utils.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/core/errors/app_exception.dart';
import 'package:intl/intl.dart';

/// Widget displaying expenses for a job with approval functionality
/// 
/// Shows all expenses with their status and allows managers to approve.
class ExpensesCard extends ConsumerWidget {
  final int jobId;
  final Job job;
  final bool isMobile;

  const ExpensesCard({
    super.key,
    required this.jobId,
    required this.job,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesForJobProvider(jobId));
    final controller = ref.read(expenseApprovalControllerProvider(jobId).notifier);
    final currentUser = ref.watch(currentUserProfileProvider);

    return expensesAsync.when(
      data: (expenses) {
        final totals = ExpenseApprovalService.computeTotals(expenses);
        final canApprove = _canApproveExpenses(currentUser, job, totals);

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          decoration: BoxDecoration(
            gradient: ChoiceLuxTheme.cardGradient,
            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
            border: Border.all(
              color: ChoiceLuxTheme.richGold.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.receipt_long,
                    color: ChoiceLuxTheme.richGold,
                    size: isMobile ? 20 : 24,
                  ),
                  SizedBox(width: isMobile ? 8 : 12),
                  Text(
                    'Expenses',
                    style: TextStyle(
                      color: ChoiceLuxTheme.richGold,
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 6 : 8),
              Text(
                'Job-related expenses and approval status',
                style: TextStyle(
                  color: ChoiceLuxTheme.platinumSilver,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
              SizedBox(height: isMobile ? 16 : 20),
              // Totals row
              _buildTotalsRow(totals, isMobile),
              SizedBox(height: isMobile ? 16 : 20),
              // Expenses list
              if (expenses.isEmpty)
                Padding(
                  padding: EdgeInsets.all(isMobile ? 16 : 20),
                  child: Center(
                    child: Text(
                      'No expenses recorded',
                      style: TextStyle(
                        color: ChoiceLuxTheme.platinumSilver,
                        fontSize: isMobile ? 14 : 16,
                      ),
                    ),
                  ),
                )
              else
                ...expenses.map((expense) => _buildExpenseRow(expense, isMobile)),
              // Approve button (only for managers when conditions met)
              if (canApprove) ...[
                SizedBox(height: isMobile ? 16 : 20),
                _buildApproveButton(context, ref, controller, totals),
              ],
            ],
          ),
        );
      },
      loading: () => Container(
        width: double.infinity,
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        decoration: BoxDecoration(
          gradient: ChoiceLuxTheme.cardGradient,
          borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
          border: Border.all(
            color: ChoiceLuxTheme.richGold.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ChoiceLuxTheme.richGold),
          ),
        ),
      ),
      error: (error, stack) {
        Log.e('Error loading expenses: $error');
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          decoration: BoxDecoration(
            gradient: ChoiceLuxTheme.cardGradient,
            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
            border: Border.all(
              color: ChoiceLuxTheme.richGold.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                color: ChoiceLuxTheme.errorColor,
                size: isMobile ? 24 : 32,
              ),
              SizedBox(height: isMobile ? 8 : 12),
              Text(
                'Failed to load expenses',
                style: TextStyle(
                  color: ChoiceLuxTheme.softWhite,
                  fontSize: isMobile ? 14 : 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTotalsRow(ExpenseTotals totals, bool isMobile) {
    final currencyFormat = NumberFormat.currency(symbol: 'R ', decimalDigits: 2);

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: ChoiceLuxTheme.richGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  color: ChoiceLuxTheme.platinumSilver,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
              SizedBox(height: 4),
              Text(
                currencyFormat.format(totals.total),
                style: TextStyle(
                  color: ChoiceLuxTheme.softWhite,
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Approved',
                style: TextStyle(
                  color: ChoiceLuxTheme.platinumSilver,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
              SizedBox(height: 4),
              Text(
                currencyFormat.format(totals.approvedTotal),
                style: TextStyle(
                  color: Colors.green,
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Pending',
                style: TextStyle(
                  color: ChoiceLuxTheme.platinumSilver,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
              SizedBox(height: 4),
              Text(
                currencyFormat.format(totals.unapprovedTotal),
                style: TextStyle(
                  color: ChoiceLuxTheme.richGold,
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseRow(Expense expense, bool isMobile) {
    final currencyFormat = NumberFormat.currency(symbol: 'R ', decimalDigits: 2);
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: expense.isApproved
            ? Colors.green.withValues(alpha: 0.1)
            : ChoiceLuxTheme.richGold.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: expense.isApproved
              ? Colors.green.withValues(alpha: 0.3)
              : ChoiceLuxTheme.richGold.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildExpenseTypeChip(expense.expenseType, isMobile),
              const Spacer(),
              Text(
                currencyFormat.format(expense.amount),
                style: TextStyle(
                  color: ChoiceLuxTheme.softWhite,
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 6 : 8),
          if (expense.displayDescription.isNotEmpty)
            Text(
              expense.displayDescription,
              style: TextStyle(
                color: ChoiceLuxTheme.platinumSilver,
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          SizedBox(height: isMobile ? 4 : 6),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: isMobile ? 12 : 14,
                color: ChoiceLuxTheme.platinumSilver,
              ),
              SizedBox(width: 4),
              Text(
                dateFormat.format(expense.expDate),
                style: TextStyle(
                  color: ChoiceLuxTheme.platinumSilver,
                  fontSize: isMobile ? 11 : 12,
                ),
              ),
              if (expense.isApproved) ...[
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 6 : 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Approved',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: isMobile ? 10 : 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseTypeChip(String type, bool isMobile) {
    Color chipColor;
    String label;

    switch (type) {
      case 'fuel':
        chipColor = Colors.orange;
        label = 'Fuel';
        break;
      case 'parking':
        chipColor = Colors.blue;
        label = 'Parking';
        break;
      case 'toll':
        chipColor = Colors.purple;
        label = 'Toll';
        break;
      case 'other':
        chipColor = ChoiceLuxTheme.platinumSilver;
        label = 'Other';
        break;
      default:
        chipColor = ChoiceLuxTheme.platinumSilver;
        label = type;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 12,
        vertical: isMobile ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: chipColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: chipColor,
          fontSize: isMobile ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildApproveButton(
    BuildContext context,
    WidgetRef ref,
    ExpensesNotifier controller,
    ExpenseTotals totals,
  ) {
    final expensesState = ref.watch(expenseApprovalControllerProvider(jobId));
    final isLoading = expensesState.isLoading;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading || totals.unapprovedCount == 0
            ? null
            : () => _handleApprove(context, ref, controller),
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            : const Icon(Icons.check_circle),
        label: Text(
          totals.unapprovedCount > 0
              ? 'Approve ${totals.unapprovedCount} Expense${totals.unapprovedCount > 1 ? 's' : ''}'
              : 'No Pending Expenses',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: ChoiceLuxTheme.richGold,
          foregroundColor: Colors.black,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: isMobile ? 12 : 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Future<void> _handleApprove(
    BuildContext context,
    WidgetRef ref,
    ExpensesNotifier controller,
  ) async {
    try {
      final approvalResult = await controller.approveAll();

      if (context.mounted) {
        final currencyFormat = NumberFormat.currency(symbol: 'R ', decimalDigits: 2);
        SnackBarUtils.showSuccess(
          context,
          'Approved ${approvalResult.approvedCount} expense${approvalResult.approvedCount > 1 ? 's' : ''} (${currencyFormat.format(approvalResult.approvedTotal)})',
        );
      }
    } catch (error) {
      Log.e('Error approving expenses: $error');
      if (context.mounted) {
        String errorMessage;
        if (error is Exception) {
          errorMessage = ExpenseApprovalService.mapApprovalErrorToMessage(
            error is AppException
                ? error
                : UnknownException(error.toString()),
          );
        } else {
          errorMessage = 'An error occurred. Please try again.';
        }

        SnackBarUtils.showError(context, errorMessage);
      }
    }
  }

  /// Check if current user can approve expenses
  bool _canApproveExpenses(dynamic currentUser, Job job, ExpenseTotals totals) {
    if (currentUser == null) return false;

    // Check if user is manager of the job
    final isManager = job.managerId != null &&
        currentUser.id.toString() == job.managerId;

    // Check if user is admin
    final isAdmin = currentUser.role?.toLowerCase() == 'administrator' ||
        currentUser.role?.toLowerCase() == 'super_admin';

    // Can approve if:
    // 1. User is manager or admin
    // 2. Job is completed
    // 3. There are unapproved expenses
    return (isManager || isAdmin) &&
        job.status.toLowerCase() == 'completed' &&
        totals.unapprovedCount > 0;
  }
}

