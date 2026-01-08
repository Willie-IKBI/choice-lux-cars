/// Expense model for job expenses
class Expense {
  final int id;
  final int jobId;
  final String driverId;
  final String expenseType;
  final double amount;
  final DateTime expDate;
  final String? expenseDescription;
  final String? otherDescription;
  final String? slipImage;
  final String? expenseLocation;
  final String? approvedBy;
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

  /// Check if expense is approved
  bool get isApproved => approvedAt != null && approvedBy != null;

  /// Get display description
  String get displayDescription {
    if (expenseType == 'other' && otherDescription != null) {
      return otherDescription!;
    }
    if (expenseDescription != null && expenseDescription!.isNotEmpty) {
      return expenseDescription!;
    }
    return expenseType.toUpperCase();
  }

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
}
