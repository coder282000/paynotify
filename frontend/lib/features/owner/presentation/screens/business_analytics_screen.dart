// lib/features/owner/presentation/screens/business_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/owner_provider.dart';
import '../../domain/models/station_summary_model.dart'; 
import '../../widgets/performance_chart.dart';
import '../../widgets/business_kpi_card.dart';
import '../../widgets/payment_breakdown_chart.dart';

class BusinessAnalyticsScreen extends StatefulWidget {
  const BusinessAnalyticsScreen({super.key});

  @override
  State<BusinessAnalyticsScreen> createState() => _BusinessAnalyticsScreenState();
}

class _BusinessAnalyticsScreenState extends State<BusinessAnalyticsScreen> {
  String _selectedTimeRange = 'Week';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OwnerProvider>().loadAllStationsSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OwnerProvider>();
    final summaries = provider.stationSummaries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Analytics'),
        backgroundColor: const Color(0xFF0B3D2E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.refreshData(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time Range Selector
                  _buildTimeRangeSelector(),
                  const SizedBox(height: 16),
                  
                  // KPI Cards Row
                  Row(
                    children: [
                      Expanded(
                        child: BusinessKPICard(
                          title: 'Total Revenue',
                          value: 'KES ${NumberFormat('#,##0').format(provider.totalMonthlySales)}',
                          subtitle: 'This Month',
                          icon: Icons.trending_up,
                          color: Colors.green,
                          change: 12.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BusinessKPICard(
                          title: 'Transactions',
                          value: provider.todayTransactions.toString(),
                          subtitle: 'Today',
                          icon: Icons.receipt,
                          color: Colors.blue,
                          change: 8.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: BusinessKPICard(
                          title: 'Active Stations',
                          value: provider.stations.where((s) => s.isActive).length.toString(),
                          subtitle: 'Total: ${provider.stations.length}',
                          icon: Icons.business,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BusinessKPICard(
                          title: 'Active Staff',
                          value: provider.totalAttendants.toString(),
                          subtitle: 'Across all stations',
                          icon: Icons.people,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Sales Chart
                  const Text(
                    'Sales Performance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 250,
                    child: PerformanceChart(
                      data: [45000, 52000, 48000, 58000, 62000, 59000, 68000],
                      labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                      title: 'Weekly Sales',
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Payment Breakdown
                  const Text(
                    'Payment Method Distribution',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  PaymentBreakdownChart(
                    cashTotal: summaries.fold(0.0, (sum, s) => sum + s.cashTotal),
                    cardTotal: summaries.fold(0.0, (sum, s) => sum + s.cardTotal),
                    mpesaTotal: summaries.fold(0.0, (sum, s) => sum + s.mpesaTotal),
                  ),
                  const SizedBox(height: 24),
                  
                  // Top Performing Station
                  const Text(
                    'Station Performance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (summaries.isNotEmpty)
                    _buildTopStationCard(summaries),
                ],
              ),
            ),
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

  Widget _buildTopStationCard(List<StationSummary> summaries) {
    if (summaries.isEmpty) return const SizedBox.shrink();
    
    final topStation = summaries.reduce(
      (a, b) => a.todaySales > b.todaySales ? a : b,
    );
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.emoji_events, color: Colors.green, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topStation.stationName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Today\'s Sales: KES ${NumberFormat('#,##0').format(topStation.todaySales)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    'Transactions: ${topStation.todayTransactions}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'TOP STATION',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}