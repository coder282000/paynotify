// lib/features/supervisor/presentation/screens/reports_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/override_pump.dart';

// MARK: - Constants
class _ReportsConstants {
  static const Color primaryDark = Color(0xFF0B3D2E);
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color warningOrange = Color(0xFFF39C12);
  static const Color errorRed = Color(0xFFE74C3C);
  static const Color infoBlue = Color(0xFF3498DB);
  static const Color reportPurple = Color(0xFF9C27B0);
  static const Color reportTeal = Color(0xFF008080);
}

// MARK: - Report Type Enum
enum ReportType {
  daily('Daily Report', Icons.calendar_today, _ReportsConstants.infoBlue),
  weekly('Weekly Report', Icons.weekend, _ReportsConstants.reportPurple),
  monthly('Monthly Report', Icons.calendar_month, _ReportsConstants.reportTeal),
  custom('Custom Report', Icons.edit_calendar, _ReportsConstants.warningOrange);

  final String displayName;
  final IconData icon;
  final Color color;

  const ReportType(this.displayName, this.icon, this.color);
}

// MARK: - Report Data Models
class SalesSummary {
  final double totalSales;
  final double mpesaTotal;
  final double cashTotal;
  final double cardTotal;
  final int transactionCount;
  final int mpesaCount;
  final int cashCount;
  final int cardCount;
  final double averageTransaction;

  SalesSummary({
    required this.totalSales,
    required this.mpesaTotal,
    required this.cashTotal,
    required this.cardTotal,
    required this.transactionCount,
    required this.mpesaCount,
    required this.cashCount,
    required this.cardCount,
    required this.averageTransaction,
  });

  double get mpesaPercentage => totalSales > 0 ? (mpesaTotal / totalSales) * 100 : 0;
  double get cashPercentage => totalSales > 0 ? (cashTotal / totalSales) * 100 : 0;
  double get cardPercentage => totalSales > 0 ? (cardTotal / totalSales) * 100 : 0;
}

class PumpPerformance {
  final String pumpName;
  final FuelType fuelType;
  final double totalSales;
  final int transactionCount;
  final double fuelDispensed;
  final double averagePerTransaction;

  PumpPerformance({
    required this.pumpName,
    required this.fuelType,
    required this.totalSales,
    required this.transactionCount,
    required this.fuelDispensed,
    required this.averagePerTransaction,
  });
}

class ShiftSummary {
  final String attendantName;
  final int shiftsCount;
  final double totalSales;
  final double totalVariance;
  final int approvedCount;
  final int pendingCount;

  ShiftSummary({
    required this.attendantName,
    required this.shiftsCount,
    required this.totalSales,
    required this.totalVariance,
    required this.approvedCount,
    required this.pendingCount,
  });

  double get averagePerShift => shiftsCount > 0 ? totalSales / shiftsCount : 0;
}

class ReportsScreen extends StatefulWidget {
  final String supervisorName;
  final String supervisorId;

  const ReportsScreen({
    super.key,
    required this.supervisorName,
    required this.supervisorId,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportType _selectedReportType = ReportType.daily;
  DateTime _selectedDate = DateTime.now();
  DateTimeRange? _customDateRange;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Report data
  SalesSummary? _salesSummary;
  List<PumpPerformance> _pumpPerformances = [];
  List<ShiftSummary> _shiftSummaries = [];
  List<Map<String, dynamic>> _dailyTransactions = [];
  
  // Charts data
  List<Map<String, dynamic>> _salesTrend = [];

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    setState(() {
      _salesSummary = _getMockSalesSummary();
      _pumpPerformances = _getMockPumpPerformances();
      _shiftSummaries = _getMockShiftSummaries();
      _dailyTransactions = _getMockDailyTransactions();
      _salesTrend = _getMockSalesTrend();
      _isLoading = false;
    });
  }

  SalesSummary _getMockSalesSummary() {
    return SalesSummary(
      totalSales: 285750,
      mpesaTotal: 185750,
      cashTotal: 75000,
      cardTotal: 25000,
      transactionCount: 142,
      mpesaCount: 95,
      cashCount: 32,
      cardCount: 15,
      averageTransaction: 2012.32,
    );
  }

  List<PumpPerformance> _getMockPumpPerformances() {
    return [
      PumpPerformance(
        pumpName: 'Pump 1',
        fuelType: FuelType.petrol,
        totalSales: 62500,
        transactionCount: 35,
        fuelDispensed: 346.2,
        averagePerTransaction: 1785.71,
      ),
      PumpPerformance(
        pumpName: 'Pump 2',
        fuelType: FuelType.diesel,
        totalSales: 58400,
        transactionCount: 32,
        fuelDispensed: 353.9,
        averagePerTransaction: 1825.00,
      ),
      PumpPerformance(
        pumpName: 'Pump 3',
        fuelType: FuelType.petrol,
        totalSales: 42300,
        transactionCount: 24,
        fuelDispensed: 234.5,
        averagePerTransaction: 1762.50,
      ),
      PumpPerformance(
        pumpName: 'Pump 4',
        fuelType: FuelType.diesel,
        totalSales: 51200,
        transactionCount: 28,
        fuelDispensed: 310.3,
        averagePerTransaction: 1828.57,
      ),
      PumpPerformance(
        pumpName: 'Pump 5',
        fuelType: FuelType.kerosene,
        totalSales: 15600,
        transactionCount: 12,
        fuelDispensed: 130.0,
        averagePerTransaction: 1300.00,
      ),
      PumpPerformance(
        pumpName: 'Pump 6',
        fuelType: FuelType.premium,
        totalSales: 55750,
        transactionCount: 11,
        fuelDispensed: 285.9,
        averagePerTransaction: 5068.18,
      ),
    ];
  }

  List<ShiftSummary> _getMockShiftSummaries() {
    return [
      ShiftSummary(
        attendantName: 'John Mwangi',
        shiftsCount: 8,
        totalSales: 62400,
        totalVariance: 0,
        approvedCount: 8,
        pendingCount: 0,
      ),
      ShiftSummary(
        attendantName: 'Sarah Wanjiku',
        shiftsCount: 7,
        totalSales: 58700,
        totalVariance: 126,
        approvedCount: 7,
        pendingCount: 0,
      ),
      ShiftSummary(
        attendantName: 'Peter Odhiambo',
        shiftsCount: 6,
        totalSales: 42800,
        totalVariance: -108,
        approvedCount: 5,
        pendingCount: 1,
      ),
      ShiftSummary(
        attendantName: 'Grace Akinyi',
        shiftsCount: 8,
        totalSales: 68900,
        totalVariance: 0,
        approvedCount: 8,
        pendingCount: 0,
      ),
      ShiftSummary(
        attendantName: 'David Omondi',
        shiftsCount: 5,
        totalSales: 39150,
        totalVariance: -236,
        approvedCount: 4,
        pendingCount: 1,
      ),
    ];
  }

  List<Map<String, dynamic>> _getMockDailyTransactions() {
    final now = DateTime.now();
    return [
      {'time': now.subtract(const Duration(hours: 1)), 'amount': 2500.0, 'type': 'M-Pesa', 'pump': 'Pump 1'},
      {'time': now.subtract(const Duration(hours: 1, minutes: 15)), 'amount': 1800.0, 'type': 'Cash', 'pump': 'Pump 2'},
      {'time': now.subtract(const Duration(hours: 2)), 'amount': 3200.0, 'type': 'M-Pesa', 'pump': 'Pump 3'},
      {'time': now.subtract(const Duration(hours: 2, minutes: 30)), 'amount': 5000.0, 'type': 'Card', 'pump': 'Pump 4'},
      {'time': now.subtract(const Duration(hours: 3)), 'amount': 1500.0, 'type': 'Cash', 'pump': 'Pump 1'},
      {'time': now.subtract(const Duration(hours: 3, minutes: 45)), 'amount': 4200.0, 'type': 'M-Pesa', 'pump': 'Pump 6'},
    ];
  }

  List<Map<String, dynamic>> _getMockSalesTrend() {
    return [
      {'day': 'Mon', 'sales': 42500.0},
      {'day': 'Tue', 'sales': 38900.0},
      {'day': 'Wed', 'sales': 45600.0},
      {'day': 'Thu', 'sales': 47800.0},
      {'day': 'Fri', 'sales': 52300.0},
      {'day': 'Sat', 'sales': 58900.0},
      {'day': 'Sun', 'sales': 51200.0},
    ];
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _ReportsConstants.primaryDark,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate && mounted) {
      setState(() {
        _selectedDate = picked;
        _loadReportData();
      });
    }
  }

  Future<void> _selectCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _customDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _ReportsConstants.primaryDark,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && mounted) {
      setState(() {
        _customDateRange = picked;
        _selectedReportType = ReportType.custom;
        _loadReportData();
      });
    }
  }

  Future<void> _exportReport() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting report...'),
        backgroundColor: _ReportsConstants.accentGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    // Simulate export delay
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report exported successfully!'),
          backgroundColor: _ReportsConstants.accentGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatCurrency(double amount) {
    return 'KES ${NumberFormat('#,##0').format(amount)}';
  }

  String _getDateRangeText() {
    if (_selectedReportType == ReportType.custom && _customDateRange != null) {
      return '${DateFormat('dd MMM yyyy').format(_customDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_customDateRange!.end)}';
    }
    return DateFormat('dd MMM yyyy').format(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: _ReportsConstants.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _exportReport,
            tooltip: 'Export Report',
          ),
        ],
      ),
      body: Column(
        children: [
          // Report Type Selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ReportType.values.map((type) {
                      final isSelected = _selectedReportType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: FilterChip(
                          label: Text(type.displayName),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedReportType = type;
                              if (type != ReportType.custom) {
                                _customDateRange = null;
                              }
                              _loadReportData();
                            });
                          },
                          avatar: Icon(type.icon, size: 16),
                          selectedColor: type.color,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                // Date Selector
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectedReportType == ReportType.custom 
                            ? _selectCustomDateRange 
                            : _selectDate,
                        icon: Icon(
                          _selectedReportType == ReportType.custom 
                              ? Icons.date_range 
                              : Icons.calendar_today,
                          size: 18,
                        ),
                        label: Text(_getDateRangeText()),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Error Message
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _ReportsConstants.errorRed.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _ReportsConstants.errorRed.withAlpha(77)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: _ReportsConstants.errorRed),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: _ReportsConstants.errorRed),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: _ReportsConstants.errorRed),
                    onPressed: () => setState(() => _errorMessage = null),
                  ),
                ],
              ),
            ),

          // Main Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sales Summary Card
                        if (_salesSummary != null)
                          _buildSalesSummaryCard(),
                        
                        const SizedBox(height: 16),
                        
                        // Payment Method Breakdown
                        if (_salesSummary != null)
                          _buildPaymentBreakdownCard(),
                        
                        const SizedBox(height: 16),
                        
                        // Sales Trend Chart
                        _buildSalesTrendCard(),
                        
                        const SizedBox(height: 16),
                        
                        // Pump Performance
                        _buildPumpPerformanceCard(),
                        
                        const SizedBox(height: 16),
                        
                        // Shift Summary
                        _buildShiftSummaryCard(),
                        
                        const SizedBox(height: 16),
                        
                        // Recent Transactions
                        _buildRecentTransactionsCard(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesSummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: _ReportsConstants.accentGreen),
                const SizedBox(width: 8),
                const Text(
                  'Sales Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Sales', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(_salesSummary!.totalSales),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _ReportsConstants.accentGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Transactions', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(
                        '${_salesSummary!.transactionCount}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Average', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(_salesSummary!.averageTransaction),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentBreakdownCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Methods',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPaymentMethodTile(
                    'M-Pesa',
                    _salesSummary!.mpesaTotal,
                    _salesSummary!.mpesaCount,
                    _salesSummary!.mpesaPercentage,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPaymentMethodTile(
                    'Cash',
                    _salesSummary!.cashTotal,
                    _salesSummary!.cashCount,
                    _salesSummary!.cashPercentage,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPaymentMethodTile(
                    'Card',
                    _salesSummary!.cardTotal,
                    _salesSummary!.cardCount,
                    _salesSummary!.cardPercentage,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: _salesSummary!.mpesaPercentage.toInt(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: _salesSummary!.cashPercentage.toInt(),
                    child: Container(
                      color: Colors.blue,
                    ),
                  ),
                  Expanded(
                    flex: _salesSummary!.cardPercentage.toInt(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile(String label, double amount, int count, double percentage, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _formatCurrency(amount),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            '$count transactions',
            style: TextStyle(fontSize: 10, color: color),
          ),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 10, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTrendCard() {
    // Find max sales for scaling
    double maxSales = 0;
    for (final data in _salesTrend) {
      final sales = data['sales'] as double;
      if (sales > maxSales) maxSales = sales;
    }
    if (maxSales == 0) maxSales = 60000;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sales Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                children: _salesTrend.map((data) {
                  final sales = data['sales'] as double;
                  final height = (sales / maxSales * 150).clamp(0.0, 150.0);
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: height,
                          width: 30,
                          decoration: BoxDecoration(
                            color: _ReportsConstants.accentGreen,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '${(sales / 1000).toStringAsFixed(0)}k',
                                style: const TextStyle(fontSize: 8, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['day'] as String,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPumpPerformanceCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pump Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pumpPerformances.length,
              itemBuilder: (context, index) {
                final pump = _pumpPerformances[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: pump.fuelType.color.withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          pump.fuelType.icon,
                          color: pump.fuelType.color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pump.pumpName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              pump.fuelType.displayName,
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatCurrency(pump.totalSales),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _ReportsConstants.accentGreen,
                            ),
                          ),
                          Text(
                            '${pump.transactionCount} trans',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftSummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Shift Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                columns: const [
                  DataColumn(label: Text('Attendant')),
                  DataColumn(label: Text('Shifts')),
                  DataColumn(label: Text('Sales')),
                  DataColumn(label: Text('Variance')),
                  DataColumn(label: Text('Status')),
                ],
                rows: _shiftSummaries.map((shift) {
                  return DataRow(
                    cells: [
                      DataCell(Text(shift.attendantName)),
                      DataCell(Text('${shift.shiftsCount}')),
                      DataCell(Text(_formatCurrency(shift.totalSales))),
                      DataCell(
                        Text(
                          shift.totalVariance >= 0 ? '+${_formatCurrency(shift.totalVariance)}' : _formatCurrency(shift.totalVariance),
                          style: TextStyle(
                            color: shift.totalVariance >= 0 ? _ReportsConstants.accentGreen : _ReportsConstants.errorRed,
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            if (shift.approvedCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _ReportsConstants.accentGreen.withAlpha(26),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${shift.approvedCount} ✓',
                                  style: TextStyle(fontSize: 10, color: _ReportsConstants.accentGreen),
                                ),
                              ),
                            if (shift.pendingCount > 0)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _ReportsConstants.warningOrange.withAlpha(26),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${shift.pendingCount} ⏳',
                                  style: TextStyle(fontSize: 10, color: _ReportsConstants.warningOrange),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._dailyTransactions.take(5).map((transaction) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: transaction['type'] == 'M-Pesa'
                      ? Colors.green.withAlpha(26)
                      : (transaction['type'] == 'Cash'
                          ? Colors.blue.withAlpha(26)
                          : Colors.purple.withAlpha(26)),
                  child: Icon(
                    transaction['type'] == 'M-Pesa'
                        ? Icons.phone_android
                        : (transaction['type'] == 'Cash'
                            ? Icons.money
                            : Icons.credit_card),
                    size: 16,
                    color: transaction['type'] == 'M-Pesa'
                        ? Colors.green
                        : (transaction['type'] == 'Cash'
                            ? Colors.blue
                            : Colors.purple),
                  ),
                ),
                title: Text(
                  _formatCurrency(transaction['amount']),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${transaction['pump']} • ${DateFormat('HH:mm').format(transaction['time'])}',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: transaction['type'] == 'M-Pesa'
                        ? Colors.green.withAlpha(26)
                        : (transaction['type'] == 'Cash'
                            ? Colors.blue.withAlpha(26)
                            : Colors.purple.withAlpha(26)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    transaction['type'],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: transaction['type'] == 'M-Pesa'
                          ? Colors.green
                          : (transaction['type'] == 'Cash'
                              ? Colors.blue
                              : Colors.purple),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('View all transactions coming soon'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.chevron_right, size: 16),
                label: const Text('View All Transactions'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}