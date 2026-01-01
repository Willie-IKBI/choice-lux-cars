import 'package:choice_lux_cars/features/jobs/models/expense.dart';
import 'package:choice_lux_cars/core/errors/app_exception.dart';

/// Service layer for expense approval business logic
/// 
/// Provides helper methods for computing totals and error mapping.
class ExpenseApprovalService {
  /// Compute expense totals from a list of expenses
  /// 
  /// Returns:
  /// - total: Sum of all expenses
  /// - approvedTotal: Sum of approved expenses
  /// - unapprovedTotal: Sum of unapproved expenses
  /// - approvedCount: Number of approved expenses
  /// - unapprovedCount: Number of unapproved expenses
  static ExpenseTotals computeTotals(List<Expense> expenses) {
    double total = 0.0;
    double approvedTotal = 0.0;
    double unapprovedTotal = 0.0;
    int approvedCount = 0;
    int unapprovedCount = 0;

    for (final expense in expenses) {
      total += expense.amount;
      if (expense.isApproved) {
        approvedTotal += expense.amount;
        approvedCount++;
      } else {
        unapprovedTotal += expense.amount;
        unapprovedCount++;
      }
    }

    return ExpenseTotals(
      total: total,
      approvedTotal: approvedTotal,
      unapprovedTotal: unapprovedTotal,
      approvedCount: approvedCount,
      unapprovedCount: unapprovedCount,
    );
  }

  /// Map approval errors to user-friendly messages
  /// 
  /// Handles RPC exceptions and RLS policy violations.
  static String mapApprovalErrorToMessage(AppException error) {
    final message = error.message.toLowerCase();

    // Job not found
    if (message.contains('job not found') || message.contains('does not exist')) {
      return 'Job not found. Please refresh and try again.';
    }

    // Job not completed
    if (message.contains('job not completed') || 
        message.contains('can only be approved for completed jobs')) {
      return 'Job must be completed before approving expenses.';
    }

    // Not authorized
    if (message.contains('not authorized') ||
        message.contains('not the manager') ||
        message.contains('does not have administrator privileges')) {
      return 'You do not have permission to approve expenses for this job.';
    }

    // No unapproved expenses
    if (message.contains('no unapproved expenses') ||
        message.contains('approved_count') && message.contains('0')) {
      return 'No pending expenses to approve.';
    }

    // RLS/Auth errors
    if (message.contains('unauthorized') ||
        message.contains('forbidden') ||
        message.contains('permission denied')) {
      return 'You do not have permission to perform this action.';
    }

    // Network errors
    if (message.contains('network') ||
        message.contains('timeout') ||
        message.contains('connection')) {
      return 'Network error. Please check your connection and try again.';
    }

    // Generic validation error
    if (error is ValidationException) {
      // Extract meaningful part
      if (message.contains('job not completed')) {
        return 'Job must be completed before approving expenses.';
      }
      return error.message;
    }

    // Default fallback
    return 'An error occurred while approving expenses. Please try again.';
  }
}

/// Expense totals summary
class ExpenseTotals {
  final double total;
  final double approvedTotal;
  final double unapprovedTotal;
  final int approvedCount;
  final int unapprovedCount;

  ExpenseTotals({
    required this.total,
    required this.approvedTotal,
    required this.unapprovedTotal,
    required this.approvedCount,
    required this.unapprovedCount,
  });
}

