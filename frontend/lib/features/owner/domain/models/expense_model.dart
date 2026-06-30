// lib/features/owner/domain/models/expense_model.dart

class OwnerExpense {
  final String id;
  final String stationId;
  final String stationName;
  final String category;
  final double amount;
  final String description;
  final DateTime date;
  final String? vendorName;
  final String? paymentMethod;
  final String? referenceNumber;

  OwnerExpense({
    required this.id,
    required this.stationId,
    required this.stationName,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
    this.vendorName,
    this.paymentMethod,
    this.referenceNumber,
  });

  factory OwnerExpense.fromJson(Map<String, dynamic> json) {
    return OwnerExpense(
      id: json['id'].toString(),
      stationId: json['station_id'].toString(),
      stationName: json['station_name'],
      category: json['category'],
      amount: (json['amount'] as num).toDouble(),
      description: json['description'],
      date: DateTime.parse(json['date']),
      vendorName: json['vendor_name'],
      paymentMethod: json['payment_method'],
      referenceNumber: json['reference_number'],
    );
  }

  // Computed properties (no Flutter UI dependencies)
  String get categoryDisplay {
    switch (category) {
      case 'fuelPurchase': return 'Fuel Purchase';
      case 'salary': return 'Salary';
      case 'maintenance': return 'Maintenance';
      case 'utilities': return 'Utilities';
      case 'rent': return 'Rent';
      case 'supplies': return 'Supplies';
      case 'marketing': return 'Marketing';
      case 'insurance': return 'Insurance';
      default: return category;
    }
  }
  
  String get categoryColorValue {
    switch (category) {
      case 'fuelPurchase': return 'orange';
      case 'salary': return 'purple';
      case 'maintenance': return 'red';
      case 'utilities': return 'blue';
      case 'rent': return 'teal';
      case 'supplies': return 'brown';
      case 'marketing': return 'pink';
      case 'insurance': return 'indigo';
      default: return 'grey';
    }
  }
  
  String get categoryIconName {
    switch (category) {
      case 'fuelPurchase': return 'local_gas_station';
      case 'salary': return 'people';
      case 'maintenance': return 'build';
      case 'utilities': return 'electric_bolt';
      case 'rent': return 'home';
      case 'supplies': return 'inventory';
      case 'marketing': return 'campaign';
      case 'insurance': return 'security';
      default: return 'receipt';
    }
  }

  String get formattedAmount => 'KES ${amount.toStringAsFixed(2)}';
  String get formattedDate => '${date.day}/${date.month}/${date.year}';
}