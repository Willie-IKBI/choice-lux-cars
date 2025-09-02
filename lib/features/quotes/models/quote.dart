import 'package:choice_lux_cars/shared/utils/sa_time_utils.dart';

class Quote {
  final String id;
  final String clientId;
  final String? agentId;
  final String? vehicleId;
  final String? driverId;
  final DateTime jobDate;
  final String? vehicleType;
  final String quoteStatus;
  final double pasCount;
  final String luggage;
  final String? passengerName;
  final String? passengerContact;
  final String? notes;
  final String? quotePdf;
  final DateTime quoteDate;
  final double? quoteAmount;
  final String? quoteTitle;
  final String? quoteDescription;
  final String? location;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Quote({
    required this.id,
    required this.clientId,
    this.agentId,
    this.vehicleId,
    this.driverId,
    required this.jobDate,
    this.vehicleType,
    required this.quoteStatus,
    required this.pasCount,
    required this.luggage,
    this.passengerName,
    this.passengerContact,
    this.notes,
    this.quotePdf,
    required this.quoteDate,
    this.quoteAmount,
    this.quoteTitle,
    this.quoteDescription,
    this.location,
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote(
      id: map['id']?.toString() ?? '',
      clientId: map['client_id']?.toString() ?? '',
      agentId: map['agent_id']?.toString(),
      vehicleId: map['vehicle_id']?.toString(),
      driverId: map['driver_id']?.toString(),
      jobDate: DateTime.parse(
        map['job_date']?.toString() ?? SATimeUtils.getCurrentSATimeISO(),
      ),
      vehicleType: map['vehicle_type']?.toString(),
      quoteStatus: map['quote_status']?.toString() ?? 'draft',
      pasCount: (map['pax'] is num)
          ? (map['pax'] as num).toDouble()
          : double.tryParse(map['pax']?.toString() ?? '0') ?? 0.0,
      luggage: map['luggage']?.toString() ?? '',
      passengerName: map['passenger_name']?.toString(),
      passengerContact: map['passenger_contact']?.toString(),
      notes: map['notes']?.toString(),
      quotePdf: map['quote_pdf']?.toString(),
      quoteDate: DateTime.parse(
        map['quote_date']?.toString() ?? SATimeUtils.getCurrentSATimeISO(),
      ),
      quoteAmount: (map['quote_amount'] is num)
          ? (map['quote_amount'] as num).toDouble()
          : double.tryParse(map['quote_amount']?.toString() ?? ''),
      quoteTitle: map['quote_title']?.toString(),
      quoteDescription: map['quote_description']?.toString(),
      location: map['location']?.toString(),
      createdBy:
          null, // Remove created_by field as it doesn't exist in database
      createdAt: DateTime.parse(
        map['created_at']?.toString() ?? SATimeUtils.getCurrentSATimeISO(),
      ),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(
              map['updated_at']?.toString() ??
                  SATimeUtils.getCurrentSATimeISO(),
            )
          : null,
    );
  }

  factory Quote.fromJson(Map<String, dynamic> json) => Quote.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': int.tryParse(id) ?? id,
      'client_id': int.tryParse(clientId) ?? clientId,
      if (agentId != null) 'agent_id': int.tryParse(agentId!) ?? agentId,
      if (vehicleId != null)
        'vehicle_id': int.tryParse(vehicleId!) ?? vehicleId,
      if (driverId != null) 'driver_id': driverId,
      'job_date': jobDate.toIso8601String(),
      'vehicle_type': vehicleType,
      'quote_status': quoteStatus,
      'pax': pasCount,
      'luggage': luggage,
      'passenger_name': passengerName,
      'passenger_contact': passengerContact,
      'notes': notes,
      'quote_pdf': quotePdf,
      'quote_date': quoteDate.toIso8601String(),
      'quote_amount': quoteAmount,
      'quote_title': quoteTitle,
      'quote_description': quoteDescription,
      'location': location,
      // 'created_by': createdBy, // Remove created_by field as it doesn't exist in database
      'created_at': createdAt.toIso8601String(),
      'updated_at':
          updatedAt?.toIso8601String() ?? SATimeUtils.getCurrentSATimeISO(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  Quote copyWith({
    String? id,
    String? clientId,
    String? agentId,
    String? vehicleId,
    String? driverId,
    DateTime? jobDate,
    String? vehicleType,
    String? quoteStatus,
    double? pasCount,
    String? luggage,
    String? passengerName,
    String? passengerContact,
    String? notes,
    String? quotePdf,
    DateTime? quoteDate,
    double? quoteAmount,
    String? quoteTitle,
    String? quoteDescription,
    String? location,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Quote(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      agentId: agentId ?? this.agentId,
      vehicleId: vehicleId ?? this.vehicleId,
      driverId: driverId ?? this.driverId,
      jobDate: jobDate ?? this.jobDate,
      vehicleType: vehicleType ?? this.vehicleType,
      quoteStatus: quoteStatus ?? this.quoteStatus,
      pasCount: pasCount ?? this.pasCount,
      luggage: luggage ?? this.luggage,
      passengerName: passengerName ?? this.passengerName,
      passengerContact: passengerContact ?? this.passengerContact,
      notes: notes ?? this.notes,
      quotePdf: quotePdf ?? this.quotePdf,
      quoteDate: quoteDate ?? this.quoteDate,
      quoteAmount: quoteAmount ?? this.quoteAmount,
      quoteTitle: quoteTitle ?? this.quoteTitle,
      quoteDescription: quoteDescription ?? this.quoteDescription,
      location: location ?? this.location,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isOpen => quoteStatus == 'open' || quoteStatus == 'draft';
  bool get isAccepted => quoteStatus == 'accepted';
  bool get isExpired => quoteStatus == 'expired';
  bool get isClosed => quoteStatus == 'closed' || quoteStatus == 'rejected';

  bool get hasCompletePassengerDetails =>
      passengerName != null &&
      passengerName!.isNotEmpty &&
      passengerContact != null &&
      passengerContact!.isNotEmpty;

  int get daysUntilJobDate {
    final now = DateTime.now();
    final jobDateOnly = DateTime(jobDate.year, jobDate.month, jobDate.day);
    final today = DateTime(now.year, now.month, now.day);
    return jobDateOnly.difference(today).inDays;
  }

  String get daysUntilJobDateText {
    if (daysUntilJobDate == 0) return 'Today';
    if (daysUntilJobDate < 0) return '${daysUntilJobDate.abs()} days ago';
    return 'In $daysUntilJobDate days';
  }

  String get statusDisplayName {
    switch (quoteStatus.toLowerCase()) {
      case 'draft':
        return 'Draft';
      case 'open':
        return 'Open';
      case 'sent':
        return 'Sent';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'expired':
        return 'Expired';
      case 'closed':
        return 'Closed';
      default:
        return quoteStatus;
    }
  }
}
