// lib/features/manager/presentation/widgets/delivery_dialog.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../domain/models/inventory_model.dart';

class DeliveryDialog extends StatefulWidget {
  final FuelTank tank;
  final Function(DeliveryRecord) onDeliveryRecorded;

  const DeliveryDialog({
    super.key,
    required this.tank,
    required this.onDeliveryRecorded,
  });

  @override
  State<DeliveryDialog> createState() => _DeliveryDialogState();
}

class _DeliveryDialogState extends State<DeliveryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _priceController = TextEditingController();
  final _supplierController = TextEditingController();
  final _invoiceController = TextEditingController();
  final _deliveredByController = TextEditingController();
  
  DateTime _deliveryDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _priceController.dispose();
    _supplierController.dispose();
    _invoiceController.dispose();
    _deliveredByController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0B3D2E),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && mounted) {
      setState(() => _deliveryDate = picked);
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final amount = double.parse(_amountController.text);
    final price = double.parse(_priceController.text);
    final totalCost = amount * price;

    final record = DeliveryRecord(
      id: 'DEL${DateTime.now().millisecondsSinceEpoch}',
      date: _deliveryDate,
      amount: amount,
      pricePerLiter: price,
      totalCost: totalCost,
      supplier: _supplierController.text.isNotEmpty ? _supplierController.text : null,
      invoiceNumber: _invoiceController.text.isNotEmpty ? _invoiceController.text : null,
      deliveredBy: _deliveredByController.text.isNotEmpty ? _deliveredByController.text : null,
    );

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    widget.onDeliveryRecorded(record);
    Navigator.pop(context);
  }

  double? _calculateTotal() {
    if (_amountController.text.isEmpty || _priceController.text.isEmpty) return null;
    
    final amount = double.tryParse(_amountController.text);
    final price = double.tryParse(_priceController.text);
    
    if (amount == null || price == null) return null;
    
    return amount * price;
  }

  @override
  Widget build(BuildContext context) {
    final total = _calculateTotal();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.tank.fuelType.color.withAlpha(26),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.tank.fuelType.icon,
                        color: widget.tank.fuelType.color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Record Delivery',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.tank.name} - ${widget.tank.fuelType.displayName}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const Divider(height: 24),
                
                // Current Level Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Current Level:'),
                      Text(
                        '${widget.tank.currentLevel.toStringAsFixed(0)} L',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Delivery Date
                Semantics(
                  button: true,
                  label: 'Select delivery date',
                  child: InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Delivery Date: ${DateFormat('dd MMM yyyy').format(_deliveryDate)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Amount
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Amount (Liters)',
                    prefixIcon: const Icon(Icons.local_gas_station),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (double.tryParse(value) == null || double.parse(value) <= 0) {
                      return 'Enter valid amount';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                
                const SizedBox(height: 16),
                
                // Price per Liter
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Price per Liter (KES)',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (double.tryParse(value) == null || double.parse(value) <= 0) {
                      return 'Enter valid price';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                
                const SizedBox(height: 16),
                
                // Supplier
                TextFormField(
                  controller: _supplierController,
                  decoration: InputDecoration(
                    labelText: 'Supplier (Optional)',
                    prefixIcon: const Icon(Icons.business),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Invoice Number
                TextFormField(
                  controller: _invoiceController,
                  decoration: InputDecoration(
                    labelText: 'Invoice Number (Optional)',
                    prefixIcon: const Icon(Icons.receipt),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Delivered By
                TextFormField(
                  controller: _deliveredByController,
                  decoration: InputDecoration(
                    labelText: 'Delivered By (Optional)',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Total Preview
                if (total != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Cost:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'KES ${NumberFormat('#,##0').format(total)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFF0B3D2E)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B3D2E),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text('Record Delivery'),
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