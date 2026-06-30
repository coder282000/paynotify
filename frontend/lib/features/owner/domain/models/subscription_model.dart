// lib/features/owner/domain/models/subscription_model.dart

class Subscription {
  final String id;
  final String stationId;
  final String stationName;
  final String tier;
  final double price;
  final String status;
  final DateTime startDate;
  final DateTime expiryDate;
  final List<String> features;

  Subscription({
    required this.id,
    required this.stationId,
    required this.stationName,
    required this.tier,
    required this.price,
    required this.status,
    required this.startDate,
    required this.expiryDate,
    required this.features,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'].toString(),
      stationId: json['station_id'].toString(),
      stationName: json['station_name'],
      tier: json['tier'],
      price: (json['price'] as num).toDouble(),
      status: json['status'],
      startDate: DateTime.parse(json['start_date']),
      expiryDate: DateTime.parse(json['expiry_date']),
      features: List<String>.from(json['features'] ?? []),
    );
  }

  // Computed properties (no Flutter UI dependencies)
  bool get isActive => status == 'active';
  bool get isPremium => tier == 'premium';
  bool get isEnterprise => tier == 'enterprise';
  
  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;
  bool get isExpiringSoon => daysUntilExpiry < 30 && daysUntilExpiry > 0;
  bool get isExpired => daysUntilExpiry <= 0;
  
  String get tierDisplay => tier.toUpperCase();
  
  String get tierColorValue {
    switch (tier) {
      case 'enterprise': return 'purple';
      case 'premium': return 'green';
      default: return 'blue';
    }
  }
  
  String get formattedPrice => 'KES ${price.toStringAsFixed(0)}';
  String get formattedExpiryDate => '${expiryDate.day}/${expiryDate.month}/${expiryDate.year}';
  String get daysRemainingText => '$daysUntilExpiry days left';
}