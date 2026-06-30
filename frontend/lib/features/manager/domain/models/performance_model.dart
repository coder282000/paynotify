// lib/features/manager/domain/models/performance_model.dart

import 'package:flutter/material.dart';

enum AdjustmentType {
  shortage('Shortage Deduction', Colors.red, Icons.trending_down),
  excess('Excess Bonus', Colors.green, Icons.trending_up),
  correction('Correction', Colors.blue, Icons.edit),
  other('Other', Colors.grey, Icons.info);

  final String displayName;
  final Color color;
  final IconData icon;
  const AdjustmentType(this.displayName, this.color, this.icon);
}

class AttendantPerformance {
  final String attendantId;
  final String attendantName;
  final String? avatar;
  final String? pumpAssigned;
  final DateTime joinDate;
  
  // Summary stats
  final int totalShifts;
  final int shiftsWithVariance;
  final double totalSales;
  final double totalShortages;
  final double totalExcess;
  final double netVariance;
  
  // Salary impact
  final double baseSalary;
  final double salaryDeduction; // Shortages deducted
  final double salaryBonus;     // Excess added (if policy allows)
  final double netSalary;
  
  // Trend data
  final List<PerformanceRecord> recentRecords;
  
  AttendantPerformance({
    required this.attendantId,
    required this.attendantName,
    this.avatar,
    this.pumpAssigned,
    required this.joinDate,
    required this.totalShifts,
    required this.shiftsWithVariance,
    required this.totalSales,
    required this.totalShortages,
    required this.totalExcess,
    required this.netVariance,
    required this.baseSalary,
    required this.salaryDeduction,
    required this.salaryBonus,
    required this.netSalary,
    required this.recentRecords,
  });

  // Computed properties
  double get varianceRate => totalSales > 0 
      ? (netVariance.abs() / totalSales * 100) 
      : 0;
  
  double get accuracyRate => totalSales > 0
      ? ((totalSales - netVariance.abs()) / totalSales * 100).clamp(0, 100)
      : 100;
  
  String get performanceGrade {
    if (accuracyRate >= 99.5) return 'A+';
    if (accuracyRate >= 99) return 'A';
    if (accuracyRate >= 98) return 'B';
    if (accuracyRate >= 97) return 'C';
    if (accuracyRate >= 95) return 'D';
    return 'F';
  }
  
  Color get gradeColor {
    if (accuracyRate >= 99) return Colors.green;
    if (accuracyRate >= 97) return Colors.blue;
    if (accuracyRate >= 95) return Colors.orange;
    return Colors.red;
  }
}

class PerformanceRecord {
  final String id;
  final String reportId;
  final DateTime date;
  final String pump;
  final double expected;
  final double actual;
  final double variance;
  final String? reason;
  final bool isApproved;

  PerformanceRecord({
    required this.id,
    required this.reportId,
    required this.date,
    required this.pump,
    required this.expected,
    required this.actual,
    required this.variance,
    this.reason,
    required this.isApproved,
  });

  // Computed
  bool get isShortage => variance < 0;
  bool get isExcess => variance > 0;
  
  String get varianceType => isShortage ? 'Shortage' : 'Excess';
  Color get varianceColor => isShortage ? Colors.red : Colors.orange;
}

class SalaryAdjustment {
  final String reason;
  final double amount;
  final AdjustmentType type;
  final DateTime date;
  final String? approvedBy;

  SalaryAdjustment({
    required this.reason,
    required this.amount,
    required this.type,
    required this.date,
    this.approvedBy,
  });
}

class PerformanceSummary {
  final DateTime startDate;
  final DateTime endDate;
  final int totalAttendants;
  final int attendantsWithVariance;
  final double totalShortages;
  final double totalExcess;
  final double totalVariance;
  final double totalSalaryImpact;

  PerformanceSummary({
    required this.startDate,
    required this.endDate,
    required this.totalAttendants,
    required this.attendantsWithVariance,
    required this.totalShortages,
    required this.totalExcess,
    required this.totalVariance,
    required this.totalSalaryImpact,
  });

  double get averageAccuracy => totalAttendants > 0
      ? ((totalShortages + totalExcess) / totalAttendants)
      : 0;
}