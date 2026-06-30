// lib/features/owner/domain/models/station_summary_model.dart

class StationSummary {
  final int stationId;
  final String stationName;
  final String stationCode;
  
  // Financial Metrics
  final double todaySales;
  final double weeklySales;
  final double monthlySales;
  final double yearlySales;
  final double lastMonthSales;
  final double salesGrowth;
  
  // Transaction Metrics
  final int todayTransactions;
  final int totalTransactions;
  final double averageTransactionValue;
  
  // Payment Method Breakdown
  final double cashTotal;
  final double cardTotal;
  final double mpesaTotal;
  
  // Operational Metrics
  final int totalPumps;
  final int activePumps;
  final int pumpsUnderMaintenance;
  final int totalAttendants;
  final int activeAttendants;
  final int pendingShiftReports;
  
  // Fuel Metrics
  final double totalFuelInventory;
  final double lowFuelAlerts;
  
  // Performance Metrics
  final double attendantPerformanceScore;
  final int customerSatisfaction;
  
  final DateTime lastUpdated;

  StationSummary({
    required this.stationId,
    required this.stationName,
    required this.stationCode,
    required this.todaySales,
    required this.weeklySales,
    required this.monthlySales,
    required this.yearlySales,
    required this.lastMonthSales,
    required this.salesGrowth,
    required this.todayTransactions,
    required this.totalTransactions,
    required this.averageTransactionValue,
    required this.cashTotal,
    required this.cardTotal,
    required this.mpesaTotal,
    required this.totalPumps,
    required this.activePumps,
    required this.pumpsUnderMaintenance,
    required this.totalAttendants,
    required this.activeAttendants,
    required this.pendingShiftReports,
    required this.totalFuelInventory,
    required this.lowFuelAlerts,
    required this.attendantPerformanceScore,
    required this.customerSatisfaction,
    required this.lastUpdated,
  });

  factory StationSummary.fromJson(Map<String, dynamic> json) {
    return StationSummary(
      stationId: json['station_id'],
      stationName: json['station_name'],
      stationCode: json['station_code'],
      todaySales: (json['today_sales'] as num?)?.toDouble() ?? 0,
      weeklySales: (json['weekly_sales'] as num?)?.toDouble() ?? 0,
      monthlySales: (json['monthly_sales'] as num?)?.toDouble() ?? 0,
      yearlySales: (json['yearly_sales'] as num?)?.toDouble() ?? 0,
      lastMonthSales: (json['last_month_sales'] as num?)?.toDouble() ?? 0,
      salesGrowth: (json['sales_growth'] as num?)?.toDouble() ?? 0,
      todayTransactions: json['today_transactions'] ?? 0,
      totalTransactions: json['total_transactions'] ?? 0,
      averageTransactionValue: (json['average_transaction_value'] as num?)?.toDouble() ?? 0,
      cashTotal: (json['cash_total'] as num?)?.toDouble() ?? 0,
      cardTotal: (json['card_total'] as num?)?.toDouble() ?? 0,
      mpesaTotal: (json['mpesa_total'] as num?)?.toDouble() ?? 0,
      totalPumps: json['total_pumps'] ?? 0,
      activePumps: json['active_pumps'] ?? 0,
      pumpsUnderMaintenance: json['pumps_under_maintenance'] ?? 0,
      totalAttendants: json['total_attendants'] ?? 0,
      activeAttendants: json['active_attendants'] ?? 0,
      pendingShiftReports: json['pending_shift_reports'] ?? 0,
      totalFuelInventory: (json['total_fuel_inventory'] as num?)?.toDouble() ?? 0,
      lowFuelAlerts: (json['low_fuel_alerts'] as num?)?.toDouble() ?? 0,
      attendantPerformanceScore: (json['attendant_performance_score'] as num?)?.toDouble() ?? 0,
      customerSatisfaction: json['customer_satisfaction'] ?? 0,
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'station_id': stationId,
      'station_name': stationName,
      'station_code': stationCode,
      'today_sales': todaySales,
      'weekly_sales': weeklySales,
      'monthly_sales': monthlySales,
      'yearly_sales': yearlySales,
      'last_month_sales': lastMonthSales,
      'sales_growth': salesGrowth,
      'today_transactions': todayTransactions,
      'total_transactions': totalTransactions,
      'average_transaction_value': averageTransactionValue,
      'cash_total': cashTotal,
      'card_total': cardTotal,
      'mpesa_total': mpesaTotal,
      'total_pumps': totalPumps,
      'active_pumps': activePumps,
      'pumps_under_maintenance': pumpsUnderMaintenance,
      'total_attendants': totalAttendants,
      'active_attendants': activeAttendants,
      'pending_shift_reports': pendingShiftReports,
      'total_fuel_inventory': totalFuelInventory,
      'low_fuel_alerts': lowFuelAlerts,
      'attendant_performance_score': attendantPerformanceScore,
      'customer_satisfaction': customerSatisfaction,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  // Computed properties (no Flutter UI dependencies)
  double get totalSales => cashTotal + cardTotal + mpesaTotal;
  double get mpesaPercentage => totalSales > 0 ? (mpesaTotal / totalSales) * 100 : 0;
  double get cashPercentage => totalSales > 0 ? (cashTotal / totalSales) * 100 : 0;
  double get cardPercentage => totalSales > 0 ? (cardTotal / totalSales) * 100 : 0;
  double get pumpUtilization => totalPumps > 0 ? (activePumps / totalPumps) * 100 : 0;
  double get attendantUtilization => totalAttendants > 0 ? (activeAttendants / totalAttendants) * 100 : 0;
  
  String get salesGrowthIcon => salesGrowth >= 0 ? '▲' : '▼';
  String get salesGrowthColorName => salesGrowth >= 0 ? 'green' : 'red';
  
  bool get hasLowFuel => lowFuelAlerts > 0;
  bool get hasPendingReports => pendingShiftReports > 0;
}