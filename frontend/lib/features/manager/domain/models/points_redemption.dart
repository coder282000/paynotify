import 'package:flutter/material.dart';

enum RedemptionStatus {
  pending,
  approved,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case RedemptionStatus.pending:
        return 'Pending';
      case RedemptionStatus.approved:
        return 'Approved';
      case RedemptionStatus.completed:
        return 'Completed';
      case RedemptionStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case RedemptionStatus.pending:
        return Colors.orange;
      case RedemptionStatus.approved:
        return Colors.blue;
      case RedemptionStatus.completed:
        return Colors.green;
      case RedemptionStatus.cancelled:
        return Colors.red;
    }
  }
}

class PointsRedemption {
  final String id;
  final String customerId;
  final String customerName;
  final int points;
  final double valueKes;
  final DateTime date;
  final String redeemedBy;
  final String redeemedByName;
  final RedemptionStatus status;
  final String? notes;

  PointsRedemption({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.points,
    required this.valueKes,
    required this.date,
    required this.redeemedBy,
    required this.redeemedByName,
    required this.status,
    this.notes,
  });

  String get formattedPoints => '$points pts';
  String get formattedValue => 'KES ${valueKes.toStringAsFixed(0)}';
  String get formattedDate => _formatDate(date);
  String get formattedTime => _formatTime(date);

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerId': customerId,
    'customerName': customerName,
    'points': points,
    'valueKes': valueKes,
    'date': date.toIso8601String(),
    'redeemedBy': redeemedBy,
    'redeemedByName': redeemedByName,
    'status': status.name,
    'notes': notes,
  };

  factory PointsRedemption.fromJson(Map<String, dynamic> json) {
    return PointsRedemption(
      id: json['id'],
      customerId: json['customerId'],
      customerName: json['customerName'],
      points: json['points'],
      valueKes: json['valueKes'],
      date: DateTime.parse(json['date']),
      redeemedBy: json['redeemedBy'],
      redeemedByName: json['redeemedByName'],
      status: RedemptionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RedemptionStatus.pending,
      ),
      notes: json['notes'],
    );
  }
}