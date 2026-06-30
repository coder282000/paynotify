// lib/features/owner/presentation/screens/profit_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class ProfitAnalyticsScreen extends StatefulWidget {
  const ProfitAnalyticsScreen({super.key});

  @override
  State<ProfitAnalyticsScreen> createState() => _ProfitAnalyticsScreenState();
}

class _ProfitAnalyticsScreenState extends State<ProfitAnalyticsScreen> {
  String _selectedTimeRange = 'This Month';
  String _selectedStation = 'all';

  final List<String> _timeRanges = ['Today', 'This Week', 'This Month', 'This Year'];

  // Data for profit analytics
  Map<String, dynamic> _profitData = {};
  List<Map<String, dynamic>> _monthlyData = [];
  List<Map<String, dynamic>> _stationProfits = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Replace with actual API call to OwnerProvider when backend is ready
      // final provider = context.read<OwnerProvider>();
      // await provider.loadProfitAnalytics();
      // _profitData = provider.profitData;
      // _monthlyData = provider.monthlyProfitData;
      // _stationProfits = provider.stationProfitData;
      
      await Future.delayed(const Duration(milliseconds: 800));
      
      _profitData = _getMockProfitData();
      _monthlyData = _getMockMonthlyData();
      _stationProfits = _getMockStationProfits();
      
      _isLoading = false;
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<String> get _stations {
    return ['all', ..._stationProfits.map((s) => s['name'] as String).toSet()];
  }

  double get _totalRevenue => _profitData['revenue'] ?? 0;
  double get _totalExpenses => _profitData['expenses'] ?? 0;
  double get _totalProfit => _totalRevenue - _totalExpenses;
  double get _profitMargin => _totalRevenue > 0 ? (_totalProfit / _totalRevenue) * 100 : 0;
  String get _revenueGrowth => '+12.5%';
  String get _expenseGrowth => '+5.2%';

  List<Map<String, dynamic>> get _filteredStationProfits {
    if (_selectedStation == 'all') return _stationProfits;
    return _stationProfits.where((s) => s['name'] == _selectedStation).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isProfitable = _totalProfit > 0;
    final filteredStationProfits = _filteredStationProfits;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profit Analytics'),
        backgroundColor: const Color(0xFF0B3D2E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time Range Selector
                      _buildTimeRangeSelector(),
                      const SizedBox(height: 16),
                      
                      // Station Filter
                      _buildStationFilter(),
                      const SizedBox(height: 16),
                      
                      // Profit Summary Cards
                      _buildProfitSummaryCards(isProfitable),
                      const SizedBox(height: 24),
                      
                      // Revenue vs Expenses Chart
                      const Text(
                        'Revenue vs Expenses',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildRevenueExpenseChart(),
                      const SizedBox(height: 24),
                      
                      // Monthly Performance
                      const Text(
                        'Monthly Performance',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildMonthlyTable(),
                      const SizedBox(height: 24),
                      
                      // Profit by Station
                      const Text(
                        'Profit by Station',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildStationProfitList(filteredStationProfits),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: _timeRanges.map((range) {
          final isSelected = _selectedTimeRange == range;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTimeRange = range),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0B3D2E) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    range,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStationFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStation,
          isExpanded: true,
          hint: const Text('Filter by Station'),
          items: _stations.map((station) {
            return DropdownMenuItem(
              value: station,
              child: Text(station == 'all' ? 'All Stations' : station),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedStation = value!),
        ),
      ),
    );
  }

  Widget _buildProfitSummaryCards(bool isProfitable) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0B3D2E), Color(0xFF1A5D4A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildProfitCard(
                    'Revenue',
                    'KES ${NumberFormat('#,##0').format(_totalRevenue)}',
                    Icons.trending_up,
                    Colors.green,
                    _revenueGrowth,
                  ),
                ),
                Expanded(
                  child: _buildProfitCard(
                    'Expenses',
                    'KES ${NumberFormat('#,##0').format(_totalExpenses)}',
                    Icons.trending_down,
                    Colors.red,
                    _expenseGrowth,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Net Profit',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'KES ${NumberFormat('#,##0').format(_totalProfit)}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isProfitable ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isProfitable ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 14,
                        color: isProfitable ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_profitMargin.toStringAsFixed(1)}% Margin',
                        style: TextStyle(
                          color: isProfitable ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitCard(String title, String value, IconData icon, Color color, String change) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              change.contains('+') ? Icons.arrow_upward : Icons.arrow_downward,
              size: 10,
              color: change.contains('+') ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 2),
            Text(
              change,
              style: TextStyle(
                fontSize: 10,
                color: change.contains('+') ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRevenueExpenseChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.green, 'Revenue'),
                const SizedBox(width: 24),
                _buildLegendItem(Colors.red, 'Expenses'),
                const SizedBox(width: 24),
                _buildLegendItem(Colors.blue, 'Profit'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: CustomPaint(
                painter: ProfitChartPainter(
                  revenueData: _monthlyData.map((d) => d['revenue'] as double).toList(),
                  expenseData: _monthlyData.map((d) => d['expenses'] as double).toList(),
                  profitData: _monthlyData.map((d) => d['profit'] as double).toList(),
                ),
                size: Size.infinite,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _monthlyData.map((d) {
                return Text(
                  d['month'] as String,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildMonthlyTable() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          headingRowColor: WidgetStateProperty.resolveWith(
            (states) => const Color(0xFF0B3D2E).withValues(alpha: 0.1),
          ),
          columns: const [
            DataColumn(label: Text('Month')),
            DataColumn(label: Text('Revenue'), numeric: true),
            DataColumn(label: Text('Expenses'), numeric: true),
            DataColumn(label: Text('Profit'), numeric: true),
            DataColumn(label: Text('Margin'), numeric: true),
          ],
          rows: _monthlyData.map((data) {
            final profit = data['profit'] as double;
            final isProfitPositive = profit > 0;
            
            return DataRow(
              cells: [
                DataCell(Text(data['month'])),
                DataCell(Text('KES ${NumberFormat('#,##0').format(data['revenue'])}')),
                DataCell(Text('KES ${NumberFormat('#,##0').format(data['expenses'])}')),
                DataCell(
                  Text(
                    'KES ${NumberFormat('#,##0').format(profit)}',
                    style: TextStyle(
                      color: isProfitPositive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '${data['margin'].toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: isProfitPositive ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStationProfitList(List<Map<String, dynamic>> stations) {
    if (stations.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No data available')),
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stations.length,
      itemBuilder: (context, index) {
        final station = stations[index];
        final profit = station['profit'] as double;
        final isProfitPositive = profit > 0;
        final percentage = (profit / (station['revenue'] as double)) * 100;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: isProfitPositive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.business,
                        color: isProfitPositive ? Colors.green : Colors.red,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            station['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${station['transactions']} transactions',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'KES ${NumberFormat('#,##0').format(profit)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isProfitPositive ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${percentage.toStringAsFixed(1)}% margin',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStationMetric('Revenue', station['revenue']),
                    ),
                    Expanded(
                      child: _buildStationMetric('Expenses', station['expenses']),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isProfitPositive ? Colors.green : Colors.red,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStationMetric(String label, double value) {
    return Column(
      children: [
        Text(
          'KES ${NumberFormat('#,##0').format(value)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }

  // Mock data methods (TODO: Replace with actual API calls when backend is ready)
  Map<String, dynamic> _getMockProfitData() {
    return {
      'revenue': 1250000.0,
      'expenses': 450000.0,
    };
  }

  List<Map<String, dynamic>> _getMockMonthlyData() {
    return [
      {'month': 'Jan', 'revenue': 980000.0, 'expenses': 380000.0, 'profit': 600000.0, 'margin': 61.2},
      {'month': 'Feb', 'revenue': 1020000.0, 'expenses': 390000.0, 'profit': 630000.0, 'margin': 61.8},
      {'month': 'Mar', 'revenue': 1150000.0, 'expenses': 420000.0, 'profit': 730000.0, 'margin': 63.5},
      {'month': 'Apr', 'revenue': 1080000.0, 'expenses': 410000.0, 'profit': 670000.0, 'margin': 62.0},
      {'month': 'May', 'revenue': 1250000.0, 'expenses': 450000.0, 'profit': 800000.0, 'margin': 64.0},
      {'month': 'Jun', 'revenue': 1320000.0, 'expenses': 470000.0, 'profit': 850000.0, 'margin': 64.4},
    ];
  }

  List<Map<String, dynamic>> _getMockStationProfits() {
    return [
      {'name': 'Westlands Main Station', 'revenue': 520000.0, 'expenses': 180000.0, 'profit': 340000.0, 'margin': 65.4, 'transactions': 1250},
      {'name': 'Mombasa Beach Road', 'revenue': 410000.0, 'expenses': 150000.0, 'profit': 260000.0, 'margin': 63.4, 'transactions': 980},
      {'name': 'Kisumu Lakeside', 'revenue': 220000.0, 'expenses': 90000.0, 'profit': 130000.0, 'margin': 59.1, 'transactions': 520},
    ];
  }
}

// Custom chart painter
class ProfitChartPainter extends CustomPainter {
  final List<double> revenueData;
  final List<double> expenseData;
  final List<double> profitData;

  ProfitChartPainter({
    required this.revenueData,
    required this.expenseData,
    required this.profitData,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (revenueData.isEmpty) return;

    final paintRevenue = Paint()
      ..color = Colors.green
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final paintExpense = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final paintProfit = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final xStep = size.width / (revenueData.length - 1);
    final maxValue = revenueData.reduce((a, b) => a > b ? a : b);
    final yScale = size.height / maxValue;

    // Draw revenue line
    for (int i = 0; i < revenueData.length - 1; i++) {
      final start = Offset(i * xStep, size.height - (revenueData[i] * yScale));
      final end = Offset((i + 1) * xStep, size.height - (revenueData[i + 1] * yScale));
      canvas.drawLine(start, end, paintRevenue);
    }

    // Draw expense line
    for (int i = 0; i < expenseData.length - 1; i++) {
      final start = Offset(i * xStep, size.height - (expenseData[i] * yScale));
      final end = Offset((i + 1) * xStep, size.height - (expenseData[i + 1] * yScale));
      canvas.drawLine(start, end, paintExpense);
    }

    // Draw profit line
    for (int i = 0; i < profitData.length - 1; i++) {
      final start = Offset(i * xStep, size.height - (profitData[i] * yScale));
      final end = Offset((i + 1) * xStep, size.height - (profitData[i + 1] * yScale));
      canvas.drawLine(start, end, paintProfit);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}