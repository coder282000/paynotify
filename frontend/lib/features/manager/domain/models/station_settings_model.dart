import 'package:flutter/material.dart';

class StationSettings {
  String stationId;
  
  // Operating Hours
  Map<String, OperatingHours> operatingHours;
  
  // Fuel Settings
  List<FuelTypeConfig> fuelTypes;
  
  // Tax Settings
  TaxSettings taxSettings;
  
  // Receipt Settings
  ReceiptSettings receiptSettings;
  
  // General Settings
  String currency;
  String timezone;
  int lowFuelThreshold;
  bool autoBackup;
  String? backupEmail;

  StationSettings({
    required this.stationId,
    required this.operatingHours,
    required this.fuelTypes,
    required this.taxSettings,
    required this.receiptSettings,
    this.currency = 'KES',
    this.timezone = 'Africa/Nairobi',
    this.lowFuelThreshold = 15,
    this.autoBackup = false,
    this.backupEmail,
  });

  Map<String, dynamic> toJson() => {
    'stationId': stationId,
    'operatingHours': operatingHours.map((k, v) => MapEntry(k, v.toJson())),
    'fuelTypes': fuelTypes.map((f) => f.toJson()).toList(),
    'taxSettings': taxSettings.toJson(),
    'receiptSettings': receiptSettings.toJson(),
    'currency': currency,
    'timezone': timezone,
    'lowFuelThreshold': lowFuelThreshold,
    'autoBackup': autoBackup,
    'backupEmail': backupEmail,
  };

  factory StationSettings.fromJson(Map<String, dynamic> json) {
    return StationSettings(
      stationId: json['stationId'],
      operatingHours: (json['operatingHours'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, OperatingHours.fromJson(v)),
      ),
      fuelTypes: (json['fuelTypes'] as List)
          .map((f) => FuelTypeConfig.fromJson(f))
          .toList(),
      taxSettings: TaxSettings.fromJson(json['taxSettings']),
      receiptSettings: ReceiptSettings.fromJson(json['receiptSettings']),
      currency: json['currency'],
      timezone: json['timezone'],
      lowFuelThreshold: json['lowFuelThreshold'],
      autoBackup: json['autoBackup'],
      backupEmail: json['backupEmail'],
    );
  }
}

class OperatingHours {
  final String day;
  TimeOfDay openTime;
  TimeOfDay closeTime;
  bool isClosed;
  bool is24Hours;

  OperatingHours({
    required this.day,
    required this.openTime,
    required this.closeTime,
    this.isClosed = false,
    this.is24Hours = false,
  });

  String get formattedHours {
    if (isClosed) return 'Closed';
    if (is24Hours) return '24 Hours';
    return '${_formatTime(openTime)} - ${_formatTime(closeTime)}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Map<String, dynamic> toJson() => {
    'day': day,
    'openHour': openTime.hour,
    'openMinute': openTime.minute,
    'closeHour': closeTime.hour,
    'closeMinute': closeTime.minute,
    'isClosed': isClosed,
    'is24Hours': is24Hours,
  };

  factory OperatingHours.fromJson(Map<String, dynamic> json) {
    return OperatingHours(
      day: json['day'],
      openTime: TimeOfDay(hour: json['openHour'], minute: json['openMinute']),
      closeTime: TimeOfDay(hour: json['closeHour'], minute: json['closeMinute']),
      isClosed: json['isClosed'],
      is24Hours: json['is24Hours'],
    );
  }
}

class FuelTypeConfig {
  final String id;
  final String name;
  double price;
  bool isAvailable;
  final String unit;

  FuelTypeConfig({
    required this.id,
    required this.name,
    required this.price,
    this.isAvailable = true,
    this.unit = 'Liters',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'isAvailable': isAvailable,
    'unit': unit,
  };

  factory FuelTypeConfig.fromJson(Map<String, dynamic> json) {
    return FuelTypeConfig(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      isAvailable: json['isAvailable'],
      unit: json['unit'],
    );
  }
}

class TaxSettings {
  double vatRate;
  bool vatEnabled;
  double withholdingTaxRate;
  bool withholdingTaxEnabled;
  double otherTaxRate;
  String otherTaxName;
  bool taxInclusivePricing;

  TaxSettings({
    this.vatRate = 16.0,
    this.vatEnabled = true,
    this.withholdingTaxRate = 5.0,
    this.withholdingTaxEnabled = false,
    this.otherTaxRate = 0.0,
    this.otherTaxName = 'Other Tax',
    this.taxInclusivePricing = true,
  });

  Map<String, dynamic> toJson() => {
    'vatRate': vatRate,
    'vatEnabled': vatEnabled,
    'withholdingTaxRate': withholdingTaxRate,
    'withholdingTaxEnabled': withholdingTaxEnabled,
    'otherTaxRate': otherTaxRate,
    'otherTaxName': otherTaxName,
    'taxInclusivePricing': taxInclusivePricing,
  };

  factory TaxSettings.fromJson(Map<String, dynamic> json) {
    return TaxSettings(
      vatRate: json['vatRate'],
      vatEnabled: json['vatEnabled'],
      withholdingTaxRate: json['withholdingTaxRate'],
      withholdingTaxEnabled: json['withholdingTaxEnabled'],
      otherTaxRate: json['otherTaxRate'],
      otherTaxName: json['otherTaxName'],
      taxInclusivePricing: json['taxInclusivePricing'],
    );
  }
}

class ReceiptSettings {
  String footerMessage;
  bool showVat;
  bool showWithholdingTax;
  bool showCustomerDetails;
  bool showLoyaltyPoints;
  bool digitalReceiptEnabled;
  String? digitalReceiptMessage;

  ReceiptSettings({
    this.footerMessage = 'Thank you for fueling with us!',
    this.showVat = true,
    this.showWithholdingTax = false,
    this.showCustomerDetails = true,
    this.showLoyaltyPoints = true,
    this.digitalReceiptEnabled = false,
    this.digitalReceiptMessage,
  });

  Map<String, dynamic> toJson() => {
    'footerMessage': footerMessage,
    'showVat': showVat,
    'showWithholdingTax': showWithholdingTax,
    'showCustomerDetails': showCustomerDetails,
    'showLoyaltyPoints': showLoyaltyPoints,
    'digitalReceiptEnabled': digitalReceiptEnabled,
    'digitalReceiptMessage': digitalReceiptMessage,
  };

  factory ReceiptSettings.fromJson(Map<String, dynamic> json) {
    return ReceiptSettings(
      footerMessage: json['footerMessage'],
      showVat: json['showVat'],
      showWithholdingTax: json['showWithholdingTax'],
      showCustomerDetails: json['showCustomerDetails'],
      showLoyaltyPoints: json['showLoyaltyPoints'],
      digitalReceiptEnabled: json['digitalReceiptEnabled'],
      digitalReceiptMessage: json['digitalReceiptMessage'],
    );
  }
}