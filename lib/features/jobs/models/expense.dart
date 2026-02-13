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

  /// Parse from database JSON. DB uses exp_amount; supports both for backward compatibility.
  factory Expense.fromJson(Map<String, dynamic> json) {
    final amountRaw = json['exp_amount'] ?? json['amount'];
    final amount = (amountRaw is num)
        ? amountRaw.toDouble()
        : double.tryParse(amountRaw?.toString() ?? '0') ?? 0.0;

    return Expense(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      jobId: int.tryParse(json['job_id']?.toString() ?? '') ?? 0,
      driverId: json['driver_id']?.toString() ?? '',
      expenseType: json['expense_type']?.toString() ?? 'other',
      amount: amount,
      expDate: json['exp_date'] != null
          ? DateTime.parse(json['exp_date'].toString())
          : DateTime.now(),
      expenseDescription: json['expense_description']?.toString(),
      otherDescription: json['other_description']?.toString(),
      slipImage: json['slip_image']?.toString(),
      expenseLocation: json['expense_location']?.toString(),
      approvedBy: json['approved_by']?.toString(),
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
    );
  }

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
