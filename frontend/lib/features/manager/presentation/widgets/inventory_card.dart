// lib/features/manager/presentation/widgets/inventory_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/inventory_model.dart';
import 'fuel_level_indicator.dart';

class InventoryCard extends StatelessWidget {
  final FuelTank tank;
  final VoidCallback onTap;
  final VoidCallback? onRecordDelivery;
  final VoidCallback? onViewHistory;

  const InventoryCard({
    super.key,
    required this.tank,
    required this.onTap,
    this.onRecordDelivery,
    this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    final status = tank.stockStatus;
    final daysRemaining = tank.estimatedDaysRemaining;
    
    return Semantics(
      button: true,
      label: '${tank.name}, ${tank.fuelType.displayName}, ${status.displayName} at ${tank.levelPercentage.toStringAsFixed(1)}%',
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header Row
                Row(
                  children: [
                    // Fuel Type Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: tank.fuelType.color.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        tank.fuelType.icon,
                        color: tank.fuelType.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Tank Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  tank.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: status.color.withAlpha(26),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      status.icon,
                                      color: status.color,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      status.displayName,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: status.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tank.fuelType.displayName,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Fuel Level Indicator
                FuelLevelIndicator(
                  level: tank.currentLevel,
                  capacity: tank.capacity,
                  color: status.color,
                  height: 10,
                ),
                
                const SizedBox(height: 12),
                
                // Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatBox(
                        'Current',
                        '${tank.currentLevel.toStringAsFixed(0)} L',
                        Icons.local_gas_station,
                        status.color,
                      ),
                    ),
                    Expanded(
                      child: _buildStatBox(
                        'Capacity',
                        '${tank.capacity.toStringAsFixed(0)} L',
                        Icons.speed,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildStatBox(
                        'Est. Days',
                        daysRemaining > 0 
                            ? '${daysRemaining.toStringAsFixed(0)}d'
                            : 'N/A',
                        Icons.timer_outlined,
                        daysRemaining < 3 ? Colors.orange : Colors.grey,
                      ),
                    ),
                  ],
                ),
                
                if (tank.needsReorder) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: status.color.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: status.color.withAlpha(77)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: status.color,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Reorder recommended - below ${tank.minThreshold.toStringAsFixed(0)}% threshold',
                            style: TextStyle(
                              fontSize: 12,
                              color: status.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                if (tank.lastDeliveryDate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Last: ${DateFormat('dd MMM yyyy').format(tank.lastDeliveryDate!)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 12),
                
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onViewHistory != null)
                      TextButton.icon(
                        onPressed: onViewHistory,
                        icon: const Icon(Icons.history, size: 16),
                        label: const Text('History'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                        ),
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: onRecordDelivery ?? onTap,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Record Delivery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B3D2E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}