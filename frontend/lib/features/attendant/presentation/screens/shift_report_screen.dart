import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ShiftReportScreen extends StatefulWidget {
  final String selectedPump;
  final String attendantName;
  final double todaySales;

  const ShiftReportScreen({
    super.key,
    required this.selectedPump,
    required this.attendantName,
    required this.todaySales,
  });

  @override
  State<ShiftReportScreen> createState() => _ShiftReportScreenState();
}

class _ShiftReportScreenState extends State<ShiftReportScreen> {
  final _openingMeterController = TextEditingController();
  final _closingMeterController = TextEditingController();
  final _cashCollectedController = TextEditingController();
  final _remarksController = TextEditingController();

  double _fuelDispensed = 0.0;
  double _mpesaReceived = 0.0;
  double _cashCollected = 0.0;
  double _totalExpected = 0.0;
  double _variance = 0.0;
  bool _isSubmitting = false;
  bool _hasVarianceIssue = false;

  final List<ShiftTransaction> _transactions = [
    ShiftTransaction(
      id: '1',
      time: DateTime.now().subtract(const Duration(hours: 3)),
      phone: '712345678',
      amount: 1500.00,
      type: PaymentType.mpesa,
      status: TransactionStatus.completed,
      customerName: 'John M.',
    ),
    ShiftTransaction(
      id: '2',
      time: DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
      phone: '723456789',
      amount: 2500.00,
      type: PaymentType.mpesa,
      status: TransactionStatus.completed,
      customerName: 'Sarah W.',
    ),
    ShiftTransaction(
      id: '3',
      time: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
      phone: '734567890',
      amount: 3000.00,
      type: PaymentType.cash,
      status: TransactionStatus.completed,
      customerName: 'Mike T.',
    ),
    ShiftTransaction(
      id: '4',
      time: DateTime.now().subtract(const Duration(minutes: 30)),
      phone: '745678901',
      amount: 1200.00,
      type: PaymentType.mpesa,
      status: TransactionStatus.pending,
      customerName: 'Jane D.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadShiftData();
  }

  void _loadShiftData() {
    final openingReading = 12345.6;
    _openingMeterController.text = openingReading.toStringAsFixed(1);

    _mpesaReceived = _transactions
        .where((t) => t.type == PaymentType.mpesa && t.status == TransactionStatus.completed)
        .fold(0.0, (sum, t) => sum + t.amount);

    _totalExpected = widget.todaySales;
    _cashCollected = _totalExpected - _mpesaReceived;
    _cashCollectedController.text = _cashCollected.toStringAsFixed(0);

    _closingMeterController.text = (openingReading + 180.5).toStringAsFixed(1);
    _calculateDispensed();
  }

  void _calculateDispensed() {
    final opening = double.tryParse(_openingMeterController.text) ?? 0.0;
    final closing = double.tryParse(_closingMeterController.text) ?? 0.0;

    setState(() {
      _fuelDispensed = closing - opening;
      if (_fuelDispensed < 0) _fuelDispensed = 0.0;
      _recalculateVariance();
    });
  }

  void _recalculateVariance() {
    final cashEntered = double.tryParse(_cashCollectedController.text.replaceAll(',', '')) ?? 0.0;
    final expectedFromFuel = _fuelDispensed * 180;

    setState(() {
      _cashCollected = cashEntered;
      _totalExpected = _cashCollected + _mpesaReceived;
      _variance = _totalExpected - expectedFromFuel;
      _hasVarianceIssue = _variance.abs() > 100;
    });
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      symbol: 'KES ',
      decimalDigits: amount.truncateToDouble() == amount ? 0 : 2,
    ).format(amount);
  }

  void _showTransactionDetails(ShiftTransaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transaction Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Time:', DateFormat('HH:mm').format(transaction.time)),
            _buildDetailRow('Customer:', transaction.customerName ?? 'N/A'),
            _buildDetailRow('Phone:', transaction.phone),
            _buildDetailRow('Amount:', _formatCurrency(transaction.amount)),
            _buildDetailRow('Type:', transaction.type.displayName),
            _buildDetailRow('Status:', transaction.status.displayName),
            if (transaction.note != null) _buildDetailRow('Note:', transaction.note!),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReport() async {
    if (_closingMeterController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter closing meter reading')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Shift End'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _hasVarianceIssue ? Icons.warning : Icons.check_circle,
              size: 48,
              color: _hasVarianceIssue ? Colors.orange : Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              _hasVarianceIssue
                  ? '⚠️ Variance detected: ${_formatCurrency(_variance)}\n\nPlease verify before submitting.'
                  : 'End your shift and submit this report?',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Review')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _hasVarianceIssue ? Colors.orange : const Color(0xFF0B3D2E),
            ),
            child: Text(_hasVarianceIssue ? 'Submit Anyway' : 'Submit Report'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text('Shift report submitted successfully!\nAwaiting manager approval.')),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _exportReport() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report exported (PDF/Excel coming soon)'), backgroundColor: Colors.blue),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift Report'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _exportReport, tooltip: 'Share'),
          IconButton(icon: const Icon(Icons.print), onPressed: _exportReport, tooltip: 'Print'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              color: const Color(0xFF0B3D2E),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('EEE, MMM d, yyyy').format(DateTime.now()),
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0x33FFFFFF), // 20% opacity white
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'SHIFT A',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.selectedPump,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Attendant: ${widget.attendantName}', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Meter Readings
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.speed, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Meter Readings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _openingMeterController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Opening (L)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.play_arrow),
                            ),
                            enabled: false,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.arrow_forward, color: Colors.grey),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _closingMeterController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Closing (L)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.stop),
                            ),
                            onChanged: (_) => _calculateDispensed(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Fuel Dispensed:', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            '${_fuelDispensed.toStringAsFixed(1)} Liters',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Financial Summary
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.money, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Financial Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildFinancialRow(
                      icon: Icons.phone_android,
                      label: 'M-Pesa Received',
                      amount: _mpesaReceived,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _cashCollectedController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Cash Collected (KES)',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.money),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calculate),
                          onPressed: _recalculateVariance,
                          tooltip: 'Recalculate',
                        ),
                      ),
                      onChanged: (_) => _recalculateVariance(),
                    ),
                    const SizedBox(height: 12),
                    _buildFinancialRow(
                      icon: Icons.calculate,
                      label: 'Total Expected',
                      amount: _totalExpected,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _hasVarianceIssue ? Colors.orange.shade50 : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _hasVarianceIssue ? Colors.orange : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(













































































































































































































































































































                        
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _hasVarianceIssue ? Icons.warning : Icons.balance,
                                color: _hasVarianceIssue ? Colors.orange : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Variance',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _hasVarianceIssue ? Colors.orange : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _formatCurrency(_variance),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _hasVarianceIssue ? Colors.orange : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Recent Transactions
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.receipt, color: Colors.purple),
                        SizedBox(width: 8),
                        Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('${_transactions.length} transactions this shift', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    ..._transactions.take(3).map((transaction) => _buildTransactionTile(transaction)),
                    if (_transactions.length > 3)
                      TextButton(onPressed: () {}, child: const Text('View All Transactions')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Remarks
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.note_alt, color: Colors.brown),
                        SizedBox(width: 8),
                        Text('Handover Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _remarksController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Any issues, shortages, customer complaints, equipment problems, or handover instructions...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'This report will be sent to the manager for review and approval.',
                      style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitReport,
                    icon: _isSubmitting ? const SizedBox.shrink() : const Icon(Icons.send, size: 20),
                    label: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation(Colors.white)),
                          )
                        : const Text('End Shift', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hasVarianceIssue ? Colors.orange : const Color(0xFF2ECC71),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      disabledBackgroundColor: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialRow({
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
  }) {
    // Helper to get color with 10% opacity based on input color
    Color getColorWithOpacity(Color baseColor) {
      if (baseColor == Colors.green) return const Color(0x1A4CAF50);
      if (baseColor == Colors.blue) return const Color(0x1A2196F3);
      if (baseColor == Colors.orange) return const Color(0x1AFF9800);
      return baseColor.withAlpha(26); // Fallback
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: getColorWithOpacity(color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          Text(
            _formatCurrency(amount),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(ShiftTransaction transaction) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: transaction.type.color.withAlpha(51), // 0.2 opacity = 51 alpha
        child: Icon(transaction.type.icon, color: transaction.type.color, size: 20),
      ),
      title: Text(transaction.customerName ?? transaction.phone, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        '${DateFormat('HH:mm').format(transaction.time)} • ${transaction.status.displayName}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Text(_formatCurrency(transaction.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
      onTap: () => _showTransactionDetails(transaction),
    );
  }
}

// Models
class ShiftTransaction {
  final String id;
  final DateTime time;
  final String phone;
  final double amount;
  final PaymentType type;
  final TransactionStatus status;
  final String? customerName;
  final String? note;

  const ShiftTransaction({
    required this.id,
    required this.time,
    required this.phone,
    required this.amount,
    required this.type,
    required this.status,
    this.customerName,
    this.note,
  });
}

enum PaymentType {
  mpesa,
  cash,
  card;

  String get displayName {
    switch (this) {
      case PaymentType.mpesa:
        return 'M-Pesa';
      case PaymentType.cash:
        return 'Cash';
      case PaymentType.card:
        return 'Card';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentType.mpesa:
        return Icons.phone_android;
      case PaymentType.cash:
        return Icons.money;
      case PaymentType.card:
        return Icons.credit_card;
    }
  }

  Color get color {
    switch (this) {
      case PaymentType.mpesa:
        return Colors.green;
      case PaymentType.cash:
        return Colors.blue;
      case PaymentType.card:
        return Colors.purple;
    }
  }
}

enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled;

  String get displayName {
    switch (this) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.failed:
        return Colors.red;
      case TransactionStatus.cancelled:
        return Colors.grey;
    }
  }
}