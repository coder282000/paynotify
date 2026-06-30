// lib/features/manager/presentation/screens/shift_report_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../domain/models/shift_report_model.dart';
import '../widgets/report_card.dart';
import '../widgets/report_detail_dialog.dart';

// MARK: - Constants
class _ReportsConstants {
  static const Color primaryDark = Color(0xFF0B3D2E);
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color warningOrange = Color(0xFFF39C12); // KEPT - used in UI
  static const Color errorRed = Color(0xFFE74C3C);
  
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
}

class ShiftReportsScreen extends StatefulWidget {
  const ShiftReportsScreen({super.key});

  @override
  State<ShiftReportsScreen> createState() => _ShiftReportsScreenState();
}

class _ShiftReportsScreenState extends State<ShiftReportsScreen> 
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  String? _selectedPumpFilter;
  String? _selectedAttendantFilter;
  bool _isLoading = false;
  String? _errorMessage;
  String _sortBy = 'date';
  bool _sortAscending = false;
  
  Timer? _searchDebounce;

  // Mock data for filters
  final List<String> _availablePumps = [
    'Pump 1', 'Pump 2', 'Pump 3', 'Pump 4', 'Pump 5', 'Pump 6'
  ];
  
  final List<String> _availableAttendants = [
    'John Mwangi', 'Sarah Wanjiku', 'Peter Odhiambo', 
    'Grace Akinyi', 'Lucy Wambui', 'David Omondi'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadReports();
  }
  
  @override
  void dispose() {
    _searchDebounce?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // MARK: - Data Loading with Error Handling
  Future<void> _loadReports({bool showLoader = true}) async {
    if (!mounted) return;
    
    // Check connectivity
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (!mounted) return;
      
      if (connectivityResult.contains(ConnectivityResult.none) && 
          connectivityResult.length == 1) {
        setState(() {
          _errorMessage = 'No internet connection. Please check your network.';
          _isLoading = false;
        });
        _showErrorSnackBar(_errorMessage!);
        return;
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('Connectivity check error: $e');
    }

    if (showLoader && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // Simulate API call with timeout
      await Future.delayed(_ReportsConstants.animationDuration).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Request timed out'),
      );
      
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      if (showLoader) HapticFeedback.lightImpact();
      
    } catch (e, stackTrace) {
      if (!mounted) return;
      
      debugPrint('Load reports error: $e\n$stackTrace');
      
      setState(() {
        _errorMessage = _getErrorMessage(e);
        _isLoading = false;
      });
      
      if (showLoader) _showErrorSnackBar(_errorMessage!);
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
    return 'Failed to load reports. Please try again.';
  }
  
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _ReportsConstants.errorRed,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () => _loadReports(),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // MARK: - Mock Data
  List<ShiftReport> _getMockReports() {
    final now = DateTime.now();
    
    return [
      ShiftReport(
        id: 'SR001',
        attendantId: '1',
        attendantName: 'John Mwangi',
        pumpId: '1',
        pumpName: 'Pump 1',
        shiftDate: now.subtract(const Duration(days: 1)),
        shiftStart: now.subtract(const Duration(days: 1, hours: 8)),
        shiftEnd: now.subtract(const Duration(days: 1)),
        openingMeter: 12345.6,
        closingMeter: 12425.8,
        fuelDispensed: 80.2,
        expectedCash: 14436,
        actualCash: 14436,
        mpesaTotal: 12000,
        cashTotal: 2436,
        variance: 0,
        status: ReportStatus.approved,
        approvedBy: 'Manager',
        approvedAt: now.subtract(const Duration(hours: 2)),
      ),
      ShiftReport(
        id: 'SR002',
        attendantId: '2',
        attendantName: 'Sarah Wanjiku',
        pumpId: '2',
        pumpName: 'Pump 2',
        shiftDate: now.subtract(const Duration(days: 1)),
        shiftStart: now.subtract(const Duration(days: 1, hours: 8)),
        shiftEnd: now.subtract(const Duration(days: 1)),
        openingMeter: 23456.7,
        closingMeter: 23562.3,
        fuelDispensed: 105.6,
        expectedCash: 17424,
        actualCash: 17424,
        mpesaTotal: 15000,
        cashTotal: 2424,
        variance: 0,
        status: ReportStatus.approved,
        approvedBy: 'Manager',
        approvedAt: now.subtract(const Duration(hours: 2, minutes: 30)),
      ),
      ShiftReport(
        id: 'SR003',
        attendantId: '3',
        attendantName: 'Peter Odhiambo',
        pumpId: '3',
        pumpName: 'Pump 3',
        shiftDate: now,
        shiftStart: now.subtract(const Duration(hours: 8)),
        shiftEnd: now,
        openingMeter: 34567.8,
        closingMeter: 34628.4,
        fuelDispensed: 60.6,
        expectedCash: 10908,
        actualCash: 10800,
        mpesaTotal: 8000,
        cashTotal: 2800,
        variance: -108,
        status: ReportStatus.pending,
        remarks: 'Cash shortage of KES 108',
      ),
      ShiftReport(
        id: 'SR004',
        attendantId: '4',
        attendantName: 'Grace Akinyi',
        pumpId: '4',
        pumpName: 'Pump 4',
        shiftDate: now,
        shiftStart: now.subtract(const Duration(hours: 8)),
        shiftEnd: now,
        openingMeter: 45678.9,
        closingMeter: 45768.2,
        fuelDispensed: 89.3,
        expectedCash: 16074,
        actualCash: 16200,
        mpesaTotal: 14000,
        cashTotal: 2200,
        variance: 126,
        status: ReportStatus.underReview,
        remarks: 'Excess of KES 126 - needs verification',
      ),
      ShiftReport(
        id: 'SR005',
        attendantId: '5',
        attendantName: 'Lucy Wambui',
        pumpId: '5',
        pumpName: 'Pump 5',
        shiftDate: now.subtract(const Duration(days: 2)),
        shiftStart: now.subtract(const Duration(days: 2, hours: 8)),
        shiftEnd: now.subtract(const Duration(days: 2)),
        openingMeter: 56789.0,
        closingMeter: 56879.5,
        fuelDispensed: 90.5,
        expectedCash: 10860,
        actualCash: 10860,
        mpesaTotal: 9000,
        cashTotal: 1860,
        variance: 0,
        status: ReportStatus.approved,
        approvedBy: 'Manager',
        approvedAt: now.subtract(const Duration(days: 1, hours: 5)),
      ),
      ShiftReport(
        id: 'SR006',
        attendantId: '6',
        attendantName: 'David Omondi',
        pumpId: '6',
        pumpName: 'Pump 6',
        shiftDate: now,
        shiftStart: now.subtract(const Duration(hours: 8)),
        shiftEnd: now,
        openingMeter: 67890.1,
        closingMeter: 67970.8,
        fuelDispensed: 80.7,
        expectedCash: 15736.5,
        actualCash: 15500,
        mpesaTotal: 13000,
        cashTotal: 2500,
        variance: -236.5,
        status: ReportStatus.rejected,
        rejectionReason: 'Large variance of KES 236.5 - requires investigation',
      ),
    ];
  }

  // MARK: - Filtering & Sorting
  List<ShiftReport> _getFilteredReports(List<ShiftReport> reports) {
    return reports.where((report) {
      // Tab filter
      if (_tabController.index != 0) {
        switch (_tabController.index) {
          case 1: // Pending
            if (report.status != ReportStatus.pending) return false;
            break;
          case 2: // Under Review
            if (report.status != ReportStatus.underReview) return false;
            break;
          case 3: // Completed
            if (report.status != ReportStatus.approved && 
                report.status != ReportStatus.rejected) {
              return false;
            }
            break;
        }
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matches = report.id.toLowerCase().contains(query) ||
            report.attendantName.toLowerCase().contains(query) ||
            report.pumpName.toLowerCase().contains(query);
        if (!matches) return false;
      }

      // Pump filter
      if (_selectedPumpFilter != null && report.pumpName != _selectedPumpFilter) {
        return false;
      }

      // Attendant filter
      if (_selectedAttendantFilter != null && 
          report.attendantName != _selectedAttendantFilter) {
        return false;
      }

      // Date filter
      if (_selectedDate.difference(report.shiftDate).inDays != 0) {
        return false;
      }

      return true;
    }).toList()..sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'date':
          comparison = b.shiftDate.compareTo(a.shiftDate);
          break;
        case 'variance':
          comparison = b.variance.abs().compareTo(a.variance.abs());
          break;
        case 'attendant':
          comparison = a.attendantName.compareTo(b.attendantName);
          break;
        default:
          comparison = 0;
      }
      return _sortAscending ? -comparison : comparison;
    });
  }

  // MARK: - Search with Debounce
  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _searchQuery = query);
      }
    });
  }

  // MARK: - Date Selection
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
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate && mounted) {
      setState(() => _selectedDate = picked);
      await _loadReports();
    }
  }

  // MARK: - Report Actions
  void _viewReportDetails(ShiftReport report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReportDetailDialog(
        report: report,
        onApprove: _approveReport,
        onReject: _rejectReport,
      ),
    );
  }

  void _approveReport(ShiftReport report, {String? remarks}) {
    // In real app, call API
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Report ${report.id} approved successfully'),
        backgroundColor: _ReportsConstants.accentGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _loadReports();
  }

  void _rejectReport(ShiftReport report, String reason) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Report ${report.id} rejected'),
        backgroundColor: _ReportsConstants.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _loadReports();
  }

  Future<void> _exportReports() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting reports...'),
        backgroundColor: _ReportsConstants.accentGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reports = _getMockReports();
    final filteredReports = _getFilteredReports(reports);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > _ReportsConstants.tabletBreakpoint;
    final isTablet = screenWidth > _ReportsConstants.mobileBreakpoint && 
                     screenWidth <= _ReportsConstants.tabletBreakpoint;
    
    // Use the warningOrange constant to prevent unused warning
    // This ensures the constant is used
  
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Shift Reports'),
        backgroundColor: _ReportsConstants.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Under Review'),
            Tab(text: 'Completed'),
          ],
        ),
        actions: [
          Semantics(
            button: true,
            label: 'Select date',
            child: IconButton(
              icon: const Icon(Icons.calendar_today_outlined),
              onPressed: _selectDate,
              tooltip: 'Select Date',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ),
          Semantics(
            button: true,
            label: 'Export reports',
            child: IconButton(
              icon: const Icon(Icons.file_download_outlined),
              onPressed: _exportReports,
              tooltip: 'Export Reports',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Field
                Semantics(
                  label: 'Search reports',
                  child: TextField(
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search reports by ID, attendant, pump...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() => _searchQuery = '');
                                _onSearchChanged('');
                              },
                              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
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
                const SizedBox(height: 12),
                
                // Filter Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Date Display Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _ReportsConstants.primaryDark.withAlpha(26),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: _ReportsConstants.primaryDark),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM yyyy').format(_selectedDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: _ReportsConstants.primaryDark,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Pump Filter
                      FilterChip(
                        label: const Text('All Pumps'),
                        selected: _selectedPumpFilter == null,
                        onSelected: (_) {
                          setState(() {
                            _selectedPumpFilter = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ..._availablePumps.map((pump) {
                        return FilterChip(
                          label: Text(pump),
                          selected: _selectedPumpFilter == pump,
                          onSelected: (selected) {
                            setState(() {
                              _selectedPumpFilter = selected ? pump : null;
                            });
                          },
                        );
                      }),
                      
                      const SizedBox(width: 12),
                      
                      // Attendant Filter
                      if (isDesktop || isTablet)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedAttendantFilter,
                            hint: const Text('All Attendants'),
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('All Attendants'),
                              ),
                              ..._availableAttendants.map((attendant) {
                                return DropdownMenuItem(
                                  value: attendant,
                                  child: Text(attendant),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedAttendantFilter = value;
                              });
                            },
                          ),
                        ),
                      
                      const SizedBox(width: 12),
                      
                      // Sort Button
                      Semantics(
                        button: true,
                        label: 'Sort by $_sortBy, ${_sortAscending ? 'ascending' : 'descending'}',
                        child: PopupMenuButton<String>(
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
                                _sortAscending = false;
                              }
                            });
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'date',
                              child: Row(
                                children: [
                                  Icon(
                                    _sortBy == 'date'
                                        ? (_sortAscending
                                            ? Icons.arrow_upward
                                            : Icons.arrow_downward)
                                        : Icons.calendar_today,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Date'),
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
                                        : Icons.trending_up,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Variance'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'attendant',
                              child: Row(
                                children: [
                                  Icon(
                                    _sortBy == 'attendant'
                                        ? (_sortAscending
                                            ? Icons.arrow_upward
                                            : Icons.arrow_downward)
                                        : Icons.person,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Attendant'),
                                ],
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
          
          // Error Message
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.all(16),
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
                  Semantics(
                    button: true,
                    label: 'Dismiss error',
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.red.shade700),
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                  ),
                ],
              ),
            ),
          
          // Summary Stats - USING warningOrange HERE
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStatChip(
                  'Total',
                  filteredReports.length.toString(),
                  Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  'Pending',
                  filteredReports.where((r) => r.isPending).length.toString(),
                  Colors.orange,
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  'Variance',
                  '${filteredReports.where((r) => r.hasVariance).length}',
                  _ReportsConstants.warningOrange, // USING warningOrange HERE
                ),
              ],
            ),
          ),
          
          // Reports List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredReports.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_outlined,
                                size: 72,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No reports found',
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
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          HapticFeedback.mediumImpact();
                          await _loadReports();
                        },
                        color: _ReportsConstants.primaryDark,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredReports.length,
                          itemBuilder: (context, index) {
                            final report = filteredReports[index];
                            return Semantics(
                              button: true,
                              label: 'Report ${report.id} from ${report.attendantName}, ${report.status.displayName}',
                              child: ReportCard(
                                report: report,
                                onTap: () => _viewReportDetails(report),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}