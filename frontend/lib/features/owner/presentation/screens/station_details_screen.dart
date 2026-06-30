// lib/features/owner/presentation/screens/station_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/owner_provider.dart';
import '../../domain/models/station_summary_model.dart';

class StationDetailsScreen extends StatefulWidget {
  final int stationId;
  final String stationName;
  
  const StationDetailsScreen({
    super.key,
    required this.stationId,
    required this.stationName,
  });

  @override
  State<StationDetailsScreen> createState() => _StationDetailsScreenState();
}

class _StationDetailsScreenState extends State<StationDetailsScreen> {
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
        title: Text(widget.stationName),
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
              : RefreshIndicator(
                  onRefresh: () => provider.loadStationSummary(widget.stationId),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildKPIsCard(summary),
                        const SizedBox(height: 16),
                        _buildPaymentBreakdownCard(summary),
                        const SizedBox(height: 16),
                        _buildOperationalMetricsCard(summary),
                        const SizedBox(height: 16),
                        _buildPerformanceCard(summary),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildKPIsCard(StationSummary summary) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
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
            const Text(
              'Key Performance Indicators',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildKPIItem(
                    'Today\'s Sales',
                    'KES ${NumberFormat('#,##0').format(summary.todaySales)}',
                    Icons.today,
                  ),
                ),
                Expanded(
                  child: _buildKPIItem(
                    'This Month',
                    'KES ${NumberFormat('#,##0').format(summary.monthlySales)}',
                    Icons.calendar_month,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildKPIItem(
                    'Avg Transaction',
                    'KES ${NumberFormat('#,##0').format(summary.averageTransactionValue)}',
                    Icons.receipt,
                  ),
                ),
                Expanded(
                  child: _buildKPIItem(
                    'Growth',
                    '${summary.salesGrowth.toStringAsFixed(1)}%',
                    summary.salesGrowth >= 0 ? Icons.trending_up : Icons.trending_down,
                    valueColor: summary.salesGrowth >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIItem(String label, String value, IconData icon,
      {Color valueColor = Colors.white}) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPaymentBreakdownCard(StationSummary summary) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Method Breakdown',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildPaymentRow('Cash', summary.cashTotal, summary.cashPercentage, Colors.green),
            const SizedBox(height: 8),
            _buildPaymentRow('Card', summary.cardTotal, summary.cardPercentage, Colors.blue),
            const SizedBox(height: 8),
            _buildPaymentRow('M-Pesa', summary.mpesaTotal, summary.mpesaPercentage, Colors.orange),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Sales', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'KES ${NumberFormat('#,##0').format(summary.totalSales)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String label, double amount, double percentage, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Text(label)),
            Text('KES ${NumberFormat('#,##0').format(amount)}', style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            SizedBox(
              width: 50,
              child: Text(
                '(${percentage.toStringAsFixed(1)}%)',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildOperationalMetricsCard(StationSummary summary) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Operational Metrics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildMetricRow('Pump Utilization', '${summary.activePumps}/${summary.totalPumps} active', summary.pumpUtilization, Colors.green),
            const SizedBox(height: 12),
            _buildMetricRow('Staff Utilization', '${summary.activeAttendants}/${summary.totalAttendants} active', summary.attendantUtilization, Colors.blue),
            const SizedBox(height: 12),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Column(
                  children: [
                    const Icon(Icons.local_gas_station, size: 20, color: Colors.grey),
                    const SizedBox(height: 4),
                    Text('${summary.totalFuelInventory.toStringAsFixed(0)}L', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Text('Total Fuel', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                )),
                Expanded(child: Column(
                  children: [
                    const Icon(Icons.warning, size: 20, color: Colors.orange),
                    const SizedBox(height: 4),
                    Text(summary.lowFuelAlerts.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Text('Low Fuel Alerts', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                )),
                Expanded(child: Column(
                  children: [
                    const Icon(Icons.people, size: 20, color: Colors.grey),
                    const SizedBox(height: 4),
                    Text('${summary.totalTransactions}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Text('Transactions', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String subtitle, double value, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ),
            Text('${value.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceCard(StationSummary summary) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Performance Metrics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 80,
                            width: 80,
                            child: CircularProgressIndicator(
                              value: summary.attendantPerformanceScore / 100,
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0B3D2E)),
                              strokeWidth: 8,
                            ),
                          ),
                          Text('${summary.attendantPerformanceScore.toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('Staff Performance', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Icon(Icons.star, size: 40, color: Colors.amber),
                      const SizedBox(height: 8),
                      Text('${summary.customerSatisfaction}/100',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Text('Customer Satisfaction', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
}