// lib/features/manager/domain/models/reconciliation_model.dart

import 'package:flutter/material.dart';

enum ReconciliationStatus {
  pending('Pending', Colors.orange, Icons.hourglass_empty),
  approved('Approved', Colors.green, Icons.check_circle),
  rejected('Rejected', Colors.red, Icons.cancel),
  underReview('Under Review', Colors.blue, Icons.visibility);

  final String displayName;
  final Color color;
  final IconData icon;
  const ReconciliationStatus(this.displayName, this.color, this.icon);
}

class ReconciliationItem {
  final String id;
  final String reportId;
  final String attendantId;
  final String attendantName;
  final String pumpId;
  final String pumpName;
  final DateTime shiftDate;
  final DateTime shiftStart;
  final DateTime shiftEnd;
  
  // Meter readings
  final double openingMeter;
  final double closingMeter;
  final double fuelDispensed;
  final double pricePerLiter;
  
  // Financials
  final double expectedCash;
  final double actualCash;
  final double mpesaTotal;
  final double cashTotal;
  final double variance;
  
  // Status
  ReconciliationStatus status;
  String? approvedBy;
  DateTime? approvedAt;
  String? rejectionReason;
  String? remarks;
  final Map<String, dynamic>? transactionSummary;

  ReconciliationItem({
    required this.id,
    required this.reportId,
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
    required this.pricePerLiter,
    required this.expectedCash,
    required this.actualCash,
    required this.mpesaTotal,
    required this.cashTotal,
    required this.variance,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.remarks,
    this.transactionSummary,
  });

  // Computed properties
  bool get isPending => status == ReconciliationStatus.pending;
  bool get isApproved => status == ReconciliationStatus.approved;
  bool get isRejected => status == ReconciliationStatus.rejected;
  bool get isUnderReview => status == ReconciliationStatus.underReview;
  
  bool get hasVariance => variance.abs() > 100;
  bool get hasExcess => variance > 100;
  bool get hasShortage => variance < -100;
  
  String get varianceType {
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
    'reportId': reportId,
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
    'pricePerLiter': pricePerLiter,
    'expectedCash': expectedCash,
    'actualCash': actualCash,
    'mpesaTotal': mpesaTotal,
    'cashTotal': cashTotal,
    'variance': variance,
    'status': status.name,
    'approvedBy': approvedBy,
    'approvedAt': approvedAt?.toIso8601String(),
    'rejectionReason': rejectionReason,
    'remarks': remarks,
    'transactionSummary': transactionSummary,
  };

  factory ReconciliationItem.fromJson(Map<String, dynamic> json) {
    return ReconciliationItem(
      id: json['id'],
      reportId: json['reportId'],
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
      pricePerLiter: json['pricePerLiter'].toDouble(),
      expectedCash: json['expectedCash'].toDouble(),
      actualCash: json['actualCash'].toDouble(),
      mpesaTotal: json['mpesaTotal'].toDouble(),
      cashTotal: json['cashTotal'].toDouble(),
      variance: json['variance'].toDouble(),
      status: ReconciliationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReconciliationStatus.pending,
      ),
      approvedBy: json['approvedBy'],
      approvedAt: json['approvedAt'] != null 
          ? DateTime.parse(json['approvedAt']) 
          : null,
      rejectionReason: json['rejectionReason'],
      remarks: json['remarks'],
      transactionSummary: json['transactionSummary'],
    );
  }
}

// Renamed this class to avoid conflict with the widget
class ReconciliationSummaryData {
  final DateTime date;
  final int totalItems;
  final int pendingItems;
  final int approvedItems;
  final int rejectedItems;
  final double totalExpected;
  final double totalActual;
  final double totalVariance;
  final int itemsWithVariance;

  ReconciliationSummaryData({
    required this.date,
    required this.totalItems,
    required this.pendingItems,
    required this.approvedItems,
    required this.rejectedItems,
    required this.totalExpected,
    required this.totalActual,
    required this.totalVariance,
    required this.itemsWithVariance,
  });

  // Computed properties
  double get reconciliationRate => totalItems > 0 
      ? (approvedItems / totalItems * 100) 
      : 0;
  
  double get accuracyRate => totalExpected > 0 
      ? ((totalExpected - totalVariance.abs()) / totalExpected * 100).clamp(0, 100)
      : 100;
}