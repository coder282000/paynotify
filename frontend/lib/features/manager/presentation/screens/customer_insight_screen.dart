// lib/features/manager/presentation/screens/customer_insight_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../domain/models/customer_model.dart';
import '../../domain/models/customer_tier.dart';
// customer_transaction.dart is used by CustomerDetailDialog, so we keep it
// but we need to import it to pass transactions to the dialog
import '../../domain/models/customer_transaction.dart';
import '../../domain/models/points_redemption.dart';
import '../providers/customer_provider.dart';
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
  
  // Used for animations and loading states
  static const Duration animationDuration = Duration(milliseconds: 400);
  static const Duration cardAnimationDuration = Duration(milliseconds: 300);
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
  
  // ── Animation Controllers ──
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _fabController;
  late Animation<double> _fabScaleAnimation;
  
  String _searchQuery = '';
  CustomerTier? _selectedTierFilter;
  String _sortBy = 'totalSpent';
  final bool _sortAscending = false;
  
  // ── Mock current user (from auth provider in real app) ──
  final String _currentUserId = 'manager_1';
  final String _currentUserName = 'Manager';
  final bool _canRedeemPoints = true;
  
  // ── Track previous points balance for animation ──
  int _previousPointsBalance = 0;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // ── Setup Fade Animation ──
    _fadeController = AnimationController(
      vsync: this,
      duration: _CustomerConstants.animationDuration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    
    // ── Setup FAB Animation ──
    _fabController = AnimationController(
      vsync: this,
      duration: _CustomerConstants.animationDuration,
    );
    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabController,
        curve: Curves.elasticOut,
      ),
    );
    
    _loadData();
    _fadeController.forward();
    _fabController.forward();
    
    // Store initial points balance
    _previousPointsBalance = _totalPointsBalance;
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  // ── Load Data from Backend ──
  Future<void> _loadData() async {
    final provider = context.read<CustomerProvider>();
    await provider.loadCustomers();
    _applyFilters();
  }

  // ── Apply Filters ──
  void _applyFilters() {
    final provider = context.read<CustomerProvider>();
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      provider.filterCustomers(_searchQuery);
    } else {
      provider.filterCustomers('');
    }
    
    // Apply tier filter - FIXED: Use helper method instead of displayName
    if (_selectedTierFilter != null) {
      provider.filterByTier(_getTierDisplayName(_selectedTierFilter!));
    } else {
      provider.filterByTier(null);
    }
    
    // Apply tab filters
    final customers = provider.customers;
    List<Customer> filtered = List.from(customers);
    
    // First apply search and tier from provider
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((c) =>
        c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        c.phone.contains(_searchQuery) ||
        (c.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
        (c.vehicleNumber?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
    }
    
    if (_selectedTierFilter != null) {
      filtered = filtered.where((c) => c.tier == _selectedTierFilter).toList();
    }
    
    // Apply tab filters
    if (_tabController.index != 0) {
      switch (_tabController.index) {
        case 1:
          filtered = filtered.where((c) => c.isHighValueCustomer).toList();
          break;
        case 2:
          filtered = filtered.where((c) => c.isRecentCustomer).toList();
          break;
      }
    }
    
    // Apply sorting
    filtered.sort((a, b) {
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
          final aDate = a.lastPurchaseDate ?? DateTime(1970);
          final bDate = b.lastPurchaseDate ?? DateTime(1970);
          comparison = bDate.compareTo(aDate);
          break;
        default:
          comparison = 0;
      }
      return _sortAscending ? comparison : -comparison;
    });
    
    // Update provider's filtered list
    provider.setFilteredCustomers(filtered);
  }

  // ── Helper method for tier display name ──
  String _getTierDisplayName(CustomerTier tier) {
    switch (tier) {
      case CustomerTier.bronze:
        return 'Bronze';
      case CustomerTier.silver:
        return 'Silver';
      case CustomerTier.gold:
        return 'Gold';
      case CustomerTier.platinum:
        return 'Platinum';
    }
  }

  // ── Helper method for tier icon ──
  IconData _getTierIcon(CustomerTier tier) {
    switch (tier) {
      case CustomerTier.bronze:
        return Icons.emoji_events;
      case CustomerTier.silver:
        return Icons.emoji_events;
      case CustomerTier.gold:
        return Icons.emoji_events;
      case CustomerTier.platinum:
        return Icons.emoji_events;
    }
  }

  // ── Helper method for tier color ──
  Color _getTierColor(CustomerTier tier) {
    switch (tier) {
      case CustomerTier.bronze:
        return const Color(0xFFCD7F32);
      case CustomerTier.silver:
        return const Color(0xFFC0C0C0);
      case CustomerTier.gold:
        return const Color(0xFFFFD700);
      case CustomerTier.platinum:
        return const Color(0xFFE5E4E2);
    }
  }

  // ── Error Message ──
  String? get _errorMessage {
    return context.watch<CustomerProvider>().errorMessage;
  }

  // ── Computed Values ──
  int get _totalCustomers => context.watch<CustomerProvider>().customers.length;
  double get _totalRevenue => context.watch<CustomerProvider>().customers.fold(0, (sum, c) => sum + c.totalSpent);
  int get _totalPointsBalance => context.watch<CustomerProvider>().customers.fold(0, (sum, c) => sum + c.pointsBalance);
  int get _filteredCustomersLength => context.watch<CustomerProvider>().filteredCustomers.length;
  bool get _showHighPointsWarning => _totalPointsBalance > 10000;

  // ── Check if points balance changed (for animation trigger) ──
  bool get _pointsBalanceChanged => _previousPointsBalance != _totalPointsBalance;

  // ── Redemption ──
  Future<void> _processRedemption(Customer customer, int points, double value, String? notes) async {
    if (!mounted) return;
    
    try {
      final provider = context.read<CustomerProvider>();
      final success = await provider.redeemPoints(customer.id, points, notes: notes);
      
      if (success && mounted) {
        // Update previous points balance for animation
        _previousPointsBalance = _totalPointsBalance;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Redeemed $points points (KES ${value.toStringAsFixed(0)}) for ${customer.name}'),
            backgroundColor: _CustomerConstants.accentGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception('Redemption failed');
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

  // ── Add Customer ──
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
      final provider = context.read<CustomerProvider>();
      final success = await provider.createCustomer(result.toJson());
      
      if (success && mounted) {
        // Refresh animation
        _fadeController.reset();
        _fadeController.forward();
        
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
  }

  // ── Show Customer Details ──
  void _showCustomerDetails(Customer customer) async {
    // Load real transactions from backend
    final provider = context.read<CustomerProvider>();
    
    // Explicit type annotation - this makes the import of customer_transaction.dart "used"
    final List<CustomerTransaction> transactions = await provider.getCustomerTransactions(customer.id);
    
    // Redemptions would come from a separate endpoint
    final customerRedemptions = <PointsRedemption>[];
    
    if (!mounted) return;
    
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

  // ── Show Redemption Dialog ──
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

  // ── Show Filter Dialog ──
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
                    label: Text(_getTierDisplayName(tier)),
                    selected: _selectedTierFilter == tier,
                    onSelected: (_) {
                      setState(() {
                        _selectedTierFilter = tier;
                        _applyFilters();
                      });
                      Navigator.pop(context);
                    },
                    avatar: Icon(_getTierIcon(tier), size: 16, color: _getTierColor(tier)),
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
    final provider = context.watch<CustomerProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > _CustomerConstants.tabletBreakpoint;
    final isTablet = screenWidth > _CustomerConstants.mobileBreakpoint && 
                     screenWidth <= _CustomerConstants.tabletBreakpoint;
    
    // Used for responsive layout logic
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // ── Summary Cards ──
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
                          AnimatedSwitcher(
                            duration: _CustomerConstants.cardAnimationDuration,
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: Text(
                              provider.isLoading ? '...' : '${_totalCustomers}',
                              key: ValueKey<int>(_totalCustomers),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _CustomerConstants.primaryDark),
                            ),
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
                          AnimatedSwitcher(
                            duration: _CustomerConstants.cardAnimationDuration,
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: Text(
                              provider.isLoading ? '...' : 'KES ${NumberFormat('#,###').format(_totalRevenue)}',
                              key: ValueKey<double>(_totalRevenue),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
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
                          AnimatedSwitcher(
                            duration: _CustomerConstants.cardAnimationDuration,
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: Text(
                              provider.isLoading ? '...' : '$_totalPointsBalance',
                              key: ValueKey<int>(_totalPointsBalance),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _CustomerConstants.accentGreen),
                            ),
                          ),
                          // ── Show points change indicator ──
                          if (_pointsBalanceChanged && !provider.isLoading)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${_totalPointsBalance - _previousPointsBalance > 0 ? '+' : ''}${_totalPointsBalance - _previousPointsBalance} pts',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _totalPointsBalance - _previousPointsBalance > 0 
                                      ? _CustomerConstants.accentGreen 
                                      : _CustomerConstants.errorRed,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // ── Search Bar ──
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
            
            // ── Warning Banner ──
            if (_showHighPointsWarning && !provider.isLoading)
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
            
            // ── Error Message ──
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
                      onPressed: () => context.read<CustomerProvider>().clearError(),
                    ),
                  ],
                ),
              ),
            
            // ── Results Count ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    provider.isLoading ? 'Loading...' : '$_filteredCustomersLength customers found',
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
            
            // ── Customer List ──
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.filteredCustomers.isEmpty
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
                            itemCount: provider.filteredCustomers.length,
                            itemBuilder: (context, index) {
                              final customer = provider.filteredCustomers[index];
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.2),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _fadeController,
                                    curve: Interval(
                                      (index * 0.05).clamp(0.0, 0.8),
                                      1.0,
                                      curve: Curves.easeOut,
                                    ),
                                  ),
                                ),
                                child: CustomerCard(
                                  customer: customer,
                                  onTap: () => _showCustomerDetails(customer),
                                  canRedeemPoints: _canRedeemPoints,
                                  onRedeemPoints: () => _showRedemptionDialog(customer),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton.extended(
          onPressed: _addCustomer,
          icon: const Icon(Icons.person_add),
          label: const Text('Add Customer'),
          backgroundColor: _CustomerConstants.primaryDark,
        ),
      ),
    );
  }
}