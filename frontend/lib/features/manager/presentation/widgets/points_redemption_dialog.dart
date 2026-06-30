import 'package:flutter/material.dart';
import '../../domain/models/customer_model.dart';

class PointsRedemptionDialog extends StatefulWidget {
  final Customer customer;
  final String currentUserId;
  final String currentUserName;
  final Function(int points, double value, String? notes) onRedeem;

  const PointsRedemptionDialog({
    super.key,
    required this.customer,
    required this.currentUserId,
    required this.currentUserName,
    required this.onRedeem,
  });

  @override
  State<PointsRedemptionDialog> createState() => _PointsRedemptionDialogState();
}

class _PointsRedemptionDialogState extends State<PointsRedemptionDialog> {
  int _points = 0;
  String? _notes;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.card_giftcard,
                      color: Color(0xFF2ECC71),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Redeem Points',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text(
                'Customer: ${widget.customer.name}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Available Points: ${widget.customer.pointsBalance} (KES ${widget.customer.pointsBalance})',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Points to Redeem',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  prefixIcon: Icon(Icons.star_outline),  // Changed from Icons.points
                  hintText: 'Enter points (1 point = KES 1)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter points';
                  }
                  final points = int.tryParse(value);
                  if (points == null || points <= 0) {
                    return 'Please enter a valid number';
                  }
                  if (points > widget.customer.pointsBalance) {
                    return 'Points cannot exceed available balance';
                  }
                  return null;
                },
                onChanged: (value) {
                  _points = int.tryParse(value) ?? 0;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  prefixIcon: Icon(Icons.note_outlined),
                  hintText: 'Reason for redemption...',
                ),
                onChanged: (value) {
                  _notes = value;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF0B3D2E)),
                      ),
                      child: const Text('CANCEL'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.pop(context);
                          widget.onRedeem(
                            _points,
                            _points.toDouble(),
                            _notes,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ECC71),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'REDEEM',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}