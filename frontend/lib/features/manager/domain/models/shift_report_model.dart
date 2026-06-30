// lib/features/manager/domain/models/shift_report_model.dart

import 'package:flutter/material.dart';

enum ReportStatus {
  pending('Pending', Colors.orange, Icons.hourglass_empty),
  underReview('Under Review', Colors.blue, Icons.visibility),
  approved('Approved', Colors.green, Icons.check_circle),
  rejected('Rejected', Colors.red, Icons.cancel);

  final String displayName;
  final Color color;
  final IconData icon;
  const ReportStatus(this.displayName, this.color, this.icon);
}

class ShiftReport {
  final String id;
  final String attendantId;
  final String attendantName;
  final String pumpId;
  final String pumpName;
  final DateTime shiftDate;
  final DateTime shiftStart;
  final DateTime shiftEnd;
  final double openingMeter;
  final double closingMeter;
  final double fuelDispensed;
  final double expectedCash;
  final double actualCash;
  final double mpesaTotal;
  final double cashTotal;
  final double variance;
  final ReportStatus status;
  final String? remarks;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final Map<String, dynamic>? transactionSummary;

  ShiftReport({
    required this.id,
    required this.attendantId,
    required this.attendantName,
    required this.pumpId,
    required this.pumpName,
    required this.shiftDate,
    required this.shiftStart,
    required this.shiftEnd,
    required this.openingMeter,
    required this.closingMeter,
    required this.fuelDispensed,
    required this.expectedCash,
    required this.actualCash,
    required this.mpesaTotal,
    required this.cashTotal,
    required this.variance,
    required this.status,
    this.remarks,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.transactionSummary,
  });

  // Computed properties
  bool get isPending => status == ReportStatus.pending;
  bool get isUnderReview => status == ReportStatus.underReview;
  bool get isApproved => status == ReportStatus.approved;
  bool get isRejected => status == ReportStatus.rejected;
  bool get hasVariance => variance.abs() > 100; // Variance > KES 100
  
  String get varianceStatus {
    if (variance > 100) return 'Excess';
    if (variance < -100) return 'Shortage';
    return 'Normal';
  }
  
  Color get varianceColor {
    if (variance > 100) return Colors.orange;
    if (variance < -100) return Colors.red;
    return Colors.green;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'attendantId': attendantId,
    'attendantName': attendantName,
    'pumpId': pumpId,
    'pumpName': pumpName,
    'shiftDate': shiftDate.toIso8601String(),
    'shiftStart': shiftStart.toIso8601String(),
    'shiftEnd': shiftEnd.toIso8601String(),
    'openingMeter': openingMeter,
    'closingMeter': closingMeter,
    'fuelDispensed': fuelDispensed,
    'expectedCash': expectedCash,
    'actualCash': actualCash,
    'mpesaTotal': mpesaTotal,
    'cashTotal': cashTotal,
    'variance': variance,
    'status': status.name,
    'remarks': remarks,
    'approvedBy': approvedBy,
    'approvedAt': approvedAt?.toIso8601String(),
    'rejectionReason': rejectionReason,
    'transactionSummary': transactionSummary,
  };

  factory ShiftReport.fromJson(Map<String, dynamic> json) {
    return ShiftReport(
      id: json['id'],
      attendantId: json['attendantId'],
      attendantName: json['attendantName'],
      pumpId: json['pumpId'],
      pumpName: json['pumpName'],
      shiftDate: DateTime.parse(json['shiftDate']),
      shiftStart: DateTime.parse(json['shiftStart']),
      shiftEnd: DateTime.parse(json['shiftEnd']),
      openingMeter: json['openingMeter'].toDouble(),
      closingMeter: json['closingMeter'].toDouble(),
      fuelDispensed: json['fuelDispensed'].toDouble(),
      expectedCash: json['expectedCash'].toDouble(),
      actualCash: json['actualCash'].toDouble(),
      mpesaTotal: json['mpesaTotal'].toDouble(),
      cashTotal: json['cashTotal'].toDouble(),
      variance: json['variance'].toDouble(),
      status: ReportStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReportStatus.pending,
      ),
      remarks: json['remarks'],
      approvedBy: json['approvedBy'],
      approvedAt: json['approvedAt'] != null 
          ? DateTime.parse(json['approvedAt']) 
          : null,
      rejectionReason: json['rejectionReason'],
      transactionSummary: json['transactionSummary'],
    );
  }
}