import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/station_model.dart';
import '../../domain/models/station_settings_model.dart';
import '../widgets/station_profile_form.dart';
import '../widgets/operating_hours_card.dart';
import '../widgets/fuel_type_card.dart';
import '../widgets/receipt_settings_form.dart';
import '../widgets/general_settings_form.dart';

// MARK: - Constants
class _StationConstants {
  static const Color primaryDark = Color(0xFF0B3D2E);
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color warningOrange = Color(0xFFF39C12);
  static const Color errorRed = Color(0xFFE74C3C);
  
  static const Duration animationDuration = Duration(milliseconds: 300);
}

class StationSettingsScreen extends StatefulWidget {
  const StationSettingsScreen({super.key});

  @override
  State<StationSettingsScreen> createState() => _StationSettingsScreenState();
}

class _StationSettingsScreenState extends State<StationSettingsScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasChanges = false;
  
  // Station Data
  Station? _station;
  StationSettings? _settings;
  
  // Form keys
  final _stationFormKey = GlobalKey<FormState>();
  
  // Station Profile Controllers
  late TextEditingController _nameController;
  late TextEditingController _registrationController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _countyController;
  late TextEditingController _postalController;
  
  // General Settings Controllers
  late TextEditingController _lowFuelThresholdController;
  late TextEditingController _backupEmailController;
  late TextEditingController _vatRateController;
  late TextEditingController _withholdingTaxController;
  late TextEditingController _otherTaxRateController;
  late TextEditingController _otherTaxNameController;
  
  // Receipt Settings Controllers
  late TextEditingController _footerMessageController;
  late TextEditingController _digitalReceiptMessageController;
  
  // Boolean settings
  bool _vatEnabled = true;
  bool _withholdingTaxEnabled = false;
  bool _taxInclusivePricing = true;
  bool _autoBackup = false;
  bool _showVat = true;
  bool _showWithholdingTax = false;
  bool _showCustomerDetails = true;
  bool _showLoyaltyPoints = true;
  bool _digitalReceiptEnabled = false;
  
  String _selectedCurrency = 'KES';
  String _selectedTimezone = 'Africa/Nairobi';
  
  // Operating Hours
  Map<String, OperatingHours> _operatingHours = {};
  
  // Fuel Types
  List<FuelTypeConfig> _fuelTypes = [];
  
  final List<String> _daysOfWeek = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  
  final List<String> _currencies = ['KES', 'USD', 'EUR', 'GBP'];
  final List<String> _timezones = [
    'Africa/Nairobi',
    'Africa/Johannesburg',
    'Africa/Lagos',
    'Africa/Cairo',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initializeControllers();
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _registrationController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countyController.dispose();
    _postalController.dispose();
    _lowFuelThresholdController.dispose();
    _backupEmailController.dispose();
    _vatRateController.dispose();
    _withholdingTaxController.dispose();
    _otherTaxRateController.dispose();
    _otherTaxNameController.dispose();
    _footerMessageController.dispose();
    _digitalReceiptMessageController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _registrationController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _cityController = TextEditingController();
    _countyController = TextEditingController();
    _postalController = TextEditingController();
    _lowFuelThresholdController = TextEditingController();
    _backupEmailController = TextEditingController();
    _vatRateController = TextEditingController();
    _withholdingTaxController = TextEditingController();
    _otherTaxRateController = TextEditingController();
    _otherTaxNameController = TextEditingController();
    _footerMessageController = TextEditingController();
    _digitalReceiptMessageController = TextEditingController();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      await Future.delayed(_StationConstants.animationDuration);
      
      if (!mounted) return;
      
      _station = _generateMockStation();
      _settings = _generateMockSettings();
      _operatingHours = _settings!.operatingHours;
      _fuelTypes = _settings!.fuelTypes;
      _populateControllers();
      
      setState(() => _isLoading = false);
      HapticFeedback.lightImpact();
      
    } catch (e, stackTrace) {
      if (!mounted) return;
      debugPrint('Load settings error: $e\n$stackTrace');
      setState(() {
        _errorMessage = _getErrorMessage(e);
        _isLoading = false;
      });
      _showErrorSnackBar();
    }
  }
  
  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('SocketException')) {
      return 'No internet connection. Please check your network.';
    }
    return 'Failed to load station settings. Please try again.';
  }
  
  void _showErrorSnackBar() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(_errorMessage ?? 'An error occurred')),
          ],
        ),
        backgroundColor: _StationConstants.errorRed,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _loadData,
        ),
      ),
    );
  }

  Station _generateMockStation() {
    return Station(
      id: '1',
      name: 'Panoifyy Petrol Station',
      registrationNumber: 'CP/12345/2024',
      phone: '0700123456',
      email: 'info@panoifyy.co.ke',
      address: 'Mombasa Road',
      city: 'Nairobi',
      county: 'Nairobi',
      postalCode: '00100',
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      updatedAt: DateTime.now(),
    );
  }

  StationSettings _generateMockSettings() {
    final operatingHours = <String, OperatingHours>{};
    for (final day in _daysOfWeek) {
      operatingHours[day] = OperatingHours(
        day: day,
        openTime: const TimeOfDay(hour: 6, minute: 0),
        closeTime: const TimeOfDay(hour: 22, minute: 0),
        isClosed: day == 'Sunday',
      );
    }
    
    return StationSettings(
      stationId: '1',
      operatingHours: operatingHours,
      fuelTypes: [
        FuelTypeConfig(id: '1', name: 'Petrol', price: 180.50),
        FuelTypeConfig(id: '2', name: 'Diesel', price: 165.00),
        FuelTypeConfig(id: '3', name: 'Kerosene', price: 120.00),
        FuelTypeConfig(id: '4', name: 'Premium', price: 195.00),
      ],
      taxSettings: TaxSettings(),
      receiptSettings: ReceiptSettings(),
      lowFuelThreshold: 15,
    );
  }

  void _populateControllers() {
    if (_station != null) {
      _nameController.text = _station!.name;
      _registrationController.text = _station!.registrationNumber;
      _phoneController.text = _station!.phone;
      _emailController.text = _station!.email ?? '';
      _addressController.text = _station!.address;
      _cityController.text = _station!.city ?? '';
      _countyController.text = _station!.county ?? '';
      _postalController.text = _station!.postalCode ?? '';
    }
    
    if (_settings != null) {
      _lowFuelThresholdController.text = _settings!.lowFuelThreshold.toString();
      _backupEmailController.text = _settings!.backupEmail ?? '';
      _selectedCurrency = _settings!.currency;
      _selectedTimezone = _settings!.timezone;
      _autoBackup = _settings!.autoBackup;
      
      _vatRateController.text = _settings!.taxSettings.vatRate.toString();
      _withholdingTaxController.text = _settings!.taxSettings.withholdingTaxRate.toString();
      _otherTaxRateController.text = _settings!.taxSettings.otherTaxRate.toString();
      _otherTaxNameController.text = _settings!.taxSettings.otherTaxName;
      _vatEnabled = _settings!.taxSettings.vatEnabled;
      _withholdingTaxEnabled = _settings!.taxSettings.withholdingTaxEnabled;
      _taxInclusivePricing = _settings!.taxSettings.taxInclusivePricing;
      
      _footerMessageController.text = _settings!.receiptSettings.footerMessage;
      _digitalReceiptMessageController.text = _settings!.receiptSettings.digitalReceiptMessage ?? '';
      _showVat = _settings!.receiptSettings.showVat;
      _showWithholdingTax = _settings!.receiptSettings.showWithholdingTax;
      _showCustomerDetails = _settings!.receiptSettings.showCustomerDetails;
      _showLoyaltyPoints = _settings!.receiptSettings.showLoyaltyPoints;
      _digitalReceiptEnabled = _settings!.receiptSettings.digitalReceiptEnabled;
    }
  }

  Future<void> _saveSettings() async {
    if (!_stationFormKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (!mounted) return;
      
      setState(() {
        _hasChanges = false;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: _StationConstants.accentGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      HapticFeedback.lightImpact();
      
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save settings: ${e.toString()}'),
          backgroundColor: _StationConstants.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showFuelPriceDialog(FuelTypeConfig fuel) {
    final priceController = TextEditingController(text: fuel.price.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update ${fuel.name} Price'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Price: KES ${fuel.price.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'New Price (KES/L)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newPrice = double.tryParse(priceController.text);
              if (newPrice != null && newPrice > 0) {
                setState(() {
                  fuel.price = newPrice;
                  _hasChanges = true;
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _StationConstants.primaryDark,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showOperatingHoursDialog(String day, OperatingHours hours) {
    TimeOfDay openTime = hours.openTime;
    TimeOfDay closeTime = hours.closeTime;
    bool isClosed = hours.isClosed;
    bool is24Hours = hours.is24Hours;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('$day Hours'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Closed'),
                  value: isClosed,
                  onChanged: (value) {
                    setDialogState(() {
                      isClosed = value;
                      if (value) is24Hours = false;
                    });
                  },
                ),
                if (!isClosed)
                  SwitchListTile(
                    title: const Text('24 Hours'),
                    value: is24Hours,
                    onChanged: (value) {
                      setDialogState(() {
                        is24Hours = value;
                        if (value) isClosed = false;
                      });
                    },
                  ),
                if (!isClosed && !is24Hours) ...[
                  ListTile(
                    title: const Text('Opening Time'),
                    subtitle: Text(_formatTimeOfDay(openTime)),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: openTime,
                      );
                      if (time != null) {
                        setDialogState(() => openTime = time);
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('Closing Time'),
                    subtitle: Text(_formatTimeOfDay(closeTime)),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: closeTime,
                      );
                      if (time != null) {
                        setDialogState(() => closeTime = time);
                      }
                    },
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _operatingHours[day] = OperatingHours(
                      day: day,
                      openTime: openTime,
                      closeTime: closeTime,
                      isClosed: isClosed,
                      is24Hours: is24Hours,
                    );
                    _hasChanges = true;
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _StationConstants.primaryDark,
                ),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _markChanged() {
    setState(() => _hasChanges = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Station Settings'),
        backgroundColor: _StationConstants.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.store), text: 'Profile'),
            Tab(icon: Icon(Icons.access_time), text: 'Hours'),
            Tab(icon: Icon(Icons.local_gas_station), text: 'Fuel'),
            Tab(icon: Icon(Icons.receipt), text: 'Receipt'),
            Tab(icon: Icon(Icons.settings), text: 'General'),
          ],
        ),
        actions: [
          if (_hasChanges)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _StationConstants.warningOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Unsaved',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
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
                        Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700))),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.red.shade700),
                          onPressed: () => setState(() => _errorMessage = null),
                        ),
                      ],
                    ),
                  ),
                
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      StationProfileForm(
                        formKey: _stationFormKey,
                        nameController: _nameController,
                        registrationController: _registrationController,
                        phoneController: _phoneController,
                        emailController: _emailController,
                        addressController: _addressController,
                        cityController: _cityController,
                        countyController: _countyController,
                        postalController: _postalController,
                        onChanged: _markChanged,
                      ),
                      
                      ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _daysOfWeek.length,
                        itemBuilder: (context, index) {
                          final day = _daysOfWeek[index];
                          final hours = _operatingHours[day]!;
                          return OperatingHoursCard(
                            day: day,
                            hours: hours,
                            onTap: () => _showOperatingHoursDialog(day, hours),
                          );
                        },
                      ),
                      
                      ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _fuelTypes.length,
                        itemBuilder: (context, index) {
                          final fuel = _fuelTypes[index];
                          return FuelTypeCard(
                            fuel: fuel,
                            onPriceEdit: () => _showFuelPriceDialog(fuel),
                            onAvailabilityChanged: (value) {
                              setState(() {
                                fuel.isAvailable = value;
                                _hasChanges = true;
                              });
                            },
                          );
                        },
                      ),
                      
                      ReceiptSettingsForm(
                        footerMessageController: _footerMessageController,
                        digitalReceiptMessageController: _digitalReceiptMessageController,
                        showVat: _showVat,
                        showWithholdingTax: _showWithholdingTax,
                        showCustomerDetails: _showCustomerDetails,
                        showLoyaltyPoints: _showLoyaltyPoints,
                        digitalReceiptEnabled: _digitalReceiptEnabled,
                        onShowVatChanged: (value) => _showVat = value,
                        onShowWithholdingTaxChanged: (value) => _showWithholdingTax = value,
                        onShowCustomerDetailsChanged: (value) => _showCustomerDetails = value,
                        onShowLoyaltyPointsChanged: (value) => _showLoyaltyPoints = value,
                        onDigitalReceiptEnabledChanged: (value) => _digitalReceiptEnabled = value,
                        onChanged: _markChanged,
                      ),
                      
                      GeneralSettingsForm(
                        vatRateController: _vatRateController,
                        withholdingTaxController: _withholdingTaxController,
                        otherTaxRateController: _otherTaxRateController,
                        otherTaxNameController: _otherTaxNameController,
                        lowFuelThresholdController: _lowFuelThresholdController,
                        backupEmailController: _backupEmailController,
                        vatEnabled: _vatEnabled,
                        withholdingTaxEnabled: _withholdingTaxEnabled,
                        taxInclusivePricing: _taxInclusivePricing,
                        autoBackup: _autoBackup,
                        selectedCurrency: _selectedCurrency,
                        selectedTimezone: _selectedTimezone,
                        currencies: _currencies,
                        timezones: _timezones,
                        onVatEnabledChanged: (value) => _vatEnabled = value,
                        onWithholdingTaxEnabledChanged: (value) => _withholdingTaxEnabled = value,
                        onTaxInclusivePricingChanged: (value) => _taxInclusivePricing = value,
                        onAutoBackupChanged: (value) => _autoBackup = value,
                        onCurrencyChanged: (value) => _selectedCurrency = value,
                        onTimezoneChanged: (value) => _selectedTimezone = value,
                        onChanged: _markChanged,
                      ),
                    ],
                  ),
                ),
                
                // Save Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _hasChanges ? _saveSettings : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _StationConstants.primaryDark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: const Text(
                        'SAVE CHANGES',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}