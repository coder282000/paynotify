// lib/features/owner/domain/models/station_model.dart

class Station {
  final int id;
  final String stationName;
  final String stationCode;
  final String? phone;
  final String? email;
  final String? physicalAddress; // maps from backend 'location'
  final String? locationLat;
  final String? locationLng;
  final bool isActive;
  final String subscriptionTier;
  final DateTime? subscriptionExpiry;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Extra fields the backend returns
  final String? city;
  final String? county;
  final String? paybillNumber;
  final String? tillNumber;
  final String? status;
  final int? totalPumps;
  final int? activePumps;
  final double? todaySales;

  Station({
    required this.id,
    required this.stationName,
    required this.stationCode,
    this.phone,
    this.email,
    this.physicalAddress,
    this.locationLat,
    this.locationLng,
    required this.isActive,
    required this.subscriptionTier,
    this.subscriptionExpiry,
    required this.createdAt,
    required this.updatedAt,
    this.city,
    this.county,
    this.paybillNumber,
    this.tillNumber,
    this.status,
    this.totalPumps,
    this.activePumps,
    this.todaySales,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      // Backend returns camelCase from getStations()
      id: _parseInt(json['id']),
      stationName: json['stationName'] ?? json['station_name'] ?? '',
      stationCode: json['stationCode'] ?? json['station_code'] ?? '',
      phone: json['phone'],
      email: json['email'],

      // Backend uses 'location' — we store it as physicalAddress
      physicalAddress: json['location'] ??
          json['physicalAddress'] ??
          json['physical_address'],

      locationLat: json['locationLat']?.toString() ??
          json['location_lat']?.toString(),
      locationLng: json['locationLng']?.toString() ??
          json['location_lng']?.toString(),

      isActive: json['isActive'] ?? json['is_active'] ?? true,

      // Backend doesn't return subscription_tier in list — default to basic
      subscriptionTier: json['subscriptionTier'] ??
          json['subscription_tier'] ??
          'basic',

      subscriptionExpiry: json['subscriptionExpiry'] != null
          ? DateTime.tryParse(json['subscriptionExpiry'].toString())
          : json['subscription_expiry'] != null
              ? DateTime.tryParse(json['subscription_expiry'].toString())
              : null,

      createdAt: DateTime.tryParse(
              (json['createdAt'] ?? json['created_at'] ?? '').toString()) ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(
              (json['updatedAt'] ?? json['updated_at'] ?? '').toString()) ??
          DateTime.now(),

      // Extra fields from list response
      city: json['city'],
      county: json['county'],
      paybillNumber: json['paybillNumber'] ?? json['paybill_number'],
      tillNumber: json['tillNumber'] ?? json['till_number'],
      status: json['status'],
      totalPumps: _parseInt(json['totalPumps'] ?? json['total_pumps']),
      activePumps: _parseInt(json['activePumps'] ?? json['active_pumps']),
      todaySales: _parseDouble(json['todaySales'] ?? json['today_sales']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'station_name': stationName,
      'station_code': stationCode,
      'location': physicalAddress,
      'phone': phone,
      'email': email,
      'city': city,
      'county': county,
      'paybill_number': paybillNumber,
      'till_number': tillNumber,
    };
  }

  // ── Helpers ──────────────────────────────────────────────────
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  bool get isPremium => subscriptionTier == 'premium';
  bool get isEnterprise => subscriptionTier == 'enterprise';
  bool get isSubscriptionActive =>
      subscriptionExpiry != null &&
      subscriptionExpiry!.isAfter(DateTime.now());
}