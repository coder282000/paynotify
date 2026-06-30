class Station {
  final String id;
  final String name;
  final String registrationNumber;
  final String phone;
  final String? email;
  final String address;
  final String? city;
  final String? county;
  final String? postalCode;
  final String? logoUrl;
  final DateTime createdAt;
  DateTime updatedAt;

  Station({
    required this.id,
    required this.name,
    required this.registrationNumber,
    required this.phone,
    this.email,
    required this.address,
    this.city,
    this.county,
    this.postalCode,
    this.logoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'registrationNumber': registrationNumber,
    'phone': phone,
    'email': email,
    'address': address,
    'city': city,
    'county': county,
    'postalCode': postalCode,
    'logoUrl': logoUrl,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'],
      name: json['name'],
      registrationNumber: json['registrationNumber'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      city: json['city'],
      county: json['county'],
      postalCode: json['postalCode'],
      logoUrl: json['logoUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}