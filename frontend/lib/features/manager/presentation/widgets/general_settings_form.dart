import 'package:flutter/material.dart';

class GeneralSettingsForm extends StatelessWidget {
  final TextEditingController vatRateController;
  final TextEditingController withholdingTaxController;
  final TextEditingController otherTaxRateController;
  final TextEditingController otherTaxNameController;
  final TextEditingController lowFuelThresholdController;
  final TextEditingController backupEmailController;
  
  final bool vatEnabled;
  final bool withholdingTaxEnabled;
  final bool taxInclusivePricing;
  final bool autoBackup;
  
  final String selectedCurrency;
  final String selectedTimezone;
  
  final List<String> currencies;
  final List<String> timezones;
  
  final ValueChanged<bool> onVatEnabledChanged;
  final ValueChanged<bool> onWithholdingTaxEnabledChanged;
  final ValueChanged<bool> onTaxInclusivePricingChanged;
  final ValueChanged<bool> onAutoBackupChanged;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<String> onTimezoneChanged;
  final VoidCallback onChanged;

  const GeneralSettingsForm({
    super.key,
    required this.vatRateController,
    required this.withholdingTaxController,
    required this.otherTaxRateController,
    required this.otherTaxNameController,
    required this.lowFuelThresholdController,
    required this.backupEmailController,
    required this.vatEnabled,
    required this.withholdingTaxEnabled,
    required this.taxInclusivePricing,
    required this.autoBackup,
    required this.selectedCurrency,
    required this.selectedTimezone,
    required this.currencies,
    required this.timezones,
    required this.onVatEnabledChanged,
    required this.onWithholdingTaxEnabledChanged,
    required this.onTaxInclusivePricingChanged,
    required this.onAutoBackupChanged,
    required this.onCurrencyChanged,
    required this.onTimezoneChanged,
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
                'Tax Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Enable VAT'),
                value: vatEnabled,
                onChanged: (value) {
                  onVatEnabledChanged(value);
                  onChanged();
                },
              ),
              if (vatEnabled)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8),
                  child: TextFormField(
                    controller: vatRateController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'VAT Rate (%)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.percent),
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Enable Withholding Tax'),
                value: withholdingTaxEnabled,
                onChanged: (value) {
                  onWithholdingTaxEnabledChanged(value);
                  onChanged();
                },
              ),
              if (withholdingTaxEnabled)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8),
                  child: TextFormField(
                    controller: withholdingTaxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Withholding Tax Rate (%)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.percent),
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Tax Inclusive Pricing'),
                subtitle: const Text('Display prices including tax'),
                value: taxInclusivePricing,
                onChanged: (value) {
                  onTaxInclusivePricingChanged(value);
                  onChanged();
                },
              ),
              const Divider(),
              const Text('Other Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedCurrency,
                decoration: const InputDecoration(
                  labelText: 'Currency',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                items: currencies.map((currency) {
                  return DropdownMenuItem(value: currency, child: Text(currency));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    onCurrencyChanged(value);
                    onChanged();
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedTimezone,
                decoration: const InputDecoration(
                  labelText: 'Timezone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
                items: timezones.map((tz) {
                  return DropdownMenuItem(value: tz, child: Text(tz));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    onTimezoneChanged(value);
                    onChanged();
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: lowFuelThresholdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Low Fuel Alert Threshold (%)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.warning),
                  suffixText: '%',
                ),
                onChanged: (_) => onChanged(),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Auto Backup'),
                subtitle: const Text('Automatically backup data daily'),
                value: autoBackup,
                onChanged: (value) {
                  onAutoBackupChanged(value);
                  onChanged();
                },
              ),
              if (autoBackup)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8),
                  child: TextFormField(
                    controller: backupEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Backup Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                      hintText: 'backup@example.com',
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