import 'package:flutter/material.dart';

class ReceiptSettingsForm extends StatelessWidget {
  final TextEditingController footerMessageController;
  final TextEditingController digitalReceiptMessageController;
  final bool showVat;
  final bool showWithholdingTax;
  final bool showCustomerDetails;
  final bool showLoyaltyPoints;
  final bool digitalReceiptEnabled;
  final ValueChanged<bool> onShowVatChanged;
  final ValueChanged<bool> onShowWithholdingTaxChanged;
  final ValueChanged<bool> onShowCustomerDetailsChanged;
  final ValueChanged<bool> onShowLoyaltyPointsChanged;
  final ValueChanged<bool> onDigitalReceiptEnabledChanged;
  final VoidCallback onChanged;

  const ReceiptSettingsForm({
    super.key,
    required this.footerMessageController,
    required this.digitalReceiptMessageController,
    required this.showVat,
    required this.showWithholdingTax,
    required this.showCustomerDetails,
    required this.showLoyaltyPoints,
    required this.digitalReceiptEnabled,
    required this.onShowVatChanged,
    required this.onShowWithholdingTaxChanged,
    required this.onShowCustomerDetailsChanged,
    required this.onShowLoyaltyPointsChanged,
    required this.onDigitalReceiptEnabledChanged,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Receipt Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: footerMessageController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Footer Message',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.message),
                  hintText: 'Thank you for fueling with us!',
                ),
                onChanged: (_) => onChanged(),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Show VAT on Receipt'),
                value: showVat,
                onChanged: (value) {
                  onShowVatChanged(value);
                  onChanged();
                },
              ),
              SwitchListTile(
                title: const Text('Show Withholding Tax'),
                value: showWithholdingTax,
                onChanged: (value) {
                  onShowWithholdingTaxChanged(value);
                  onChanged();
                },
              ),
              SwitchListTile(
                title: const Text('Show Customer Details'),
                value: showCustomerDetails,
                onChanged: (value) {
                  onShowCustomerDetailsChanged(value);
                  onChanged();
                },
              ),
              SwitchListTile(
                title: const Text('Show Loyalty Points'),
                value: showLoyaltyPoints,
                onChanged: (value) {
                  onShowLoyaltyPointsChanged(value);
                  onChanged();
                },
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Enable Digital Receipts'),
                subtitle: const Text('Send receipts via SMS/Email'),
                value: digitalReceiptEnabled,
                onChanged: (value) {
                  onDigitalReceiptEnabledChanged(value);
                  onChanged();
                },
              ),
              if (digitalReceiptEnabled)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextFormField(
                    controller: digitalReceiptMessageController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Digital Receipt Message',
                      border: OutlineInputBorder(),
                      hintText: 'Thank you for your purchase. Your receipt is attached.',
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}