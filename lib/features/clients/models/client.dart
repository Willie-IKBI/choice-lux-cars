enum ClientStatus {
  active,
  pending,
  vip,
  inactive,
}

class Client {
  final int? id;
  final String companyName;
  final String contactPerson;
  final String contactNumber;
  final String contactEmail;
  final String? companyLogo;
  final ClientStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  Client({
    this.id,
    required this.companyName,
    required this.contactPerson,
    required this.contactNumber,
    required this.contactEmail,
    this.companyLogo,
    this.status = ClientStatus.active,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  // Create from JSON
  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as int?,
      companyName: json['company_name'] as String,
      contactPerson: json['contact_person'] as String,
      contactNumber: json['contact_number'] as String,
      contactEmail: json['contact_email'] as String,
      companyLogo: json['company_logo'] as String?,
      status: _parseStatus(json['status'] as String?),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null 
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  static ClientStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'vip':
        return ClientStatus.vip;
      case 'pending':
        return ClientStatus.pending;
      case 'inactive':
        return ClientStatus.inactive;
      case 'active':
      default:
        return ClientStatus.active;
    }
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'company_name': companyName,
      'contact_person': contactPerson,
      'contact_number': contactNumber,
      'contact_email': contactEmail,
      if (companyLogo != null) 'company_logo': companyLogo,
      'status': status.name,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    };
  }

  // Create a copy with updated fields
  Client copyWith({
    int? id,
    String? companyName,
    String? contactPerson,
    String? contactNumber,
    String? contactEmail,
    String? companyLogo,
    ClientStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Client(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      contactPerson: contactPerson ?? this.contactPerson,
      contactNumber: contactNumber ?? this.contactNumber,
      contactEmail: contactEmail ?? this.contactEmail,
      companyLogo: companyLogo ?? this.companyLogo,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Client && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Client(id: $id, companyName: $companyName, contactPerson: $contactPerson)';
  }
} 