import 'package:flutter/material.dart';

class JobStep {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isCompleted;
  final bool isActive;
  final bool isEnabled;
  final VoidCallback? onTap;

  const JobStep({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.isCompleted = false,
    this.isActive = false,
    this.isEnabled = true,
    this.onTap,
  });

  JobStep copyWith({
    String? id,
    String? title,
    String? description,
    IconData? icon,
    bool? isCompleted,
    bool? isActive,
    bool? isEnabled,
    VoidCallback? onTap,
  }) {
    return JobStep(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      isCompleted: isCompleted ?? this.isCompleted,
      isActive: isActive ?? this.isActive,
      isEnabled: isEnabled ?? this.isEnabled,
      onTap: onTap ?? this.onTap,
    );
  }
}
