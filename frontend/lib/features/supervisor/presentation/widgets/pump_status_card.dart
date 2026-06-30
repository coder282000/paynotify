// lib/features/supervisor/presentation/widgets/pump_status_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/override_pump.dart';

class PumpStatusCard extends StatelessWidget {
  final OverridePump pump;
  final VoidCallback? onOverride;
  final VoidCallback? onEmergencyStop;

  const PumpStatusCard({
    super.key,
    required this.pump,
    this.onOverride,
    this.onEmergencyStop,
  });

  String _formatCurrency(double amount) {
    return 'KES ${NumberFormat('#,##0').format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    final isEmergency = pump.status == PumpStatus.emergency;
    final isMaintenance = pump.status == PumpStatus.maintenance;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isEmergency
            ? const BorderSide(color: Color(0xFFE74C3C), width: 2)
            : (pump.needsAttention
                ? const BorderSide(color: Color(0xFFF39C12), width: 1)
                : BorderSide.none),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isEmergency
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFE74C3C).withAlpha(26),
                    Colors.white,
                  ],
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header Row
              Row(
                children: [
                  // Pump Icon with Status Indicator
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: pump.fuelType.color.withAlpha(26),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          pump.fuelType.icon,
                          color: pump.fuelType.color,
                          size: 28,
                        ),
                      ),
                      if (pump.status == PumpStatus.active)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      if (isEmergency)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE74C3C),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Pump Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              pump.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: pump.status.color.withAlpha(26),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    pump.status.icon,
                                    size: 12,
                                    color: pump.status.color,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    pump.status.displayName,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: pump.status.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pump.fuelType.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (pump.attendantName != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 12,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                pump.attendantName!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatCurrency(pump.pricePerLiter),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: pump.fuelType.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '/liter',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Fuel Level Indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Fuel Level',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '${pump.fuelPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: pump.fuelLevelColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pump.fuelPercentage / 100,
                      backgroundColor: pump.fuelLevelColor.withAlpha(51),
                      valueColor: AlwaysStoppedAnimation<Color>(pump.fuelLevelColor),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pump.currentFuelLevel.toStringAsFixed(0)} / ${pump.tankCapacity.toStringAsFixed(0)} L',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Today's Sales
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71).withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Today\'s Sales',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      _formatCurrency(pump.todaySales),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2ECC71),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Alert Message (if any)
              if (pump.needsAttention && pump.alertMessage != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF39C12).withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        size: 16,
                        color: const Color(0xFFF39C12),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pump.alertMessage!,
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFFF39C12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              // Action Buttons
              Row(
                children: [
                  if (onOverride != null && !isMaintenance)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onOverride,
                        icon: const Icon(Icons.payment, size: 18),
                        label: const Text('Override'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: pump.fuelType.color,
                          side: BorderSide(color: pump.fuelType.color),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  if (onOverride != null && !isMaintenance)
                    const SizedBox(width: 8),
                  if (onEmergencyStop != null && !isMaintenance)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onEmergencyStop,
                        icon: const Icon(Icons.warning, size: 18),
                        label: Text(isEmergency ? 'Resolve' : 'Emergency'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isEmergency
                              ? const Color(0xFF2ECC71)
                              : const Color(0xFFE74C3C),
                          padding: const EdgeInsets.symmetric(vertical: 10),
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