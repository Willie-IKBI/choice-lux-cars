import 'package:choice_lux_cars/shared/utils/sa_time_utils.dart';

class Trip {
  final String id;
  final int jobId;
  final DateTime pickupDate;
  final String pickupLocation;
  final String dropoffLocation;
  final DateTime? clientPickupTime;
  final DateTime? clientDropoffTime;
  final String? notes;
  final double amount;
  final String? status;

  Trip({
    required this.id,
    required this.jobId,
    required this.pickupDate,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.clientPickupTime,
    this.clientDropoffTime,
    this.notes,
    required this.amount,
    this.status,
  });

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id']?.toString() ?? '',
      jobId: int.tryParse(map['job_id']?.toString() ?? '0') ?? 0,
      pickupDate: DateTime.parse(
        map['pickup_date']?.toString() ?? SATimeUtils.getCurrentSATimeISO(),
      ),
      pickupLocation: map['pickup_location']?.toString() ?? '',
      dropoffLocation: map['dropoff_location']?.toString() ?? '',
      clientPickupTime: map['client_pickup_time'] != null
          ? DateTime.parse(
              map['client_pickup_time']?.toString() ??
                  SATimeUtils.getCurrentSATimeISO(),
            )
          : null,
      clientDropoffTime: map['client_dropoff_time'] != null
          ? DateTime.parse(
              map['client_dropoff_time']?.toString() ??
                  SATimeUtils.getCurrentSATimeISO(),
            )
          : null,
      notes: map['notes']?.toString(),
      amount: (map['amount'] is num)
          ? (map['amount'] as num).toDouble()
          : double.tryParse(map['amount']?.toString() ?? '0') ?? 0.0,
      status: map['status']?.toString(),
    );
  }

  factory Trip.fromJson(Map<String, dynamic> json) => Trip.fromMap(json);

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'job_id': jobId,
      'pickup_date': pickupDate.toIso8601String(),
      'pickup_location': pickupLocation,
      'dropoff_location': dropoffLocation,
      'client_pickup_time': clientPickupTime?.toIso8601String(),
      'client_dropoff_time': clientDropoffTime?.toIso8601String(),
      'notes': notes,
      'amount': amount,
      'status': status,
    };

    // Only include ID if it's not empty (for updates)
    if (id.isNotEmpty) {
      map['id'] = int.tryParse(id) ?? id;
    }

    return map;
  }

  Map<String, dynamic> toJson() => toMap();

  Trip copyWith({
    String? id,
    int? jobId,
    DateTime? pickupDate,
    String? pickupLocation,
    String? dropoffLocation,
    DateTime? clientPickupTime,
    DateTime? clientDropoffTime,
    String? notes,
    double? amount,
    String? status,
  }) {
    return Trip(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      pickupDate: pickupDate ?? this.pickupDate,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      clientPickupTime: clientPickupTime ?? this.clientPickupTime,
      clientDropoffTime: clientDropoffTime ?? this.clientDropoffTime,
      notes: notes ?? this.notes,
      amount: amount ?? this.amount,
      status: status ?? this.status,
    );
  }

  // Helper methods
  String get shortSummary {
    final date = '${pickupDate.day}/${pickupDate.month}/${pickupDate.year}';
    final time =
        '${pickupDate.hour.toString().padLeft(2, '0')}:${pickupDate.minute.toString().padLeft(2, '0')}';
    return '$date at $time - ${pickupLocation.split(',').first} to ${dropoffLocation.split(',').first}';
  }

  String get formattedDateTime {
    final date = '${pickupDate.day}/${pickupDate.month}/${pickupDate.year}';
    final time =
        '${pickupDate.hour.toString().padLeft(2, '0')}:${pickupDate.minute.toString().padLeft(2, '0')}';
    return '$date at $time';
  }
}
