import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PaymentInitiateScreen extends StatefulWidget {
  final String selectedPump;
  final String attendantName;
  final Function(double amount, String phone, String? customerName)? onPaymentSuccess;  // Added callback

  const PaymentInitiateScreen({
    super.key,
    required this.selectedPump,
    required this.attendantName,
    this.onPaymentSuccess,
  });

  @override
  State<PaymentInitiateScreen> createState() => _PaymentInitiateScreenState();
}

class _PaymentInitiateScreenState extends State<PaymentInitiateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _customerNameController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  FuelType? _selectedFuelType;
  int? _selectedQuickAmount;
  String _accountNumber = '';

  // Common fuel amounts for quick selection
  final List<int> _quickAmounts = [500, 1000, 1500, 2000, 3000, 5000];

  final List<RecentContact> _recentContacts = [
    RecentContact(name: 'John M.', phone: '712345678'),
    RecentContact(name: 'Sarah W.', phone: '734567890'),
    RecentContact(name: 'Mike T.', phone: '711223344'),
  ];

  @override
  void initState() {
    super.initState();
    // Generate account number based on pump (e.g., Pump 1 = 001, Pump 2 = 002)
    final pumpNumber = widget.selectedPump.replaceAll(RegExp(r'[^0-9]'), '');
    _accountNumber = pumpNumber.padLeft(3, '0');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _customerNameController.dispose();
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
      _selectedQuickAmount = amount;
    });
  }

  void _selectRecentContact(RecentContact contact) {
    setState(() {
      _phoneController.text = contact.phone;
      _customerNameController.text = contact.name;
    });
  }

  bool _isValidKenyanPhone(String phone) {
    // Remove leading 0 if present
    final cleanPhone = phone.startsWith('0') ? phone.substring(1) : phone;
   
    // Check if starts with valid Kenyan prefix
    final validPrefixes = ['7', '1'];
    if (!validPrefixes.contains(cleanPhone.substring(0, 1))) {
      return false;
    }
   
    // Check length (should be 9 digits without leading 0)
    return cleanPhone.length == 9;
  }

  String _getSafaricomValidationMessage(String phone) {
    if (phone.isEmpty) return '';
   
    if (!_isValidKenyanPhone(phone)) {
      return 'Enter valid Safaricom number (e.g., 712345678)';
    }
   
    final cleanPhone = phone.startsWith('0') ? phone.substring(1) : phone;
    final firstDigit = cleanPhone.substring(0, 1);
   
    if (firstDigit == '7') {
      return '✓ Safaricom number';
    } else if (firstDigit == '1') {
      return '⚠️ Airtel/Telkom number (may not work with STK)';
    }
   
    return '';
  }

  Future<void> _sendPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    final amountText = _amountController.text.replaceAll(',', '');
    final amount = double.tryParse(amountText) ?? 0.0;
    final note = _noteController.text.trim();
    final customerName = _customerNameController.text.trim();

    if (amount <= 0) {
      setState(() => _errorMessage = 'Amount must be greater than 0');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _buildConfirmationDialog(
        phone: phone,
        amount: amount,
        note: note,
        customerName: customerName,
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simulate Daraja STK Push
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() => _isLoading = false);

    // Show success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'STK Push Sent!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'To: $phone\nAmount: KES ${_formatAmount(amount.toStringAsFixed(0))}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );

    // NEW: Notify dashboard
    widget.onPaymentSuccess?.call(amount, phone, customerName.isNotEmpty ? customerName : null);

    // Clear form and return
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _phoneController.clear();
        _amountController.clear();
        _noteController.clear();
        _customerNameController.clear();
        setState(() {
          _selectedFuelType = null;
          _selectedQuickAmount = null;
        });
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pop(context);
    });
  }

  Widget _buildConfirmationDialog({
    required String phone,
    required double amount,
    required String note,
    required String customerName,
  }) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.send, color: Color(0xFF0B3D2E)),
          SizedBox(width: 8),
          Text('Confirm Payment Request'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Info
            if (customerName.isNotEmpty) ...[
              _buildConfirmationItem('Customer:', customerName),
              const SizedBox(height: 4),
            ],
            _buildConfirmationItem('Phone:', phone),
           
            const SizedBox(height: 12),
           
            // Pump Info
            _buildConfirmationItem('Pump:', widget.selectedPump),
            _buildConfirmationItem('Attendant:', widget.attendantName),
            _buildConfirmationItem('Account No:', _accountNumber),
           
            const SizedBox(height: 12),
           
            // Payment Details
            _buildConfirmationItem('Amount:', 'KES ${_formatAmount(amount.toStringAsFixed(0))}'),
            if (_selectedFuelType != null)
              _buildConfirmationItem('Fuel Type:', _selectedFuelType!.displayName),
            if (note.isNotEmpty)
              _buildConfirmationItem('Note:', note),
           
            const SizedBox(height: 16),
           
            // Instructions for customer - FIXED WITH Text.rich()
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instructions:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: '1. Customer will receive STK Push on their phone\n'
                                '2. They should enter PIN to complete payment\n'
                                '3. Account number is pre-filled as ',
                        ),
                        TextSpan(
                          text: _accountNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.send, size: 18),
          label: const Text('Send STK Push'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0B3D2E),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
    final phoneValidationMessage = _getSafaricomValidationMessage(_phoneController.text);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Initiate Payment'),
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
                            const Icon(Icons.local_gas_station, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.selectedPump,
                                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Account No: $_accountNumber',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(color: Colors.white54, height: 1),
                        const SizedBox(height: 8),
                        Text('Attendant: ${widget.attendantName}', style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Recent Contacts
                if (_recentContacts.isNotEmpty) ...[
                  const Text('Recent Customers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _recentContacts.map((contact) {
                      return InputChip(
                        label: Text('${contact.name} (${contact.phone})'),
                        onPressed: () => _selectRecentContact(contact),
                        backgroundColor: Colors.grey[100],
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Customer Name
                TextFormField(
                  controller: _customerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name (optional)',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // Phone
                TextFormField(
                  controller: _phoneController,
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
                            onPressed: () {
                              setState(() => _phoneController.clear());
                            },
                          )
                        : null,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (!_isValidKenyanPhone(value)) return 'Enter valid Kenyan number (e.g., 0712345678)';
                    return null;
                  },
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

                if (phoneValidationMessage.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        phoneValidationMessage.startsWith('✓') ? Icons.check_circle : Icons.info,
                        size: 16,
                        color: phoneValidationMessage.startsWith('✓') ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          phoneValidationMessage,
                          style: TextStyle(
                            fontSize: 12,
                            color: phoneValidationMessage.startsWith('✓') ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),

                // Fuel Type
                const Text('Fuel Type (optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: FuelType.values.map((type) {
                    return ChoiceChip(
                      label: Text(type.displayName),
                      selected: _selectedFuelType == type,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFuelType = selected ? type : null;
                          if (selected) {
                            final currentNote = _noteController.text.trim();
                            _noteController.text = currentNote.isEmpty
                                ? type.displayName
                                : '$currentNote - ${type.displayName}';
                          }
                        });
                      },
                      selectedColor: const Color(0xFF0B3D2E),
                      labelStyle: TextStyle(color: _selectedFuelType == type ? Colors.white : Colors.black),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Quick Amounts
                const Text('Quick Amounts (KES)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickAmounts.map((amount) {
                    final isSelected = _selectedQuickAmount == amount;
                    return ActionChip(
                      label: Text(_formatAmount(amount.toString())),
                      onPressed: () => _setQuickAmount(amount),
                      backgroundColor: isSelected ? const Color(0xFF0B3D2E) : Colors.blue[50],
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Amount
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    TextInputFormatter.withFunction(
                      (oldValue, newValue) => TextEditingValue(
                        text: _formatAmount(newValue.text),
                        selection: TextSelection.collapsed(offset: newValue.text.length),
                      ),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Amount (KES)',
                    prefixIcon: const Icon(Icons.money),
                    border: const OutlineInputBorder(),
                    hintText: 'Enter amount',
                    suffixIcon: _amountController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() => _amountController.clear());
                            },
                          )
                        : null,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    final clean = value.replaceAll(',', '');
                    final amt = double.tryParse(clean);
                    if (amt == null || amt <= 0) return 'Enter valid amount';
                    if (amt < 100) return 'Minimum amount is KES 100';
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Note
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note / Reference (optional)',
                    hintText: 'e.g., Diesel 20L, Super 30L, Car Wash',
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
                        Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
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
                        onPressed: _isLoading ? null : _sendPayment,
                        icon: const Icon(Icons.send, size: 20),
                        label: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation(Colors.white)),
                              )
                            : const Text(
                                'Send Payment',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2ECC71),
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

// Models
enum FuelType {
  petrol('Petrol (Super)'),
  diesel('Diesel'),
  kerosene('Kerosene'),
  premium('Premium (V-Power)');

  final String displayName;
  const FuelType(this.displayName);
}

class RecentContact {
  final String name;
  final String phone;
  const RecentContact({required this.name, required this.phone});
}