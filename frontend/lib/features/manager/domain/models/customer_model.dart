// lib/features/manager/domain/models/customer_model.dart

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
  DateTime lastPurchaseDate;
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
    required this.lastPurchaseDate,
    this.totalTransactions = 0,
    this.vehicleNumber,
    this.preferredFuel,
    this.notes,
    this.tier = CustomerTier.bronze,
  });

  bool get isHighValueCustomer => totalSpent >= 50000;
  bool get isRecentCustomer => lastPurchaseDate.isAfter(DateTime.now().subtract(const Duration(days: 30)));
  String get customerSince => _formatDate(joinDate);
  String get lastPurchaseFormatted => _formatDate(lastPurchaseDate);

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
  
  // Calculate tier based on total spent
  void updateTier() {
    if (totalSpent >= 100000) {
      tier = CustomerTier.platinum;
    } else if (totalSpent >= 50000) {
      tier = CustomerTier.gold;
    } else if (totalSpent >= 20000) {
      tier = CustomerTier.silver;
    } else {
      tier = CustomerTier.bronze;
    }
  }

  // Convert to JSON for API requests
  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'email': email,
    'vehicle_number': vehicleNumber,
    'preferred_fuel': preferredFuel,
  };

  // Create from backend JSON response
  factory Customer.fromBackendJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'].toString(),
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      joinDate: DateTime.parse(json['created_at']),
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0,
      totalLiters: (json['total_liters'] as num?)?.toDouble() ?? 0,
      pointsBalance: json['points_balance'] ?? 0,
      pointsEarned: json['points_earned'] ?? 0,
      pointsRedeemed: json['points_redeemed'] ?? 0,
      lastPurchaseDate: json['last_purchase_date'] != null 
          ? DateTime.parse(json['last_purchase_date']) 
          : DateTime.now(),
      totalTransactions: json['total_transactions'] ?? 0,
      vehicleNumber: json['vehicle_number'],
      preferredFuel: json['preferred_fuel'],
      notes: json['notes'],
    );
  }
}