
class VoucherData {
  final int jobId;
  final String? quoteNo;
  final DateTime? quoteDate;
  final String companyName;
  final String? companyLogo;
  final String? clientWebsite;
  final String? clientContactPhone;
  final String? clientContactEmail;
  final String? clientRegistrationNumber;
  final String? clientVatNumber;
  final String agentName;
  final String agentContact;
  final String passengerName;
  final String passengerContact;
  final int numberPassengers;
  final String luggage;
  final String driverName;
  final String driverContact;
  final String vehicleType;
  final List<TransportDetail> transport;
  final String notes;

  VoucherData({
    required this.jobId,
    this.quoteNo,
    this.quoteDate,
    required this.companyName,
    this.companyLogo,
    this.clientWebsite,
    this.clientContactPhone,
    this.clientContactEmail,
    this.clientRegistrationNumber,
    this.clientVatNumber,
    required this.agentName,
    required this.agentContact,
    required this.passengerName,
    required this.passengerContact,
    required this.numberPassengers,
    required this.luggage,
    required this.driverName,
    required this.driverContact,
    required this.vehicleType,
    required this.transport,
    required this.notes,
  });

  factory VoucherData.fromJson(Map<String, dynamic> json) {
    return VoucherData(
      jobId: json['job_id'] as int,
      quoteNo: json['quote_no']?.toString(),
      quoteDate: json['quote_date'] != null
          ? DateTime.tryParse(json['quote_date'].toString())
          : null,
      companyName: json['company_name']?.toString() ?? 'Choice Lux Cars',
      companyLogo: json['company_logo']?.toString(),
      clientWebsite: json['client_website']?.toString(),
      clientContactPhone: json['client_contact_phone']?.toString(),
      clientContactEmail: json['client_contact_email']?.toString(),
      clientRegistrationNumber: json['client_registration']?.toString(),
      clientVatNumber: json['client_vat_number']?.toString(),
      agentName: json['agent_name']?.toString() ?? 'Not available',
      agentContact: json['agent_contact']?.toString() ?? 'Not available',
      passengerName: json['passenger_name']?.toString() ?? 'Not specified',
      passengerContact:
          json['passenger_contact']?.toString() ?? 'Not specified',
      numberPassengers: (json['number_passangers'] is num)
          ? (json['number_passangers'] as num).toInt()
          : int.tryParse(json['number_passangers']?.toString() ?? '0') ?? 0,
      luggage: json['luggage']?.toString() ?? 'Not specified',
      driverName: json['driver_name']?.toString() ?? 'Not assigned',
      driverContact: json['driver_contact']?.toString() ?? 'Not available',
      vehicleType: json['vehicle_type']?.toString() ?? 'Not assigned',
      transport:
          (json['transport_details'] as List<dynamic>?)
              ?.map(
                (item) =>
                    TransportDetail.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      notes: json['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_id': jobId,
      'quote_no': quoteNo,
      'quote_date': quoteDate?.toIso8601String(),
      'company_name': companyName,
      'company_logo': companyLogo,
      'client_website': clientWebsite,
      'client_contact_phone': clientContactPhone,
      'client_contact_email': clientContactEmail,
      'client_registration': clientRegistrationNumber,
      'client_vat_number': clientVatNumber,
      'agent_name': agentName,
      'agent_contact': agentContact,
      'passenger_name': passengerName,
      'passenger_contact': passengerContact,
      'number_passangers': numberPassengers,
      'luggage': luggage,
      'driver_name': driverName,
      'driver_contact': driverContact,
      'vehicle_type': vehicleType,
      'transport': transport.map((t) => t.toJson()).toList(),
      'notes': notes,
    };
  }

  // Helper methods
  bool get hasLogo => companyLogo != null && companyLogo!.isNotEmpty;
  bool get hasTransportDetails => transport.isNotEmpty;
  bool get hasNotes => notes.isNotEmpty && notes != 'Not specified';

  String get formattedQuoteDate {
    if (quoteDate == null) return 'Not specified';
    return '${quoteDate!.day.toString().padLeft(2, '0')} ${_getMonthName(quoteDate!.month)} ${quoteDate!.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  // Get preferred phone number for WhatsApp sharing (agent first, then passenger)
  String get preferredPhoneNumber {
    if (agentContact.isNotEmpty && agentContact != 'Not available') {
      return agentContact;
    }
    if (passengerContact.isNotEmpty && passengerContact != 'Not specified') {
      return passengerContact;
    }
    return '';
  }

  VoucherData copyWith({
    int? jobId,
    String? quoteNo,
    DateTime? quoteDate,
    String? companyName,
    String? companyLogo,
    String? clientWebsite,
    String? clientContactPhone,
    String? clientContactEmail,
    String? clientRegistrationNumber,
    String? clientVatNumber,
    String? agentName,
    String? agentContact,
    String? passengerName,
    String? passengerContact,
    int? numberPassengers,
    String? luggage,
    String? driverName,
    String? driverContact,
    String? vehicleType,
    List<TransportDetail>? transport,
    String? notes,
  }) {
    return VoucherData(
      jobId: jobId ?? this.jobId,
      quoteNo: quoteNo ?? this.quoteNo,
      quoteDate: quoteDate ?? this.quoteDate,
      companyName: companyName ?? this.companyName,
      companyLogo: companyLogo ?? this.companyLogo,
      clientWebsite: clientWebsite ?? this.clientWebsite,
      clientContactPhone: clientContactPhone ?? this.clientContactPhone,
      clientContactEmail: clientContactEmail ?? this.clientContactEmail,
      clientRegistrationNumber: clientRegistrationNumber ?? this.clientRegistrationNumber,
      clientVatNumber: clientVatNumber ?? this.clientVatNumber,
      agentName: agentName ?? this.agentName,
      agentContact: agentContact ?? this.agentContact,
      passengerName: passengerName ?? this.passengerName,
      passengerContact: passengerContact ?? this.passengerContact,
      numberPassengers: numberPassengers ?? this.numberPassengers,
      luggage: luggage ?? this.luggage,
      driverName: driverName ?? this.driverName,
      driverContact: driverContact ?? this.driverContact,
      vehicleType: vehicleType ?? this.vehicleType,
      transport: transport ?? this.transport,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'VoucherData(jobId: $jobId, companyName: $companyName, passengerName: $passengerName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VoucherData && other.jobId == jobId;
  }

  @override
  int get hashCode => jobId.hashCode;
}

class TransportDetail {
  final DateTime? pickupDate;
  final String? pickupTime;
  final String pickupLocation;
  final String dropoffLocation;

  TransportDetail({
    this.pickupDate,
    this.pickupTime,
    required this.pickupLocation,
    required this.dropoffLocation,
  });

  factory TransportDetail.fromJson(Map<String, dynamic> json) {
    return TransportDetail(
      pickupDate: json['pickup_date'] != null
          ? DateTime.tryParse(json['pickup_date'].toString())
          : null,
      pickupTime: json['pickup_time'] != null
          ? DateTime.tryParse(json['pickup_time'].toString())?.toString().substring(11, 16) // Gets HH:MM format
          : null,
      pickupLocation: json['pickup_location']?.toString() ?? 'Not specified',
      dropoffLocation: json['dropoff_location']?.toString() ?? 'Not specified',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pickup_date': pickupDate?.toIso8601String(),
      'pickup_time': pickupTime,
      'pickup_location': pickupLocation,
      'dropoff_location': dropoffLocation,
    };
  }

  String get formattedPickupDate {
    if (pickupDate == null) return 'Not specified';
    return '${pickupDate!.day.toString().padLeft(2, '0')} ${_getMonthName(pickupDate!.month)} ${pickupDate!.year}';
  }

  String get formattedPickupTime {
    if (pickupTime == null) return 'Not specified';
    return pickupTime!;
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  @override
  String toString() {
    return 'TransportDetail(pickupLocation: $pickupLocation, dropoffLocation: $dropoffLocation)';
  }
}
