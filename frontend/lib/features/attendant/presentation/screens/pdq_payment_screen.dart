import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paynotify/core/services/transaction_service.dart';

class PdqPaymentScreen extends StatefulWidget {
  final String attendantName;
  final String selectedPump;

  const PdqPaymentScreen({
    super.key,
    required this.attendantName,
    required this.selectedPump,
  });

  @override
  State<PdqPaymentScreen> createState() => _PdqPaymentScreenState();
}

class _PdqPaymentScreenState extends State<PdqPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  
  bool _isProcessing = false;
  bool _isManualEntry = false;
  String? _selectedCardType;
  String? _selectedBank;

  final List<String> _cardTypes = ['Visa', 'Mastercard', 'American Express', 'Discovery'];
  final List<String> _banks = ['Equity Bank', 'KCB', 'Co-op Bank', 'Absa', 'Stanbic', 'NCBA', 'Standard Chartered'];

  @override
  void dispose() {
    _amountController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  // Helper to get pump ID from pump name
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

  Future<void> _processPayment() async {
    // Validate amount
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter payment amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Parse amount safely
    double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isManualEntry && (_selectedCardType == null || _selectedBank == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select card type and bank'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_isManualEntry) {
      if (_cardNumberController.text.isEmpty ||
          _cardHolderController.text.isEmpty ||
          _expiryController.text.isEmpty ||
          _cvvController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all card details'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      if (!_formKey.currentState!.validate()) {
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      // 🔥 CALL BACKEND API TO RECORD CARD SALE
      final result = await TransactionService.recordCardSale(
        pumpId: _getPumpId(),
        amount: amount,
        customerName: _cardHolderController.text.isNotEmpty 
            ? _cardHolderController.text 
            : null,
        note: 'Card payment via ${_selectedCardType ?? 'PDQ'} - ${_selectedBank ?? 'Bank'}',
      );

      if (!mounted) return;

      setState(() => _isProcessing = false);

      if (result != null) {
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Column(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 60),
                SizedBox(height: 16),
                Text('Payment Successful'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'KES ${NumberFormat('#,##0.00').format(amount)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B3D2E),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Card', _selectedCardType ?? 'Card'),
                _buildDetailRow('Bank', _selectedBank ?? 'Bank'),
                _buildDetailRow('Transaction ID', result['transaction_id']?.substring(0, 15) ?? 'N/A'),
                _buildDetailRow('Time', DateFormat('hh:mm a').format(DateTime.now())),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to dashboard
                },
                child: const Text('Done'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Printing receipt...')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B3D2E),
                ),
                child: const Text('Print Receipt'),
              ),
            ],
          ),
        );

        // Show snackbar notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Card payment of KES ${NumberFormat('#,##0.00').format(amount)} completed'),
            duration: const Duration(seconds: 3),
          ),
        );

        // Clear form
        _amountController.clear();
        _cardNumberController.clear();
        _cardHolderController.clear();
        _expiryController.clear();
        _cvvController.clear();
        setState(() {
          _selectedCardType = null;
          _selectedBank = null;
        });
      } else {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Card payment error: $e');
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDQ Card Payment'),
        backgroundColor: const Color(0xFF0B3D2E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isManualEntry ? Icons.credit_card : Icons.edit),
            onPressed: () {
              setState(() {
                _isManualEntry = !_isManualEntry;
              });
            },
            tooltip: _isManualEntry ? 'Switch to Terminal' : 'Manual Entry',
          ),
        ],
      ),
      body: SafeArea(
        child: _isProcessing
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text(
                      'Processing Card Payment...',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please wait while the transaction completes',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B3D2E).withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B3D2E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.credit_card,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Card Payment',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.selectedPump,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _isManualEntry ? Colors.orange : Colors.green,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _isManualEntry ? 'Manual Mode' : 'Quick Mode',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Amount field
                    const Text(
                      'Payment Amount',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixText: 'KES ',
                        hintText: '0.00',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF0B3D2E), width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid amount';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Amount must be greater than 0';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    if (!_isManualEntry) ...[
                      // Quick Mode - Card Type Selection
                      const Text(
                        'Card Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _cardTypes.map((type) {
                          return FilterChip(
                            label: Text(type),
                            selected: _selectedCardType == type,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCardType = selected ? type : null;
                              });
                            },
                            selectedColor: const Color(0xFF0B3D2E).withAlpha(51),
                            checkmarkColor: const Color(0xFF0B3D2E),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // Bank Selection
                      const Text(
                        'Bank',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedBank,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.account_balance),
                        ),
                        hint: const Text('Select Bank'),
                        items: _banks.map((bank) {
                          return DropdownMenuItem(
                            value: bank,
                            child: Text(bank),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedBank = value;
                          });
                        },
                      ),
                    ] else ...[
                      // Manual Entry Mode - Full Card Details
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Card Number
                            TextFormField(
                              controller: _cardNumberController,
                             keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Card Number',
                                prefixIcon: const Icon(Icons.credit_card),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFF0B3D2E), width: 2),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter card number';
                                }
                                if (value.length < 16) {
                                  return 'Invalid card number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Card Holder
                            TextFormField(
                              controller: _cardHolderController,
                              decoration: InputDecoration(
                                labelText: 'Card Holder Name',
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFF0B3D2E), width: 2),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter card holder name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Expiry and CVV
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _expiryController,
                                    keyboardType: TextInputType.datetime,
                                    decoration: InputDecoration(
                                      labelText: 'Expiry (MM/YY)',
                                      prefixIcon: const Icon(Icons.calendar_today),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Color(0xFF0B3D2E), width: 2),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                                        return 'Use format MM/YY';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _cvvController,
                                    keyboardType: TextInputType.number,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      labelText: 'CVV',
                                      prefixIcon: const Icon(Icons.lock),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Color(0xFF0B3D2E), width: 2),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      if (value.length < 3) {
                                        return 'Invalid CVV';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Process Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _processPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B3D2E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Process Payment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Security Notice
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.security,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isManualEntry
                                  ? 'PCI Compliant • Encrypted transmission'
                                  : 'Connected to secure payment gateway',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}