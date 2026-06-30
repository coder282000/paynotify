// lib/features/supervisor/presentation/screens/supervisor_dashboard.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../shared/screens/ai_assistant_screen.dart';
import '../../domain/models/override_pump.dart';
import '../providers/supervisor_provider.dart';
import 'pump_override_screen.dart';
import 'fuel_refill_screen.dart';
import 'meter_reading_screen.dart';
import 'shift_approval_screen.dart';
import 'emergency_control_screen.dart';
import 'view_logs_screen.dart';
import 'reports_screen.dart';

// MARK: - Constants
class _SupervisorConstants {
  static const Color primaryDark = Color(0xFF0B3D2E);
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color warningOrange = Color(0xFFF39C12);
  static const Color errorRed = Color(0xFFE74C3C);
  static const Color supervisorPurple = Color(0xFF9C27B0);
}

class SupervisorDashboard extends StatefulWidget {
  final String supervisorName;
  final String supervisorId;

  const SupervisorDashboard({
    super.key,
    required this.supervisorName,
    required this.supervisorId,
  });

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  List<OverridePump> _pumps = [];
  bool _isLoading = true;
  int _activeAlerts = 0;
  int _pendingApprovals = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() {
      _pumps = _getMockPumps();
      _activeAlerts = _pumps.where((p) => p.needsAttention).length;
      _pendingApprovals = 3;
      _isLoading = false;
    });
  }

  Future<void> _refreshData() async {
    await _loadData();
    HapticFeedback.lightImpact();
  }

  List<OverridePump> _getMockPumps() {
    return [
      OverridePump(
        id: '1',
        name: 'Pump 1',
        fuelType: FuelType.petrol,
        status: PumpStatus.active,
        attendantName: 'John Mwangi',
        pricePerLiter: 180.50,
        currentFuelLevel: 4500,
        tankCapacity: 10000,
        todaySales: 12500,
      ),
      OverridePump(
        id: '2',
        name: 'Pump 2',
        fuelType: FuelType.diesel,
        status: PumpStatus.active,
        attendantName: 'Sarah Wanjiku',
        pricePerLiter: 165.00,
        currentFuelLevel: 8200,
        tankCapacity: 15000,
        todaySales: 18400,
      ),
      OverridePump(
        id: '3',
        name: 'Pump 3',
        fuelType: FuelType.petrol,
        status: PumpStatus.idle,
        attendantName: null,
        pricePerLiter: 180.50,
        currentFuelLevel: 1200,
        tankCapacity: 10000,
        todaySales: 0,
        needsAttention: true,
        alertMessage: 'Low fuel - 12% remaining',
      ),
      OverridePump(
        id: '4',
        name: 'Pump 4',
        fuelType: FuelType.diesel,
        status: PumpStatus.occupied,
        attendantName: 'Mike T.',
        pricePerLiter: 165.00,
        currentFuelLevel: 6300,
        tankCapacity: 15000,
        todaySales: 8900,
      ),
      OverridePump(
        id: '5',
        name: 'Pump 5',
        fuelType: FuelType.kerosene,
        status: PumpStatus.maintenance,
        attendantName: null,
        pricePerLiter: 120.00,
        currentFuelLevel: 500,
        tankCapacity: 8000,
        todaySales: 0,
        needsAttention: true,
        alertMessage: 'Under maintenance',
      ),
      OverridePump(
        id: '6',
        name: 'Pump 6',
        fuelType: FuelType.premium,
        status: PumpStatus.active,
        attendantName: 'Grace K.',
        pricePerLiter: 195.00,
        currentFuelLevel: 3800,
        tankCapacity: 10000,
        todaySales: 5600,
      ),
    ];
  }

  // NAVIGATION METHODS
  void _navigateToPumpOverride() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PumpOverrideScreen(
          supervisorName: widget.supervisorName,
          supervisorId: widget.supervisorId,
          pumps: _pumps,
        ),
      ),
    ).then((_) => _refreshData());
  }

  void _navigateToFuelRefill() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FuelRefillScreen(
          supervisorName: widget.supervisorName,
          supervisorId: widget.supervisorId,
          pumps: _pumps,
        ),
      ),
    ).then((_) => _refreshData());
  }

  void _navigateToMeterReading() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MeterReadingScreen(
          supervisorName: widget.supervisorName,
          supervisorId: widget.supervisorId,
          pumps: _pumps,
        ),
      ),
    ).then((_) => _refreshData());
  }

  void _navigateToShiftApproval() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShiftApprovalScreen(
          supervisorName: widget.supervisorName,
          supervisorId: widget.supervisorId,
        ),
      ),
    ).then((_) => _refreshData());
  }

  void _navigateToEmergencyControl() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmergencyControlScreen(
          supervisorName: widget.supervisorName,
          supervisorId: widget.supervisorId,
          pumps: _pumps,
        ),
      ),
    );
  }

  void _navigateToViewLogs() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewLogsScreen(
          supervisorName: widget.supervisorName,
          supervisorId: widget.supervisorId,
        ),
      ),
    );
  }

  void _navigateToReports() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportsScreen(
          supervisorName: widget.supervisorName,
          supervisorId: widget.supervisorId,
        ),
      ),
    );
  }

  void _navigateToAIAssistant() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AIAssistantScreen(
          isManager: false,
          attendantName: 'Supervisor',
        ),
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Session'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<SupervisorProvider>(context, listen: false).endSession();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return 'KES ${NumberFormat('#,##0').format(amount)}';
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(77)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPumpCard(OverridePump pump) {
    final todaySales = pump.todaySales;
    final isActive = pump.status == PumpStatus.active || pump.status == PumpStatus.occupied;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: pump.needsAttention
            ? BorderSide(color: _SupervisorConstants.warningOrange, width: 1)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: pump.fuelType.color.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    pump.fuelType.icon,
                    color: pump.fuelType.color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            pump.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: pump.status.color.withAlpha(26),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  pump.status.icon,
                                  size: 12,
                                  color: pump.status.color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  pump.status.displayName,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: pump.status.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pump.fuelType.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (pump.attendantName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Attendant: ${pump.attendantName}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatCurrency(pump.pricePerLiter),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: pump.fuelType.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '/liter',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Fuel Level
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Fuel Level',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '${pump.fuelPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: pump.fuelLevelColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pump.fuelPercentage / 100,
                    backgroundColor: pump.fuelLevelColor.withAlpha(51),
                    valueColor: AlwaysStoppedAnimation<Color>(pump.fuelLevelColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Today's Sales
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: _SupervisorConstants.accentGreen.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Today\'s Sales',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    _formatCurrency(todaySales),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _SupervisorConstants.accentGreen,
                    ),
                  ),
                ],
              ),
            ),
            
            if (pump.needsAttention && pump.alertMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _SupervisorConstants.warningOrange.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      size: 16,
                      color: _SupervisorConstants.warningOrange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pump.alertMessage!,
                        style: TextStyle(
                          fontSize: 11,
                          color: _SupervisorConstants.warningOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Action Buttons
            Row(
              children: [
                if (isActive)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _navigateToPumpOverride(),
                      icon: const Icon(Icons.payment, size: 18),
                      label: const Text('Override'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: pump.fuelType.color,
                        side: BorderSide(color: pump.fuelType.color),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                if (isActive) const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToEmergencyControl(),
                    icon: const Icon(Icons.warning, size: 18),
                    label: const Text('Emergency'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _SupervisorConstants.errorRed,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalTodaySales = _pumps.fold<double>(0, (sum, p) => sum + p.todaySales);
    final activePumps = _pumps.where((p) => p.status == PumpStatus.active || p.status == PumpStatus.occupied).length;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Supervisor Dashboard'),
        backgroundColor: _SupervisorConstants.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: _SupervisorConstants.primaryDark,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _SupervisorConstants.supervisorPurple,
                      _SupervisorConstants.supervisorPurple.withAlpha(204),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white,
                      child: Text(
                        widget.supervisorName.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _SupervisorConstants.supervisorPurple,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${widget.supervisorName}!',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Supervisor Access',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withAlpha(204),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(26),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'SUPERVISOR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Active Pumps',
                      '$activePumps / ${_pumps.length}',
                      Icons.local_gas_station,
                      _SupervisorConstants.accentGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Pending Approvals',
                      '$_pendingApprovals',
                      Icons.pending_actions,
                      _SupervisorConstants.warningOrange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Active Alerts',
                      '$_activeAlerts',
                      Icons.notifications_active,
                      _SupervisorConstants.errorRed,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Today's Sales Summary
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Today\'s Total Sales',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      _formatCurrency(totalTodaySales),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _SupervisorConstants.accentGreen,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildQuickAction(
                    icon: Icons.payment,
                    label: 'Any Pump\nSale',
                    color: _SupervisorConstants.accentGreen,
                    onTap: _navigateToPumpOverride,
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    icon: Icons.local_gas_station,
                    label: 'Fuel\nRefill',
                    color: Colors.blue,
                    onTap: _navigateToFuelRefill,
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    icon: Icons.speed,
                    label: 'Meter\nReading',
                    color: Colors.purple,
                    onTap: _navigateToMeterReading,
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    icon: Icons.approval,
                    label: 'Approve\nShifts',
                    color: _SupervisorConstants.warningOrange,
                    onTap: _navigateToShiftApproval,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildQuickAction(
                    icon: Icons.warning,
                    label: 'Emergency\nStop',
                    color: _SupervisorConstants.errorRed,
                    onTap: _navigateToEmergencyControl,
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    icon: Icons.smart_toy,
                    label: 'AI\nAssistant',
                    color: _SupervisorConstants.supervisorPurple,
                    onTap: _navigateToAIAssistant,
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    icon: Icons.history,
                    label: 'View\nLogs',
                    color: Colors.grey,
                    onTap: _navigateToViewLogs,
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    icon: Icons.analytics,
                    label: 'Reports',
                    color: Colors.teal,
                    onTap: _navigateToReports,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Pump Status Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pump Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () => _showComingSoon('Full Pump View'),
                    icon: const Icon(Icons.chevron_right, size: 16),
                    label: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _pumps.length,
                      itemBuilder: (context, index) {
                        final pump = _pumps[index];
                        return _buildPumpCard(pump);
                      },
                    ),
              
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for "Coming Soon" feature (used for Full Pump View)
  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}