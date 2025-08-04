class Trip {
  final String id;
  final String jobId;
  final DateTime tripDateTime;
  final String pickUpAddress;
  final String dropOffAddress;
  final String? notes;
  final double amount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Trip({
    required this.id,
    required this.jobId,
    required this.tripDateTime,
    required this.pickUpAddress,
    required this.dropOffAddress,
    this.notes,
    required this.amount,
    required this.createdAt,
    this.updatedAt,
  });

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'] as String,
      jobId: map['job_id'] as String,
      tripDateTime: DateTime.parse(map['trip_date_time'] as String),
      pickUpAddress: map['pick_up_address'] as String,
      dropOffAddress: map['drop_off_address'] as String,
      notes: map['notes'] as String?,
      amount: (map['amount'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'job_id': jobId,
      'trip_date_time': tripDateTime.toIso8601String(),
      'pick_up_address': pickUpAddress,
      'drop_off_address': dropOffAddress,
      'notes': notes,
      'amount': amount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Trip copyWith({
    String? id,
    String? jobId,
    DateTime? tripDateTime,
    String? pickUpAddress,
    String? dropOffAddress,
    String? notes,
    double? amount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Trip(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      tripDateTime: tripDateTime ?? this.tripDateTime,
      pickUpAddress: pickUpAddress ?? this.pickUpAddress,
      dropOffAddress: dropOffAddress ?? this.dropOffAddress,
      notes: notes ?? this.notes,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  String get shortSummary {
    final date = '${tripDateTime.day}/${tripDateTime.month}/${tripDateTime.year}';
    final time = '${tripDateTime.hour.toString().padLeft(2, '0')}:${tripDateTime.minute.toString().padLeft(2, '0')}';
    return '$date at $time - ${pickUpAddress.split(',').first} to ${dropOffAddress.split(',').first}';
  }

  String get formattedDateTime {
    final date = '${tripDateTime.day}/${tripDateTime.month}/${tripDateTime.year}';
    final time = '${tripDateTime.hour.toString().padLeft(2, '0')}:${tripDateTime.minute.toString().padLeft(2, '0')}';
    return '$date at $time';
  }
} 