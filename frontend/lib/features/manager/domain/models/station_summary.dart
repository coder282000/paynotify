class StationSummary {
  final double todaySales;
  final double salesChange;
  final int transactionCount;
  final double transactionChange;
  final int activePumps;
  final int totalPumps;
  final int activeAttendants;
  final int totalAttendants;

  StationSummary({
    required this.todaySales,
    required this.salesChange,
    required this.transactionCount,
    required this.transactionChange,
    required this.activePumps,
    required this.totalPumps,
    required this.activeAttendants,
    required this.totalAttendants,
  });
}