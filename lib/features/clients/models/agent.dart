class Agent {
  final int? id;
  final String agentName;
  final int clientKey;
  final String contactNumber;
  final String contactEmail;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;

  Agent({
    this.id,
    required this.agentName,
    required this.clientKey,
    required this.contactNumber,
    required this.contactEmail,
    this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  // Create from JSON
  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'] as int?,
      agentName: json['agent_name'] as String,
      clientKey: json['client_key'] as int,
      contactNumber: json['contact_number'] as String,
      contactEmail: json['contact_email'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      isDeleted: json['is_deleted'] as bool? ?? false,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'agent_name': agentName,
      'client_key': clientKey,
      'contact_number': contactNumber,
      'contact_email': contactEmail,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  // Create a copy with updated fields
  Agent copyWith({
    int? id,
    String? agentName,
    int? clientKey,
    String? contactNumber,
    String? contactEmail,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Agent(
      id: id ?? this.id,
      agentName: agentName ?? this.agentName,
      clientKey: clientKey ?? this.clientKey,
      contactNumber: contactNumber ?? this.contactNumber,
      contactEmail: contactEmail ?? this.contactEmail,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Agent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Agent(id: $id, agentName: $agentName, clientKey: $clientKey)';
  }
}
