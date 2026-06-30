// lib/features/manager/presentation/screens/reconciliation_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../domain/models/reconciliation_model.dart';
import '../widgets/reconciliation_card.dart' as card_widget;
import '../widgets/reconciliation_summary.dart';

// MARK: - Constants
class _ReconciliationConstants {
  static const Color primaryDark = Color(0xFF0B3D2E);
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color warningOrange = Color(0xFFF39C12);
  static const Color errorRed = Color(0xFFE74C3C);
  
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
}

class ReconciliationScreen extends StatefulWidget {
  const ReconciliationScreen({super.key});

  @override
  State<ReconciliationScreen> createState() => _ReconciliationScreenState();
}

class _ReconciliationScreenState extends State<ReconciliationScreen> 
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
    _tabController = TabController(length: 3, vsync: this);
    _loadReconciliationData();
  }
  
  @override
  void dispose() {
    _searchDebounce?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // MARK: - Data Loading with Error Handling
  Future<void> _loadReconciliationData({bool showLoader = true}) async {
    if (!mounted) return;
    
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (!mounted) return;
      
      if (connectivityResult.contains(ConnectivityResult.none)) {
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
      await Future.delayed(_ReconciliationConstants.animationDuration).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Request timed out'),
      );
      
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      if (showLoader) HapticFeedback.lightImpact();
      
    } catch (e, stackTrace) {
      if (!mounted) return;
      
      debugPrint('Load reconciliation data error: $e\n$stackTrace');
      
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
    return 'Failed to load reconciliation data. Please try again.';
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
        backgroundColor: _ReconciliationConstants.errorRed,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () => _loadReconciliationData(),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // MARK: - Mock Data
  List<ReconciliationItem> _getMockReconciliationItems() {
    final now = DateTime.now();
    
    return [
      ReconciliationItem(
        id: 'REC001',
        reportId: 'SR003',
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
        pricePerLiter: 180,
        expectedCash: 10908,
        actualCash: 10800,
        mpesaTotal: 8000,
        cashTotal: 2800,
        variance: -108,
        status: ReconciliationStatus.pending,
        remarks: 'Cash shortage of KES 108',
      ),
      ReconciliationItem(
        id: 'REC002',
        reportId: 'SR004',
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
        pricePerLiter: 180,
        expectedCash: 16074,
        actualCash: 16200,
        mpesaTotal: 14000,
        cashTotal: 2200,
        variance: 126,
        status: ReconciliationStatus.underReview,
        remarks: 'Excess of KES 126 - needs verification',
      ),
      ReconciliationItem(
        id: 'REC003',
        reportId: 'SR006',
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
        pricePerLiter: 195,
        expectedCash: 15736.5,
        actualCash: 15500,
        mpesaTotal: 13000,
        cashTotal: 2500,
        variance: -236.5,
        status: ReconciliationStatus.pending,
        remarks: 'Large variance detected',
      ),
      ReconciliationItem(
        id: 'REC004',
        reportId: 'SR001',
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
        pricePerLiter: 180,
        expectedCash: 14436,
        actualCash: 14436,
        mpesaTotal: 12000,
        cashTotal: 2436,
        variance: 0,
        status: ReconciliationStatus.approved,
        approvedBy: 'Manager',
        approvedAt: now.subtract(const Duration(hours: 2)),
      ),
      ReconciliationItem(
        id: 'REC005',
        reportId: 'SR002',
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
        pricePerLiter: 165,
        expectedCash: 17424,
        actualCash: 17424,
        mpesaTotal: 15000,
        cashTotal: 2424,
        variance: 0,
        status: ReconciliationStatus.approved,
        approvedBy: 'Manager',
        approvedAt: now.subtract(const Duration(hours: 2, minutes: 30)),
      ),
    ];
  }

  ReconciliationSummaryData _getSummary(List<ReconciliationItem> items) {
    final totalItems = items.length;
    final pendingItems = items.where((i) => i.isPending).length;
    final approvedItems = items.where((i) => i.isApproved).length;
    final rejectedItems = items.where((i) => i.isRejected).length;
    final totalExpected = items.fold<double>(0, (sum, i) => sum + i.expectedCash);
    final totalActual = items.fold<double>(0, (sum, i) => sum + i.actualCash);
    final totalVariance = items.fold<double>(0, (sum, i) => sum + i.variance);
    final itemsWithVariance = items.where((i) => i.hasVariance).length;

    return ReconciliationSummaryData(
      date: _selectedDate,
      totalItems: totalItems,
      pendingItems: pendingItems,
      approvedItems: approvedItems,
      rejectedItems: rejectedItems,
      totalExpected: totalExpected,
      totalActual: totalActual,
      totalVariance: totalVariance,
      itemsWithVariance: itemsWithVariance,
    );
  }

  // MARK: - Filtering & Sorting
  List<ReconciliationItem> _getFilteredItems(List<ReconciliationItem> items) {
    return items.where((item) {
      if (_tabController.index != 0) {
        switch (_tabController.index) {
          case 1:
            if (!item.isPending) return false;
            break;
          case 2:
            if (!item.isApproved && !item.isRejected) return false;
            break;
        }
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matches = item.id.toLowerCase().contains(query) ||
            item.attendantName.toLowerCase().contains(query) ||
            item.pumpName.toLowerCase().contains(query);
        if (!matches) return false;
      }

      if (_selectedPumpFilter != null && item.pumpName != _selectedPumpFilter) {
        return false;
      }

      if (_selectedAttendantFilter != null && 
          item.attendantName != _selectedAttendantFilter) {
        return false;
      }

      if (_selectedDate.difference(item.shiftDate).inDays != 0) {
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

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _searchQuery = query);
      }
    });
  }

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
              primary: _ReconciliationConstants.primaryDark,
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
      await _loadReconciliationData();
    }
  }

  void _approveItem(ReconciliationItem item, {String? remarks}) {
    setState(() {
      item.status = ReconciliationStatus.approved;
      item.approvedBy = 'Manager';
      item.approvedAt = DateTime.now();
      item.remarks = remarks;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Report ${item.reportId} approved successfully'),
        backgroundColor: _ReconciliationConstants.accentGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _rejectItem(ReconciliationItem item, String reason) {
    setState(() {
      item.status = ReconciliationStatus.rejected;
      item.rejectionReason = reason;
      item.approvedBy = 'Manager';
      item.approvedAt = DateTime.now();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Report ${item.reportId} rejected'),
        backgroundColor: _ReconciliationConstants.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _flagForReview(ReconciliationItem item) {
    setState(() {
      item.status = ReconciliationStatus.underReview;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Report ${item.reportId} flagged for review'),
        backgroundColor: _ReconciliationConstants.warningOrange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _exportReport() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting reconciliation report...'),
        backgroundColor: _ReconciliationConstants.accentGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _getMockReconciliationItems();
    final filteredItems = _getFilteredItems(items);
    final summaryData = _getSummary(filteredItems);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > _ReconciliationConstants.tabletBreakpoint;
    final isTablet = screenWidth > _ReconciliationConstants.mobileBreakpoint && 
                     screenWidth <= _ReconciliationConstants.tabletBreakpoint;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Reconciliation'),
        backgroundColor: _ReconciliationConstants.primaryDark,
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
            Tab(text: 'Completed'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: _selectDate,
            tooltip: 'Select Date',
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _exportReport,
            tooltip: 'Export Report',
          ),
        ],
      ),
      body: SingleChildScrollView(  // ← Make the ENTIRE body scrollable
        child: Column(
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search by ID, attendant, pump...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() => _searchQuery = '');
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _ReconciliationConstants.primaryDark.withAlpha(26),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 14, color: _ReconciliationConstants.primaryDark),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('dd MMM yyyy').format(_selectedDate),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _ReconciliationConstants.primaryDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        
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
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red.shade700),
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            
            // Summary Stats
            ReconciliationSummary(
              summaryData: summaryData,
            ),
            
            // Items List - Now part of the scrollable column
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredItems.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('No reconciliation items found'),
                        ),
                      )
                    : Column(
                        children: filteredItems.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: card_widget.ReconciliationCard(
                              item: item,
                              onApprove: () => _approveItem(item),
                              onReject: (reason) => _rejectItem(item, reason),
                              onFlagForReview: () => _flagForReview(item),
                            ),
                          );
                        }).toList(),
                      ),
            
            // Extra bottom padding for desktop
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}