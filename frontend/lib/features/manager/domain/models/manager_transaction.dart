// lib/features/manager/domain/models/manager_transaction.dart

class ManagerTransaction {
  final String id;
  final DateTime time;
  final String pump;
  final String attendant;
  final double amount;
  final String type; // 'mpesa', 'cash', 'card'
  final String status; // 'completed', 'pending', 'failed'

  ManagerTransaction({
    required this.id,
    required this.time,
    required this.pump,
    required this.attendant,
    required this.amount,
    required this.type,
    required this.status,
  });
  
  // Create from backend JSON response
  factory ManagerTransaction.fromBackendJson(Map<String, dynamic> json) {
    return ManagerTransaction(
      id: json['transaction_id'] ?? json['id'].toString(),
      time: DateTime.parse(json['created_at']),
      pump: json['pump_number'] ?? 'Pump ${json['pump_id']}',
      attendant: json['attendant_name'] ?? 'Attendant ${json['attendant_id']}',
      amount: (json['amount'] as num).toDouble(),
      type: json['payment_type'],
      status: json['status'],
    );
  }
  
  String get formattedAmount => 'KES ${amount.toStringAsFixed(2)}';
  String get formattedTime => '${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  
  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';
  
  bool get isCash => type == 'cash';
  bool get isCard => type == 'card';
  bool get isMpesa => type == 'mpesa';
}