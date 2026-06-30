// lib/features/owner/presentation/screens/subscription_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/subscription_model.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  List<Subscription> _subscriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    
    _subscriptions = [
      Subscription(
        id: '1', stationId: '1', stationName: 'Westlands Main Station',
        tier: 'premium', price: 15000, status: 'active',
        startDate: DateTime.now().subtract(const Duration(days: 180)),
        expiryDate: DateTime.now().add(const Duration(days: 180)),
        features: ['Multi-station', 'Advanced Analytics', 'Priority Support', 'Unlimited Staff'],
      ),
      Subscription(
        id: '2', stationId: '2', stationName: 'Mombasa Beach Road',
        tier: 'premium', price: 15000, status: 'active',
        startDate: DateTime.now().subtract(const Duration(days: 150)),
        expiryDate: DateTime.now().add(const Duration(days: 150)),
        features: ['Multi-station', 'Advanced Analytics', 'Priority Support', 'Unlimited Staff'],
      ),
      Subscription(
        id: '3', stationId: '3', stationName: 'Kisumu Lakeside',
        tier: 'basic', price: 5000, status: 'active',
        startDate: DateTime.now().subtract(const Duration(days: 90)),
        expiryDate: DateTime.now().add(const Duration(days: 30)),
        features: ['Single Station', 'Basic Analytics', 'Email Support', 'Up to 5 Staff'],
      ),
    ];
    
    _isLoading = false;
    setState(() {});
  }

  double get _totalMonthlyRevenue => _subscriptions.fold(0.0, (sum, s) => sum + s.price);

  // Helper method to convert tier color value to actual Color
  Color _getTierColor(String colorValue) {
    switch (colorValue) {
      case 'green': return Colors.green;
      case 'purple': return Colors.purple;
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Management'),
        backgroundColor: const Color(0xFF0B3D2E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSubscriptions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Revenue Card
                  Card(
                    color: const Color(0xFF0B3D2E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'Monthly Recurring Revenue',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'KES ${NumberFormat('#,##0').format(_totalMonthlyRevenue)}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'From ${_subscriptions.length} stations',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Subscription Plans
                  const Text(
                    'Available Plans',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildPlanCard(
                    name: 'Basic',
                    price: 'KES 5,000/month',
                    description: 'For single station owners',
                    color: Colors.blue,
                    features: ['Single Station', 'Basic Analytics', 'Email Support', 'Up to 5 Staff'],
                  ),
                  const SizedBox(height: 12),
                  _buildPlanCard(
                    name: 'Premium',
                    price: 'KES 15,000/month',
                    description: 'For growing businesses',
                    color: Colors.green,
                    features: ['Multi-station', 'Advanced Analytics', 'Priority Support', 'Unlimited Staff', 'API Access'],
                  ),
                  const SizedBox(height: 12),
                  _buildPlanCard(
                    name: 'Enterprise',
                    price: 'Custom Pricing',
                    description: 'For large chains',
                    color: Colors.purple,
                    features: [
                      'Unlimited Stations',
                      'Custom Analytics',
                      '24/7 Support',
                      'Dedicated Account Manager',
                      'Custom Integration',
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Current Subscriptions
                  const Text(
                    'Current Subscriptions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ..._subscriptions.map((sub) => _buildSubscriptionCard(sub)),
                ],
              ),
            ),
    );
  }

  Widget _buildPlanCard({
    required String name,
    required String price,
    required String description,
    required Color color,
    required List<String> features,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    name == 'Enterprise' ? Icons.star : Icons.rocket,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        price,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: color),
                  ),
                  child: const Text('Upgrade'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: features.map((feature) {
                return Chip(
                  label: Text(
                    feature,
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: color.withValues(alpha: 0.1),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(Subscription subscription) {
    
    final isExpiringSoon = subscription.isExpiringSoon;
    final tierColor = _getTierColor(subscription.tierColorValue);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: tierColor.withValues(alpha: 0.1),
          child: Text(
            subscription.tier[0].toUpperCase(),
            style: TextStyle(color: tierColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(subscription.stationName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${subscription.tierDisplay} - ${subscription.formattedPrice}/month'),
            Text(
              'Expires: ${subscription.formattedExpiryDate} (${subscription.daysRemainingText})',
              style: TextStyle(
                color: isExpiringSoon ? Colors.red : Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: subscription.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            subscription.status.toUpperCase(),
            style: TextStyle(
              color: subscription.isActive ? Colors.green : Colors.red,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () {},
      ),
    );
  }
}