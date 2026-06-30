import 'package:flutter/material.dart';
import '../../domain/models/station_settings_model.dart';

class FuelTypeCard extends StatelessWidget {
  final FuelTypeConfig fuel;
  final VoidCallback onPriceEdit;
  final ValueChanged<bool> onAvailabilityChanged;

  const FuelTypeCard({
    super.key,
    required this.fuel,
    required this.onPriceEdit,
    required this.onAvailabilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B3D2E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_gas_station, color: Color(0xFF0B3D2E)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fuel.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Price per ${fuel.unit}', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'KES ${fuel.price.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B3D2E)),
                    ),
                    const SizedBox(height: 4),
                    Text('/${fuel.unit}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(width: 8),
                Switch(
                  value: fuel.isAvailable,
                  onChanged: onAvailabilityChanged,
                  activeThumbColor: const Color(0xFF2ECC71),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onPriceEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Price'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}