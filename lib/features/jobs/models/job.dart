class Job {
  final String id;
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
  final String? cancelReason;
  final String? location; // Branch location (Jhb, Cpt, Dbn)
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool? driverConfirmation; // Whether driver confirmed receiving the job (legacy field)
  final bool? isConfirmed; // New confirmation field
  final DateTime? confirmedAt; // When the job was confirmed
  final String? confirmedBy; // Who confirmed the job

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
    this.cancelReason,
    this.location,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.driverConfirmation,
    this.isConfirmed,
    this.confirmedAt,
    this.confirmedBy,
  });

  factory Job.fromMap(Map<String, dynamic> map) {
    return Job(
      id: map['id']?.toString() ?? '',
      clientId: map['client_id']?.toString() ?? '',
      agentId: map['agent_id']?.toString(),
      vehicleId: map['vehicle_id']?.toString() ?? '',
      driverId: map['driver_id']?.toString() ?? '',
      jobStartDate: DateTime.parse(map['job_start_date']?.toString() ?? DateTime.now().toIso8601String()),
      orderDate: DateTime.parse(map['order_date']?.toString() ?? DateTime.now().toIso8601String()),
      passengerName: map['passenger_name']?.toString(),
      passengerContact: map['passenger_contact']?.toString(),
      pasCount: (map['pax'] is num) ? (map['pax'] as num).toDouble() : double.tryParse(map['pax']?.toString() ?? '0') ?? 0.0,
      luggageCount: map['number_bags']?.toString() ?? '',
      notes: map['notes']?.toString(),
      collectPayment: map['amount_collect'] == true,
      paymentAmount: (map['amount'] is num) ? (map['amount'] as num).toDouble() : double.tryParse(map['amount']?.toString() ?? ''),
      status: map['job_status']?.toString() ?? 'open',
      quoteNo: map['quote_no']?.toString(),
      voucherPdf: map['voucher_pdf']?.toString(),
      cancelReason: map['cancel_reason']?.toString(),
      location: map['location']?.toString(),
      createdBy: map['created_by']?.toString() ?? '',
      createdAt: DateTime.parse(map['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']?.toString() ?? DateTime.now().toIso8601String()) 
          : null,
      driverConfirmation: map['driver_confirm_ind'] == true,
      isConfirmed: map['is_confirmed'] == true,
      confirmedAt: map['confirmed_at'] != null 
          ? DateTime.parse(map['confirmed_at']?.toString() ?? DateTime.now().toIso8601String()) 
          : null,
      confirmedBy: map['confirmed_by']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // Don't include id if it's empty (let database auto-generate)
      if (id.isNotEmpty) 'id': int.tryParse(id) ?? id,
      'client_id': int.tryParse(clientId) ?? clientId,
      if (agentId != null) 'agent_id': int.tryParse(agentId!) ?? agentId,
      'vehicle_id': int.tryParse(vehicleId) ?? vehicleId,
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
      'cancel_reason': cancelReason,
      'location': location,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'driver_confirm_ind': driverConfirmation,
      'is_confirmed': isConfirmed,
      if (confirmedAt != null) 'confirmed_at': confirmedAt!.toIso8601String(),
      'confirmed_by': confirmedBy,
    };
  }

  Job copyWith({
    String? id,
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
    String? cancelReason,
    String? location,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? driverConfirmation,
    bool? isConfirmed,
    DateTime? confirmedAt,
    String? confirmedBy,
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
      cancelReason: cancelReason ?? this.cancelReason,
      location: location ?? this.location,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      driverConfirmation: driverConfirmation ?? this.driverConfirmation,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      confirmedBy: confirmedBy ?? this.confirmedBy,
    );
  }

  // Helper methods
  bool get isOpen => status == 'open';
  bool get isClosed => status == 'closed' || status == 'completed';
  bool get isInProgress => status == 'in_progress';
  
  bool get hasCompletePassengerDetails => 
      passengerName != null && 
      passengerName!.isNotEmpty && 
      passengerContact != null && 
      passengerContact!.isNotEmpty;

  int get daysUntilStart {
    final now = DateTime.now();
    final startDate = DateTime(jobStartDate.year, jobStartDate.month, jobStartDate.day);
    final today = DateTime(now.year, now.month, now.day);
    return startDate.difference(today).inDays;
  }

  String get daysUntilStartText {
    if (daysUntilStart == 0) return 'Starts today';
    if (daysUntilStart < 0) return 'Started ${daysUntilStart.abs()} days ago';
    return 'Starts in $daysUntilStart days';
  }
} 