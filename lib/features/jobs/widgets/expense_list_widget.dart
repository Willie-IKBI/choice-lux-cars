import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:choice_lux_cars/features/jobs/models/expense.dart';
import 'package:choice_lux_cars/features/jobs/providers/expenses_provider.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/app/theme_tokens.dart';
import 'package:choice_lux_cars/shared/utils/snackbar_utils.dart';
import 'package:choice_lux_cars/core/errors/app_exception.dart';
import 'package:intl/intl.dart';

/// Reusable widget for displaying expenses list in driver flow
/// 
/// Shows expenses with slip status and retry upload functionality.
class ExpenseListWidget extends ConsumerWidget {
  final int jobId;

  const ExpenseListWidget({
    super.key,
    required this.jobId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesForJobProvider(jobId));

    return expensesAsync.when(
      data: (expenses) {
        if (expenses.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                'No expenses yet',
                style: TextStyle(
                  color: ChoiceLuxTheme.platinumSilver,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: expenses.map((expense) => _ExpenseRow(
            expense: expense,
            jobId: jobId,
          )).toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Error loading expenses: ${error.toString()}',
            style: const TextStyle(
              color: Colors.red,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

/// Individual expense row with retry upload functionality
class _ExpenseRow extends ConsumerStatefulWidget {
  final Expense expense;
  final int jobId;

  const _ExpenseRow({
    required this.expense,
    required this.jobId,
  });

  @override
  ConsumerState<_ExpenseRow> createState() => _ExpenseRowState();
}

class _ExpenseRowState extends ConsumerState<_ExpenseRow> {
  bool _isUploading = false;

  /// Pick and upload slip file
  Future<void> _retrySlipUpload() async {
    // Defensive guard: cannot retry for approved expenses
    if (widget.expense.isApproved) {
      return;
    }

    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return; // User cancelled
      }

      final file = result.files.first;
      if (file.bytes == null) {
        if (mounted) {
          SnackBarUtils.showError(context, 'Failed to read file');
        }
        return;
      }

      // Validate file size (5MB max)
      if (file.bytes!.length > 5 * 1024 * 1024) {
        if (mounted) {
          SnackBarUtils.showError(context, 'File size must be less than 5MB');
        }
        return;
      }

      // Validate extension
      final extension = file.extension?.toLowerCase() ?? '';
      if (!['jpg', 'jpeg', 'png', 'pdf'].contains(extension)) {
        if (mounted) {
          SnackBarUtils.showError(context, 'Only JPG, JPEG, PNG, and PDF files are allowed');
        }
        return;
      }

      setState(() {
        _isUploading = true;
      });

      // Call retry upload
      final controller = ref.read(expensesForJobProvider(widget.jobId).notifier);
      await controller.retrySlipUpload(
        expenseId: widget.expense.id,
        slipBytes: file.bytes!,
        slipFileName: file.name,
      );

      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Slip uploaded successfully');
      }
    } catch (error) {
      if (mounted) {
        // Extract user-friendly error message
        String errorMessage;
        if (error is AppException) {
          errorMessage = error.message;
        } else {
          errorMessage = error.toString();
        }
        SnackBarUtils.showError(
          context,
          'Failed to upload slip: $errorMessage',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'R ', decimalDigits: 2);
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    final expense = widget.expense;
    final hasSlip = expense.slipImage != null && expense.slipImage!.isNotEmpty;
    final isApproved = expense.isApproved;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isApproved
            ? Colors.green.withValues(alpha: 0.1)
            : ChoiceLuxTheme.richGold.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isApproved
              ? Colors.green.withValues(alpha: 0.3)
              : ChoiceLuxTheme.richGold.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: Type and Amount
          Row(
            children: [
              _buildExpenseTypeChip(expense.expenseType),
              const Spacer(),
              Text(
                currencyFormat.format(expense.amount),
                style: const TextStyle(
                  color: ChoiceLuxTheme.softWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Description
          if (expense.displayDescription.isNotEmpty) ...[
            Text(
              expense.displayDescription,
              style: const TextStyle(
                color: ChoiceLuxTheme.platinumSilver,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
          ],
          
          // Date and status row
          Row(
            children: [
              const Icon(
                Icons.access_time,
                size: 14,
                color: ChoiceLuxTheme.platinumSilver,
              ),
              const SizedBox(width: 4),
              Text(
                dateFormat.format(expense.expDate),
                style: const TextStyle(
                  color: ChoiceLuxTheme.platinumSilver,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              // Slip status and retry button
              if (!hasSlip && !isApproved) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Slip Missing',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ChoiceLuxTheme.richGold,
                          ),
                        ),
                      )
                    : TextButton.icon(
                        onPressed: widget.expense.isApproved ? null : _retrySlipUpload,
                        icon: Icon(
                          Icons.upload_file,
                          size: 16,
                          color: widget.expense.isApproved
                              ? ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.5)
                              : ChoiceLuxTheme.richGold,
                        ),
                        label: Text(
                          'Retry Upload',
                          style: TextStyle(
                            color: widget.expense.isApproved
                                ? ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.5)
                                : ChoiceLuxTheme.richGold,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
              ] else if (hasSlip && !isApproved) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Slip Uploaded',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ] else if (isApproved) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Approved',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 11,
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

  Widget _buildExpenseTypeChip(String type) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
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
        chipColor = tokens.textBody;
        label = 'Other';
        break;
      default:
        chipColor = tokens.textBody;
        label = type;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: chipColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

