import 'package:flutter/material.dart';
import 'notification_rule.dart';

enum NotificationStatus {
  unread,
  read,
  delivered,
  failed;

  String get displayName {
    switch (this) {
      case NotificationStatus.unread:
        return 'Unread';
      case NotificationStatus.read:
        return 'Read';
      case NotificationStatus.delivered:
        return 'Delivered';
      case NotificationStatus.failed:
        return 'Failed';
    }
  }

  Color get color {
    switch (this) {
      case NotificationStatus.unread:
        return Colors.blue;
      case NotificationStatus.read:
        return Colors.grey;
      case NotificationStatus.delivered:
        return Colors.green;
      case NotificationStatus.failed:
        return Colors.red;
    }
  }
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime createdAt;
  final String? senderId;
  final String? senderName;
  final List<String> recipientIds;
  final List<String> recipientNames;
  NotificationStatus status;
  final bool isSystemNotification;
  final Map<String, dynamic>? metadata;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.createdAt,
    this.senderId,
    this.senderName,
    required this.recipientIds,
    required this.recipientNames,
    required this.status,
    this.isSystemNotification = false,
    this.metadata,
  });

  bool get isUrgent => priority == NotificationPriority.high || priority == NotificationPriority.urgent;
  bool get isUnread => status == NotificationStatus.unread;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'type': type.name,
    'priority': priority.name,
    'createdAt': createdAt.toIso8601String(),
    'senderId': senderId,
    'senderName': senderName,
    'recipientIds': recipientIds,
    'recipientNames': recipientNames,
    'status': status.name,
    'isSystemNotification': isSystemNotification,
    'metadata': metadata,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: NotificationType.values.firstWhere((e) => e.name == json['type']),
      priority: NotificationPriority.values.firstWhere((e) => e.name == json['priority']),
      createdAt: DateTime.parse(json['createdAt']),
      senderId: json['senderId'],
      senderName: json['senderName'],
      recipientIds: List<String>.from(json['recipientIds']),
      recipientNames: List<String>.from(json['recipientNames']),
      status: NotificationStatus.values.firstWhere((e) => e.name == json['status']),
      isSystemNotification: json['isSystemNotification'],
      metadata: json['metadata'],
    );
  }
}