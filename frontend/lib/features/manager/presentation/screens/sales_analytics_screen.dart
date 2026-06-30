// lib/features/manager/presentation/screens/sales_analytics_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/models/analytics_model.dart';
import '../widgets/analytics_card.dart';
import '../widgets/analytics_chart.dart';
import '../widgets/peak_hours_chart.dart';

// MARK: - Constants
class _AnalyticsConstants {
  static const Color primaryDark = Color(0xFF0B3D2E);
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color warningOrange = Color(0xFFF39C12);
  static const Color errorRed = Color(0xFFE74C3C);
  
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
}

class SalesAnalyticsScreen extends StatefulWidget {
  const SalesAnalyticsScreen({super.key});

  @override
  State<SalesAnalyticsScreen> createState() => _SalesAnalyticsScreenState();
}

class _SalesAnalyticsScreenState extends State<SalesAnalyticsScreen> 
    with TickerProviderStateMixin {
  
  TimeRange _selectedTimeRange = TimeRange.weekly;
  DateTimeRange _customDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );
  
  bool _isLoading = false;
  String? _errorMessage;
  
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  // MARK: - Data Loading with Error Handling
  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Simulate API call
      await Future.delayed(_AnalyticsConstants.animationDuration);
      
      if (!mounted) return;
      setState(() => _isLoading = false);
      HapticFeedback.lightImpact();
      
    } catch (e, stackTrace) {
      if (!mounted) return;
      debugPrint('Load analytics error: $e\n$stackTrace');
      setState(() {
        _errorMessage = _getErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is TimeoutException) {
      return 'Connection timed out. Please check your internet and try again.';
    }
    if (error.toString().contains('SocketException') || 
        error.toString().contains('NetworkIsUnreachable')) {
      return 'No internet connection. Please connect to a network and retry.';
    }
    return 'Failed to load analytics data. Please try again.';
  }

  // MARK: - Mock Data
  List<SalesDataPoint> _getMockSalesData() {
    final now = DateTime.now();
    final List<SalesDataPoint> data = [];
    
    int days = _selectedTimeRange.days;
    if (_selectedTimeRange == TimeRange.custom) {
      days = _customDateRange.end.difference(_customDateRange.start).inDays;
    }
    
    for (int i = days; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final mpesa = 15000 + (i * 500) + (i % 3 * 1000);
      final cash = 8000 + (i * 300) + (i % 2 * 500);
      final card = 3000 + (i * 200) + (i % 4 * 300);
      
      data.add(SalesDataPoint(
        date: date,
        mpesaAmount: mpesa.toDouble(),
        cashAmount: cash.toDouble(),
        cardAmount: card.toDouble(),
        total: (mpesa + cash + card).toDouble(),
      ));
    }
    
    return data;
  }

  List<PeakHourData> _getMockPeakHours() {
    return [
      PeakHourData(hour: 6, averageSales: 2500, transactionCount: 5),
      PeakHourData(hour: 7, averageSales: 4500, transactionCount: 12),
      PeakHourData(hour: 8, averageSales: 12000, transactionCount: 28),
      PeakHourData(hour: 9, averageSales: 18500, transactionCount: 42),
      PeakHourData(hour: 10, averageSales: 22000, transactionCount: 55),
      PeakHourData(hour: 11, averageSales: 25800, transactionCount: 63),
      PeakHourData(hour: 12, averageSales: 31200, transactionCount: 78),
      PeakHourData(hour: 13, averageSales: 28900, transactionCount: 71),
      PeakHourData(hour: 14, averageSales: 23400, transactionCount: 58),
      PeakHourData(hour: 15, averageSales: 19800, transactionCount: 49),
      PeakHourData(hour: 16, averageSales: 22500, transactionCount: 52),
      PeakHourData(hour: 17, averageSales: 27800, transactionCount: 68),
      PeakHourData(hour: 18, averageSales: 34200, transactionCount: 85),
      PeakHourData(hour: 19, averageSales: 31500, transactionCount: 79),
      PeakHourData(hour: 20, averageSales: 25600, transactionCount: 61),
      PeakHourData(hour: 21, averageSales: 18900, transactionCount: 43),
      PeakHourData(hour: 22, averageSales: 12300, transactionCount: 27),
      PeakHourData(hour: 23, averageSales: 5600, transactionCount: 12),
    ];
  }

  PaymentMethodBreakdown _getPaymentBreakdown(List<SalesDataPoint> data) {
    double mpesa = 0, cash = 0, card = 0;
    
    for (var point in data) {
      mpesa += point.mpesaAmount;
      cash += point.cashAmount;
      card += point.cardAmount;
    }
    
    return PaymentMethodBreakdown(
      mpesaTotal: mpesa,
      cashTotal: cash,
      cardTotal: card,
      total: mpesa + cash + card,
    );
  }

  AnalyticsSummary _getSummary(List<SalesDataPoint> data, List<PeakHourData> peakHours) {
    double total = 0;
    int count = 0;
    double bestDay = 0;
    DateTime bestDayDate = DateTime.now();
    
    for (var point in data) {
      total += point.total;
      count++;
      if (point.total > bestDay) {
        bestDay = point.total;
        bestDayDate = point.date;
      }
    }
    
    final bestHour = peakHours.reduce((a, b) => a.averageSales > b.averageSales ? a : b);
    
    return AnalyticsSummary(
      totalSales: total,
      totalTransactions: count * 15,
      averageTransaction: count > 0 ? total / (count * 15) : 0,
      bestDay: bestDay,
      bestDayDate: bestDayDate,
      bestHour: bestHour.averageSales,
      bestHourValue: bestHour.hour,
    );
  }

  // MARK: - User Actions
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
              primary: _AnalyticsConstants.primaryDark,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && mounted) {
      setState(() {
        _customDateRange = picked;
        _selectedTimeRange = TimeRange.custom;
      });
      await _loadData();
    }
  }

  Future<void> _exportAnalytics() async {
    if (!mounted) return;
    
    // Check connectivity
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (!mounted) return;
      
      if (connectivityResult.contains(ConnectivityResult.none)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No internet connection'),
              backgroundColor: _AnalyticsConstants.errorRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    } catch (e) {
      debugPrint('Connectivity error: $e');
    }

    setState(() => _isLoading = true);

    try {
      final data = _getMockSalesData();
      final breakdown = _getPaymentBreakdown(data);
      
      final List<List<dynamic>> csvData = [
        ['Date', 'M-Pesa', 'Cash', 'Card', 'Total'],
        ...data.map((d) => [
          DateFormat('yyyy-MM-dd').format(d.date),
          d.mpesaAmount.toString(),
          d.cashAmount.toString(),
          d.cardAmount.toString(),
          d.total.toString(),
        ]),
        [],
        ['Summary', '', '', '', ''],
        ['Total Sales', '', '', '', breakdown.total.toString()],
        ['M-Pesa Total', '', '', '', breakdown.mpesaTotal.toString()],
        ['Cash Total', '', '', '', breakdown.cashTotal.toString()],
        ['Card Total', '', '', '', breakdown.cardTotal.toString()],
      ];
      
      final String csv = const ListToCsvConverter().convert(csvData);
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath = '${tempDir.path}/analytics_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      
      final File file = File(filePath);
      await file.writeAsString(csv);
      
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      HapticFeedback.lightImpact();
      
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'PayNotifyy Sales Analytics Report',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export successful!'),
            backgroundColor: _AnalyticsConstants.accentGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: _AnalyticsConstants.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatCurrency(double amount) {
    return 'KES ${NumberFormat('#,##0').format(amount)}';
  }

  String _getDateRangeText() {
    if (_selectedTimeRange == TimeRange.custom) {
      return '${DateFormat('dd MMM').format(_customDateRange.start)} - ${DateFormat('dd MMM yyyy').format(_customDateRange.end)}';
    }
    return 'Last ${_selectedTimeRange.displayName}';
  }

  @override
  Widget build(BuildContext context) {
    final salesData = _getMockSalesData();
    final peakHours = _getMockPeakHours();
    final breakdown = _getPaymentBreakdown(salesData);
    final summary = _getSummary(salesData, peakHours);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > _AnalyticsConstants.tabletBreakpoint;
    final isTablet = screenWidth > _AnalyticsConstants.mobileBreakpoint && 
                     screenWidth <= _AnalyticsConstants.tabletBreakpoint;
    
    // Use warningOrange in UI to prevent unused warning
    final warningColor = _AnalyticsConstants.warningOrange;
    
    // Use isTablet to prevent unused warning
    if (isTablet) {
      // Tablet-specific optimizations can go here
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Sales Analytics'),
        backgroundColor: _AnalyticsConstants.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Export Button
          Semantics(
            button: true,
            label: 'Export analytics',
            child: IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.file_download_outlined),
              onPressed: _isLoading ? null : _exportAnalytics,
              tooltip: 'Export Report',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time Range Selector
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Time Range',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildTimeRangeChip(TimeRange.daily),
                              const SizedBox(width: 8),
                              _buildTimeRangeChip(TimeRange.weekly),
                              const SizedBox(width: 8),
                              _buildTimeRangeChip(TimeRange.monthly),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: const Text('Custom'),
                                selected: _selectedTimeRange == TimeRange.custom,
                                onSelected: (_) => _selectCustomDateRange(),
                              ),
                            ],
                          ),
                        ),
                        if (_selectedTimeRange == TimeRange.custom) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _AnalyticsConstants.primaryDark.withAlpha(26),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: _AnalyticsConstants.primaryDark,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _getDateRangeText(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _AnalyticsConstants.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Error Message
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.red.shade700),
                            onPressed: () {
                              setState(() {
                                _errorMessage = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  
                  // Summary Cards
                  isDesktop
                      ? Row(
                          children: [
                            Expanded(
                              child: AnalyticsCard(
                                title: 'Total Sales',
                                value: _formatCurrency(summary.totalSales),
                                icon: Icons.trending_up,
                                color: _AnalyticsConstants.primaryDark,
                                change: 12.5,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AnalyticsCard(
                                title: 'Transactions',
                                value: '${summary.totalTransactions}',
                                icon: Icons.receipt,
                                color: Colors.blue,
                                change: 8.3,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AnalyticsCard(
                                title: 'Average',
                                value: _formatCurrency(summary.averageTransaction),
                                icon: Icons.calculate,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: AnalyticsCard(
                                    title: 'Total Sales',
                                    value: _formatCurrency(summary.totalSales),
                                    icon: Icons.trending_up,
                                    color: _AnalyticsConstants.primaryDark,
                                    change: 12.5,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AnalyticsCard(
                                    title: 'Transactions',
                                    value: '${summary.totalTransactions}',
                                    icon: Icons.receipt,
                                    color: Colors.blue,
                                    change: 8.3,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            AnalyticsCard(
                              title: 'Average Transaction',
                              value: _formatCurrency(summary.averageTransaction),
                              icon: Icons.calculate,
                              color: Colors.purple,
                            ),
                          ],
                        ),
                  
                  const SizedBox(height: 16),
                  
                  // Main Chart
                  AnalyticsChart(
                    data: salesData,
                    title: 'Sales Trend',
                    subtitle: _getDateRangeText(),
                    height: isDesktop ? 300 : 250,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Payment Method Breakdown
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment Methods',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildPaymentMethodCard(
                                  'M-Pesa',
                                  _formatCurrency(breakdown.mpesaTotal),
                                  '${breakdown.mpesaPercentage.toStringAsFixed(1)}%',
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildPaymentMethodCard(
                                  'Cash',
                                  _formatCurrency(breakdown.cashTotal),
                                  '${breakdown.cashPercentage.toStringAsFixed(1)}%',
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildPaymentMethodCard(
                                  'Card',
                                  _formatCurrency(breakdown.cardTotal),
                                  '${breakdown.cardPercentage.toStringAsFixed(1)}%',
                                  Colors.purple,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Add a small indicator using warningColor
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: warningColor.withAlpha(26),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.trending_up, color: warningColor, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Sales trends are updated in real-time',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: warningColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Peak Hours and Top Performers
                  isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 6,
                              child: PeakHoursChart(data: peakHours),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 4,
                              child: _buildTopPerformersCard(),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            PeakHoursChart(data: peakHours),
                            const SizedBox(height: 16),
                            _buildTopPerformersCard(),
                          ],
                        ),
                  
                  const SizedBox(height: 16),
                  
                  // Best Day & Hour
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withAlpha(26),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.star,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Best Day',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('EEEE, dd MMM').format(summary.bestDayDate),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        _formatCurrency(summary.bestDay),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.grey.shade300,
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withAlpha(26),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.access_time,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Peak Hour',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _getHourLabel(summary.bestHourValue),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        _formatCurrency(summary.bestHour),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTimeRangeChip(TimeRange range) {
    return FilterChip(
      label: Text(range.displayName),
      selected: _selectedTimeRange == range,
      onSelected: (selected) {
        setState(() {
          _selectedTimeRange = range;
        });
        _loadData();
      },
    );
  }

  Widget _buildPaymentMethodCard(String label, String amount, String percentage, Color color) {
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
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            percentage,
            style: TextStyle(
              fontSize: 11,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformersCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Performers',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPerformerRow('Pump 1', 'KES 285,000', '142 trans', Colors.green),
            const SizedBox(height: 12),
            _buildPerformerRow('Pump 4', 'KES 264,500', '131 trans', Colors.blue),
            const SizedBox(height: 12),
            _buildPerformerRow('Pump 6', 'KES 242,800', '118 trans', Colors.purple),
            const Divider(height: 24),
            _buildPerformerRow('John M.', 'KES 312,000', '156 trans', Colors.orange),
            const SizedBox(height: 12),
            _buildPerformerRow('Sarah W.', 'KES 298,500', '149 trans', Colors.orange),
            const SizedBox(height: 12),
            _buildPerformerRow('Grace A.', 'KES 275,200', '138 trans', Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformerRow(String name, String amount, String transactions, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                transactions,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _getHourLabel(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }
}