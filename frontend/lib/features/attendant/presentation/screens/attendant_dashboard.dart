// lib/features/attendant/presentation/screens/attendant_dashboard.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'payment_initiate_screen.dart';
import 'shift_report_screen.dart';
import 'cash_sale_screen.dart';
import '../../../shared/screens/ai_assistant_screen.dart';
import 'receipt_history_screen.dart';
import 'mobile_scanner.dart';
import 'pdq_payment_screen.dart';
import 'notice_board_screen.dart';

// MARK: - Constants
class _AttendantConstants {
  static const Color primaryDark = Color(0xFF0B3D2E);
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color warningOrange = Color(0xFFF39C12);
  static const Color permissionPurple = Color(0xFF9C27B0);
  
  static const Duration streamDelay = Duration(seconds: 30);
  static const Duration refreshDelay = Duration(milliseconds: 1500);
  static const Duration initialDataDelay = Duration(seconds: 1);
  static const Duration permissionTimeout = Duration(minutes: 30);
}

// MARK: - Models (Local to this file)
class Transaction {
  final String id;
  final double amount;
  final String phone;
  final DateTime timestamp;
  final TransactionStatus status;
  final String pump;
  final String? customerName;
  final String? paymentType;
  final String? reference;
  final String? note;
  final String? processedBy;

  const Transaction({
    required this.id,
    required this.amount,
    required this.phone,
    required this.timestamp,
    required this.status,
    required this.pump,
    this.customerName,
    this.paymentType,
    this.reference,
    this.note,
    this.processedBy,
  });
}

enum TransactionStatus {
  pending,
  completed,
  failed;

  String get displayName {
    switch (this) {
      case pending: return 'PENDING';
      case completed: return 'COMPLETED';
      case failed: return 'FAILED';
    }
  }

  Color get color {
    switch (this) {
      case pending: return Colors.orange;
      case completed: return Colors.green;
      case failed: return Colors.red;
    }
  }
}

enum TransactionFilter {
  all,
  completed,
  pending;

  String get displayName {
    switch (this) {
      case all: return 'All';
      case completed: return 'Completed';
      case pending: return 'Pending';
    }
  }
}

// MARK: - Permission Model
class AttendantPermission {
  final String id;
  final String attendantId;
  final String attendantName;
  final String pumpNumber;
  final DateTime grantedAt;
  final DateTime expiresAt;
  final bool isActive;

  AttendantPermission({
    required this.id,
    required this.attendantId,
    required this.attendantName,
    required this.pumpNumber,
    required this.grantedAt,
    required this.expiresAt,
    required this.isActive,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  Duration get timeRemaining => expiresAt.difference(DateTime.now());
}

// MARK: - Available Attendants (Mock Data)
class AvailableAttendant {
  final String id;
  final String name;
  final String role;

  AvailableAttendant({
    required this.id,
    required this.name,
    required this.role,
  });
}

// MARK: - Main Screen
class AttendantDashboard extends StatefulWidget {
  final String selectedPump;
  final String attendantName;

  const AttendantDashboard({
    super.key,
    required this.selectedPump,
    required this.attendantName,
  });

  @override
  State<AttendantDashboard> createState() => _AttendantDashboardState();
}

class _AttendantDashboardState extends State<AttendantDashboard> {
  // State
  double _totalSales = 0.0;
  int _transactionCount = 0;
  int _pendingCount = 0;
  bool _isLoading = true;
  TransactionFilter _currentFilter = TransactionFilter.all;
  DateTime? _shiftStartTime;
  double _fuelLevel = 85.0;
  bool _isPumpActive = true;

  // Permissions - Made final
  final List<AttendantPermission> _activePermissions = [];
  bool _isShowingPermissionDialog = false;

  // Stream Control
  bool _isStreamActive = false;
  Timer? _mockTransactionTimer;
  Timer? _fuelConsumptionTimer;
  Timer? _permissionCleanupTimer;

  // Transactions
  final List<Transaction> _allTransactions = [];
  List<Transaction> _filteredTransactions = [];

  // Mock available attendants
  final List<AvailableAttendant> _availableAttendants = [
    AvailableAttendant(id: 'att1', name: 'James Mwangi', role: 'Senior Attendant'),
    AvailableAttendant(id: 'att2', name: 'Mary Wanjiku', role: 'Attendant'),
    AvailableAttendant(id: 'att3', name: 'Peter Ochieng', role: 'Attendant'),
    AvailableAttendant(id: 'att4', name: 'Grace Atieno', role: 'Attendant'),
  ];

  // MARK: - Lifecycle
  @override
  void initState() {
    super.initState();
    _shiftStartTime = DateTime.now();
    _loadInitialData();
    _startPermissionCleanupTimer();

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _isStreamActive = true;
        _startMockTransactionStream();
        _simulateFuelConsumption();
      }
    });
  }

  @override
  void dispose() {
    _isStreamActive = false;
    _mockTransactionTimer?.cancel();
    _fuelConsumptionTimer?.cancel();
    _permissionCleanupTimer?.cancel();
    _isPumpActive = false;
    super.dispose();
  }

  // MARK: - Permission Management
  void _startPermissionCleanupTimer() {
    _permissionCleanupTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _cleanupExpiredPermissions();
      }
    });
  }

  void _cleanupExpiredPermissions() {
    // Removed unused 'now' variable
    bool hasChanges = false;
    
    for (int i = 0; i < _activePermissions.length; i++) {
      if (_activePermissions[i].isExpired) {
        // Since _activePermissions is final, we need to create a new list
        // This will be handled by creating a new list in setState
        hasChanges = true;
      }
    }
    
    if (hasChanges && mounted) {
      setState(() {
        // Remove expired permissions
        _activePermissions.removeWhere((p) => p.isExpired);
      });
      _showPermissionExpiredSnackBar();
    }
  }

  void _showPermissionExpiredSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏰ Some assistant permissions have expired'),
        backgroundColor: _AttendantConstants.warningOrange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  int get _activePermissionCount {
    return _activePermissions.where((p) => p.isActive && !p.isExpired).length;
  }

  bool get _canGrantMorePermissions {
    return _activePermissionCount < 2;
  }

  void _showGrantPermissionDialog() {
    if (_isShowingPermissionDialog) return;
    
    if (!_canGrantMorePermissions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Maximum 2 assistant permissions already granted. Please wait for some to expire.'),
          backgroundColor: _AttendantConstants.warningOrange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    _isShowingPermissionDialog = true;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.people_outline, color: _AttendantConstants.permissionPurple),
            SizedBox(width: 8),
            Text('Grant Assistant Permission'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select an attendant to help you during rush hour:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ..._availableAttendants.map((attendant) {
              final hasActivePermission = _activePermissions.any(
                (p) => p.attendantId == attendant.id && p.isActive && !p.isExpired
              );
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _AttendantConstants.permissionPurple.withAlpha(26),
                  child: Text(
                    attendant.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: _AttendantConstants.permissionPurple),
                  ),
                ),
                title: Text(attendant.name),
                subtitle: Text(attendant.role),
                trailing: hasActivePermission
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(26),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(fontSize: 10, color: Colors.green),
                        ),
                      )
                    : null,
                onTap: hasActivePermission
                    ? null
                    : () {
                        _grantPermission(attendant);
                        Navigator.pop(dialogContext);
                      },
                enabled: !hasActivePermission,
              );
            }),
            const SizedBox(height: 8),
            if (_activePermissions.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Active Permissions:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ..._activePermissions
                        .where((p) => p.isActive && !p.isExpired)
                        .map((permission) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.person, size: 14, color: _AttendantConstants.permissionPurple),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  permission.attendantName,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              Text(
                                'Expires in ${permission.timeRemaining.inMinutes}m',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _isShowingPermissionDialog = false;
              Navigator.pop(dialogContext);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    ).then((_) {
      _isShowingPermissionDialog = false;
    });
  }

  void _grantPermission(AvailableAttendant attendant) {
    final newPermission = AttendantPermission(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      attendantId: attendant.id,
      attendantName: attendant.name,
      pumpNumber: widget.selectedPump,
      grantedAt: DateTime.now(),
      expiresAt: DateTime.now().add(_AttendantConstants.permissionTimeout),
      isActive: true,
    );

    setState(() {
      _activePermissions.add(newPermission);
    });

    HapticFeedback.mediumImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✅ Permission granted to ${attendant.name}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              'They can help you on ${widget.selectedPump} for 30 minutes',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: _AttendantConstants.permissionPurple,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _revokePermission(AttendantPermission permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Permission?'),
        content: Text('Remove ${permission.attendantName}\'s access to ${widget.selectedPump}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _activePermissions.removeWhere((p) => p.id == permission.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Permission revoked for ${permission.attendantName}'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Revoke', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showActivePermissionsDialog() {
    final activePerms = _activePermissions.where((p) => p.isActive && !p.isExpired).toList();
    
    if (activePerms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active assistant permissions'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Active Assistant Permissions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...activePerms.map((permission) => ListTile(
              leading: const Icon(Icons.person, color: _AttendantConstants.permissionPurple),
              title: Text(permission.attendantName),
              subtitle: Text('Expires in ${permission.timeRemaining.inMinutes}m ${permission.timeRemaining.inSeconds % 60}s'),
              trailing: IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () {
                  Navigator.pop(context);
                  _revokePermission(permission);
                },
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  bool get _canProcessTransaction {
    return _isPumpActive;
  }

  // MARK: - Data Loading
  void _loadInitialData() {
    Future.delayed(_AttendantConstants.initialDataDelay, () {
      if (!mounted) return;

      setState(() {
        _allTransactions.addAll([
          Transaction(
            id: '1',
            amount: 2500,
            phone: '0712345678',
            timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
            status: TransactionStatus.completed,
            pump: widget.selectedPump,
            customerName: 'John M.',
            paymentType: 'M-Pesa',
            reference: 'NRF7890123',
            processedBy: widget.attendantName,
          ),
          Transaction(
            id: '2',
            amount: 5000,
            phone: '0723456789',
            timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
            status: TransactionStatus.completed,
            pump: widget.selectedPump,
            customerName: 'Sarah W.',
            paymentType: 'M-Pesa',
            reference: 'NRF4567890',
            processedBy: widget.attendantName,
          ),
          Transaction(
            id: '3',
            amount: 1800,
            phone: '0734567890',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            status: TransactionStatus.pending,
            pump: widget.selectedPump,
            paymentType: 'Card',
            note: 'Waiting for confirmation',
            processedBy: widget.attendantName,
          ),
          Transaction(
            id: '4',
            amount: 3200,
            phone: '0745678901',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            status: TransactionStatus.completed,
            pump: widget.selectedPump,
            customerName: 'Mike T.',
            paymentType: 'M-Pesa',
            reference: 'NRF1234567',
            processedBy: widget.attendantName,
          ),
          Transaction(
            id: '5',
            amount: 4000,
            phone: '0756789012',
            timestamp: DateTime.now().subtract(const Duration(hours: 3)),
            status: TransactionStatus.completed,
            pump: widget.selectedPump,
            customerName: 'Jane D.',
            paymentType: 'Cash',
            note: 'Paid in full',
            processedBy: widget.attendantName,
          ),
        ]);
        _applyFilter();
        _isLoading = false;
      });
    });
  }

  Future<void> _refreshData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    await Future.delayed(_AttendantConstants.refreshDelay);

    if (!mounted) return;

    setState(() => _isLoading = false);
    HapticFeedback.lightImpact();
  }

  // MARK: - Mock Transaction Stream
  void _startMockTransactionStream() {
    _mockTransactionTimer?.cancel();
    _mockTransactionTimer = Timer(_AttendantConstants.streamDelay, () {
      if (mounted && _isStreamActive && _isPumpActive) {
        _addMockTransaction();
        _startMockTransactionStream();
      }
    });
  }

  void _addMockTransaction() {
    if (DateTime.now().second % 10 > 3) return;

    final randomAmount = [1500, 2000, 2500, 3000, 3500][DateTime.now().second % 5];

    final newTransaction = Transaction(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      amount: randomAmount.toDouble(),
      phone: '07${DateTime.now().second}${DateTime.now().millisecond}${DateTime.now().microsecond}'
          .padRight(8, '0')
          .substring(0, 8),
      timestamp: DateTime.now(),
      status: TransactionStatus.completed,
      pump: widget.selectedPump,
      paymentType: 'M-Pesa',
      reference: 'REF${DateTime.now().millisecondsSinceEpoch}'.substring(0, 10),
      processedBy: widget.attendantName,
    );

    if (!mounted) return;

    setState(() {
      _allTransactions.insert(0, newTransaction);
      _applyFilter();
    });

    if (mounted && _isPumpActive) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _AttendantConstants.accentGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          content: Row(
            children: [
              const Icon(Icons.payment, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'New payment: ${_formatCurrency(randomAmount.toDouble())}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // MARK: - Fuel Consumption Simulation
  void _simulateFuelConsumption() {
    _fuelConsumptionTimer?.cancel();
    _fuelConsumptionTimer = Timer(const Duration(seconds: 30), () {
      if (mounted && _isStreamActive && _isPumpActive) {
        setState(() {
          _fuelLevel = (_fuelLevel - 1.5).clamp(0.0, 100.0);
        });
        _simulateFuelConsumption();
      }
    });
  }

  // MARK: - Filtering & Calculations
  void _applyFilter() {
    if (!mounted) return;

    setState(() {
      _filteredTransactions = _allTransactions.where((t) {
        switch (_currentFilter) {
          case TransactionFilter.all: return true;
          case TransactionFilter.completed: return t.status == TransactionStatus.completed;
          case TransactionFilter.pending: return t.status == TransactionStatus.pending;
        }
      }).toList();

      _totalSales = _allTransactions
          .where((t) => t.status == TransactionStatus.completed)
          .fold(0.0, (sum, t) => sum + t.amount);
      _transactionCount = _allTransactions.length;
      _pendingCount = _allTransactions.where((t) => t.status == TransactionStatus.pending).length;
    });
  }

  String _formatCurrency(double amount) {
    return 'KES ${NumberFormat('#,##0').format(amount)}';
  }

  String _getShiftDuration() {
    if (_shiftStartTime == null) return '0h 0m';
    final duration = DateTime.now().difference(_shiftStartTime!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  // MARK: - Pump Control
  void _togglePumpStatus() {
    HapticFeedback.mediumImpact();

    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(!_isPumpActive ? 'Activate Pump' : 'Pause Pump'),
        content: Text(!_isPumpActive
            ? 'Are you sure you want to activate ${widget.selectedPump}?'
            : 'Are you sure you want to pause ${widget.selectedPump}? No new payments can be processed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ).then((confirm) {
      if (!mounted) return;
      
      if (confirm == true) {
        setState(() {
          _isPumpActive = !_isPumpActive;
        });

        HapticFeedback.mediumImpact();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isPumpActive
                ? '✅ ${widget.selectedPump} is now ACTIVE'
                : '⏸️ ${widget.selectedPump} is now PAUSED'),
            backgroundColor: _isPumpActive ? _AttendantConstants.accentGreen : _AttendantConstants.warningOrange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  // MARK: - Navigation Methods
  void _recordCashSale() {
    if (!_canProcessTransaction) {
      _showPumpInactiveWarning();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CashSaleScreen(
          selectedPump: widget.selectedPump,
          attendantName: widget.attendantName,
          onCashSaleRecorded: (amount, customerName, note) {
            final newTxn = Transaction(
              id: 'CASH_${DateTime.now().millisecondsSinceEpoch}',
              amount: amount,
              phone: 'CASH',
              timestamp: DateTime.now(),
              status: TransactionStatus.completed,
              pump: widget.selectedPump,
              customerName: customerName,
              paymentType: 'Cash',
              note: note,
              processedBy: widget.attendantName,
            );

            if (!mounted) return;

            setState(() {
              _allTransactions.insert(0, newTxn);
              _applyFilter();
            });

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: _AttendantConstants.accentGreen,
                duration: const Duration(seconds: 3),
                content: Text('Cash sale of ${_formatCurrency(amount)} recorded'),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showPumpInactiveWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏸️ Pump is paused. Activate pump to process transactions.'),
        backgroundColor: _AttendantConstants.warningOrange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _openReceiptHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptHistoryScreen(
          attendantName: widget.attendantName,
          selectedPump: widget.selectedPump,
        ),
      ),
    );
  }

  void _openQRPay() {
    if (!_canProcessTransaction) {
      _showPumpInactiveWarning();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrPayScreen(
          attendantName: widget.attendantName,
          selectedPump: widget.selectedPump,
        ),
      ),
    );
  }

  void _openPDQPayment() {
    if (!_canProcessTransaction) {
      _showPumpInactiveWarning();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdqPaymentScreen(
          attendantName: widget.attendantName,
          selectedPump: widget.selectedPump,
        ),
      ),
    );
  }

  void _openNoticeBoard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoticeBoardScreen(
          attendantName: widget.attendantName,
          selectedPump: widget.selectedPump,
        ),
      ),
    );
  }

  void _openAIAssistant() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AIAssistantScreen(
          attendantName: widget.attendantName,
          selectedPump: widget.selectedPump,
        ),
      ),
    );
  }

  // MARK: - Transaction Details Modal
  void _viewTransactionDetails(Transaction transaction) {
    HapticFeedback.lightImpact();

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Semantics(
                  label: 'Payment receipt for ${_formatCurrency(transaction.amount)}',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_gas_station, color: _AttendantConstants.primaryDark, size: 32),
                      const SizedBox(width: 8),
                      const Text(
                        'PayNotify',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _AttendantConstants.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Payment Receipt',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM yyyy • hh:mm a').format(transaction.timestamp),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const Divider(height: 32, thickness: 1),

                _receiptRow('Transaction ID', transaction.id),
                _receiptRow('Pump', transaction.pump),
                _receiptRow('Customer', transaction.customerName ?? 'N/A'),
                _receiptRow('Phone Number', transaction.phone),
                _receiptRow('Amount Paid', _formatCurrency(transaction.amount)),
                _receiptRow('Payment Type', transaction.paymentType ?? 'Not specified'),
                if (transaction.processedBy != null && transaction.processedBy != widget.attendantName)
                  _receiptRow('Processed By', transaction.processedBy!),
                Semantics(
                  label: 'Status: ${transaction.status.displayName}',
                  child: _receiptRow(
                    'Status',
                    transaction.status.displayName,
                    statusColor: transaction.status.color,
                  ),
                ),
                if (transaction.reference != null)
                  _receiptRow('Reference No.', transaction.reference!),
                if (transaction.note != null && transaction.note!.isNotEmpty)
                  _receiptRow('Note', transaction.note!),

                const SizedBox(height: 24),
                const Divider(),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Thank you for your business!\nPayment processed securely via PayNotify',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Semantics(
                      button: true,
                      label: 'Share receipt',
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Share/Print coming soon')),
                          );
                        },
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Share'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _AttendantConstants.primaryDark,
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Close receipt',
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.done, size: 18),
                        label: const Text('Done'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _AttendantConstants.accentGreen,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value, {Color? statusColor}) {
    return Semantics(
      label: '$label: $value',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: statusColor ?? Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MARK: - Back Button Handling
  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Dashboard?'),
        content: const Text('Are you sure you want to go back to pump selection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  // MARK: - Build Methods
  @override
  Widget build(BuildContext context) {
    final activePermCount = _activePermissionCount;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        
        final shouldPop = await _onWillPop();
        if (shouldPop == true && mounted) {
          Navigator.of(context).pop('shift_ended');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Semantics(label: 'Dashboard for ${widget.selectedPump}', child: Text(widget.selectedPump)),
          backgroundColor: _AttendantConstants.primaryDark,
          foregroundColor: Colors.white,
          leading: Semantics(
            button: true,
            label: 'Go back to pump selection',
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                final shouldPop = await _onWillPop();
                if (mounted && shouldPop) {
                  Navigator.of(context).pop('shift_ended');
                }
              },
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ),
          actions: [
            if (activePermCount > 0)
              Semantics(
                button: true,
                label: 'Active assistant permissions: $activePermCount',
                child: Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.people_alt),
                      onPressed: _showActivePermissionsDialog,
                      tooltip: 'Active Permissions ($activePermCount/2)',
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$activePermCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Semantics(
              button: true,
              label: 'Refresh data',
              child: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshData,
                tooltip: 'Refresh',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ),
            Semantics(
              button: true,
              label: 'End shift and log out',
              child: IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'End Shift',
                onPressed: () async {
                  final shouldEndShift = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('End Shift?'),
                      content: const Text('Submit shift report and log out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Yes'),
                        ),
                      ],
                    ),
                  );
                  if (mounted && shouldEndShift == true) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShiftReportScreen(
                          selectedPump: widget.selectedPump,
                          attendantName: widget.attendantName,
                          todaySales: _totalSales,
                        ),
                      ),
                    );
                  }
                },
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ),
            Semantics(
              button: true,
              label: 'Record cash sale',
              child: IconButton(
                icon: const Icon(Icons.money),
                tooltip: 'Record Cash Sale',
                onPressed: _recordCashSale,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Header Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _AttendantConstants.primaryDark,
                          _AttendantConstants.accentGreen.withAlpha(204),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Semantics(
                          label: 'Hello ${widget.attendantName}, shift duration ${_getShiftDuration()}',
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.white,
                                child: Text(
                                  widget.attendantName.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: _AttendantConstants.primaryDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hello, ${widget.attendantName}!',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Shift: ${_getShiftDuration()}',
                                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                              Semantics(
                                button: true,
                                label: _isPumpActive ? 'Pause pump' : 'Activate pump',
                                child: IconButton(
                                  icon: Icon(
                                    _isPumpActive ? Icons.pause : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  onPressed: _togglePumpStatus,
                                  tooltip: _isPumpActive ? 'Pause Pump' : 'Activate Pump',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Semantics(
                                  label: 'Today\'s sales: ${_formatCurrency(_totalSales)}, $_transactionCount payments',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(38),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'TODAY\'S SALES',
                                          style: TextStyle(fontSize: 10, color: Colors.white70),
                                        ),
                                        const SizedBox(height: 4),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            _formatCurrency(_totalSales),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$_transactionCount payments',
                                          style: const TextStyle(fontSize: 10, color: Colors.white70),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Semantics(
                                  label: 'Fuel level: ${_fuelLevel.toStringAsFixed(0)}%',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(38),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'FUEL LEVEL',
                                          style: TextStyle(fontSize: 10, color: Colors.white70),
                                        ),
                                        const SizedBox(height: 4),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            '${_fuelLevel.toStringAsFixed(0)}%',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        SizedBox(
                                          height: 4,
                                          child: LinearProgressIndicator(
                                            value: _fuelLevel / 100,
                                            backgroundColor: Colors.white.withAlpha(77),
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              _fuelLevel > 30 ? Colors.green : Colors.orange,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (_pendingCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '$_pendingCount Pending',
                                style: TextStyle(fontSize: 11, color: Colors.orange[900]),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Quick Actions Bar
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Semantics(button: true, label: 'Open notices', child: _buildQuickAction(icon: Icons.notifications_active, label: 'Notices', color: Colors.red, onTap: _openNoticeBoard)),
                          const SizedBox(width: 10),
                          Semantics(button: true, label: 'View receipt history', child: _buildQuickAction(icon: Icons.receipt_long, label: 'Receipt', color: Colors.purple, onTap: _openReceiptHistory)),
                          const SizedBox(width: 10),
                          Semantics(button: true, label: 'View transaction history', child: _buildQuickAction(icon: Icons.history, label: 'History', color: Colors.blue, onTap: _openReceiptHistory)),
                          const SizedBox(width: 10),
                          Semantics(button: true, label: 'PDQ payment', child: _buildQuickAction(icon: Icons.credit_card, label: 'PDQ', color: Colors.deepOrange, onTap: _openPDQPayment)),
                          const SizedBox(width: 10),
                          Semantics(button: true, label: 'QR code payment', child: _buildQuickAction(icon: Icons.qr_code, label: 'QR Pay', color: Colors.teal, onTap: _openQRPay)),
                          const SizedBox(width: 10),
                          Semantics(button: true, label: 'Record cash sale', child: _buildQuickAction(icon: Icons.money, label: 'Cash', color: Colors.green, onTap: _recordCashSale)),
                        ],
                      ),
                    ),
                  ),

                  // Filter Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        const Text(
                          'Recent Transactions',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Flexible(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: TransactionFilter.values.map((filter) {
                                return Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Semantics(
                                    button: true,
                                    selected: _currentFilter == filter,
                                    label: 'Filter by ${filter.displayName}',
                                    child: ChoiceChip(
                                      label: Text(filter.displayName, style: const TextStyle(fontSize: 12)),
                                      selected: _currentFilter == filter,
                                      onSelected: (selected) {
                                        setState(() {
                                          _currentFilter = filter;
                                          _applyFilter();
                                        });
                                      },
                                      selectedColor: _AttendantConstants.primaryDark,
                                      labelStyle: TextStyle(
                                        color: _currentFilter == filter ? Colors.white : Colors.black,
                                        fontSize: 12,
                                      ),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Transactions List
                  Expanded(
                    child: _filteredTransactions.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _currentFilter == TransactionFilter.all ? Icons.inbox : Icons.filter_alt_outlined,
                                    size: 60,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _currentFilter == TransactionFilter.all
                                        ? 'No transactions yet\nWaiting for payments...'
                                        : 'No ${_currentFilter.displayName.toLowerCase()} transactions',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 20),
                                  Semantics(
                                    button: true,
                                    label: 'Initiate first payment',
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        if (!_canProcessTransaction) {
                                          _showPumpInactiveWarning();
                                          return;
                                        }
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PaymentInitiateScreen(
                                              selectedPump: widget.selectedPump,
                                              attendantName: widget.attendantName,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text('Initiate First Payment', style: TextStyle(fontSize: 14)),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              HapticFeedback.mediumImpact();
                              await _refreshData();
                            },
                            color: _AttendantConstants.primaryDark,
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 80),
                              itemCount: _filteredTransactions.length,
                              itemBuilder: (context, index) {
                                final transaction = _filteredTransactions[index];
                                return Semantics(
                                  button: true,
                                  label: '${transaction.paymentType} payment of ${_formatCurrency(transaction.amount)}, ${transaction.status.displayName}',
                                  child: _buildTransactionCard(transaction),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),

              if (_isLoading)
                Container(
                  color: Colors.black.withAlpha(77),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),

        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              button: true,
              label: 'Grant assistant permission during rush hour',
              child: FloatingActionButton(
                heroTag: "grant_permission",
                onPressed: _showGrantPermissionDialog,
                backgroundColor: _AttendantConstants.permissionPurple,
                tooltip: 'Grant Assistant Permission',
                mini: true,
                child: const Icon(Icons.person_add, size: 22),
              ),
            ),
            const SizedBox(height: 10),
            Semantics(
              button: true,
              label: 'Ask AI assistant',
              child: FloatingActionButton(
                heroTag: "ai_assistant",
                onPressed: _openAIAssistant,
                backgroundColor: Colors.orange[700],
                tooltip: 'Ask AI',
                mini: true,
                child: const Icon(Icons.smart_toy, size: 22),
              ),
            ),
            const SizedBox(height: 10),
            Semantics(
              button: true,
              label: 'Initiate new payment',
              child: FloatingActionButton.extended(
                heroTag: "new_payment",
                onPressed: () {
                  if (!_canProcessTransaction) {
                    _showPumpInactiveWarning();
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentInitiateScreen(
                        selectedPump: widget.selectedPump,
                        attendantName: widget.attendantName,
                        onPaymentSuccess: (amount, phone, customerName) {
                          final newTxn = Transaction(
                            id: '${DateTime.now().millisecondsSinceEpoch}',
                            amount: amount,
                            phone: phone,
                            timestamp: DateTime.now(),
                            status: TransactionStatus.pending,
                            pump: widget.selectedPump,
                            customerName: customerName,
                            paymentType: 'M-Pesa',
                            processedBy: widget.attendantName,
                          );

                          if (!mounted) return;

                          setState(() {
                            _allTransactions.insert(0, newTxn);
                            _applyFilter();
                          });

                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.blue,
                              duration: const Duration(seconds: 4),
                              content: Text(
                                'Payment initiated: ${_formatCurrency(amount)} to $phone (Pending)',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
                label: const Text('New Payment', style: TextStyle(fontSize: 13)),
                icon: const Icon(Icons.add, size: 16),
                backgroundColor: _AttendantConstants.accentGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(51),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final isProcessedByHelper = transaction.processedBy != null && 
                                 transaction.processedBy != widget.attendantName;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        onTap: () => _viewTransactionDetails(transaction),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: transaction.status.color.withAlpha(51),
          child: Icon(
            transaction.paymentType == 'Cash'
                ? Icons.money
                : transaction.paymentType == 'PDQ' || transaction.paymentType == 'Card'
                    ? Icons.credit_card
                    : Icons.payment,
            color: transaction.status.color,
            size: 16,
          ),
        ),
        title: Row(
          children: [
            Text(
              _formatCurrency(transaction.amount),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: transaction.status.color.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: transaction.status.color.withAlpha(77)),
              ),
              child: Text(
                transaction.status.displayName,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: transaction.status.color,
                ),
              ),
            ),
            if (isProcessedByHelper)
              const SizedBox(width: 6),
            if (isProcessedByHelper)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: _AttendantConstants.permissionPurple.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ASSISTED',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: _AttendantConstants.permissionPurple,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              'From: ${transaction.customerName ?? transaction.phone}',
              style: const TextStyle(fontSize: 11),
            ),
            Text(
              'Type: ${transaction.paymentType ?? "N/A"}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            Text(
              DateFormat('hh:mm a • dd MMM').format(transaction.timestamp),
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400], size: 16),
      ),
    );
  }
}