import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paynotify/core/services/transaction_service.dart';

class CashSaleScreen extends StatefulWidget {
  final String selectedPump;
  final String attendantName;
  final Function(double amount, String? customerName, String? note)? onCashSaleRecorded;

  const CashSaleScreen({
    super.key,
    required this.selectedPump,
    required this.attendantName,
    this.onCashSaleRecorded,
  });

  @override
  State<CashSaleScreen> createState() => _CashSaleScreenState();
}

class _CashSaleScreenState extends State<CashSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _noteController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Common fuel amounts for quick selection
  final List<int> _quickAmounts = [500, 1000, 1500, 2000, 3000, 5000];
  
  // Helper to convert pump name to ID
  int _getPumpId() {
    switch (widget.selectedPump) {
      case 'Pump 1': return 1;
      case 'Pump 2': return 2;
      case 'Pump 3': return 3;
      case 'Pump 4': return 4;
      case 'Pump 5': return 5;
      case 'Pump 6': return 6;
      default: return 1;
    }
  }
  
  String _formatAmount(String value) {
    if (value.isEmpty) return '';
    final number = int.tryParse(value.replaceAll(',', ''));
    if (number == null) return value;
    return NumberFormat('#,##0').format(number);
  }
  
  void _setQuickAmount(int amount) {
    setState(() {
      _amountController.text = amount.toString();
    });
  }
  
  Future<void> _recordCashSale() async {
    if (!_formKey.currentState!.validate()) return;
    
    final amountText = _amountController.text.replaceAll(',', '');
    final amount = double.tryParse(amountText) ?? 0.0;
    final customerName = _customerNameController.text.trim();
    final note = _noteController.text.trim();
    
    if (amount <= 0) {
      setState(() => _errorMessage = 'Amount must be greater than 0');
      return;
    }
    
    // Show confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Cash Sale'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Record this cash sale?'),
            const SizedBox(height: 12),
            _buildDetailRow('Pump:', widget.selectedPump),
            _buildDetailRow('Amount:', 'KES ${_formatAmount(amount.toStringAsFixed(0))}'),
            if (customerName.isNotEmpty) _buildDetailRow('Customer:', customerName),
            if (note.isNotEmpty) _buildDetailRow('Note:', note),
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
              backgroundColor: Colors.green,
            ),
            child: const Text('Record Sale'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // 🔥 CALL THE BACKEND API
      final result = await TransactionService.recordCashSale(
        pumpId: _getPumpId(),
        amount: amount,
        customerName: customerName.isNotEmpty ? customerName : null,
        note: note.isNotEmpty ? note : null,
      );
      
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      
      if (result != null) {
        // Notify parent dashboard to add the transaction to the list
        widget.onCashSaleRecorded?.call(amount, customerName.isNotEmpty ? customerName : null, note);
        
        // Show success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Cash sale of KES ${_formatAmount(amount.toStringAsFixed(0))} recorded'),
              ],
            ),
          ),
        );
        
        // Return to dashboard
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        setState(() => _errorMessage = 'Failed to record sale. Please try again.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Connection error: $e';
      });
    }
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Cash Sale'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Card(
                  color: Colors.green[800],
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.money, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.selectedPump,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Attendant: ${widget.attendantName}',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Customer Name (optional)
                TextFormField(
                  controller: _customerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name (optional)',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Quick Amounts
                const Text(
                  'Quick Amounts (KES)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickAmounts.map((amount) {
                    return ActionChip(
                      label: Text(_formatAmount(amount.toString())),
                      onPressed: () => _setQuickAmount(amount),
                      backgroundColor: Colors.green[50],
                      labelStyle: const TextStyle(color: Colors.green),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 24),
                
                // Amount
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount (KES)',
                    prefixIcon: Icon(Icons.money),
                    border: OutlineInputBorder(),
                    hintText: 'Enter amount',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    final clean = value.replaceAll(',', '');
                    final amount = double.tryParse(clean);
                    if (amount == null || amount <= 0) return 'Enter valid amount';
                    if (amount < 100) return 'Minimum amount is KES 100';
                    return null;
                  },
                  onChanged: (value) {
                    // Auto-format as user types
                    final cursorPos = _amountController.selection.start;
                    _amountController.text = _formatAmount(value);
                    _amountController.selection = TextSelection.collapsed(
                      offset: cursorPos + (_amountController.text.length - value.length),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Note
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note / Description (optional)',
                    hintText: 'e.g., Diesel 20L, Petrol 30L, Car Wash',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[100]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 40),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
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
                        onPressed: _isLoading ? null : _recordCashSale,
                        icon: const Icon(Icons.save, size: 20),
                        label: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text(
                                'Record Sale',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.grey,
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
}