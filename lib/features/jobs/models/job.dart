import 'package:flutter/material.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/utils/sa_time_utils.dart';

// Job status enum for type-safe status handling
enum JobStatus {
  open,
  assigned,
  started,
  inProgress,
  readyToClose,
  completed,
  cancelled,
}

// Extension for JobStatus to provide labels and colors
extension JobStatusX on JobStatus {
  String get label => switch (this) {
    JobStatus.open => 'OPEN',
    JobStatus.assigned => 'ASSIGNED',
    JobStatus.started => 'STARTED',
    JobStatus.inProgress => 'IN PROGRESS',
    JobStatus.readyToClose => 'READY TO CLOSE',
    JobStatus.completed => 'COMPLETED',
    JobStatus.cancelled => 'CANCELLED',
  };

  Color get color => switch (this) {
    JobStatus.open => ChoiceLuxTheme.platinumSilver,
    JobStatus.assigned => ChoiceLuxTheme.richGold,
    JobStatus.started => ChoiceLuxTheme.orange,
    JobStatus.inProgress => ChoiceLuxTheme.infoColor,
    JobStatus.readyToClose => ChoiceLuxTheme.purple,
    JobStatus.completed => ChoiceLuxTheme.successColor,
    JobStatus.cancelled => ChoiceLuxTheme.errorColor,
  };

  // Convert string to JobStatus enum
  static JobStatus fromString(String status) {
    return switch (status.toLowerCase()) {
      'open' => JobStatus.open,
      'assigned' => JobStatus.assigned,
      'started' => JobStatus.started,
      'in_progress' => JobStatus.inProgress,
      'ready_to_close' => JobStatus.readyToClose,
      'completed' => JobStatus.completed,
      'cancelled' => JobStatus.cancelled,
      _ => JobStatus.open, // Default fallback
    };
  }

  // Convert JobStatus enum to string
  String get value => switch (this) {
    JobStatus.open => 'open',
    JobStatus.assigned => 'assigned',
    JobStatus.started => 'started',
    JobStatus.inProgress => 'in_progress',
    JobStatus.readyToClose => 'ready_to_close',
    JobStatus.completed => 'completed',
    JobStatus.cancelled => 'cancelled',
  };
}

class Job {
  final int id;
  final String clientId;
  final String? agentId;
  final String vehicleId;
  final String driverId;
  final DateTime jobStartDate;
  final DateTime orderDate;
  final String? passengerName;
  final String? passengerContact;
  final double pasCount; // Number of customers (pax)
  final String luggageCount; // Number of bags (number_bags as text)
  final String? notes;
  final bool collectPayment;
  final double? paymentAmount;
  final String status; // open, closed, in_progress
  final String? quoteNo;
  final String? voucherPdf;
  final String? invoicePdf;
  final String? cancelReason;
  final String? location; // Branch location (Jhb, Cpt, Dbn)
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool?
  driverConfirmation; // Whether driver confirmed receiving the job (legacy field)
  final bool? isConfirmed; // New confirmation field
  final DateTime? confirmedAt; // When the job was confirmed
  final String? confirmedBy; // Who confirmed the job
  final String? jobNumber; // Job number for display purposes

  Job({
    required this.id,
    required this.clientId,
    this.agentId,
    required this.vehicleId,
    required this.driverId,
    required this.jobStartDate,
    required this.orderDate,
    this.passengerName,
    this.passengerContact,
    required this.pasCount,
    required this.luggageCount,
    this.notes,
    required this.collectPayment,
    this.paymentAmount,
    required this.status,
    this.quoteNo,
    this.voucherPdf,
    this.invoicePdf,
    this.cancelReason,
    this.location,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.driverConfirmation,
    this.isConfirmed,
    this.confirmedAt,
    this.confirmedBy,
    this.jobNumber,
  });

  // Getter for JobStatus enum
  JobStatus get statusEnum => JobStatusX.fromString(status);

  // Getter for days until start with null safety
  int? get daysUntilStart {
    final now = DateTime.now();
    final start = jobStartDate;
    return start.difference(now).inDays;
  }

  static DateTime _parseDateTime(dynamic value, DateTime fallback) {
    if (value == null) return fallback;
    final str = value.toString().trim();
    if (str.isEmpty) return fallback;
    return DateTime.tryParse(str) ?? fallback;
  }

  factory Job.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    return Job(
      id: (map['id'] is int) ? map['id'] as int : (int.tryParse(map['id']?.toString() ?? '') ?? 0),
      clientId: map['client_id']?.toString() ?? '',
      agentId: map['agent_id']?.toString(),
      vehicleId: map['vehicle_id']?.toString() ?? '',
      driverId: map['driver_id']?.toString() ?? '',
      jobStartDate: _parseDateTime(map['job_start_date'], now),
      orderDate: _parseDateTime(map['order_date'], now),
      passengerName: map['passenger_name']?.toString(),
      passengerContact: map['passenger_contact']?.toString(),
      pasCount: (map['pax'] is num)
          ? (map['pax'] as num).toDouble()
          : double.tryParse(map['pax']?.toString() ?? '0') ?? 0.0,
      luggageCount: map['number_bags']?.toString() ?? '',
      notes: map['notes']?.toString(),
      collectPayment: map['amount_collect'] == true,
      paymentAmount: (map['amount'] is num)
          ? (map['amount'] as num).toDouble()
          : double.tryParse(map['amount']?.toString() ?? ''),
      status: map['job_status']?.toString() ?? 'open',
      quoteNo: map['quote_no']?.toString(),
      voucherPdf: map['voucher_pdf']?.toString(),
      invoicePdf: map['invoice_pdf']?.toString(),
      cancelReason: map['cancel_reason']?.toString(),
      location: map['location']?.toString(),
      createdBy: map['created_by']?.toString() ?? '',
      createdAt: _parseDateTime(map['created_at'], now),
      updatedAt: map['updated_at'] != null
          ? _parseDateTime(map['updated_at'], now)
          : null,
      driverConfirmation: map['driver_confirm_ind'] == true,
      isConfirmed:
          map['is_confirmed'] == true || map['driver_confirm_ind'] == true,
      confirmedAt: map['confirmed_at'] != null
          ? _parseDateTime(map['confirmed_at'], now)
          : null,
      confirmedBy: map['confirmed_by']?.toString(),
      jobNumber: map['job_number']?.toString(),
    );
  }

  factory Job.fromJson(Map<String, dynamic> json) => Job.fromMap(json);

  /// Helper method for safe int parsing from String
  /// Throws FormatException if value cannot be converted to int
  static int _parseToInt(String value, String fieldName) {
    final parsed = int.tryParse(value);
    if (parsed == null) {
      throw FormatException(
        'Invalid $fieldName: "$value" cannot be converted to integer',
      );
    }
    return parsed;
  }

  /// Convert Job to map for database operations
  /// Use toUpdateMap() for updates to exclude immutable fields
  Map<String, dynamic> toMap() {
    return {
      // Don't include id if it's empty (let database auto-generate)
      if (id != 0) 'id': id,
      'client_id': _parseToInt(clientId, 'client_id'),
      if (agentId != null && agentId!.isNotEmpty) 
        'agent_id': _parseToInt(agentId!, 'agent_id'),
      'vehicle_id': _parseToInt(vehicleId, 'vehicle_id'),
      'driver_id': driverId, // Keep as UUID string
      'job_start_date': jobStartDate.toIso8601String(),
      'order_date': orderDate.toIso8601String(),
      'passenger_name': passengerName,
      'passenger_contact': passengerContact,
      'pax': pasCount,
      'number_bags': luggageCount,
      'notes': notes,
      'amount_collect': collectPayment,
      'amount': paymentAmount,
      'job_status': status,
      'quote_no': quoteNo,
      'voucher_pdf': voucherPdf,
      'invoice_pdf': invoicePdf,
      'cancel_reason': cancelReason,
      'location': location,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at':
          updatedAt?.toIso8601String() ?? SATimeUtils.getCurrentSATimeISO(),
      'driver_confirm_ind': driverConfirmation,
      'is_confirmed': isConfirmed,
      if (confirmedAt != null) 'confirmed_at': confirmedAt!.toIso8601String(),
      'confirmed_by': confirmedBy,
      'job_number': jobNumber,
    };
  }

  /// Convert Job to map for UPDATE operations
  /// Excludes immutable fields (id, created_at) that shouldn't be updated
  Map<String, dynamic> toUpdateMap() {
    final map = toMap();
    // Remove immutable fields that shouldn't be in update payload
    map.remove('id');
    map.remove('created_at');
    return map;
  }

  Map<String, dynamic> toJson() => toMap();

  Job copyWith({
    int? id,
    String? clientId,
    String? agentId,
    String? vehicleId,
    String? driverId,
    DateTime? jobStartDate,
    DateTime? orderDate,
    String? passengerName,
    String? passengerContact,
    double? pasCount,
    String? luggageCount,
    String? notes,
    bool? collectPayment,
    double? paymentAmount,
    String? status,
    String? quoteNo,
    String? voucherPdf,
    String? invoicePdf,
    String? cancelReason,
    String? location,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? driverConfirmation,
    bool? isConfirmed,
    DateTime? confirmedAt,
    String? confirmedBy,
    String? jobNumber,
  }) {
    return Job(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      agentId: agentId ?? this.agentId,
      vehicleId: vehicleId ?? this.vehicleId,
      driverId: driverId ?? this.driverId,
      jobStartDate: jobStartDate ?? this.jobStartDate,
      orderDate: orderDate ?? this.orderDate,
      passengerName: passengerName ?? this.passengerName,
      passengerContact: passengerContact ?? this.passengerContact,
      pasCount: pasCount ?? this.pasCount,
      luggageCount: luggageCount ?? this.luggageCount,
      notes: notes ?? this.notes,
      collectPayment: collectPayment ?? this.collectPayment,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      status: status ?? this.status,
      quoteNo: quoteNo ?? this.quoteNo,
      voucherPdf: voucherPdf ?? this.voucherPdf,
      invoicePdf: invoicePdf ?? this.invoicePdf,
      cancelReason: cancelReason ?? this.cancelReason,
      location: location ?? this.location,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      driverConfirmation: driverConfirmation ?? this.driverConfirmation,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      confirmedBy: confirmedBy ?? this.confirmedBy,
      jobNumber: jobNumber ?? this.jobNumber,
    );
  }

  // Helper methods
  bool get isOpen => status == 'open' || status == 'assigned';
  bool get isClosed => status == 'completed' || status == 'cancelled';
  bool get isInProgress =>
      status == 'started' ||
      status == 'in_progress' ||
      status == 'ready_to_close';
  bool get isStarted => status == 'started';
  bool get isReadyToClose => status == 'ready_to_close';

  bool get hasCompletePassengerDetails =>
      passengerName != null &&
      passengerName!.isNotEmpty &&
      passengerContact != null &&
      passengerContact!.isNotEmpty;

  String get daysUntilStartText {
    if (daysUntilStart == 0) return 'Starts today';
    if (daysUntilStart == null) return 'Unknown start date';
    if (daysUntilStart! < 0) return 'Started ${daysUntilStart!.abs()} days ago';
    return 'Starts in ${daysUntilStart!} days';
  }
}
