// lib/features/supervisor/presentation/screens/shift_approval_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// MARK: - Constants
class _ShiftApprovalConstants {
  static const Color primaryDark = Color(0xFF0B3D2E);
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color warningOrange = Color(0xFFF39C12);
  static const Color errorRed = Color(0xFFE74C3C);
  static const Color approvalBlue = Color(0xFF3498DB);
  static const Color pendingOrange = Color(0xFFFF9800);
  static const Color approvedGreen = Color(0xFF4CAF50);
  static const Color rejectedRed = Color(0xFFF44336);
  static const Color reviewPurple = Color(0xFF9C27B0);
}

// MARK: - Shift Report Model
class ShiftReportForApproval {
  final String id;
  final String attendantId;
  final String attendantName;
  final String pumpId;
  final String pumpName;
  final DateTime shiftDate;
  final DateTime shiftStart;
  final DateTime shiftEnd;
  final double openingMeter;
  final double closingMeter;
  final double fuelDispensed;
  final double expectedCash;
  final double actualCash;
  final double mpesaTotal;
  final double cashTotal;
  final double variance;
  final String? remarks;
  final ReportStatus status;

  ShiftReportForApproval({
    required this.id,
    required this.attendantId,
    required this.attendantName,
    required this.pumpId,
    required this.pumpName,
    required this.shiftDate,
    required this.shiftStart,
    required this.shiftEnd,
    required this.openingMeter,
    required this.closingMeter,
    required this.fuelDispensed,
    required this.expectedCash,
    required this.actualCash,
    required this.mpesaTotal,
    required this.cashTotal,
    required this.variance,
    this.remarks,
    required this.status,
  });

  bool get hasVariance => variance != 0;
  bool get isShortage => variance < 0;
  bool get isExcess => variance > 0;
  String get varianceStatus => isShortage ? 'Shortage' : (isExcess ? 'Excess' : 'Balanced');
  Color get varianceColor => isShortage ? _ShiftApprovalConstants.errorRed : (isExcess ? _ShiftApprovalConstants.warningOrange : _ShiftApprovalConstants.accentGreen);
  
  String get formattedFuelDispensed => NumberFormat('#,##0.0').format(fuelDispensed);
  String get formattedExpectedCash => NumberFormat('#,##0').format(expectedCash);
  String get formattedActualCash => NumberFormat('#,##0').format(actualCash);
  String get formattedVariance => NumberFormat('#,##0').format(variance.abs());
  String get formattedShiftTime => '${DateFormat('HH:mm').format(shiftStart)} - ${DateFormat('HH:mm').format(shiftEnd)}';
}

enum ReportStatus {
  pending('Pending', Icons.pending, _ShiftApprovalConstants.pendingOrange),
  underReview('Under Review', Icons.visibility, _ShiftApprovalConstants.reviewPurple),
  approved('Approved', Icons.check_circle, _ShiftApprovalConstants.approvedGreen),
  rejected('Rejected', Icons.cancel, _ShiftApprovalConstants.rejectedRed);

  final String displayName;
  final IconData icon;
  final Color color;

  const ReportStatus(this.displayName, this.icon, this.color);
}

class ShiftApprovalScreen extends StatefulWidget {
  final String supervisorName;
  final String supervisorId;

  const ShiftApprovalScreen({
    super.key,
    required this.supervisorName,
    required this.supervisorId,
  });

  @override
  State<ShiftApprovalScreen> createState() => _ShiftApprovalScreenState();
}

class _ShiftApprovalScreenState extends State<ShiftApprovalScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  List<ShiftReportForApproval> _allReports = [];
  List<ShiftReportForApproval> _filteredReports = [];
  
  String _searchQuery = '';
  String? _selectedPumpFilter;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Filter counts
  int get _pendingCount => _allReports.where((r) => r.status == ReportStatus.pending).length;
  int get _underReviewCount => _allReports.where((r) => r.status == ReportStatus.underReview).length;
  int get _approvedCount => _allReports.where((r) => r.status == ReportStatus.approved).length;
  int get _rejectedCount => _allReports.where((r) => r.status == ReportStatus.rejected).length;

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  // Available pumps for filter
  final List<String> _availablePumps = [
    'Pump 1', 'Pump 2', 'Pump 3', 'Pump 4', 'Pump 5', 'Pump 6'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _loadReports() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    // Simulate API call
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _allReports = _getMockReports();
        _applyFilters();
        _isLoading = false;
      });
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load reports. Please try again.';
          _isLoading = false;
        });
      }
    });
  }

  List<ShiftReportForApproval> _getMockReports() {
    final now = DateTime.now();
    return [
      ShiftReportForApproval(
        id: 'SR001',
        attendantId: '1',
        attendantName: 'John Mwangi',
        pumpId: '1',
        pumpName: 'Pump 1',
        shiftDate: now,
        shiftStart: now.subtract(const Duration(hours: 8)),
        shiftEnd: now,
        openingMeter: 12345.6,
        closingMeter: 12425.8,
        fuelDispensed: 80.2,
        expectedCash: 14436,
        actualCash: 14436,
        mpesaTotal: 12000,
        cashTotal: 2436,
        variance: 0,
        status: ReportStatus.pending,
      ),
      ShiftReportForApproval(
        id: 'SR002',
        attendantId: '2',
        attendantName: 'Sarah Wanjiku',
        pumpId: '2',
        pumpName: 'Pump 2',
        shiftDate: now,
        shiftStart: now.subtract(const Duration(hours: 8)),
        shiftEnd: now,
        openingMeter: 23456.7,
        closingMeter: 23562.3,
        fuelDispensed: 105.6,
        expectedCash: 17424,
        actualCash: 17424,
        mpesaTotal: 15000,
        cashTotal: 2424,
        variance: 0,
        status: ReportStatus.pending,
      ),
      ShiftReportForApproval(
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
        remarks: 'Cash shortage of KES 108 - customer short-changed?',
        status: ReportStatus.underReview,
      ),
      ShiftReportForApproval(
        id: 'SR004',
        attendantId: '4',
        attendantName: 'Grace Akinyi',
        pumpId: '4',
        pumpName: 'Pump 4',
        shiftDate: now.subtract(const Duration(days: 1)),
        shiftStart: now.subtract(const Duration(days: 1, hours: 8)),
        shiftEnd: now.subtract(const Duration(days: 1)),
        openingMeter: 45678.9,
        closingMeter: 45768.2,
        fuelDispensed: 89.3,
        expectedCash: 16074,
        actualCash: 16200,
        mpesaTotal: 14000,
        cashTotal: 2200,
        variance: 126,
        remarks: 'Excess of KES 126 - customer overpaid',
        status: ReportStatus.pending,
      ),
      ShiftReportForApproval(
        id: 'SR005',
        attendantId: '5',
        attendantName: 'Lucy Wambui',
        pumpId: '5',
        pumpName: 'Pump 5',
        shiftDate: now.subtract(const Duration(days: 1)),
        shiftStart: now.subtract(const Duration(days: 1, hours: 8)),
        shiftEnd: now.subtract(const Duration(days: 1)),
        openingMeter: 56789.0,
        closingMeter: 56879.5,
        fuelDispensed: 90.5,
        expectedCash: 10860,
        actualCash: 10860,
        mpesaTotal: 9000,
        cashTotal: 1860,
        variance: 0,
        status: ReportStatus.approved,
      ),
      ShiftReportForApproval(
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
        remarks: 'Large variance of KES 236.5 - requires investigation',
        status: ReportStatus.underReview,
      ),
    ];
  }

  void _applyFilters() {
    setState(() {
      _filteredReports = _allReports.where((report) {
        // Tab filter
        if (_tabController.index != 0) {
          switch (_tabController.index) {
            case 1: // Pending
              if (report.status != ReportStatus.pending) return false;
              break;
            case 2: // Under Review
              if (report.status != ReportStatus.underReview) return false;
              break;
            case 3: // Approved
              if (report.status != ReportStatus.approved) return false;
              break;
            case 4: // Rejected
              if (report.status != ReportStatus.rejected) return false;
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

  Future<void> _approveReport(ShiftReportForApproval report) async {
    final TextEditingController remarksController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: _ShiftApprovalConstants.accentGreen),
            const SizedBox(width: 8),
            const Text('Approve Shift Report'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Approve shift report for ${report.attendantName} on ${report.pumpName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: remarksController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Approval Remarks (Optional)',
                hintText: 'Add any notes or observations',
                border: OutlineInputBorder(),
              ),
            ),
            if (report.hasVariance) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: report.varianceColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      report.isShortage ? Icons.trending_down : Icons.trending_up,
                      color: report.varianceColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Variance of ${report.formattedVariance} (${report.varianceStatus}) will be noted',
                        style: TextStyle(color: report.varianceColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _ShiftApprovalConstants.accentGreen,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        final index = _allReports.indexWhere((r) => r.id == report.id);
        if (index != -1) {
          final remarksText = remarksController.text.trim();
          _allReports[index] = ShiftReportForApproval(
            id: report.id,
            attendantId: report.attendantId,
            attendantName: report.attendantName,
            pumpId: report.pumpId,
            pumpName: report.pumpName,
            shiftDate: report.shiftDate,
            shiftStart: report.shiftStart,
            shiftEnd: report.shiftEnd,
            openingMeter: report.openingMeter,
            closingMeter: report.closingMeter,
            fuelDispensed: report.fuelDispensed,
            expectedCash: report.expectedCash,
            actualCash: report.actualCash,
            mpesaTotal: report.mpesaTotal,
            cashTotal: report.cashTotal,
            variance: report.variance,
            remarks: remarksText.isNotEmpty ? remarksText : report.remarks,
            status: ReportStatus.approved,
          );
        }
        _applyFilters();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report ${report.id} approved successfully'),
          backgroundColor: _ShiftApprovalConstants.accentGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _rejectReport(ShiftReportForApproval report) async {
    final TextEditingController reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cancel, color: _ShiftApprovalConstants.errorRed),
            const SizedBox(width: 8),
            const Text('Reject Shift Report'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject shift report for ${report.attendantName} on ${report.pumpName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason for Rejection *',
                hintText: 'Explain why this report is being rejected',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: reasonController.text.trim().isEmpty ? null : () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _ShiftApprovalConstants.errorRed,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final reason = reasonController.text.trim();
      setState(() {
        final index = _allReports.indexWhere((r) => r.id == report.id);
        if (index != -1) {
          _allReports[index] = ShiftReportForApproval(
            id: report.id,
            attendantId: report.attendantId,
            attendantName: report.attendantName,
            pumpId: report.pumpId,
            pumpName: report.pumpName,
            shiftDate: report.shiftDate,
            shiftStart: report.shiftStart,
            shiftEnd: report.shiftEnd,
            openingMeter: report.openingMeter,
            closingMeter: report.closingMeter,
            fuelDispensed: report.fuelDispensed,
            expectedCash: report.expectedCash,
            actualCash: report.actualCash,
            mpesaTotal: report.mpesaTotal,
            cashTotal: report.cashTotal,
            variance: report.variance,
            remarks: 'Rejected: $reason',
            status: ReportStatus.rejected,
          );
        }
        _applyFilters();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report ${report.id} rejected'),
          backgroundColor: _ShiftApprovalConstants.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      HapticFeedback.mediumImpact();
    }
  }

  void _flagForReview(ShiftReportForApproval report) {
    setState(() {
      final index = _allReports.indexWhere((r) => r.id == report.id);
      if (index != -1) {
        _allReports[index] = ShiftReportForApproval(
          id: report.id,
          attendantId: report.attendantId,
          attendantName: report.attendantName,
          pumpId: report.pumpId,
          pumpName: report.pumpName,
          shiftDate: report.shiftDate,
          shiftStart: report.shiftStart,
          shiftEnd: report.shiftEnd,
          openingMeter: report.openingMeter,
          closingMeter: report.closingMeter,
          fuelDispensed: report.fuelDispensed,
          expectedCash: report.expectedCash,
          actualCash: report.actualCash,
          mpesaTotal: report.mpesaTotal,
          cashTotal: report.cashTotal,
          variance: report.variance,
          remarks: report.remarks,
          status: ReportStatus.underReview,
        );
      }
      _applyFilters();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Report ${report.id} flagged for review'),
        backgroundColor: _ShiftApprovalConstants.approvalBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showReportDetails(ShiftReportForApproval report) {
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
                    color: report.status.color.withAlpha(26),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.receipt,
                              color: report.status.color,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Report ${report.id}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: report.status.color,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    report.status.displayName,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  report.attendantName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Attendant',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 30,
                            width: 1,
                            color: Colors.grey.shade300,
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  report.pumpName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Pump',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 30,
                            width: 1,
                            color: Colors.grey.shade300,
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  DateFormat('dd MMM').format(report.shiftDate),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  report.formattedShiftTime,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                      _buildInfoSection('Meter Readings', [
                        _buildInfoRow('Opening', '${NumberFormat('#,##0.0').format(report.openingMeter)} L'),
                        _buildInfoRow('Closing', '${NumberFormat('#,##0.0').format(report.closingMeter)} L'),
                        _buildInfoRow('Fuel Dispensed', '${report.formattedFuelDispensed} L',
                            valueColor: _ShiftApprovalConstants.approvalBlue),
                      ]),
                      
                      const SizedBox(height: 16),
                      
                      _buildInfoSection('Financial Summary', [
                        _buildInfoRow('Expected Cash', 'KES ${report.formattedExpectedCash}'),
                        _buildInfoRow('Actual Cash', 'KES ${report.formattedActualCash}'),
                        _buildInfoRow('M-Pesa Total', 'KES ${NumberFormat('#,##0').format(report.mpesaTotal)}'),
                        _buildInfoRow('Cash Total', 'KES ${NumberFormat('#,##0').format(report.cashTotal)}'),
                        const Divider(height: 24),
                        _buildInfoRow(
                          'Variance',
                          '${report.isShortage ? "-" : (report.isExcess ? "+" : "")}KES ${report.formattedVariance}',
                          valueColor: report.varianceColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ]),
                      
                      if (report.remarks != null && report.remarks!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildInfoSection('Remarks', [
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              report.remarks!,
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ),
                        ]),
                      ],
                    ],
                  ),
                ),
                
                // Action Buttons
                if (report.status == ReportStatus.pending || report.status == ReportStatus.underReview)
                  Container(
                    padding: const EdgeInsets.all(20),
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
                            onPressed: () {
                              Navigator.pop(context);
                              _flagForReview(report);
                            },
                            icon: const Icon(Icons.visibility),
                            label: const Text('Review Later'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _rejectReport(report);
                            },
                            icon: const Icon(Icons.close),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _ShiftApprovalConstants.errorRed,
                              side: const BorderSide(color: _ShiftApprovalConstants.errorRed),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _approveReport(report);
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _ShiftApprovalConstants.accentGreen,
                              padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _buildInfoRow(String label, String value, {Color? valueColor, FontWeight? fontWeight}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(
            value,
            style: TextStyle(
              fontWeight: fontWeight ?? FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(ShiftReportForApproval report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: report.hasVariance
            ? BorderSide(color: report.varianceColor, width: 1)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showReportDetails(report),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: report.status.color.withAlpha(26),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      report.status.icon,
                      color: report.status.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${report.pumpName} - ${report.attendantName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('dd MMM yyyy').format(report.shiftDate),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (report.hasVariance)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: report.varianceColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${report.isShortage ? "-" : "+"}KES ${report.formattedVariance}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: report.varianceColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatChip(
                      'Fuel',
                      '${report.formattedFuelDispensed}L',
                      _ShiftApprovalConstants.approvalBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatChip(
                      'Expected',
                      'KES ${report.formattedExpectedCash}',
                      Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatChip(
                      'Actual',
                      'KES ${report.formattedActualCash}',
                      _ShiftApprovalConstants.accentGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (report.status == ReportStatus.pending) ...[
                    TextButton.icon(
                      onPressed: () => _flagForReview(report),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Review'),
                      style: TextButton.styleFrom(
                        foregroundColor: _ShiftApprovalConstants.approvalBlue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _rejectReport(report),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: TextButton.styleFrom(
                        foregroundColor: _ShiftApprovalConstants.errorRed,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _approveReport(report),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _ShiftApprovalConstants.accentGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ] else if (report.status == ReportStatus.underReview) ...[
                    TextButton.icon(
                      onPressed: () => _rejectReport(report),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: TextButton.styleFrom(
                        foregroundColor: _ShiftApprovalConstants.errorRed,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _approveReport(report),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _ShiftApprovalConstants.accentGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ] else if (report.status == ReportStatus.approved) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '✓ Approved',
                        style: TextStyle(
                          fontSize: 12,
                          color: _ShiftApprovalConstants.approvedGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ] else if (report.status == ReportStatus.rejected) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '✗ Rejected',
                        style: TextStyle(
                          fontSize: 12,
                          color: _ShiftApprovalConstants.rejectedRed,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Shift Report Approvals'),
        backgroundColor: _ShiftApprovalConstants.primaryDark,
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
            Tab(text: 'Pending'),
            Tab(text: 'Review'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search by ID, attendant, pump...',
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
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All Pumps'),
                        selected: _selectedPumpFilter == null,
                        onSelected: (_) {
                          setState(() {
                            _selectedPumpFilter = null;
                            _applyFilters();
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
                              _applyFilters();
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Error Message - Now using _errorMessage
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _ShiftApprovalConstants.errorRed.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _ShiftApprovalConstants.errorRed.withAlpha(77)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: _ShiftApprovalConstants.errorRed),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: _ShiftApprovalConstants.errorRed),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: _ShiftApprovalConstants.errorRed),
                    onPressed: () => setState(() => _errorMessage = null),
                  ),
                ],
              ),
            ),

          // Summary Stats
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildSummaryChip('Pending', _pendingCount, _ShiftApprovalConstants.pendingOrange),
                const SizedBox(width: 8),
                _buildSummaryChip('Review', _underReviewCount, _ShiftApprovalConstants.reviewPurple),
                const SizedBox(width: 8),
                _buildSummaryChip('Approved', _approvedCount, _ShiftApprovalConstants.approvedGreen),
                const SizedBox(width: 8),
                _buildSummaryChip('Rejected', _rejectedCount, _ShiftApprovalConstants.rejectedRed),
              ],
            ),
          ),

          // Reports List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredReports.isEmpty
                    ? Center(
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
                              'No shift reports found',
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
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          HapticFeedback.mediumImpact();
                          _loadReports();
                        },
                        color: _ShiftApprovalConstants.primaryDark,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredReports.length,
                          itemBuilder: (context, index) {
                            final report = _filteredReports[index];
                            return _buildReportCard(report);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, int count, Color color) {
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
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}