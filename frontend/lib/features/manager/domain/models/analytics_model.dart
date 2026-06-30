// lib/features/manager/domain/models/analytics_model.dart


enum TimeRange {
  daily('Daily', 1),
  weekly('Weekly', 7),
  monthly('Monthly', 30),
  custom('Custom', 0);

  final String displayName;
  final int days;
  const TimeRange(this.displayName, this.days);
}

class SalesDataPoint {
  final DateTime date;
  final double mpesaAmount;
  final double cashAmount;
  final double cardAmount;
  final double total;

  SalesDataPoint({
    required this.date,
    required this.mpesaAmount,
    required this.cashAmount,
    required this.cardAmount,
    required this.total,
  });
}

class PaymentMethodBreakdown {
  final double mpesaTotal;
  final double cashTotal;
  final double cardTotal;
  final double total;

  PaymentMethodBreakdown({
    required this.mpesaTotal,
    required this.cashTotal,
    required this.cardTotal,
    required this.total,
  });

  double get mpesaPercentage => total > 0 ? (mpesaTotal / total * 100) : 0;
  double get cashPercentage => total > 0 ? (cashTotal / total * 100) : 0;
  double get cardPercentage => total > 0 ? (cardTotal / total * 100) : 0;
}

class PeakHourData {
  final int hour;
  final double averageSales;
  final int transactionCount;

  PeakHourData({
    required this.hour,
    required this.averageSales,
    required this.transactionCount,
  });

  String get hourDisplay {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }
}

class TopPerformer {
  final String id;
  final String name;
  final double totalSales;
  final int transactionCount;
  final double averageTransaction;

  TopPerformer({
    required this.id,
    required this.name,
    required this.totalSales,
    required this.transactionCount,
    required this.averageTransaction,
  });
}

class AnalyticsSummary {
  final double totalSales;
  final int totalTransactions;
  final double averageTransaction;
  final double bestDay;
  final DateTime bestDayDate;
  final double bestHour;
  final int bestHourValue;

  AnalyticsSummary({
    required this.totalSales,
    required this.totalTransactions,
    required this.averageTransaction,
    required this.bestDay,
    required this.bestDayDate,
    required this.bestHour,
    required this.bestHourValue,
  });
}