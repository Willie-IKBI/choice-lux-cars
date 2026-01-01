import 'package:choice_lux_cars/shared/utils/sa_time_utils.dart';

/// Model representing a trip progress row from the trip_progress table
/// 
/// This tracks the execution status of individual trips within a job.
/// Status transitions are enforced by database trigger:
/// pending -> pickup_arrived -> passenger_onboard -> dropoff_arrived -> completed
class TripProgress {
  final int id;
  final int jobId;
  final int tripIndex;
  final String status;
  final DateTime? pickupArrivedAt;
  final DateTime? passengerOnboardAt;
  final DateTime? dropoffArrivedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  TripProgress({
    required this.id,
    required this.jobId,
    required this.tripIndex,
    required this.status,
    this.pickupArrivedAt,
    this.passengerOnboardAt,
    this.dropoffArrivedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TripProgress.fromMap(Map<String, dynamic> map) {
    return TripProgress(
      id: (map['id'] as num).toInt(),
      jobId: (map['job_id'] as num).toInt(),
      tripIndex: (map['trip_index'] as num).toInt(),
      status: map['status'] as String,
      pickupArrivedAt: map['pickup_arrived_at'] != null
          ? DateTime.parse(map['pickup_arrived_at'] as String)
          : null,
      passengerOnboardAt: map['passenger_onboard_at'] != null
          ? DateTime.parse(map['passenger_onboard_at'] as String)
          : null,
      dropoffArrivedAt: map['dropoff_arrived_at'] != null
          ? DateTime.parse(map['dropoff_arrived_at'] as String)
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  factory TripProgress.fromJson(Map<String, dynamic> json) => TripProgress.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'job_id': jobId,
      'trip_index': tripIndex,
      'status': status,
      'pickup_arrived_at': pickupArrivedAt?.toIso8601String(),
      'passenger_onboard_at': passengerOnboardAt?.toIso8601String(),
      'dropoff_arrived_at': dropoffArrivedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  TripProgress copyWith({
    int? id,
    int? jobId,
    int? tripIndex,
    String? status,
    DateTime? pickupArrivedAt,
    DateTime? passengerOnboardAt,
    DateTime? dropoffArrivedAt,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TripProgress(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      tripIndex: tripIndex ?? this.tripIndex,
      status: status ?? this.status,
      pickupArrivedAt: pickupArrivedAt ?? this.pickupArrivedAt,
      passengerOnboardAt: passengerOnboardAt ?? this.passengerOnboardAt,
      dropoffArrivedAt: dropoffArrivedAt ?? this.dropoffArrivedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if this trip is completed
  bool get isCompleted => status == 'completed';

  /// Check if this trip is pending
  bool get isPending => status == 'pending';
}

