import 'package:choice_lux_cars/shared/utils/sa_time_utils.dart';

/// Model representing an expense row from the expenses table
/// 
/// Tracks job-related expenses with type classification and manager approval.
class Expense {
  final int id;
  final int jobId;
  final String driverId;
  final String expenseType; // 'fuel', 'parking', 'toll', 'other'
  final double amount;
  final DateTime expDate;
  final String? expenseDescription;
  final String? otherDescription; // Required if expenseType == 'other'
  final String? slipImage; // Receipt/slip image URL
  final String? expenseLocation;
  final String? approvedBy; // Manager UUID who approved
  final DateTime? approvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Expense({
    required this.id,
    required this.jobId,
    required this.driverId,
    required this.expenseType,
    required this.amount,
    required this.expDate,
    this.expenseDescription,
    this.otherDescription,
    this.slipImage,
    this.expenseLocation,
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: (map['id'] as num).toInt(),
      jobId: (map['job_id'] as num).toInt(),
      driverId: map['driver_id']?.toString() ?? '',
      expenseType: map['expense_type'] as String,
      amount: (map['exp_amount'] as num).toDouble(),
      expDate: DateTime.parse(map['exp_date'] as String),
      expenseDescription: map['expense_description']?.toString(),
      otherDescription: map['other_description']?.toString(),
      slipImage: map['slip_image']?.toString(),
      expenseLocation: map['expense_location']?.toString(),
      approvedBy: map['approved_by']?.toString(),
      approvedAt: map['approved_at'] != null
          ? DateTime.parse(map['approved_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  factory Expense.fromJson(Map<String, dynamic> json) => Expense.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'job_id': jobId,
      'driver_id': driverId,
      'expense_type': expenseType,
      'exp_amount': amount,
      'exp_date': expDate.toIso8601String(),
      'expense_description': expenseDescription,
      'other_description': otherDescription,
      'slip_image': slipImage,
      'expense_location': expenseLocation,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  Expense copyWith({
    int? id,
    int? jobId,
    String? driverId,
    String? expenseType,
    double? amount,
    DateTime? expDate,
    String? expenseDescription,
    String? otherDescription,
    String? slipImage,
    String? expenseLocation,
    String? approvedBy,
    DateTime? approvedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      driverId: driverId ?? this.driverId,
      expenseType: expenseType ?? this.expenseType,
      amount: amount ?? this.amount,
      expDate: expDate ?? this.expDate,
      expenseDescription: expenseDescription ?? this.expenseDescription,
      otherDescription: otherDescription ?? this.otherDescription,
      slipImage: slipImage ?? this.slipImage,
      expenseLocation: expenseLocation ?? this.expenseLocation,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if this expense is approved
  bool get isApproved => approvedBy != null && approvedAt != null;

  /// Get display description (expense_description or other_description)
  String get displayDescription {
    if (expenseType == 'other' && otherDescription != null) {
      return otherDescription!;
    }
    return expenseDescription ?? expenseType;
  }
}

/// Result from approve_job_expenses RPC
class ExpenseApprovalResult {
  final int approvedCount;
  final double approvedTotal;

  ExpenseApprovalResult({
    required this.approvedCount,
    required this.approvedTotal,
  });

  factory ExpenseApprovalResult.fromMap(Map<String, dynamic> map) {
    return ExpenseApprovalResult(
      approvedCount: (map['approved_count'] as num).toInt(),
      approvedTotal: (map['approved_total'] as num).toDouble(),
    );
  }
}

