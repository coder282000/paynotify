// lib/features/owner/domain/models/profit_model.dart

class ProfitData {
  final String period;
  final double revenue;
  final double expenses;
  final double profit;
  final double margin;

  ProfitData({
    required this.period,
    required this.revenue,
    required this.expenses,
    required this.profit,
    required this.margin,
  });

  factory ProfitData.fromJson(Map<String, dynamic> json) {
    return ProfitData(
      period: json['period'],
      revenue: (json['revenue'] as num).toDouble(),
      expenses: (json['expenses'] as num).toDouble(),
      profit: (json['profit'] as num).toDouble(),
      margin: (json['margin'] as num).toDouble(),
    );
  }

  String get formattedRevenue => 'KES ${revenue.toStringAsFixed(0)}';
  String get formattedExpenses => 'KES ${expenses.toStringAsFixed(0)}';
  String get formattedProfit => 'KES ${profit.toStringAsFixed(0)}';
  String get formattedMargin => '${margin.toStringAsFixed(1)}%';
  
  bool get isProfitable => profit > 0;
  String get profitColorValue => isProfitable ? 'green' : 'red';
  String get profitIcon => isProfitable ? '▲' : '▼';
}

class StationProfit {
  final String stationId;
  final String stationName;
  final double revenue;
  final double expenses;
  final double profit;
  final double margin;

  StationProfit({
    required this.stationId,
    required this.stationName,
    required this.revenue,
    required this.expenses,
    required this.profit,
    required this.margin,
  });

  factory StationProfit.fromJson(Map<String, dynamic> json) {
    return StationProfit(
      stationId: json['station_id'].toString(),
      stationName: json['station_name'],
      revenue: (json['revenue'] as num).toDouble(),
      expenses: (json['expenses'] as num).toDouble(),
      profit: (json['profit'] as num).toDouble(),
      margin: (json['margin'] as num).toDouble(),
    );
  }

  double get profitPercentage => (profit / revenue) * 100;
  String get formattedRevenue => 'KES ${revenue.toStringAsFixed(0)}';
  String get formattedExpenses => 'KES ${expenses.toStringAsFixed(0)}';
  String get formattedProfit => 'KES ${profit.toStringAsFixed(0)}';
  String get formattedMargin => '${margin.toStringAsFixed(1)}%';
  String get marginColorValue => margin >= 20 ? 'green' : 'orange';
}