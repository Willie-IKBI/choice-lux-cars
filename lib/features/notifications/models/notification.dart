class AppNotification {
  final String id;
  final String userId;
  final String jobId;
  final String message; // Changed from 'body' to 'message'
  final bool isRead;
  final bool isHidden;
  final String notificationType;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? readAt; // New field
  final DateTime? dismissedAt; // New field
  final String priority; // New field
  final Map<String, dynamic>? actionData; // New field for deep linking
  final DateTime? expiresAt; // New field

  AppNotification({
    required this.id,
    required this.userId,
    required this.jobId,
    required this.message,
    required this.isRead,
    required this.isHidden,
    required this.notificationType,
    required this.createdAt,
    this.updatedAt,
    this.readAt,
    this.dismissedAt,
    this.priority = 'normal',
    this.actionData,
    this.expiresAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      jobId: json['job_id']?.toString() ?? '', // Convert BIGINT to String
      message: json['message']?.toString() ?? '', // Handle null message
      isRead: json['is_read'] as bool? ?? false,
      isHidden: json['is_hidden'] as bool? ?? false,
      notificationType: json['notification_type']?.toString() ?? 'unknown',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'].toString()) 
          : null,
      readAt: json['read_at'] != null 
          ? DateTime.parse(json['read_at'].toString()) 
          : null,
      dismissedAt: json['dismissed_at'] != null 
          ? DateTime.parse(json['dismissed_at'].toString()) 
          : null,
      priority: json['priority']?.toString() ?? 'normal',
      actionData: json['action_data'] != null 
          ? Map<String, dynamic>.from(json['action_data'] as Map)
          : null,
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'job_id': jobId,
      'message': message,
      'is_read': isRead,
      'is_hidden': isHidden,
      'notification_type': notificationType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'dismissed_at': dismissedAt?.toIso8601String(),
      'priority': priority,
      'action_data': actionData,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? jobId,
    String? message,
    bool? isRead,
    bool? isHidden,
    String? notificationType,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? readAt,
    DateTime? dismissedAt,
    String? priority,
    Map<String, dynamic>? actionData,
    DateTime? expiresAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      jobId: jobId ?? this.jobId,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      isHidden: isHidden ?? this.isHidden,
      notificationType: notificationType ?? this.notificationType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      readAt: readAt ?? this.readAt,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      priority: priority ?? this.priority,
      actionData: actionData ?? this.actionData,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppNotification &&
        other.id == id &&
        other.userId == userId &&
        other.jobId == jobId &&
        other.message == message &&
        other.isRead == isRead &&
        other.isHidden == isHidden &&
        other.notificationType == notificationType &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.readAt == readAt &&
        other.dismissedAt == dismissedAt &&
        other.priority == priority &&
        other.actionData == actionData &&
        other.expiresAt == expiresAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        jobId.hashCode ^
        message.hashCode ^
        isRead.hashCode ^
        isHidden.hashCode ^
        notificationType.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        readAt.hashCode ^
        dismissedAt.hashCode ^
        priority.hashCode ^
        actionData.hashCode ^
        expiresAt.hashCode;
  }

  @override
  String toString() {
    return 'AppNotification(id: $id, userId: $userId, jobId: $jobId, message: $message, isRead: $isRead, isHidden: $isHidden, notificationType: $notificationType, createdAt: $createdAt, updatedAt: $updatedAt, readAt: $readAt, dismissedAt: $dismissedAt, priority: $priority, actionData: $actionData, expiresAt: $expiresAt)';
  }

  // Helper methods
  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get isDismissed => dismissedAt != null;
  bool get isUnread => !isRead && !isDismissed && !isExpired;
  
  // Get action route for deep linking
  String? get actionRoute => actionData?['route'] as String?;
  
  // Get action type
  String? get actionType => actionData?['action'] as String?;
  
  // Get job number from action data
  String? get jobNumber => actionData?['job_number'] as String?;
  
  // Check if notification is high priority
  bool get isHighPriority => priority == 'high' || priority == 'urgent';
  
  // Check if notification is urgent
  bool get isUrgent => priority == 'urgent';
} 