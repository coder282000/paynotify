// lib/features/manager/presentation/screens/transaction_history_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/models/manager_transaction.dart';
import '../../domain/models/transaction_filter.dart';
import '../widgets/transaction_filter_dialog.dart';

// MARK: - Constants
class _TransactionConstants {
  static const Color primaryDark = Color(0xFF0B3D2E);
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color warningOrange = Color(0xFFF39C12);
  static const Color errorRed = Color(0xFFE74C3C);
  
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
}

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> 
    with TickerProviderStateMixin {
  
  bool _isLoading = false;
  String? _errorMessage;
  List<ManagerTransaction> _allTransactions = [];
  List<ManagerTransaction> _filteredTransactions = [];
  TransactionFilter _filter = TransactionFilter();
  
  Timer? _searchDebounce;
  final TextEditingController _searchController = TextEditingController();
  
  // Summary stats
  double _totalAmount = 0;
  double _mpesaTotal = 0;
  double _cashTotal = 0;
  double _cardTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }
  
  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // MARK: - Data Loading with Error Handling
  Future<void> _loadTransactions({bool refresh = true}) async {
    if (!mounted) return;
    
    // Check connectivity
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

    if (refresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // Simulate API call with timeout
      await Future.delayed(_TransactionConstants.animationDuration).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Request timed out'),
      );
      
      if (!mounted) return;
      
      // Load mock data
      _allTransactions = _getMockTransactions();
      _applyFilters();
      
      setState(() => _isLoading = false);
      HapticFeedback.lightImpact();
      
    } catch (e, stackTrace) {
      if (!mounted) return;
      
      debugPrint('Load transactions error: $e\n$stackTrace');
      
      setState(() {
        _errorMessage = _getErrorMessage(e);
        _isLoading = false;
      });
      
      _showErrorSnackBar(_errorMessage!);
    }
  }

  List<ManagerTransaction> _getMockTransactions() {
    final now = DateTime.now();
    return [
      ManagerTransaction(
        id: 'T001',
        time: now.subtract(const Duration(minutes: 5)),
        pump: 'Pump 1',
        attendant: 'John Mwangi',
        amount: 2500,
        type: 'M-Pesa',
        status: 'Completed',
      ),
      ManagerTransaction(
        id: 'T002',
        time: now.subtract(const Duration(minutes: 12)),
        pump: 'Pump 2',
        attendant: 'Sarah Wanjiku',
        amount: 5000,
        type: 'Cash',
        status: 'Completed',
      ),
      ManagerTransaction(
        id: 'T003',
        time: now.subtract(const Duration(minutes: 18)),
        pump: 'Pump 4',
        attendant: 'Mike T.',
        amount: 3200,
        type: 'M-Pesa',
        status: 'Completed',
      ),
      ManagerTransaction(
        id: 'T004',
        time: now.subtract(const Duration(minutes: 25)),
        pump: 'Pump 1',
        attendant: 'John Mwangi',
        amount: 1800,
        type: 'Cash',
        status: 'Pending',
      ),
      ManagerTransaction(
        id: 'T005',
        time: now.subtract(const Duration(minutes: 32)),
        pump: 'Pump 6',
        attendant: 'Grace K.',
        amount: 4200,
        type: 'M-Pesa',
        status: 'Completed',
      ),
      ManagerTransaction(
        id: 'T006',
        time: now.subtract(const Duration(minutes: 41)),
        pump: 'Pump 2',
        attendant: 'Sarah Wanjiku',
        amount: 3500,
        type: 'Card',
        status: 'Completed',
      ),
      ManagerTransaction(
        id: 'T007',
        time: now.subtract(const Duration(hours: 1, minutes: 5)),
        pump: 'Pump 3',
        attendant: 'Peter Odhiambo',
        amount: 2800,
        type: 'M-Pesa',
        status: 'Failed',
      ),
      ManagerTransaction(
        id: 'T008',
        time: now.subtract(const Duration(hours: 1, minutes: 15)),
        pump: 'Pump 5',
        attendant: 'Lucy Wambui',
        amount: 1500,
        type: 'Cash',
        status: 'Completed',
      ),
      ManagerTransaction(
        id: 'T009',
        time: now.subtract(const Duration(hours: 1, minutes: 22)),
        pump: 'Pump 4',
        attendant: 'Mike T.',
        amount: 6000,
        type: 'M-Pesa',
        status: 'Completed',
      ),
      ManagerTransaction(
        id: 'T010',
        time: now.subtract(const Duration(hours: 1, minutes: 35)),
        pump: 'Pump 6',
        attendant: 'Grace K.',
        amount: 2200,
        type: 'Card',
        status: 'Completed',
      ),
    ];
  }

  void _applyFilters() {
    setState(() {
      _filteredTransactions = _allTransactions.where((tx) {
        // Search filter
        if (_filter.searchQuery != null && _filter.searchQuery!.isNotEmpty) {
          final query = _filter.searchQuery!.toLowerCase();
          final matches = tx.id.toLowerCase().contains(query) ||
              tx.pump.toLowerCase().contains(query) ||
              tx.attendant.toLowerCase().contains(query);
          if (!matches) return false;
        }

        // Date range filter
        if (_filter.dateRange != null) {
          if (tx.time.isBefore(_filter.dateRange!.start) ||
              tx.time.isAfter(_filter.dateRange!.end)) {
            return false;
          }
        }

        // Type filter
        if (_filter.type != null && _filter.type != TransactionType.all) {
          if (tx.type != _filter.type!.displayName) return false;
        }

        // Status filter
        if (_filter.status != null && _filter.status != TransactionStatus.all) {
          if (tx.status != _filter.status!.displayName) return false;
        }

        // Pump filter
        if (_filter.pumpId != null && tx.pump != _filter.pumpId) return false;

        // Amount range filter
        if (_filter.minAmount != null && tx.amount < _filter.minAmount!) {
          return false;
        }
        if (_filter.maxAmount != null && tx.amount > _filter.maxAmount!) {
          return false;
        }

        return true;
      }).toList();

      // Calculate totals
      _totalAmount = _filteredTransactions.fold(0.0, (sum, t) => sum + t.amount);
      _mpesaTotal = _filteredTransactions
          .where((t) => t.type == 'M-Pesa')
          .fold(0.0, (sum, t) => sum + t.amount);
      _cashTotal = _filteredTransactions
          .where((t) => t.type == 'Cash')
          .fold(0.0, (sum, t) => sum + t.amount);
      _cardTotal = _filteredTransactions
          .where((t) => t.type == 'Card')
          .fold(0.0, (sum, t) => sum + t.amount);
    });
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _filter = _filter.copyWith(searchQuery: query);
          _applyFilters();
        });
      }
    });
  }

  Future<void> _showFilterDialog() async {
    final result = await showDialog<TransactionFilter>(
      context: context,
      builder: (context) => TransactionFilterDialog(
        currentFilter: _filter,
      ),
    );
    
    if (result != null && mounted) {
      setState(() {
        _filter = result;
        _applyFilters();
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _filter.clear();
      _searchController.clear();
      _applyFilters();
    });
  }

  String _getErrorMessage(dynamic error) {
    if (error is TimeoutException) {
      return 'Connection timed out. Please check your internet and try again.';
    }
    if (error.toString().contains('SocketException') || 
        error.toString().contains('NetworkIsUnreachable')) {
      return 'No internet connection. Please connect to a network and retry.';
    }
    return 'Failed to load transactions. Please try again.';
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
        backgroundColor: _TransactionConstants.errorRed,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () => _loadTransactions(),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _exportTransactions() async {
    try {
      final List<List<dynamic>> csvData = [
        ['ID', 'Date', 'Time', 'Pump', 'Attendant', 'Amount', 'Method', 'Status'],
        ..._filteredTransactions.map((txn) => [
          txn.id,
          DateFormat('yyyy-MM-dd').format(txn.time),
          DateFormat('HH:mm').format(txn.time),
          txn.pump,
          txn.attendant,
          txn.amount.toString(),
          txn.type,
          txn.status,
        ]),
      ];
      
      final String csv = const ListToCsvConverter().convert(csvData);
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath = '${tempDir.path}/transactions_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      
      final File file = File(filePath);
      await file.writeAsString(csv);
      
      if (!mounted) return;
      
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'PayNotifyy Transaction Export',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export successful!'),
            backgroundColor: _TransactionConstants.accentGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: _TransactionConstants.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showTransactionDetails(ManagerTransaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
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
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getTypeColor(transaction.type).withAlpha(26),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getTypeIcon(transaction.type),
                          color: _getTypeColor(transaction.type),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transaction ${transaction.id}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(transaction.status).withAlpha(26),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                transaction.status,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getStatusColor(transaction.status),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                Divider(color: Colors.grey.shade200),
                
                // Details
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildDetailRow('Date', DateFormat('dd MMM yyyy').format(transaction.time)),
                      _buildDetailRow('Time', DateFormat('HH:mm:ss').format(transaction.time)),
                      _buildDetailRow('Pump', transaction.pump),
                      _buildDetailRow('Attendant', transaction.attendant),
                      _buildDetailRow(
                        'Amount',
                        'KES ${NumberFormat('#,##0').format(transaction.amount)}',
                        valueColor: _TransactionConstants.primaryDark,
                      ),
                      _buildDetailRow('Payment Method', transaction.type),
                      if (transaction.type == 'M-Pesa')
                        _buildDetailRow('Reference', 'MPE${transaction.id}'),
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

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'M-Pesa':
        return Colors.green;
      case 'Cash':
        return Colors.blue;
      case 'Card':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'M-Pesa':
        return Icons.phone_android;
      case 'Cash':
        return Icons.money;
      case 'Card':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper method to get color for TransactionStatus
  Color _getStatusColorForFilter(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.all:
        return Colors.grey;
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.failed:
        return Colors.red;
    }
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
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
          const SizedBox(height: 4),
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
    );
  }

  Widget _buildTransactionCard(ManagerTransaction transaction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () => _showTransactionDetails(transaction),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(transaction.type).withAlpha(26),
          child: Icon(
            _getTypeIcon(transaction.type),
            color: _getTypeColor(transaction.type),
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                '${transaction.pump} • ${transaction.attendant}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(transaction.status).withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                transaction.status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(transaction.status),
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'ID: ${transaction.id}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
            Text(
              DateFormat('dd MMM yyyy • HH:mm').format(transaction.time),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'KES ${NumberFormat('#,##0').format(transaction.amount)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > _TransactionConstants.tabletBreakpoint;
    final isTablet = screenWidth > _TransactionConstants.mobileBreakpoint && 
                    screenWidth <= _TransactionConstants.tabletBreakpoint;
    
    // Use warningOrange in UI
    final warningColor = _TransactionConstants.warningOrange;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: _TransactionConstants.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Filter Button
          Semantics(
            button: true,
            label: 'Filter transactions',
            child: IconButton(
              icon: const Icon(Icons.filter_list_outlined),
              onPressed: _showFilterDialog,
              tooltip: 'Filter',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ),
          // Export Button
          Semantics(
            button: true,
            label: 'Export transactions',
            child: IconButton(
              icon: const Icon(Icons.file_download_outlined),
              onPressed: _exportTransactions,
              tooltip: 'Export',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
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
                  child: Semantics(
                    label: 'Search transactions',
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search by ID, pump, attendant...',
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
                ),
                if (_filter.hasFilters) ...[
                  const SizedBox(width: 12),
                  Semantics(
                    button: true,
                    label: 'Clear filters',
                    child: IconButton(
                      icon: const Icon(Icons.clear_all),
                      onPressed: _clearFilters,
                      tooltip: 'Clear Filters',
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Filter Chips (if filters are active)
          if (_filter.hasFilters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_filter.dateRange != null)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _TransactionConstants.primaryDark.withAlpha(26),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: _TransactionConstants.primaryDark),
                            const SizedBox(width: 4),
                            Text(
                              '${DateFormat('dd/MM').format(_filter.dateRange!.start)} - ${DateFormat('dd/MM').format(_filter.dateRange!.end)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: _TransactionConstants.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_filter.type != null && _filter.type != TransactionType.all)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getTypeColor(_filter.type!.displayName).withAlpha(26),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _filter.type!.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getTypeColor(_filter.type!.displayName),
                          ),
                        ),
                      ),
                    if (_filter.status != null && _filter.status != TransactionStatus.all)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColorForFilter(_filter.status!).withAlpha(26),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _filter.status!.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStatusColorForFilter(_filter.status!),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          
          // Summary Stats - NOW USING ALL VARIABLES
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Main stats row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatBox(
                        'Total',
                        'KES ${NumberFormat('#,##0').format(_totalAmount)}',
                        _TransactionConstants.primaryDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatBox(
                        'M-Pesa',
                        'KES ${NumberFormat('#,##0').format(_mpesaTotal)}',
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatBox(
                        'Cash',
                        'KES ${NumberFormat('#,##0').format(_cashTotal)}',
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Card payments row - using warningColor
                if (_cardTotal > 0)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: warningColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.credit_card, color: warningColor),
                            const SizedBox(width: 8),
                            Text(
                              'Card Payments',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: warningColor,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'KES ${NumberFormat('#,##0').format(_cardTotal)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: warningColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Device info - using isDesktop and isTablet
                if (isDesktop || isTablet)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      isDesktop ? '🖥️ Desktop View' : '📱 Tablet View',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                        fontStyle: FontStyle.italic,
                      ),
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
          
          // Transaction List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTransactions.isEmpty
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
                                'No transactions found',
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
                          await _loadTransactions();
                        },
                        color: _TransactionConstants.primaryDark,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final transaction = _filteredTransactions[index];
                            return _buildTransactionCard(transaction);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}