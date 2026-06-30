// lib/features/manager/presentation/screens/attendant_performance_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/models/performance_model.dart';
import '../widgets/performance_card.dart';
import '../widgets/performance_chart.dart';

// MARK: - Constants
class _PerformanceConstants {
  static const Color primaryDark = Color(0xFF0B3D2E);
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color warningOrange = Color(0xFFF39C12);
  static const Color errorRed = Color(0xFFE74C3C);
  
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
}

class AttendantPerformanceScreen extends StatefulWidget {
  const AttendantPerformanceScreen({super.key});

  @override
  State<AttendantPerformanceScreen> createState() => _AttendantPerformanceScreenState();
}

class _AttendantPerformanceScreenState extends State<AttendantPerformanceScreen> 
    with TickerProviderStateMixin {
  
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  
  String _searchQuery = '';
  String? _selectedGradeFilter;
  bool _isLoading = false;
  String? _errorMessage;
  String _sortBy = 'name';
  bool _sortAscending = true;
  
  Timer? _searchDebounce;
  final TextEditingController _searchController = TextEditingController();

  List<AttendantPerformance> _getMockPerformances() {
    final DateTime now = DateTime.now();
    
    return [
      AttendantPerformance(
        attendantId: '1',
        attendantName: 'John Mwangi',
        pumpAssigned: 'Pump 1',
        joinDate: now.subtract(const Duration(days: 120)),
        totalShifts: 85,
        shiftsWithVariance: 3,
        totalSales: 1250000,
        totalShortages: 4500,
        totalExcess: 1200,
        netVariance: -3300,
        baseSalary: 30000,
        salaryDeduction: 3300,
        salaryBonus: 0,
        netSalary: 26700,
        recentRecords: [
          PerformanceRecord(
            id: '1',
            reportId: 'SR003',
            date: now.subtract(const Duration(days: 2)),
            pump: 'Pump 1',
            expected: 45000,
            actual: 44500,
            variance: -500,
            reason: 'Cash shortage',
            isApproved: true,
          ),
          PerformanceRecord(
            id: '2',
            reportId: 'SR008',
            date: now.subtract(const Duration(days: 5)),
            pump: 'Pump 1',
            expected: 38000,
            actual: 37600,
            variance: -400,
            reason: 'Counting error',
            isApproved: true,
          ),
          PerformanceRecord(
            id: '3',
            reportId: 'SR012',
            date: now.subtract(const Duration(days: 8)),
            pump: 'Pump 1',
            expected: 52000,
            actual: 52400,
            variance: 400,
            reason: 'Customer overpaid',
            isApproved: true,
          ),
        ],
      ),
      AttendantPerformance(
        attendantId: '2',
        attendantName: 'Sarah Wanjiku',
        pumpAssigned: 'Pump 2',
        joinDate: now.subtract(const Duration(days: 245)),
        totalShifts: 168,
        shiftsWithVariance: 1,
        totalSales: 2450000,
        totalShortages: 0,
        totalExcess: 1200,
        netVariance: 1200,
        baseSalary: 35000,
        salaryDeduction: 0,
        salaryBonus: 1200,
        netSalary: 36200,
        recentRecords: [
          PerformanceRecord(
            id: '4',
            reportId: 'SR005',
            date: now.subtract(const Duration(days: 3)),
            pump: 'Pump 2',
            expected: 55000,
            actual: 55600,
            variance: 600,
            reason: 'Excess',
            isApproved: true,
          ),
        ],
      ),
      AttendantPerformance(
        attendantId: '3',
        attendantName: 'Peter Odhiambo',
        pumpAssigned: 'Pump 3',
        joinDate: now.subtract(const Duration(days: 60)),
        totalShifts: 42,
        shiftsWithVariance: 5,
        totalSales: 620000,
        totalShortages: 8200,
        totalExcess: 0,
        netVariance: -8200,
        baseSalary: 28000,
        salaryDeduction: 8200,
        salaryBonus: 0,
        netSalary: 19800,
        recentRecords: [
          PerformanceRecord(
            id: '5',
            reportId: 'SR009',
            date: now.subtract(const Duration(days: 1)),
            pump: 'Pump 3',
            expected: 32000,
            actual: 31000,
            variance: -1000,
            reason: 'Cash shortage',
            isApproved: true,
          ),
          PerformanceRecord(
            id: '6',
            reportId: 'SR011',
            date: now.subtract(const Duration(days: 3)),
            pump: 'Pump 3',
            expected: 28000,
            actual: 27200,
            variance: -800,
            reason: 'Shortage',
            isApproved: true,
          ),
          PerformanceRecord(
            id: '7',
            reportId: 'SR014',
            date: now.subtract(const Duration(days: 6)),
            pump: 'Pump 3',
            expected: 35000,
            actual: 34300,
            variance: -700,
            reason: 'Miscount',
            isApproved: false,
          ),
        ],
      ),
      AttendantPerformance(
        attendantId: '4',
        attendantName: 'Grace Akinyi',
        pumpAssigned: 'Pump 4',
        joinDate: now.subtract(const Duration(days: 365)),
        totalShifts: 250,
        shiftsWithVariance: 0,
        totalSales: 3750000,
        totalShortages: 0,
        totalExcess: 0,
        netVariance: 0,
        baseSalary: 40000,
        salaryDeduction: 0,
        salaryBonus: 0,
        netSalary: 40000,
        recentRecords: [],
      ),
      AttendantPerformance(
        attendantId: '5',
        attendantName: 'Lucy Wambui',
        pumpAssigned: 'Pump 5',
        joinDate: now.subtract(const Duration(days: 90)),
        totalShifts: 65,
        shiftsWithVariance: 2,
        totalSales: 980000,
        totalShortages: 1500,
        totalExcess: 800,
        netVariance: -700,
        baseSalary: 30000,
        salaryDeduction: 1500,
        salaryBonus: 800,
        netSalary: 29300,
        recentRecords: [
          PerformanceRecord(
            id: '8',
            reportId: 'SR007',
            date: now.subtract(const Duration(days: 4)),
            pump: 'Pump 5',
            expected: 42000,
            actual: 41500,
            variance: -500,
            reason: 'Shortage',
            isApproved: true,
          ),
          PerformanceRecord(
            id: '9',
            reportId: 'SR013',
            date: now.subtract(const Duration(days: 10)),
            pump: 'Pump 5',
            expected: 38000,
            actual: 38500,
            variance: 500,
            reason: 'Excess',
            isApproved: true,
          ),
        ],
      ),
      AttendantPerformance(
        attendantId: '6',
        attendantName: 'David Omondi',
        pumpAssigned: 'Pump 6',
        joinDate: now.subtract(const Duration(days: 150)),
        totalShifts: 110,
        shiftsWithVariance: 4,
        totalSales: 1650000,
        totalShortages: 5500,
        totalExcess: 200,
        netVariance: -5300,
        baseSalary: 32000,
        salaryDeduction: 5500,
        salaryBonus: 200,
        netSalary: 26700,
        recentRecords: [
          PerformanceRecord(
            id: '10',
            reportId: 'SR006',
            date: now.subtract(const Duration(days: 2)),
            pump: 'Pump 6',
            expected: 48000,
            actual: 47200,
            variance: -800,
            reason: 'Shortage',
            isApproved: true,
          ),
          PerformanceRecord(
            id: '11',
            reportId: 'SR010',
            date: now.subtract(const Duration(days: 7)),
            pump: 'Pump 6',
            expected: 44000,
            actual: 44200,
            variance: 200,
            reason: 'Excess',
            isApproved: true,
          ),
        ],
      ),
    ];
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future.delayed(_PerformanceConstants.animationDuration);

    if (!mounted) return;
    
    setState(() {
      _isLoading = false;
    });
  }

  PerformanceSummary _getSummary(List<AttendantPerformance> performances) {
    final totalAttendants = performances.length;
    final attendantsWithVariance = performances.where((p) => p.shiftsWithVariance > 0).length;
    final totalShortages = performances.fold<double>(0, (sum, p) => sum + p.totalShortages);
    final totalExcess = performances.fold<double>(0, (sum, p) => sum + p.totalExcess);
    final totalVariance = totalExcess - totalShortages;
    final totalSalaryImpact = performances.fold<double>(0, (sum, p) => sum + (p.salaryBonus - p.salaryDeduction));

    return PerformanceSummary(
      startDate: _selectedDateRange.start,
      endDate: _selectedDateRange.end,
      totalAttendants: totalAttendants,
      attendantsWithVariance: attendantsWithVariance,
      totalShortages: totalShortages,
      totalExcess: totalExcess,
      totalVariance: totalVariance,
      totalSalaryImpact: totalSalaryImpact,
    );
  }

  List<AttendantPerformance> _getFilteredPerformances(List<AttendantPerformance> performances) {
    return performances.where((p) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matches = p.attendantName.toLowerCase().contains(query) ||
            (p.pumpAssigned?.toLowerCase().contains(query) ?? false);
        if (!matches) return false;
      }

      if (_selectedGradeFilter != null) {
        if (_selectedGradeFilter == 'Excellent' && p.accuracyRate < 99) return false;
        if (_selectedGradeFilter == 'Good' && (p.accuracyRate < 97 || p.accuracyRate >= 99)) return false;
        if (_selectedGradeFilter == 'Average' && (p.accuracyRate < 95 || p.accuracyRate >= 97)) return false;
        if (_selectedGradeFilter == 'Needs Improvement' && p.accuracyRate >= 95) return false;
      }

      return true;
    }).toList()..sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'name':
          comparison = a.attendantName.compareTo(b.attendantName);
          break;
        case 'accuracy':
          comparison = a.accuracyRate.compareTo(b.accuracyRate);
          break;
        case 'variance':
          comparison = a.netVariance.abs().compareTo(b.netVariance.abs());
          break;
        case 'salary':
          comparison = a.netSalary.compareTo(b.netSalary);
          break;
        default:
          comparison = 0;
      }
      return _sortAscending ? comparison : -comparison;
    });
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _searchQuery = query);
      }
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _PerformanceConstants.primaryDark,
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
      setState(() => _selectedDateRange = picked);
      _loadData();
    }
  }

  Future<void> _exportReport() async {
    try {
      final performances = _getFilteredPerformances(_getMockPerformances());
      
      final List<List<dynamic>> csvData = [
        ['Attendant', 'Pump', 'Join Date', 'Total Shifts', 'Shifts with Variance', 
         'Total Sales', 'Shortages', 'Excess', 'Net Variance', 'Base Salary', 
         'Salary Impact', 'Net Salary', 'Accuracy Rate', 'Grade'],
        ...performances.map((p) => [
          p.attendantName,
          p.pumpAssigned ?? 'N/A',
          DateFormat('yyyy-MM-dd').format(p.joinDate),
          p.totalShifts.toString(),
          p.shiftsWithVariance.toString(),
          p.totalSales.toString(),
          p.totalShortages.toString(),
          p.totalExcess.toString(),
          p.netVariance.toString(),
          p.baseSalary.toString(),
          (p.salaryBonus - p.salaryDeduction).toString(),
          p.netSalary.toString(),
          '${p.accuracyRate.toStringAsFixed(2)}%',
          p.performanceGrade,
        ]),
      ];
      
      final String csv = const ListToCsvConverter().convert(csvData);
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath = '${tempDir.path}/performance_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      
      final File file = File(filePath);
      await file.writeAsString(csv);
      
      if (!mounted) return;
      
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'PayNotifyy Performance Report',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export successful!'),
            backgroundColor: _PerformanceConstants.accentGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: _PerformanceConstants.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showPerformanceDetails(AttendantPerformance performance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: performance.gradeColor.withAlpha(26),
                        child: Text(
                          performance.attendantName.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: performance.gradeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              performance.attendantName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Grade: ${performance.performanceGrade} • ${performance.accuracyRate.toStringAsFixed(1)}% accuracy',
                              style: TextStyle(
                                color: performance.gradeColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                Divider(color: Colors.grey.shade200),
                
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildInfoSection('Performance Stats', [
                        _buildInfoRow('Total Shifts', '${performance.totalShifts}', Icons.calendar_today),
                        _buildInfoRow('Shifts with Variance', '${performance.shiftsWithVariance}', Icons.warning),
                        _buildInfoRow('Total Sales', 'KES ${NumberFormat('#,##0').format(performance.totalSales)}', Icons.trending_up),
                      ]),
                      
                      const SizedBox(height: 16),
                      
                      _buildInfoSection('Variance Analysis', [
                        _buildInfoRow('Shortages', 'KES ${NumberFormat('#,##0').format(performance.totalShortages)}', Icons.trending_down, valueColor: Colors.red),
                        _buildInfoRow('Excess', 'KES ${NumberFormat('#,##0').format(performance.totalExcess)}', Icons.trending_up, valueColor: Colors.green),
                        _buildInfoRow('Net Variance', '${performance.netVariance >= 0 ? "+" : "-"}KES ${NumberFormat('#,##0').format(performance.netVariance.abs())}', Icons.compare_arrows, 
                            valueColor: performance.netVariance >= 0 ? Colors.green : Colors.red),
                      ]),
                      
                      const SizedBox(height: 16),
                      
                      _buildInfoSection('Salary Impact', [
                        _buildInfoRow('Base Salary', 'KES ${NumberFormat('#,##0').format(performance.baseSalary)}', Icons.attach_money),
                        _buildInfoRow('Deductions', 'KES ${NumberFormat('#,##0').format(performance.salaryDeduction)}', Icons.remove_circle, valueColor: Colors.red),
                        _buildInfoRow('Bonuses', 'KES ${NumberFormat('#,##0').format(performance.salaryBonus)}', Icons.add_circle, valueColor: Colors.green),
                        const Divider(height: 24),
                        _buildInfoRow('Net Salary', 'KES ${NumberFormat('#,##0').format(performance.netSalary)}', Icons.account_balance_wallet, 
                            valueColor: performance.netSalary >= performance.baseSalary ? Colors.green : Colors.red),
                      ]),
                      
                      const SizedBox(height: 16),
                      
                      _buildInfoSection('Recent Records', [
                        ...performance.recentRecords.map((record) => 
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildRecordTile(record),
                          )
                        ),
                      ]),
                    ],
                  ),
                ),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.history),
                          label: const Text('View All Records'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: _PerformanceConstants.primaryDark),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.calculate),
                          label: const Text('Adjust Salary'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _PerformanceConstants.primaryDark,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordTile(PerformanceRecord record) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: record.varianceColor.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: record.varianceColor.withAlpha(77)),
      ),
      child: Row(
        children: [
          Icon(
            record.isShortage ? Icons.trending_down : Icons.trending_up,
            color: record.varianceColor,
            size: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${DateFormat('dd MMM yyyy').format(record.date)} • ${record.pump}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  record.reason ?? 'No reason provided',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${record.variance > 0 ? "+" : ""}${NumberFormat('#,##0').format(record.variance)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: record.varianceColor,
                ),
              ),
              if (!record.isApproved)
                const Text(
                  'Pending',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final performances = _getMockPerformances();
    final filteredPerformances = _getFilteredPerformances(performances);
    final summary = _getSummary(filteredPerformances);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > _PerformanceConstants.tabletBreakpoint;
    final isTablet = screenWidth > _PerformanceConstants.mobileBreakpoint && 
                     screenWidth <= _PerformanceConstants.tabletBreakpoint;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Attendant Performance'),
        backgroundColor: _PerformanceConstants.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_outlined),
            onPressed: _selectDateRange,
            tooltip: 'Select Date Range',
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _exportReport,
            tooltip: 'Export Report',
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Date Range Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('dd MMM yyyy').format(_selectedDateRange.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange.end)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            
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
                        hintText: 'Search by name or pump...',
                        prefixIcon: const Icon(Icons.search),
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
                  if (_searchQuery.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
            
            // Filter Chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All Grades'),
                      selected: _selectedGradeFilter == null,
                      onSelected: (_) {
                        setState(() {
                          _selectedGradeFilter = null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Excellent'),
                      selected: _selectedGradeFilter == 'Excellent',
                      onSelected: (selected) {
                        setState(() {
                          _selectedGradeFilter = selected ? 'Excellent' : null;
                        });
                      },
                      backgroundColor: Colors.green.withAlpha(26),
                      selectedColor: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Good'),
                      selected: _selectedGradeFilter == 'Good',
                      onSelected: (selected) {
                        setState(() {
                          _selectedGradeFilter = selected ? 'Good' : null;
                        });
                      },
                      backgroundColor: Colors.blue.withAlpha(26),
                      selectedColor: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Average'),
                      selected: _selectedGradeFilter == 'Average',
                      onSelected: (selected) {
                        setState(() {
                          _selectedGradeFilter = selected ? 'Average' : null;
                        });
                      },
                      backgroundColor: Colors.orange.withAlpha(26),
                      selectedColor: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Needs Improvement'),
                      selected: _selectedGradeFilter == 'Needs Improvement',
                      onSelected: (selected) {
                        setState(() {
                          _selectedGradeFilter = selected ? 'Needs Improvement' : null;
                        });
                      },
                      backgroundColor: Colors.red.withAlpha(26),
                      selectedColor: Colors.red,
                    ),
                    
                    const SizedBox(width: 16),
                    const VerticalDivider(width: 1),
                    const SizedBox(width: 16),
                    
                    PopupMenuButton<String>(
                      icon: Icon(
                        _sortAscending ? Icons.sort : Icons.sort_by_alpha,
                      ),
                      tooltip: 'Sort by',
                      onSelected: (value) {
                        setState(() {
                          if (_sortBy == value) {
                            _sortAscending = !_sortAscending;
                          } else {
                            _sortBy = value;
                            _sortAscending = true;
                          }
                        });
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'name',
                          child: Row(
                            children: [
                              Icon(
                                _sortBy == 'name'
                                    ? (_sortAscending
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward)
                                    : Icons.sort_by_alpha,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              const Text('Name'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'accuracy',
                          child: Row(
                            children: [
                              Icon(
                                _sortBy == 'accuracy'
                                    ? (_sortAscending
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward)
                                    : Icons.trending_up,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              const Text('Accuracy'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'variance',
                          child: Row(
                            children: [
                              Icon(
                                _sortBy == 'variance'
                                    ? (_sortAscending
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward)
                                    : Icons.compare_arrows,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              const Text('Variance'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'salary',
                          child: Row(
                            children: [
                              Icon(
                                _sortBy == 'salary'
                                    ? (_sortAscending
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward)
                                    : Icons.attach_money,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              const Text('Net Salary'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Summary Cards - Reduced height
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Attendants',
                          '${summary.totalAttendants}',
                          Icons.people,
                          _PerformanceConstants.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryCard(
                          'With Variance',
                          '${summary.attendantsWithVariance}',
                          Icons.warning,
                          _PerformanceConstants.warningOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Shortages',
                          'KES ${NumberFormat('#,##0').format(summary.totalShortages)}',
                          Icons.trending_down,
                          Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Excess',
                          'KES ${NumberFormat('#,##0').format(summary.totalExcess)}',
                          Icons.trending_up,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: summary.totalSalaryImpact >= 0 
                          ? Colors.green.withAlpha(26)
                          : Colors.red.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              color: summary.totalSalaryImpact >= 0 ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Total Salary Impact',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${summary.totalSalaryImpact >= 0 ? "+" : "-"}KES ${NumberFormat('#,##0').format(summary.totalSalaryImpact.abs())}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: summary.totalSalaryImpact >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: _PerformanceConstants.errorRed,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Performance Chart (Desktop/Tablet only) - Reduced height
            if (isDesktop || isTablet)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: PerformanceChart(
                  performances: filteredPerformances,
                  height: 180,
                ),
              ),
            
            // Performance List
            _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : filteredPerformances.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 72,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No attendants found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your filters',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          ...filteredPerformances.map((performance) {
                            return PerformanceCard(
                              performance: performance,
                              onTap: () => _showPerformanceDetails(performance),
                            );
                          }),
                          const SizedBox(height: 80), // Extra bottom padding
                        ],
                      ),
          ],
        ),
      ),
    );
  }
}