// lib/features/supervisor/presentation/screens/pump_override_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../domain/models/override_pump.dart';

// MARK: - Constants
class _PumpOverrideConstants {
  static const Color primaryDark = Color(0xFF0B3D2E);
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color warningOrange = Color(0xFFF39C12);
  static const Color errorRed = Color(0xFFE74C3C);
  static const Color overridePurple = Color(0xFF9C27B0);
}

// MARK: - Payment Method Enum
enum PaymentMethod {
  mpesa('M-Pesa', Icons.phone_android, Colors.green),
  cash('Cash', Icons.money, Colors.blue),
  card('Card', Icons.credit_card, Colors.purple);

  final String displayName;
  final IconData icon;
  final Color color;

  const PaymentMethod(this.displayName, this.icon, this.color);
}

class PumpOverrideScreen extends StatefulWidget {
  final String supervisorName;
  final String supervisorId;
  final List<OverridePump> pumps;
  final OverridePump? preselectedPump;

  const PumpOverrideScreen({
    super.key,
    required this.supervisorName,
    required this.supervisorId,
    required this.pumps,
    this.preselectedPump,
  });

  @override
  State<PumpOverrideScreen> createState() => _PumpOverrideScreenState();
}

class _PumpOverrideScreenState extends State<PumpOverrideScreen> {
  // Selection State
  OverridePump? _selectedPump;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.mpesa;
  
  // Form Controllers
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  
  // State
  bool _isProcessing = false;
  String? _errorMessage;
  String? _successMessage;
  
  // Focus Nodes
  final FocusNode _amountFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _customerNameFocus = FocusNode();
  final FocusNode _reasonFocus = FocusNode();

  // Quick amounts for selection
  final List<int> _quickAmounts = [500, 1000, 1500, 2000, 3000, 5000];

  @override
  void initState() {
    super.initState();
    if (widget.preselectedPump != null) {
      _selectedPump = widget.preselectedPump;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    _customerNameController.dispose();
    _reasonController.dispose();
    _amountFocus.dispose();
    _phoneFocus.dispose();
    _customerNameFocus.dispose();
    _reasonFocus.dispose();
    super.dispose();
  }

  String _formatAmount(String value) {
    if (value.isEmpty) return '';
    final number = int.tryParse(value.replaceAll(',', ''));
    if (number == null) return value;
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  void _setQuickAmount(int amount) {
    setState(() {
      _amountController.text = _formatAmount(amount.toString());
    });
    _amountFocus.requestFocus();
  }

  bool _isValidKenyanPhone(String phone) {
    final cleanPhone = phone.startsWith('0') ? phone.substring(1) : phone;
    final validPrefixes = ['7', '1'];
    if (cleanPhone.isEmpty || !validPrefixes.contains(cleanPhone.substring(0, 1))) {
      return false;
    }
    return cleanPhone.length == 9;
  }

  String _getPhoneValidationMessage(String phone) {
    if (phone.isEmpty) return '';
    if (!_isValidKenyanPhone(phone)) {
      return 'Enter valid Safaricom number (e.g., 712345678)';
    }
    return '✓ Valid number';
  }

  Future<void> _processPayment() async {
    // Validate pump selection
    if (_selectedPump == null) {
      setState(() => _errorMessage = 'Please select a pump');
      return;
    }

    // Validate amount
    final amountText = _amountController.text.replaceAll(',', '');
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid amount');
      return;
    }

    if (amount < 100) {
      setState(() => _errorMessage = 'Minimum amount is KES 100');
      return;
    }

    // Validate payment method specific fields
    if (_selectedPaymentMethod == PaymentMethod.mpesa) {
      final phone = _phoneController.text.trim();
      if (phone.isEmpty) {
        setState(() => _errorMessage = 'Please enter customer phone number');
        return;
      }
      if (!_isValidKenyanPhone(phone)) {
        setState(() => _errorMessage = 'Please enter a valid Kenyan phone number');
        return;
      }
    }

    // Validate reason
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _errorMessage = 'Please provide a reason for override');
      return;
    }

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(amount);
    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _successMessage = null;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _successMessage = 'Payment of ${_formatCurrency(amount)} processed successfully on ${_selectedPump!.name}!';
    });

    HapticFeedback.mediumImpact();

    // Reset form after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _resetForm();
      }
    });
  }

  Future<bool?> _showConfirmationDialog(double amount) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: _PumpOverrideConstants.warningOrange),
            const SizedBox(width: 8),
            const Text('Confirm Override Sale'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _PumpOverrideConstants.overridePurple.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield, color: _PumpOverrideConstants.overridePurple),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Supervisor Override Sale',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _PumpOverrideConstants.overridePurple,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildConfirmationRow('Pump', _selectedPump!.name),
            _buildConfirmationRow('Amount', _formatCurrency(amount)),
            _buildConfirmationRow('Payment Method', _selectedPaymentMethod.displayName),
            if (_selectedPaymentMethod == PaymentMethod.mpesa)
              _buildConfirmationRow('Phone', _phoneController.text.trim()),
            if (_customerNameController.text.trim().isNotEmpty)
              _buildConfirmationRow('Customer', _customerNameController.text.trim()),
            _buildConfirmationRow('Reason', _reasonController.text.trim()),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _PumpOverrideConstants.errorRed.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _PumpOverrideConstants.errorRed.withAlpha(77)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: _PumpOverrideConstants.errorRed, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '⚠️ This action will be logged for audit purposes',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
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
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _PumpOverrideConstants.overridePurple,
            ),
            child: const Text('Confirm Sale'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return 'KES ${NumberFormat('#,##0').format(amount)}';
  }

  void _resetForm() {
    setState(() {
      _amountController.clear();
      _phoneController.clear();
      _customerNameController.clear();
      _reasonController.clear();
      _errorMessage = null;
      _successMessage = null;
    });
    _amountFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final availablePumps = widget.pumps.where(
      (p) => p.status != PumpStatus.maintenance
    ).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Override Sale - Any Pump'),
        backgroundColor: _PumpOverrideConstants.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetForm,
            tooltip: 'Reset Form',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Supervisor Info Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _PumpOverrideConstants.overridePurple.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _PumpOverrideConstants.overridePurple.withAlpha(77),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.admin_panel_settings, color: _PumpOverrideConstants.overridePurple),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Supervisor: ${widget.supervisorName}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _PumpOverrideConstants.overridePurple,
                            ),
                          ),
                          const Text(
                            'You have permission to make sales on any pump',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Pump Selection
              const Text(
                'Select Pump',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedPump != null
                        ? _PumpOverrideConstants.accentGreen
                        : Colors.grey.shade300,
                    width: _selectedPump != null ? 2 : 1,
                  ),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availablePumps.map((pump) {
                    final isSelected = _selectedPump?.id == pump.id;
                    return FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            pump.fuelType.icon,
                            size: 16,
                            color: isSelected ? Colors.white : pump.fuelType.color,
                          ),
                          const SizedBox(width: 4),
                          Text(pump.name),
                          if (pump.attendantName != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(${pump.attendantName})',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _selectedPump = pump;
                          _errorMessage = null;
                        });
                        HapticFeedback.lightImpact();
                      },
                      backgroundColor: Colors.grey.shade100,
                      selectedColor: pump.fuelType.color,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    );
                  }).toList(),
                ),
              ),

              if (_selectedPump != null) ...[
                const SizedBox(height: 16),
                // Selected Pump Info Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _selectedPump!.fuelType.color.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedPump!.fuelType.icon,
                        color: _selectedPump!.fuelType.color,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedPump!.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _selectedPump!.fuelType.color,
                              ),
                            ),
                            Text(
                              '${_selectedPump!.fuelType.displayName} • KES ${_selectedPump!.pricePerLiter.toStringAsFixed(2)}/L',
                              style: TextStyle(
                                fontSize: 12,
                                color: _selectedPump!.fuelType.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _selectedPump!.status.color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _selectedPump!.status.icon,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _selectedPump!.status.displayName,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Payment Method Selection
              const Text(
                'Payment Method',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: PaymentMethod.values.map((method) {
                  final isSelected = _selectedPaymentMethod == method;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedPaymentMethod = method);
                          HapticFeedback.lightImpact();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? method.color : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: method.color,
                              width: isSelected ? 0 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                method.icon,
                                color: isSelected ? Colors.white : method.color,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                method.displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.white : method.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Customer Name (Optional)
              TextFormField(
                controller: _customerNameController,
                decoration: const InputDecoration(
                  labelText: 'Customer Name (Optional)',
                  hintText: 'Enter customer name for receipt',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                onEditingComplete: () => _amountFocus.requestFocus(),
              ),

              const SizedBox(height: 16),

              // Amount Section
              const Text(
                'Amount (KES)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              
              // Quick Amount Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickAmounts.map((amount) {
                  return ActionChip(
                    label: Text(_formatAmount(amount.toString())),
                    onPressed: () => _setQuickAmount(amount),
                    backgroundColor: _PumpOverrideConstants.accentGreen.withAlpha(26),
                    labelStyle: const TextStyle(color: _PumpOverrideConstants.accentGreen),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _amountController,
                focusNode: _amountFocus,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter amount',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: const OutlineInputBorder(),
                  suffixIcon: _amountController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => _amountController.clear(),
                        )
                      : null,
                ),
                onChanged: (value) {
                  final cursorPos = _amountController.selection.start;
                  _amountController.text = _formatAmount(value);
                  _amountController.selection = TextSelection.collapsed(
                    offset: cursorPos + (_amountController.text.length - value.length),
                  );
                },
              ),

              // M-Pesa specific fields
              if (_selectedPaymentMethod == PaymentMethod.mpesa) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Customer Phone Number',
                    hintText: '0712345678',
                    prefixIcon: const Icon(Icons.phone_android),
                    border: const OutlineInputBorder(),
                    suffixIcon: _phoneController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => _phoneController.clear(),
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {});
                    if (value.length == 1 && !value.startsWith('0')) {
                      _phoneController.text = '0$value';
                      _phoneController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _phoneController.text.length),
                      );
                    }
                  },
                ),
                if (_phoneController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _getPhoneValidationMessage(_phoneController.text),
                      style: TextStyle(
                        fontSize: 12,
                        color: _isValidKenyanPhone(_phoneController.text)
                            ? Colors.green
                            : _PumpOverrideConstants.warningOrange,
                      ),
                    ),
                  ),
              ],

              const SizedBox(height: 16),

              // Reason for Override (Required)
              TextFormField(
                controller: _reasonController,
                focusNode: _reasonFocus,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Reason for Override *',
                  hintText: 'e.g., Attendant busy, Rush hour, Technical issue',
                  prefixIcon: const Icon(Icons.edit_note),
                  border: const OutlineInputBorder(),
                  helperText: 'This will be logged for audit purposes',
                  helperMaxLines: 1,
                ),
              ),

              // Error Message - Using errorRed
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _PumpOverrideConstants.errorRed.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _PumpOverrideConstants.errorRed.withAlpha(77)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: _PumpOverrideConstants.errorRed, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: _PumpOverrideConstants.errorRed, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Success Message
              if (_successMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: TextStyle(color: Colors.green.shade700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _processPayment,
                      icon: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle),
                      label: _isProcessing
                          ? const Text('Processing...')
                          : const Text('Process Sale', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _PumpOverrideConstants.overridePurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Audit Notice - Using errorRed
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _PumpOverrideConstants.errorRed.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, size: 16, color: _PumpOverrideConstants.errorRed),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All supervisor sales are logged and will appear in audit reports',
                        style: TextStyle(fontSize: 11, color: _PumpOverrideConstants.errorRed),
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