// lib/features/owner/presentation/screens/station_performance_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/owner_provider.dart';
import '../../domain/models/station_activity_model.dart';
import '../../domain/models/station_summary_model.dart';  // ✅ ADD THIS IMPORT
import '../../widgets/performance_chart.dart';
import '../../widgets/recent_activity_tile.dart';

class StationPerformanceScreen extends StatefulWidget {
  final int stationId;
  final String stationName;

  const StationPerformanceScreen({
    super.key,
    required this.stationId,
    required this.stationName,
  });

  @override
  State<StationPerformanceScreen> createState() => _StationPerformanceScreenState();
}

class _StationPerformanceScreenState extends State<StationPerformanceScreen> {
  String _selectedMetric = 'sales'; // sales, transactions, fuel
  String _selectedTimeRange = 'Week';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OwnerProvider>().loadStationSummary(widget.stationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OwnerProvider>();
    final summary = provider.selectedStationSummary;

    return Scaffold(
      appBar: AppBar(
        title: Text('Performance - ${widget.stationName}'),
        backgroundColor: const Color(0xFF0B3D2E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.loadStationSummary(widget.stationId),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : summary == null
              ? const Center(child: Text('No data available'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Metric Selector
                      _buildMetricSelector(),
                      const SizedBox(height: 16),
                      
                      // Time Range Selector
                      _buildTimeRangeSelector(),
                      const SizedBox(height: 16),
                      
                      // Performance Chart
                      SizedBox(
                        height: 250,
                        child: PerformanceChart(
                          data: _getChartData(),
                          labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                          title: _getChartTitle(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Key Metrics Grid
                      const Text(
                        'Key Metrics',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildKeyMetricsGrid(summary),
                      const SizedBox(height: 24),
                      
                      // Recent Activity
                      const Text(
                        'Recent Activity',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildRecentActivities(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMetricSelector() {
    final metrics = [
      {'value': 'sales', 'label': 'Sales', 'icon': Icons.trending_up},
      {'value': 'transactions', 'label': 'Transactions', 'icon': Icons.receipt},
      {'value': 'fuel', 'label': 'Fuel Usage', 'icon': Icons.local_gas_station},
    ];
    
    return Row(
      children: metrics.map((metric) {
        final isSelected = _selectedMetric == metric['value'];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(metric['icon'] as IconData, size: 16),
                  const SizedBox(width: 4),
                  Text(metric['label'] as String),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedMetric = metric['value'] as String;
                  });
                }
              },
              selectedColor: const Color(0xFF0B3D2E).withOpacity(0.1),
              checkmarkColor: const Color(0xFF0B3D2E),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeRangeSelector() {
    final ranges = ['Today', 'Week', 'Month', 'Year'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ranges.map((range) {
          final isSelected = _selectedTimeRange == range;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTimeRange = range;
                });
              },
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

  List<double> _getChartData() {
    // Replace with real API data from repository
    switch (_selectedMetric) {
      case 'sales':
        return [45000, 52000, 48000, 58000, 62000, 59000, 68000];
      case 'transactions':
        return [28, 32, 30, 36, 38, 35, 42];
      case 'fuel':
        return [850, 920, 780, 950, 1020, 980, 1100];
      default:
        return [45000, 52000, 48000, 58000, 62000, 59000, 68000];
    }
  }

  String _getChartTitle() {
    switch (_selectedMetric) {
      case 'sales':
        return 'Sales Performance (KES)';
      case 'transactions':
        return 'Transaction Count';
      case 'fuel':
        return 'Fuel Dispensed (Liters)';
      default:
        return 'Performance';
    }
  }

  Widget _buildKeyMetricsGrid(StationSummary summary) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          'Today\'s Sales',
          'KES ${NumberFormat('#,##0').format(summary.todaySales)}',
          Icons.trending_up,
          Colors.green,
          summary.salesGrowth,
        ),
        _buildMetricCard(
          'Avg Transaction',
          'KES ${NumberFormat('#,##0').format(summary.averageTransactionValue)}',
          Icons.receipt,
          Colors.blue,
        ),
        _buildMetricCard(
          'Active Pumps',
          '${summary.activePumps}/${summary.totalPumps}',
          Icons.local_gas_station,
          Colors.orange,
        ),
        _buildMetricCard(
          'Staff Present',
          '${summary.activeAttendants}/${summary.totalAttendants}',
          Icons.people,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, [double? change]) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (change != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    change >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 12,
                    color: change >= 0 ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${change.abs().toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 10,
                      color: change >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    final activities = [
      StationActivity(
        id: '1',
        stationId: widget.stationId,
        stationName: widget.stationName,
        activityType: 'sale',
        description: 'Cash sale of KES 5,000',
        amount: 5000,
        attendantName: 'John M.',
        paymentType: 'cash',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      StationActivity(
        id: '2',
        stationId: widget.stationId,
        stationName: widget.stationName,
        activityType: 'sale',
        description: 'Card payment of KES 7,500',
        amount: 7500,
        attendantName: 'Sarah W.',
        paymentType: 'card',
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
      ),
      StationActivity(
        id: '3',
        stationId: widget.stationId,
        stationName: widget.stationName,
        activityType: 'shift_start',
        description: 'Shift started by Mary Gathoni',
        attendantName: 'Mary Gathoni',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];

    return Column(
      children: activities.map((activity) {
        return RecentActivityTile(activity: activity);
      }).toList(),
    );
  }
}