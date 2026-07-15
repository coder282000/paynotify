// lib/features/manager/domain/models/customer_model.dart

import 'package:flutter/material.dart';
import 'customer_tier.dart';

class Customer {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final DateTime joinDate;
  double totalSpent;
  double totalLiters;
  int pointsBalance;
  int pointsEarned;
  int pointsRedeemed;
  DateTime? lastPurchaseDate;
  int totalTransactions;
  final String? vehicleNumber;
  final String? preferredFuel;
  final String? notes;
  CustomerTier tier;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.joinDate,
    this.totalSpent = 0,
    this.totalLiters = 0,
    this.pointsBalance = 0,
    this.pointsEarned = 0,
    this.pointsRedeemed = 0,
    this.lastPurchaseDate,
    this.totalTransactions = 0,
    this.vehicleNumber,
    this.preferredFuel,
    this.notes,
    this.tier = CustomerTier.bronze,
  });

  // ── Computed Properties ──
  bool get isHighValueCustomer => totalSpent >= 50000;

  bool get isRecentCustomer => lastPurchaseDate != null &&
      lastPurchaseDate!.isAfter(DateTime.now().subtract(const Duration(days: 30)));

  String get customerSince => _formatDate(joinDate);

  String get lastPurchaseFormatted => lastPurchaseDate != null
      ? _formatDate(lastPurchaseDate!)
      : 'Never';

  String get tierDisplayName => tier.displayName;
  String get tierEmoji => tier.emoji;
  Color get tierColor => tier.color;
  Color get tierBackgroundColor => tier.backgroundColor;
  String get tierDescription => tier.description;
  double get tierProgress => tier.progressToNextTier(totalSpent);
  String get nextTierName => tier.nextTierName;
  int get nextTierThreshold => tier.nextTierThreshold;
  bool get isMaxTier => tier.isMaxTier;

  // ── Tier Calculation (mirrors server-side computeTier in customerController.js) ──
  static CustomerTier computeTier(double totalSpent) {
    return CustomerTierHelpers.fromSpent(totalSpent);
  }

  void updateTier() {
    tier = computeTier(totalSpent);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()} weeks ago';
    if (difference.inDays < 365) return '${(difference.inDays / 30).floor()} months ago';
    return '${(difference.inDays / 365).floor()} years ago';
  }

  // ── Convert to JSON for API Requests ──
  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'email': email,
    'vehicle_number': vehicleNumber,
    'preferred_fuel': preferredFuel,
    'notes': notes,
  };

  // Kept as an alias for clarity at call sites (PUT vs POST); identical
  // payload shape today since the backend's updateCustomer accepts the
  // same fields as createCustomer.
  Map<String, dynamic> toUpdateJson() => toJson();

  // ── Create from Backend JSON Response ──
  //
  // IMPORTANT: total_spent and total_liters are NUMERIC/DECIMAL columns
  // in Postgres. The node-postgres driver serializes these as STRINGS
  // (e.g. "3500.00"), not JSON numbers — unlike points_balance /
  // points_earned / points_redeemed / total_transactions, which are
  // INTEGER columns and DO arrive as real numbers. A plain `as num?`
  // cast on a string throws at runtime; _toDouble() below safely
  // handles both cases (and int, for good measure).
  factory Customer.fromBackendJson(Map<String, dynamic> json) {
    final customer = Customer(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      joinDate: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      totalSpent: _toDouble(json['total_spent']),
      totalLiters: _toDouble(json['total_liters']),
      pointsBalance: _toInt(json['points_balance']),
      pointsEarned: _toInt(json['points_earned']),
      pointsRedeemed: _toInt(json['points_redeemed']),
      lastPurchaseDate: json['last_purchase_date'] != null
          ? DateTime.tryParse(json['last_purchase_date'].toString())
          : null,
      totalTransactions: _toInt(json['total_transactions']),
      vehicleNumber: json['vehicle_number'],
      preferredFuel: json['preferred_fuel'],
      notes: json['notes'],
    );

    if (json['tier'] != null) {
      customer.tier = CustomerTierHelpers.fromString(json['tier'].toString());
    } else {
      customer.updateTier();
    }

    return customer;
  }

  // ── Copy With ──
  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    DateTime? joinDate,
    double? totalSpent,
    double? totalLiters,
    int? pointsBalance,
    int? pointsEarned,
    int? pointsRedeemed,
    DateTime? lastPurchaseDate,
    int? totalTransactions,
    String? vehicleNumber,
    String? preferredFuel,
    String? notes,
    CustomerTier? tier,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      joinDate: joinDate ?? this.joinDate,
      totalSpent: totalSpent ?? this.totalSpent,
      totalLiters: totalLiters ?? this.totalLiters,
      pointsBalance: pointsBalance ?? this.pointsBalance,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      pointsRedeemed: pointsRedeemed ?? this.pointsRedeemed,
      lastPurchaseDate: lastPurchaseDate ?? this.lastPurchaseDate,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      preferredFuel: preferredFuel ?? this.preferredFuel,
      notes: notes ?? this.notes,
      tier: tier ?? this.tier,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Customer &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, phone: $phone, tier: ${tier.displayName})';
  }

  // ── Safe numeric parsing helpers ──
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}