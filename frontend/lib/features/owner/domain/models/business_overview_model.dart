// lib/features/owner/domain/models/business_overview_model.dart
import '../../domain/models/station_summary_model.dart';
class BusinessOverview {
  final double totalTodaySales;
  final double totalWeeklySales;
  final double totalMonthlySales;
  final double totalYearlySales;
  final int totalStations;
  final int activeStations;
  final int totalPumps;
  final int totalAttendants;
  final int totalTransactionsToday;
  final double overallSalesGrowth;
  final List<StationSummary> stationSummaries;
  final DateTime lastUpdated;

  BusinessOverview({
    required this.totalTodaySales,
    required this.totalWeeklySales,
    required this.totalMonthlySales,
    required this.totalYearlySales,
    required this.totalStations,
    required this.activeStations,
    required this.totalPumps,
    required this.totalAttendants,
    required this.totalTransactionsToday,
    required this.overallSalesGrowth,
    required this.stationSummaries,
    required this.lastUpdated,
  });

  factory BusinessOverview.fromJson(Map<String, dynamic> json) {
    return BusinessOverview(
      totalTodaySales: (json['total_today_sales'] as num?)?.toDouble() ?? 0,
      totalWeeklySales: (json['total_weekly_sales'] as num?)?.toDouble() ?? 0,
      totalMonthlySales: (json['total_monthly_sales'] as num?)?.toDouble() ?? 0,
      totalYearlySales: (json['total_yearly_sales'] as num?)?.toDouble() ?? 0,
      totalStations: json['total_stations'] ?? 0,
      activeStations: json['active_stations'] ?? 0,
      totalPumps: json['total_pumps'] ?? 0,
      totalAttendants: json['total_attendants'] ?? 0,
      totalTransactionsToday: json['total_transactions_today'] ?? 0,
      overallSalesGrowth: (json['overall_sales_growth'] as num?)?.toDouble() ?? 0,
      stationSummaries: (json['station_summaries'] as List)
          .map((s) => StationSummary.fromJson(s))
          .toList(),
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }

  double get averageSalesPerStation => totalStations > 0 ? totalMonthlySales / totalStations : 0;
}