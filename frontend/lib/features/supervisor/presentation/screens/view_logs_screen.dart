// lib/features/supervisor/presentation/screens/view_logs_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../domain/models/override_pump.dart';
import '../../domain/models/supervision_intervention.dart';

// MARK: - Constants
class _ViewLogsConstants {
  static const Color primaryDark = Color(0xFF0B3D2E);
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color warningOrange = Color(0xFFF39C12);
  static const Color errorRed = Color(0xFFE74C3C);
  static const Color infoBlue = Color(0xFF3498DB);
  static const Color logPurple = Color(0xFF9C27B0);
}

// MARK: - Log Entry Model
enum LogType {
  intervention('Intervention', Icons.payment, _ViewLogsConstants.accentGreen),
  refill('Fuel Refill', Icons.local_gas_station, _ViewLogsConstants.infoBlue),
  reading('Meter Reading', Icons.speed, _ViewLogsConstants.logPurple),
  emergency('Emergency', Icons.warning, _ViewLogsConstants.errorRed),
  shiftApproval('Shift Approval', Icons.approval, _ViewLogsConstants.warningOrange);

  final String displayName;
  final IconData icon;
  final Color color;

  const LogType(this.displayName, this.icon, this.color);
}

class LogEntry {
  final String id;
  final LogType type;
  final String title;
  final String description;
  final DateTime timestamp;
  final String supervisorName;
  final String pumpName;
  final double? amount;
  final String? details;
  final bool isResolved;
  final FuelType? fuelType;  // Using FuelType from override_pump.dart
  final PumpStatus? pumpStatus;  // Using PumpStatus from override_pump.dart
  final InterventionType? interventionType;  // Using InterventionType from supervision_intervention.dart

  LogEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.supervisorName,
    required this.pumpName,
    this.amount,
    this.details,
    this.isResolved = true,
    this.fuelType,
    this.pumpStatus,
    this.interventionType,
  });

  String get formattedTime => DateFormat('HH:mm:ss').format(timestamp);
  String get formattedDate => DateFormat('dd MMM yyyy').format(timestamp);
  String get formattedDateTime => DateFormat('dd MMM yyyy, HH:mm').format(timestamp);
  
  String get fuelTypeDisplayName => fuelType?.displayName ?? 'N/A';
  IconData get fuelTypeIcon => fuelType?.icon ?? Icons.local_gas_station;
  Color get fuelTypeColor => fuelType?.color ?? Colors.grey;
  
  String get pumpStatusDisplayName => pumpStatus?.displayName ?? 'N/A';
  Color get pumpStatusColor => pumpStatus?.color ?? Colors.grey;
  
  String get interventionTypeDisplayName => interventionType?.displayName ?? 'N/A';
}

class ViewLogsScreen extends StatefulWidget {
  final String supervisorName;
  final String supervisorId;

  const ViewLogsScreen({
    super.key,
    required this.supervisorName,
    required this.supervisorId,
  });

  @override
  State<ViewLogsScreen> createState() => _ViewLogsScreenState();
}

class _ViewLogsScreenState extends State<ViewLogsScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  List<LogEntry> _allLogs = [];
  List<LogEntry> _filteredLogs = [];
  
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;
  LogType? _selectedTypeFilter;
  bool _isLoading = true;
  
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _loadLogs() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _allLogs = _getMockLogs();
        _applyFilters();
        _isLoading = false;
      });
    });
  }

  List<LogEntry> _getMockLogs() {
    final now = DateTime.now();
    return [
      LogEntry(
        id: 'INT001',
        type: LogType.intervention,
        title: 'Override Sale',
        description: 'Processed sale of KES 2,500 on Pump 3',
        timestamp: now.subtract(const Duration(minutes: 15)),
        supervisorName: widget.supervisorName,
        pumpName: 'Pump 3',
        amount: 2500,
        details: 'Customer: John Doe, Phone: 0712345678, Reason: Attendant busy',
        fuelType: FuelType.petrol,
        pumpStatus: PumpStatus.active,
        interventionType: InterventionType.sale,
      ),
      LogEntry(
        id: 'REF001',
        type: LogType.refill,
        title: 'Fuel Refill',
        description: 'Added 5,000L of Petrol to Tank 1',
        timestamp: now.subtract(const Duration(minutes: 32)),
        supervisorName: widget.supervisorName,
        pumpName: 'Tank 1',
        amount: 5000,
        details: 'Supplier: Total Energies, Cost: KES 180.50/L, Total: KES 902,500',
        fuelType: FuelType.petrol,
      ),
      LogEntry(
        id: 'RED001',
        type: LogType.reading,
        title: 'Meter Reading',
        description: 'Recorded reading 12,425.8L on Pump 1',
        timestamp: now.subtract(const Duration(hours: 1)),
        supervisorName: widget.supervisorName,
        pumpName: 'Pump 1',
        details: 'Previous: 12,345.6L, Dispensed: 80.2L',
        fuelType: FuelType.petrol,
        pumpStatus: PumpStatus.active,
      ),
      LogEntry(
        id: 'EMG001',
        type: LogType.emergency,
        title: 'Emergency Stop',
        description: 'Emergency activated on Pump 3 - Pump Malfunction',
        timestamp: now.subtract(const Duration(hours: 2)),
        supervisorName: widget.supervisorName,
        pumpName: 'Pump 3',
        details: 'Reason: Meter not displaying correctly',
        isResolved: true,
        fuelType: FuelType.petrol,
        pumpStatus: PumpStatus.emergency,
      ),
      LogEntry(
        id: 'APP001',
        type: LogType.shiftApproval,
        title: 'Shift Approval',
        description: 'Approved shift report SR003 for Peter Odhiambo',
        timestamp: now.subtract(const Duration(hours: 3)),
        supervisorName: widget.supervisorName,
        pumpName: 'Pump 3',
        details: 'Variance: -KES 108 (Shortage)',
        fuelType: FuelType.petrol,
      ),
      LogEntry(
        id: 'INT002',
        type: LogType.intervention,
        title: 'Override Sale',
        description: 'Processed sale of KES 5,000 on Pump 2',
        timestamp: now.subtract(const Duration(hours: 4)),
        supervisorName: 'Mary Gathoni',
        pumpName: 'Pump 2',
        amount: 5000,
        details: 'Customer: Sarah W., Payment: M-Pesa',
        fuelType: FuelType.diesel,
        pumpStatus: PumpStatus.active,
        interventionType: InterventionType.sale,
      ),
      LogEntry(
        id: 'REF002',
        type: LogType.refill,
        title: 'Fuel Refill',
        description: 'Added 8,000L of Diesel to Tank 2',
        timestamp: now.subtract(const Duration(days: 1)),
        supervisorName: 'Mike Otieno',
        pumpName: 'Tank 2',
        amount: 8000,
        details: 'Supplier: Vivo Energy, Cost: KES 165.00/L',
        fuelType: FuelType.diesel,
      ),
    ];
  }

  void _applyFilters() {
    setState(() {
      _filteredLogs = _allLogs.where((log) {
        // Tab filter
        if (_tabController.index != 0) {
          switch (_tabController.index) {
            case 1: // Interventions
              if (log.type != LogType.intervention) return false;
              break;
            case 2: // Refills
              if (log.type != LogType.refill) return false;
              break;
            case 3: // Emergencies
              if (log.type != LogType.emergency) return false;
              break;
          }
        }

        // Search filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final matches = log.title.toLowerCase().contains(query) ||
              log.description.toLowerCase().contains(query) ||
              log.pumpName.toLowerCase().contains(query) ||
              log.supervisorName.toLowerCase().contains(query) ||
              log.fuelTypeDisplayName.toLowerCase().contains(query);
          if (!matches) return false;
        }

        // Date range filter
        if (_selectedDateRange != null) {
          if (log.timestamp.isBefore(_selectedDateRange!.start) ||
              log.timestamp.isAfter(_selectedDateRange!.end)) {
            return false;
          }
        }

        // Type filter
        if (_selectedTypeFilter != null && log.type != _selectedTypeFilter) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _searchQuery = query);
        _applyFilters();
      }
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _ViewLogsConstants.primaryDark,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && mounted) {
      setState(() {
        _selectedDateRange = picked;
        _applyFilters();
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedDateRange = null;
      _selectedTypeFilter = null;
      _searchQuery = '';
      _searchController.clear();
      _applyFilters();
    });
  }

  void _showLogDetails(LogEntry log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: log.type.color.withAlpha(26),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          log.type.icon,
                          color: log.type.color,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              log.type.displayName,
                              style: TextStyle(
                                fontSize: 14,
                                color: log.type.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildDetailRow('Log ID', log.id),
                      _buildDetailRow('Date & Time', log.formattedDateTime),
                      _buildDetailRow('Pump/Tank', log.pumpName),
                      _buildDetailRow('Supervisor', log.supervisorName),
                      _buildDetailRow('Description', log.description),
                      // Using fuelType from imported model
                      if (log.fuelType != null)
                        _buildDetailRow('Fuel Type', log.fuelTypeDisplayName,
                            valueColor: log.fuelTypeColor),
                      if (log.amount != null)
                        _buildDetailRow(
                          'Amount',
                          'KES ${NumberFormat('#,##0').format(log.amount)}',
                          valueColor: _ViewLogsConstants.accentGreen,
                        ),
                      if (log.details != null)
                        _buildDetailRow('Details', log.details!),
                      if (log.type == LogType.emergency)
                        _buildDetailRow(
                          'Status',
                          log.isResolved ? 'Resolved' : 'Active',
                          valueColor: log.isResolved ? _ViewLogsConstants.accentGreen : _ViewLogsConstants.errorRed,
                        ),
                      // Using pumpStatus from imported model
                      if (log.pumpStatus != null)
                        _buildDetailRow('Pump Status', log.pumpStatusDisplayName,
                            valueColor: log.pumpStatusColor),
                      // Using interventionType from imported model
                      if (log.interventionType != null)
                        _buildDetailRow('Intervention Type', log.interventionTypeDisplayName),
                    ],
                  ),
                ),
                
                // Close Button
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _ViewLogsConstants.primaryDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(LogEntry log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: log.type == LogType.emergency && !log.isResolved
            ? BorderSide(color: _ViewLogsConstants.errorRed, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showLogDetails(log),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: log.type.color.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  log.type.icon,
                  color: log.type.color,
                  size: 24,
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
                          log.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: log.type.color.withAlpha(26),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            log.type.displayName,
                            style: TextStyle(
                              fontSize: 9,
                              color: log.type.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // Fuel type badge using imported FuelType
                        if (log.fuelType != null)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: log.fuelTypeColor.withAlpha(26),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  log.fuelTypeIcon,
                                  size: 10,
                                  color: log.fuelTypeColor,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  log.fuelTypeDisplayName,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: log.fuelTypeColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      log.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          log.formattedTime,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.person_outline,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          log.supervisorName,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.local_gas_station,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          log.pumpName,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (log.amount != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'KES ${NumberFormat('#,##0').format(log.amount)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _ViewLogsConstants.accentGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                  ],
                )
              else
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Activity Logs'),
        backgroundColor: _ViewLogsConstants.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          onTap: (_) => _applyFilters(),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Interventions'),
            Tab(text: 'Refills'),
            Tab(text: 'Emergencies'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _selectDateRange,
            tooltip: 'Filter by Date',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search logs...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                if (_selectedDateRange != null || _selectedTypeFilter != null)
                  const SizedBox(width: 8),
                if (_selectedDateRange != null || _selectedTypeFilter != null)
                  IconButton(
                    icon: const Icon(Icons.clear_all),
                    onPressed: _clearFilters,
                    tooltip: 'Clear Filters',
                  ),
              ],
            ),
          ),

          // Active Filters
          if (_selectedDateRange != null || _selectedTypeFilter != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_selectedDateRange != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _ViewLogsConstants.infoBlue.withAlpha(26),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: _ViewLogsConstants.infoBlue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: _ViewLogsConstants.infoBlue,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDateRange = null;
                                  _applyFilters();
                                });
                              },
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: _ViewLogsConstants.infoBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_selectedTypeFilter != null) ...[
                      if (_selectedDateRange != null) const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedTypeFilter!.color.withAlpha(26),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _selectedTypeFilter!.icon,
                              size: 14,
                              color: _selectedTypeFilter!.color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _selectedTypeFilter!.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                color: _selectedTypeFilter!.color,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTypeFilter = null;
                                  _applyFilters();
                                });
                              },
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: _selectedTypeFilter!.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // Results Count
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredLogs.length} logs found',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                if (_filteredLogs.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Export feature coming soon!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.file_download_outlined, size: 16),
                    label: const Text('Export'),
                  ),
              ],
            ),
          ),

          // Logs List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLogs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 72,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No logs found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your filters',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _clearFilters,
                              icon: const Icon(Icons.clear_all),
                              label: const Text('Clear Filters'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          HapticFeedback.mediumImpact();
                          _loadLogs();
                        },
                        color: _ViewLogsConstants.primaryDark,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredLogs.length,
                          itemBuilder: (context, index) {
                            final log = _filteredLogs[index];
                            return _buildLogCard(log);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Filter by Type',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...LogType.values.map((type) {
                    return ListTile(
                      leading: Icon(type.icon, color: type.color),
                      title: Text(type.displayName),
                      onTap: () {
                        setState(() {
                          _selectedTypeFilter = type;
                          _applyFilters();
                        });
                        Navigator.pop(context);
                      },
                    );
                  }),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.clear_all),
                    title: const Text('Clear Filter'),
                    onTap: () {
                      setState(() {
                        _selectedTypeFilter = null;
                        _applyFilters();
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          );
        },
        icon: const Icon(Icons.filter_list),
        label: const Text('Filter by Type'),
        backgroundColor: _ViewLogsConstants.primaryDark,
      ),
    );
  }
}