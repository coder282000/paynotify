// lib/features/manager/presentation/screens/customer_insight_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../domain/models/customer_model.dart';
import '../../domain/models/customer_tier.dart';
import '../../domain/models/customer_transaction.dart';
import '../../domain/models/points_redemption.dart';
import '../widgets/customer_card.dart';
import '../widgets/customer_detail_dialog.dart';
import '../widgets/customer_search_bar.dart';
import '../widgets/points_redemption_dialog.dart';
import '../widgets/add_customer_dialog.dart';

// MARK: - Constants
class _CustomerConstants {
  static const Color primaryDark = Color(0xFF0B3D2E);
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color warningOrange = Color(0xFFF39C12);
  static const Color errorRed = Color(0xFFE74C3C);
  
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
}

class CustomerInsightScreen extends StatefulWidget {
  const CustomerInsightScreen({super.key});

  @override
  State<CustomerInsightScreen> createState() => _CustomerInsightScreenState();
}

class _CustomerInsightScreenState extends State<CustomerInsightScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  String _searchQuery = '';
  CustomerTier? _selectedTierFilter;
  bool _isLoading = false;
  String? _errorMessage;
  String _sortBy = 'totalSpent';
  final bool _sortAscending = false;
  
  // Data
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  List<PointsRedemption> _redemptions = [];
  
  // Mock current user (from auth provider in real app)
  final String _currentUserId = 'manager_1';
  final String _currentUserName = 'Manager';
  final bool _canRedeemPoints = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      await Future.delayed(_CustomerConstants.animationDuration);
      
      if (!mounted) return;
      
      _customers = _generateMockCustomers();
      _redemptions = _generateMockRedemptions();
      _applyFilters();
      
      setState(() => _isLoading = false);
      HapticFeedback.lightImpact();
      
    } catch (e, stackTrace) {
      if (!mounted) return;
      debugPrint('Load customers error: $e\n$stackTrace');
      setState(() {
        _errorMessage = _getErrorMessage(e);
        _isLoading = false;
      });
      _showErrorSnackBar();
    }
  }
  
  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('SocketException') || 
        error.toString().contains('NetworkIsUnreachable')) {
      return 'No internet connection. Please check your network.';
    }
    if (error.toString().contains('Unauthorized') || 
        error.toString().contains('401')) {
      return 'Session expired. Please log in again.';
    }
    return 'Failed to load customers. Please try again.';
  }
  
  void _showErrorSnackBar() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(_errorMessage ?? 'An error occurred')),
          ],
        ),
        backgroundColor: _CustomerConstants.errorRed,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _loadData,
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  List<Customer> _generateMockCustomers() {
    final now = DateTime.now();
    return [
      Customer(
        id: '1',
        name: 'John Mwangi',
        phone: '0712345678',
        email: 'john.mwangi@email.com',
        joinDate: now.subtract(const Duration(days: 365)),
        totalSpent: 125000,
        totalLiters: 1250,
        pointsBalance: 1250,
        pointsEarned: 1250,
        pointsRedeemed: 0,
        lastPurchaseDate: now.subtract(const Duration(days: 2)),
        totalTransactions: 25,
        vehicleNumber: 'KCA 123A',
        preferredFuel: 'Petrol',
        tier: CustomerTier.gold,
      ),
      Customer(
        id: '2',
        name: 'Sarah Wanjiku',
        phone: '0723456789',
        email: 'sarah.wanjiku@email.com',
        joinDate: now.subtract(const Duration(days: 180)),
        totalSpent: 75000,
        totalLiters: 750,
        pointsBalance: 750,
        pointsEarned: 750,
        pointsRedeemed: 0,
        lastPurchaseDate: now.subtract(const Duration(days: 5)),
        totalTransactions: 15,
        vehicleNumber: 'KCB 456B',
        preferredFuel: 'Diesel',
        tier: CustomerTier.silver,
      ),
      Customer(
        id: '3',
        name: 'Peter Odhiambo',
        phone: '0734567890',
        joinDate: now.subtract(const Duration(days: 90)),
        totalSpent: 35000,
        totalLiters: 350,
        pointsBalance: 350,
        pointsEarned: 350,
        pointsRedeemed: 0,
        lastPurchaseDate: now.subtract(const Duration(days: 10)),
        totalTransactions: 7,
        vehicleNumber: 'KCD 789C',
        preferredFuel: 'Petrol',
        tier: CustomerTier.bronze,
      ),
      Customer(
        id: '4',
        name: 'Grace Akinyi',
        phone: '0745678901',
        email: 'grace.akinyi@email.com',
        joinDate: now.subtract(const Duration(days: 540)),
        totalSpent: 250000,
        totalLiters: 2500,
        pointsBalance: 2300,
        pointsEarned: 2500,
        pointsRedeemed: 200,
        lastPurchaseDate: now.subtract(const Duration(days: 1)),
        totalTransactions: 50,
        vehicleNumber: 'KCE 012D',
        preferredFuel: 'Premium',
        notes: 'VIP customer',
        tier: CustomerTier.platinum,
      ),
      Customer(
        id: '5',
        name: 'James Kariuki',
        phone: '0756789012',
        joinDate: now.subtract(const Duration(days: 45)),
        totalSpent: 15000,
        totalLiters: 150,
        pointsBalance: 150,
        pointsEarned: 150,
        pointsRedeemed: 0,
        lastPurchaseDate: now.subtract(const Duration(days: 3)),
        totalTransactions: 3,
        vehicleNumber: 'KCF 345E',
        preferredFuel: 'Diesel',
        tier: CustomerTier.bronze,
      ),
    ];
  }

  List<PointsRedemption> _generateMockRedemptions() {
    final now = DateTime.now();
    return [
      PointsRedemption(
        id: 'r1',
        customerId: '4',
        customerName: 'Grace Akinyi',
        points: 200,
        valueKes: 200,
        date: now.subtract(const Duration(days: 15)),
        redeemedBy: 'manager_1',
        redeemedByName: 'Manager',
        status: RedemptionStatus.completed,
        notes: 'Redeemed for fuel discount',
      ),
    ];
  }

  List<CustomerTransaction> _generateCustomerTransactions(String customerId) {
    final now = DateTime.now();
    if (customerId == '4') {
      return [
        CustomerTransaction(
          id: 't1',
          customerId: customerId,
          amount: 5000,
          liters: 50,
          date: now.subtract(const Duration(days: 1)),
          pumpId: '1',
          attendantName: 'John M.',
          pointsEarned: 50,
          type: TransactionType.fuelPurchase,
        ),
        CustomerTransaction(
          id: 't2',
          customerId: customerId,
          amount: 10000,
          liters: 100,
          date: now.subtract(const Duration(days: 8)),
          pumpId: '2',
          attendantName: 'Sarah W.',
          pointsEarned: 100,
          type: TransactionType.fuelPurchase,
        ),
      ];
    }
    return [];
  }

  void _applyFilters() {
    setState(() {
      _filteredCustomers = _customers.where((customer) {
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final matches = customer.name.toLowerCase().contains(query) ||
              customer.phone.contains(query) ||
              (customer.email?.toLowerCase().contains(query) ?? false) ||
              (customer.vehicleNumber?.toLowerCase().contains(query) ?? false);
          if (!matches) return false;
        }
        
        if (_selectedTierFilter != null && customer.tier != _selectedTierFilter) {
          return false;
        }
        
        if (_tabController.index != 0) {
          switch (_tabController.index) {
            case 1:
              if (!customer.isHighValueCustomer) return false;
              break;
            case 2:
              if (!customer.isRecentCustomer) return false;
              break;
          }
        }
        
        return true;
      }).toList()..sort((a, b) {
        int comparison;
        switch (_sortBy) {
          case 'name':
            comparison = a.name.compareTo(b.name);
            break;
          case 'totalSpent':
            comparison = a.totalSpent.compareTo(b.totalSpent);
            break;
          case 'pointsBalance':
            comparison = a.pointsBalance.compareTo(b.pointsBalance);
            break;
          case 'lastPurchase':
            comparison = b.lastPurchaseDate.compareTo(a.lastPurchaseDate);
            break;
          default:
            comparison = 0;
        }
        return _sortAscending ? comparison : -comparison;
      });
    });
  }

  double get _totalRevenue {
    return _customers.fold(0, (sum, c) => sum + c.totalSpent);
  }

  int get _totalPointsBalance {
    return _customers.fold(0, (sum, c) => sum + c.pointsBalance);
  }

  int get _filteredCustomersLength => _filteredCustomers.length;

  bool get _showHighPointsWarning => _totalPointsBalance > 10000;

  Future<void> _processRedemption(Customer customer, int points, double value, String? notes) async {
    if (!mounted) return;
    
    try {
      setState(() {
        customer.pointsBalance -= points;
        customer.pointsRedeemed += points;
      });
      
      _redemptions.insert(0, PointsRedemption(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        customerId: customer.id,
        customerName: customer.name,
        points: points,
        valueKes: value,
        date: DateTime.now(),
        redeemedBy: _currentUserId,
        redeemedByName: _currentUserName,
        status: RedemptionStatus.completed,
        notes: notes,
      ));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Redeemed $points points (KES ${value.toStringAsFixed(0)}) for ${customer.name}'),
            backgroundColor: _CustomerConstants.accentGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to redeem points: ${e.toString()}'),
            backgroundColor: _CustomerConstants.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _addCustomer() async {
    final result = await showDialog<Customer>(
      context: context,
      builder: (context) => AddCustomerDialog(
        onSave: (customer) {
          Navigator.pop(context, customer);
        },
      ),
    );
    
    if (result != null && mounted) {
      setState(() {
        _customers.insert(0, result);
        _applyFilters();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.name} added successfully'),
          backgroundColor: _CustomerConstants.accentGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showCustomerDetails(Customer customer) {
    final transactions = _generateCustomerTransactions(customer.id);
    final customerRedemptions = _redemptions.where((r) => r.customerId == customer.id).toList();
    
    showDialog(
      context: context,
      builder: (context) => CustomerDetailDialog(
        customer: customer,
        transactions: transactions,
        redemptions: customerRedemptions,
        canRedeemPoints: _canRedeemPoints,
        onRedeemPoints: () => _showRedemptionDialog(customer),
      ),
    );
  }

  void _showRedemptionDialog(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => PointsRedemptionDialog(
        customer: customer,
        currentUserId: _currentUserId,
        currentUserName: _currentUserName,
        onRedeem: (points, value, notes) async {
          await _processRedemption(customer, points, value, notes);
        },
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter & Sort',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Customer Tier', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedTierFilter == null,
                  onSelected: (_) {
                    setState(() {
                      _selectedTierFilter = null;
                      _applyFilters();
                    });
                    Navigator.pop(context);
                  },
                ),
                ...CustomerTier.values.map((tier) {
                  return FilterChip(
                    label: Text(tier.displayName),
                    selected: _selectedTierFilter == tier,
                    onSelected: (_) {
                      setState(() {
                        _selectedTierFilter = tier;
                        _applyFilters();
                      });
                      Navigator.pop(context);
                    },
                    avatar: Icon(tier.icon, size: 16, color: tier.color),
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Sort by', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'totalSpent', label: Text('Spend')),
                      ButtonSegment(value: 'pointsBalance', label: Text('Points')),
                      ButtonSegment(value: 'lastPurchase', label: Text('Recent')),
                    ],
                    selected: {_sortBy},
                    onSelectionChanged: (Set<String> selection) {
                      setState(() {
                        _sortBy = selection.first;
                        _applyFilters();
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > _CustomerConstants.tabletBreakpoint;
    final isTablet = screenWidth > _CustomerConstants.mobileBreakpoint && 
                     screenWidth <= _CustomerConstants.tabletBreakpoint;
    
    if (isDesktop) {
      debugPrint('Desktop layout active');
    } else if (isTablet) {
      debugPrint('Tablet layout active');
    } else {
      debugPrint('Mobile layout active');
    }
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Customer Insight'),
        backgroundColor: _CustomerConstants.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          onTap: (index) {
            if (index != 0) {
              setState(() {
                _selectedTierFilter = null;
              });
            }
            _applyFilters();
          },
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'All'),
            Tab(icon: Icon(Icons.trending_up), text: 'High Value'),
            Tab(icon: Icon(Icons.access_time), text: 'Recent'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter & Sort',
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Cards
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.people, color: _CustomerConstants.primaryDark, size: 16),
                            const SizedBox(width: 4),
                            Text('Total Customers', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_customers.length}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _CustomerConstants.primaryDark),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.money, color: Colors.green, size: 16),
                            const SizedBox(width: 4),
                            Text('Total Revenue', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'KES ${NumberFormat('#,###').format(_totalRevenue)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.card_giftcard, color: _CustomerConstants.accentGreen, size: 16),
                            const SizedBox(width: 4),
                            Text('Points Balance', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_totalPointsBalance',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _CustomerConstants.accentGreen),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Search Bar
          CustomerSearchBar(
            searchQuery: _searchQuery,
            onSearchChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
            onClearSearch: () {
              setState(() {
                _searchQuery = '';
                _applyFilters();
              });
            },
          ),
          
          // Warning Banner (using warningOrange)
          if (_showHighPointsWarning)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _CustomerConstants.warningOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _CustomerConstants.warningOrange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: _CustomerConstants.warningOrange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'High points balance ($_totalPointsBalance pts) - Consider promoting redemptions',
                      style: TextStyle(
                        fontSize: 12,
                        color: _CustomerConstants.warningOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Error Message
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700))),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red.shade700),
                    onPressed: () => setState(() => _errorMessage = null),
                  ),
                ],
              ),
            ),
          
          // Results Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_filteredCustomersLength customers found',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedTierFilter = null;
                      _searchQuery = '';
                      _tabController.index = 0;
                      _applyFilters();
                    });
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear Filters'),
                ),
              ],
            ),
          ),
          
          // Customer List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCustomers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 72, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text('No customers found', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                            const SizedBox(height: 8),
                            Text('Try adjusting your search or filters', style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: _CustomerConstants.primaryDark,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredCustomers.length,
                          itemBuilder: (context, index) {
                            final customer = _filteredCustomers[index];
                            return CustomerCard(
                              customer: customer,
                              onTap: () => _showCustomerDetails(customer),
                              canRedeemPoints: _canRedeemPoints,
                              onRedeemPoints: () => _showRedemptionDialog(customer),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCustomer,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Customer'),
        backgroundColor: _CustomerConstants.primaryDark,
      ),
    );
  }
}