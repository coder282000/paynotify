import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/customer_model.dart';
import '../../domain/models/customer_transaction.dart';
import '../../domain/models/points_redemption.dart';

class CustomerDetailDialog extends StatelessWidget {
  final Customer customer;
  final List<CustomerTransaction> transactions;
  final List<PointsRedemption> redemptions;
  final bool canRedeemPoints;
  final VoidCallback onRedeemPoints;

  const CustomerDetailDialog({
    super.key,
    required this.customer,
    required this.transactions,
    required this.redemptions,
    required this.canRedeemPoints,
    required this.onRedeemPoints,
  });

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with Gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    customer.tier.color,
                    customer.tier.color.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          customer.tier.icon,
                          color: customer.tier.color,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              customer.tier.displayName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.9),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          customer.phone,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: customer.tier.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Total Spent',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'KES ${NumberFormat('#,###').format(customer.totalSpent)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 30,
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Points Balance',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${customer.pointsBalance} pts',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 30,
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Total Liters',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${customer.totalLiters.toStringAsFixed(0)} L',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoSection('Contact Information', [
                      _buildInfoRow('Phone', customer.phone, Icons.phone_outlined),
                      if (customer.email != null)
                        _buildInfoRow('Email', customer.email!, Icons.email_outlined),
                      if (customer.vehicleNumber != null)
                        _buildInfoRow('Vehicle', customer.vehicleNumber!, Icons.directions_car_outlined),
                      if (customer.preferredFuel != null)
                        _buildInfoRow('Preferred Fuel', customer.preferredFuel!, Icons.local_gas_station_outlined),
                    ]),
                    
                    const SizedBox(height: 16),
                    
                    _buildInfoSection('Loyalty Points', [
                      _buildInfoRow(
                        'Points Earned',
                        '${customer.pointsEarned} pts',
                        Icons.card_giftcard_outlined,
                        valueColor: const Color(0xFF2ECC71),
                      ),
                      _buildInfoRow(
                        'Points Redeemed',
                        '${customer.pointsRedeemed} pts',
                        Icons.card_giftcard,
                        valueColor: const Color(0xFFF39C12),
                      ),
                      _buildInfoRow(
                        'Points Balance',
                        '${customer.pointsBalance} pts (KES ${customer.pointsBalance})',
                        Icons.account_balance_wallet_outlined,
                        valueColor: const Color(0xFF0B3D2E),
                      ),
                    ]),
                    
                    const SizedBox(height: 16),
                    
                    _buildInfoSection('Statistics', [
                      _buildInfoRow('Total Transactions', '${customer.totalTransactions}', Icons.receipt_outlined),
                      _buildInfoRow('Customer Since', DateFormat('dd MMM yyyy').format(customer.joinDate), Icons.calendar_today_outlined),
                      _buildInfoRow('Last Purchase', DateFormat('dd MMM yyyy').format(customer.lastPurchaseDate), Icons.access_time_outlined),
                    ]),
                    
                    if (customer.notes != null) ...[
                      const SizedBox(height: 16),
                      _buildInfoSection('Notes', [
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            customer.notes!,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ),
                      ]),
                    ],
                    
                    // Transaction History
                    if (transactions.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildInfoSection('Transaction History', [
                        ...transactions.map((transaction) {
                          return ListTile(
                            leading: Icon(
                              transaction.type.icon,
                              color: transaction.type.color,
                            ),
                            title: Text(transaction.formattedAmount),
                            subtitle: Text('${transaction.formattedLiters} - ${transaction.attendantName}'),
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  transaction.formattedPoints,
                                  style: TextStyle(
                                    color: transaction.type == TransactionType.fuelPurchase
                                        ? const Color(0xFF2ECC71)
                                        : const Color(0xFFF39C12),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  transaction.formattedDate,
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          );
                        }),
                      ]),
                    ],
                    
                    // Redemption History
                    if (redemptions.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildInfoSection('Redemption History', [
                        ...redemptions.map((redemption) {
                          return ListTile(
                            leading: const Icon(Icons.card_giftcard, color: Color(0xFF2ECC71)),
                            title: Text(redemption.formattedPoints),
                            subtitle: Text(redemption.formattedDate),
                            trailing: Text(
                              redemption.formattedValue,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        }),
                      ]),
                    ],
                  ],
                ),
              ),
            ),
            
            // Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF0B3D2E)),
                      ),
                      child: const Text('CLOSE'),
                    ),
                  ),
                  if (canRedeemPoints && customer.pointsBalance > 0) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onRedeemPoints,
                        icon: const Icon(Icons.card_giftcard),
                        label: const Text('REDEEM POINTS'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2ECC71),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}