class AppNotification {
  final String id;
  final String userId;
  final String jobId;
  final String message;
  final bool isRead;
  final bool isHidden;
  final String notificationType;
  final DateTime createdAt;
  final DateTime? updatedAt;

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
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      jobId: json['job_id']?.toString() ?? '', // Convert BIGINT to String
      message: json['body'] as String, // Database uses 'body', not 'message'
      isRead: json['is_read'] as bool,
      isHidden: json['is_hidden'] as bool? ?? false,
      notificationType: json['notification_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
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
        other.updatedAt == updatedAt;
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
        updatedAt.hashCode;
  }

  @override
  String toString() {
    return 'AppNotification(id: $id, userId: $userId, jobId: $jobId, message: $message, isRead: $isRead, isHidden: $isHidden, notificationType: $notificationType, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
} 