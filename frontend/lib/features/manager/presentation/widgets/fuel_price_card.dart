// lib/features/manager/presentation/widgets/fuel_price_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/pump_config.dart';

class FuelPriceCard extends StatelessWidget {
  final FuelType fuelType;
  final double currentPrice;
  final double? nextPrice;
  final DateTime? nextPriceDate;
  final double priceChange;
  final double percentageChange;
  final VoidCallback onEdit;
  final VoidCallback onViewHistory;

  const FuelPriceCard({
    super.key,
    required this.fuelType,
    required this.currentPrice,
    this.nextPrice,
    this.nextPriceDate,
    required this.priceChange,
    required this.percentageChange,
    required this.onEdit,
    required this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasScheduledChange = nextPrice != null && nextPriceDate != null;
    final bool isPriceIncrease = priceChange > 0;
    
    return Semantics(
      button: true,
      label: '${fuelType.displayName} price: KES ${currentPrice.toStringAsFixed(2)} per liter${hasScheduledChange ? ', scheduled change to KES ${nextPrice!.toStringAsFixed(2)} on ${DateFormat('dd MMM').format(nextPriceDate!)}' : ''}',
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                fuelType.color.withAlpha(26),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header with icon and fuel type
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: fuelType.color.withAlpha(26),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        fuelType.icon,
                        color: fuelType.color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fuelType.displayName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Price per liter',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isPriceIncrease ? Colors.red.withAlpha(26) : Colors.green.withAlpha(26),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isPriceIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isPriceIncrease ? Colors.red : Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${percentageChange.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: isPriceIncrease ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Current price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Current:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'KES ${currentPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: fuelType.color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '/L',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                
                if (hasScheduledChange) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scheduled Change',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Will change to KES ${nextPrice!.toStringAsFixed(2)} on ${DateFormat('dd MMM yyyy').format(nextPriceDate!)}',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 20),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: 'View price history for ${fuelType.displayName}',
                        child: OutlinedButton.icon(
                          onPressed: onViewHistory,
                          icon: const Icon(Icons.history, size: 18),
                          label: const Text('History'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: fuelType.color),
                            foregroundColor: fuelType.color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: 'Set new price for ${fuelType.displayName}',
                        child: ElevatedButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Set Price'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: fuelType.color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
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
}