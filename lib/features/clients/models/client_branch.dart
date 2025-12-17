class ClientBranch {
  final int? id;
  final int clientId;
  final String branchName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  ClientBranch({
    this.id,
    required this.clientId,
    required this.branchName,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  // Create from JSON
  factory ClientBranch.fromJson(Map<String, dynamic> json) {
    return ClientBranch(
      id: json['id'] as int?,
      clientId: json['client_id'] as int,
      branchName: json['branch_name'] as String,
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

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'client_id': clientId,
      'branch_name': branchName,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    };
  }

  // Create a copy with updated fields
  ClientBranch copyWith({
    int? id,
    int? clientId,
    String? branchName,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ClientBranch(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      branchName: branchName ?? this.branchName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  // Check if branch is deleted (soft delete)
  bool get isDeleted => deletedAt != null;

  // Check if branch is active (not deleted)
  bool get isActive => deletedAt == null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClientBranch && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ClientBranch(id: $id, clientId: $clientId, branchName: $branchName)';
  }
}

