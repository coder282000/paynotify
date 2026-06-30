// lib/features/owner/presentation/screens/all_stations_overview.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/owner_provider.dart';
import '../../widgets/station_card.dart';
import 'station_details_screen.dart';
import '../../domain/models/station_summary_model.dart';

class AllStationsOverview extends StatefulWidget {
  const AllStationsOverview({super.key});

  @override
  State<AllStationsOverview> createState() => _AllStationsOverviewState();
}

class _AllStationsOverviewState extends State<AllStationsOverview> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OwnerProvider>();
      provider.loadStations();
      provider.loadAllStationsSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OwnerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Stations'),
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
      body: provider.isLoading && provider.stations.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.stations.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.business, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No stations found'),
                      SizedBox(height: 8),
                      Text(
                        'You don\'t have any stations yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: provider.refreshData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.stations.length,
                    itemBuilder: (context, index) {
                      final station = provider.stations[index];
                      final summary = provider.stationSummaries.firstWhere(
                        (s) => s.stationId == station.id,
                        orElse: () => StationSummary(
                          stationId: station.id,
                          stationName: station.stationName,
                          stationCode: station.stationCode,
                          todaySales: 0,
                          weeklySales: 0,
                          monthlySales: 0,
                          yearlySales: 0,
                          lastMonthSales: 0,
                          salesGrowth: 0,
                          todayTransactions: 0,
                          totalTransactions: 0,
                          averageTransactionValue: 0,
                          cashTotal: 0,
                          cardTotal: 0,
                          mpesaTotal: 0,
                          totalPumps: 0,
                          activePumps: 0,
                          pumpsUnderMaintenance: 0,
                          totalAttendants: 0,
                          activeAttendants: 0,
                          pendingShiftReports: 0,
                          totalFuelInventory: 0,
                          lowFuelAlerts: 0,
                          attendantPerformanceScore: 0,
                          customerSatisfaction: 0,
                          lastUpdated: DateTime.now(),
                        ),
                      );
                      return StationCard(
                        station: station,
                        summary: summary,
                        onTap: () {
                          // FIX: Create NEW provider instance for StationDetailsScreen (same as OwnerDashboard)
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider(
                                create: (_) => OwnerProvider(),  // New instance
                                child: StationDetailsScreen(
                                  stationId: station.id,
                                  stationName: station.stationName,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}