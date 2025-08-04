class Job {
  final String id;
  final String clientId;
  final String? agentId;
  final String branch; // Jhb, Cpt, Dbn
  final String vehicleId;
  final String driverId;
  final DateTime jobStartDate;
  final DateTime orderDate;
  final String? passengerName;
  final String? passengerContact;
  final int pasCount; // Number of customers
  final int luggageCount; // Number of bags
  final String? notes;
  final bool collectPayment;
  final double? paymentAmount;
  final String status; // open, closed, in_progress
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Job({
    required this.id,
    required this.clientId,
    this.agentId,
    required this.branch,
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
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  factory Job.fromMap(Map<String, dynamic> map) {
    return Job(
      id: map['id'] as String,
      clientId: map['client_id'] as String,
      agentId: map['agent_id'] as String?,
      branch: map['branch'] as String,
      vehicleId: map['vehicle_id'] as String,
      driverId: map['driver_id'] as String,
      jobStartDate: DateTime.parse(map['job_start_date'] as String),
      orderDate: DateTime.parse(map['order_date'] as String),
      passengerName: map['passenger_name'] as String?,
      passengerContact: map['passenger_contact'] as String?,
      pasCount: map['pas_count'] as int,
      luggageCount: map['luggage_count'] as int,
      notes: map['notes'] as String?,
      collectPayment: map['collect_payment'] as bool,
      paymentAmount: map['payment_amount'] as double?,
      status: map['status'] as String,
      createdBy: map['created_by'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_id': clientId,
      'agent_id': agentId,
      'branch': branch,
      'vehicle_id': vehicleId,
      'driver_id': driverId,
      'job_start_date': jobStartDate.toIso8601String(),
      'order_date': orderDate.toIso8601String(),
      'passenger_name': passengerName,
      'passenger_contact': passengerContact,
      'pas_count': pasCount,
      'luggage_count': luggageCount,
      'notes': notes,
      'collect_payment': collectPayment,
      'payment_amount': paymentAmount,
      'status': status,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Job copyWith({
    String? id,
    String? clientId,
    String? agentId,
    String? branch,
    String? vehicleId,
    String? driverId,
    DateTime? jobStartDate,
    DateTime? orderDate,
    String? passengerName,
    String? passengerContact,
    int? pasCount,
    int? luggageCount,
    String? notes,
    bool? collectPayment,
    double? paymentAmount,
    String? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Job(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      agentId: agentId ?? this.agentId,
      branch: branch ?? this.branch,
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
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isOpen => status == 'open';
  bool get isClosed => status == 'closed';
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