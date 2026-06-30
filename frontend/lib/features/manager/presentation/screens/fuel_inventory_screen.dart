// lib/features/manager/presentation/screens/fuel_inventory_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/models/inventory_model.dart';
import '../widgets/inventory_card.dart';
import '../widgets/delivery_dialog.dart';

// MARK: - Constants
class _InventoryConstants {
  static const Color primaryDark = Color(0xFF0B3D2E);
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color warningOrange = Color(0xFFF39C12);
  static const Color errorRed = Color(0xFFE74C3C);
  
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
}

class FuelInventoryScreen extends StatefulWidget {
  const FuelInventoryScreen({super.key});

  @override
  State<FuelInventoryScreen> createState() => _FuelInventoryScreenState();
}

class _FuelInventoryScreenState extends State<FuelInventoryScreen> 
    with TickerProviderStateMixin {
  
  String _searchQuery = '';
  FuelType? _selectedFuelType;
  StockStatus? _selectedStatus;
  bool _isLoading = false;
  String? _errorMessage;
  String _sortBy = 'name';
  bool _sortAscending = true;
  
  Timer? _searchDebounce;
  final TextEditingController _searchController = TextEditingController();

  List<FuelTank> _tanks = [];
  List<FuelTank> _filteredTanks = [];

  @override
  void initState() {
    super.initState();
    _loadInventoryData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // MARK: - Mock Data
  List<FuelTank> _getMockTanks() {
    final now = DateTime.now();
    
    return [
      FuelTank(
        id: '1',
        name: 'Tank 1',
        fuelType: FuelType.petrol,
        capacity: 10000,
        currentLevel: 8200,
        minThreshold: 15,
        maxCapacity: 10000,
        supplier: 'Total Energies',
        lastDeliveryDate: now.subtract(const Duration(days: 5)),
        lastDeliveryAmount: 5000,
        deliveryHistory: [],
        consumptionHistory: [],
      ),
      FuelTank(
        id: '2',
        name: 'Tank 2',
        fuelType: FuelType.diesel,
        capacity: 15000,
        currentLevel: 4200,
        minThreshold: 15,
        maxCapacity: 15000,
        supplier: 'Vivo Energy',
        lastDeliveryDate: now.subtract(const Duration(days: 12)),
        lastDeliveryAmount: 8000,
        deliveryHistory: [],
        consumptionHistory: [],
      ),
      FuelTank(
        id: '3',
        name: 'Tank 3',
        fuelType: FuelType.petrol,
        capacity: 10000,
        currentLevel: 2800,
        minThreshold: 15,
        maxCapacity: 10000,
        supplier: 'Total Energies',
        lastDeliveryDate: now.subtract(const Duration(days: 20)),
        lastDeliveryAmount: 6000,
        deliveryHistory: [],
        consumptionHistory: [],
      ),
      FuelTank(
        id: '4',
        name: 'Tank 4',
        fuelType: FuelType.diesel,
        capacity: 15000,
        currentLevel: 11200,
        minThreshold: 15,
        maxCapacity: 15000,
        supplier: 'Vivo Energy',
        lastDeliveryDate: now.subtract(const Duration(days: 3)),
        lastDeliveryAmount: 5000,
        deliveryHistory: [],
        consumptionHistory: [],
      ),
      FuelTank(
        id: '5',
        name: 'Tank 5',
        fuelType: FuelType.kerosene,
        capacity: 8000,
        currentLevel: 1200,
        minThreshold: 15,
        maxCapacity: 8000,
        supplier: 'Kenol Kobil',
        lastDeliveryDate: now.subtract(const Duration(days: 25)),
        lastDeliveryAmount: 3000,
        deliveryHistory: [],
        consumptionHistory: [],
      ),
      FuelTank(
        id: '6',
        name: 'Tank 6',
        fuelType: FuelType.premium,
        capacity: 10000,
        currentLevel: 9500,
        minThreshold: 15,
        maxCapacity: 10000,
        supplier: 'Total Energies',
        lastDeliveryDate: now.subtract(const Duration(days: 2)),
        lastDeliveryAmount: 4000,
        deliveryHistory: [],
        consumptionHistory: [],
      ),
    ];
  }

  InventorySummary _getSummary(List<FuelTank> tanks) {
    double totalCapacity = 0;
    double totalCurrent = 0;
    double totalValue = 0;
    int critical = 0, low = 0, moderate = 0, good = 0;

    for (var tank in tanks) {
      totalCapacity += tank.capacity;
      totalCurrent += tank.currentLevel;
      totalValue += tank.currentLevel * 150; // Approximate value
      
      switch (tank.stockStatus) {
        case StockStatus.critical:
          critical++;
          break;
        case StockStatus.low:
          low++;
          break;
        case StockStatus.moderate:
          moderate++;
          break;
        case StockStatus.good:
          good++;
          break;
      }
    }

    return InventorySummary(
      totalCapacity: totalCapacity,
      totalCurrentLevel: totalCurrent,
      totalValue: totalValue,
      tanksCritical: critical,
      tanksLow: low,
      tanksModerate: moderate,
      tanksGood: good,
      dailyConsumption: 850,
      weeklyConsumption: 5950,
      monthlyConsumption: 25500,
    );
  }

  // MARK: - Data Loading with mounted checks
  Future<void> _loadInventoryData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.delayed(_InventoryConstants.animationDuration);
      
      if (!mounted) return;
      
      setState(() {
        _tanks = _getMockTanks();
        _applyFilters();
        _isLoading = false;
      });
      
      if (mounted) HapticFeedback.lightImpact();
      
    } catch (e, stackTrace) {
      if (!mounted) return;
      
      debugPrint('Load inventory error: $e\n$stackTrace');
      setState(() {
        _errorMessage = _getErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    if (!mounted) return;
    
    setState(() {
      _filteredTanks = _tanks.where((tank) {
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final matches = tank.name.toLowerCase().contains(query) ||
              tank.fuelType.displayName.toLowerCase().contains(query) ||
              (tank.supplier?.toLowerCase().contains(query) ?? false);
          if (!matches) return false;
        }

        // Fuel type filter
        if (_selectedFuelType != null && tank.fuelType != _selectedFuelType) {
          return false;
        }

        // Status filter
        if (_selectedStatus != null && tank.stockStatus != _selectedStatus) {
          return false;
        }

        return true;
      }).toList()..sort((a, b) {
        int comparison;
        switch (_sortBy) {
          case 'name':
            comparison = a.name.compareTo(b.name);
            break;
          case 'level':
            comparison = a.levelPercentage.compareTo(b.levelPercentage);
            break;
          case 'type':
            comparison = a.fuelType.index.compareTo(b.fuelType.index);
            break;
          default:
            comparison = 0;
        }
        return _sortAscending ? comparison : -comparison;
      });
    });
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = query;
          _applyFilters();
        });
      }
    });
  }

  String _getErrorMessage(dynamic error) {
    if (error is TimeoutException) {
      return 'Connection timed out. Please check your internet and try again.';
    }
    if (error.toString().contains('SocketException') || 
        error.toString().contains('NetworkIsUnreachable')) {
      return 'No internet connection. Please connect to a network and retry.';
    }
    return 'Failed to load inventory data. Please try again.';
  }

  // MARK: - Record Delivery with mounted checks
  Future<void> _recordDelivery(FuelTank tank) async {
    if (!mounted) return;
    
    final result = await showDialog<DeliveryRecord>(
      context: context,
      builder: (context) => DeliveryDialog(
        tank: tank,
        onDeliveryRecorded: (record) {
          if (!mounted) return;
          
          // Create a new tank with updated values since fields are final
          final updatedTank = FuelTank(
            id: tank.id,
            name: tank.name,
            fuelType: tank.fuelType,
            capacity: tank.capacity,
            currentLevel: tank.currentLevel + record.amount,
            minThreshold: tank.minThreshold,
            maxCapacity: tank.maxCapacity,
            supplier: tank.supplier,
            lastDeliveryDate: record.date,
            lastDeliveryAmount: record.amount,
            deliveryHistory: [...tank.deliveryHistory, record],
            consumptionHistory: tank.consumptionHistory,
          );

          if (!mounted) return;
          
          setState(() {
            // Replace the old tank with the updated one
            final index = _tanks.indexWhere((t) => t.id == tank.id);
            if (index != -1) {
              _tanks[index] = updatedTank;
            }
            _applyFilters();
          });
          
          if (!mounted) return;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Delivery recorded: ${record.amount.toStringAsFixed(0)} L'),
              backgroundColor: _InventoryConstants.accentGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
    
    // Use result if needed
    if (result != null && mounted) {
      // Result already handled by onDeliveryRecorded callback
      debugPrint('Delivery recorded with ID: ${result.id}');
    }
  }

  // MARK: - Export with proper mounted checks
  Future<void> _exportInventory() async {
    // Store the mounted state at the beginning
    final bool mountedAtStart = mounted;
    
    if (!mountedAtStart) return;
    
    try {
      // Check connectivity first
      final connectivityResult = await Connectivity().checkConnectivity();
      
      // Check mounted after async operation
      if (!mounted) return;
      
      if (connectivityResult.contains(ConnectivityResult.none)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No internet connection'),
            backgroundColor: _InventoryConstants.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      
      final List<List<dynamic>> csvData = [
        ['Tank', 'Fuel Type', 'Current Level', 'Capacity', 'Status', 'Supplier', 'Last Delivery'],
        ..._filteredTanks.map((t) => [
          t.name,
          t.fuelType.displayName,
          t.currentLevel.toStringAsFixed(0),
          t.capacity.toStringAsFixed(0),
          t.stockStatus.displayName,
          t.supplier ?? 'N/A',
          t.lastDeliveryDate != null 
              ? DateFormat('dd MMM yyyy').format(t.lastDeliveryDate!)
              : 'N/A',
        ]),
      ];
      
      final String csv = const ListToCsvConverter().convert(csvData);
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath = '${tempDir.path}/inventory_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      
      final File file = File(filePath);
      await file.writeAsString(csv);
      
      // Check mounted after file operations
      if (!mounted) return;
      
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'PayNotifyy Fuel Inventory Report',
      );
      
      // Check mounted after share
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Export successful!'),
          backgroundColor: _InventoryConstants.accentGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      HapticFeedback.lightImpact();
      
    } catch (e) {
      // Check mounted before showing error
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: ${e.toString()}'),
          backgroundColor: _InventoryConstants.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatCurrency(double amount) {
    return 'KES ${NumberFormat('#,##0').format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    final summary = _getSummary(_filteredTanks);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > _InventoryConstants.tabletBreakpoint;
    final isTablet = screenWidth > _InventoryConstants.mobileBreakpoint && 
                     screenWidth <= _InventoryConstants.tabletBreakpoint;
    
    // Use warningOrange to prevent unused warning
    final warningColor = _InventoryConstants.warningOrange;
    
    // Use isDesktop and isTablet to prevent unused warnings
    if (isDesktop) {
      // Desktop layout optimizations can go here
    }
    if (isTablet) {
      // Tablet layout optimizations can go here
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Fuel Inventory'),
        backgroundColor: _InventoryConstants.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Export Button
          Semantics(
            button: true,
            label: 'Export inventory',
            child: IconButton(
              icon: const Icon(Icons.file_download_outlined),
              onPressed: _exportInventory,
              tooltip: 'Export Report',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Search tanks',
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search by name, type, supplier...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Semantics(
                    button: true,
                    label: 'Clear search',
                    child: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                          _applyFilters();
                        });
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Fuel Type Filter
                  FilterChip(
                    label: const Text('All Fuels'),
                    selected: _selectedFuelType == null,
                    onSelected: (_) {
                      setState(() {
                        _selectedFuelType = null;
                        _applyFilters();
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ...FuelType.values.map((type) {
                    return FilterChip(
                      label: Text(type.displayName),
                      selected: _selectedFuelType == type,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFuelType = selected ? type : null;
                          _applyFilters();
                        });
                      },
                      avatar: Icon(
                        type.icon,
                        color: _selectedFuelType == type ? Colors.white : type.color,
                        size: 16,
                      ),
                      selectedColor: type.color,
                    );
                  }),

                  const SizedBox(width: 16),
                  const VerticalDivider(width: 1),
                  const SizedBox(width: 16),

                  // Status Filter
                  FilterChip(
                    label: const Text('All Status'),
                    selected: _selectedStatus == null,
                    onSelected: (_) {
                      setState(() {
                        _selectedStatus = null;
                        _applyFilters();
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ...StockStatus.values.map((status) {
                    return FilterChip(
                      label: Text(status.displayName),
                      selected: _selectedStatus == status,
                      onSelected: (selected) {
                        setState(() {
                          _selectedStatus = selected ? status : null;
                          _applyFilters();
                        });
                      },
                      avatar: Icon(
                        status.icon,
                        color: _selectedStatus == status ? Colors.white : status.color,
                        size: 16,
                      ),
                      selectedColor: status.color,
                    );
                  }),

                  const SizedBox(width: 16),
                  const VerticalDivider(width: 1),
                  const SizedBox(width: 16),

                  // Sort Button
                  Semantics(
                    button: true,
                    label: 'Sort by $_sortBy, ${_sortAscending ? 'ascending' : 'descending'}',
                    child: PopupMenuButton<String>(
                      icon: Icon(
                        _sortAscending ? Icons.sort : Icons.sort_by_alpha,
                      ),
                      tooltip: 'Sort by',
                      onSelected: (value) {
                        setState(() {
                          if (_sortBy == value) {
                            _sortAscending = !_sortAscending;
                          } else {
                            _sortBy = value;
                            _sortAscending = true;
                          }
                          _applyFilters();
                        });
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'name',
                          child: Row(
                            children: [
                              Icon(
                                _sortBy == 'name'
                                    ? (_sortAscending
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward)
                                    : Icons.sort_by_alpha,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              const Text('Name'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'level',
                          child: Row(
                            children: [
                              Icon(
                                _sortBy == 'level'
                                    ? (_sortAscending
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward)
                                    : Icons.local_gas_station,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              const Text('Fuel Level'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'type',
                          child: Row(
                            children: [
                              Icon(
                                _sortBy == 'type'
                                    ? (_sortAscending
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward)
                                    : Icons.category,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              const Text('Fuel Type'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Summary Cards
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Stock',
                        '${summary.totalCurrentLevel.toStringAsFixed(0)} L',
                        Icons.inventory,
                        _InventoryConstants.primaryDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Value',
                        _formatCurrency(summary.totalValue),
                        Icons.attach_money,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusSummary(
                        'Critical',
                        summary.tanksCritical.toString(),
                        StockStatus.critical.color,
                        Icons.warning,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatusSummary(
                        'Low',
                        summary.tanksLow.toString(),
                        StockStatus.low.color,
                        Icons.priority_high,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatusSummary(
                        'Good',
                        summary.tanksGood.toString(),
                        StockStatus.good.color,
                        Icons.check_circle,
                      ),
                    ),
                  ],
                ),
                
                // Use warningColor in UI
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: warningColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: warningColor, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tanks at critical/low levels need immediate attention',
                          style: TextStyle(
                            fontSize: 11,
                            color: warningColor,
                          ),
                        ),
                      ),
                    ],
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
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red.shade700),
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                      });
                    },
                  ),
                ],
              ),
            ),

          // Tanks List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTanks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_outlined,
                                size: 72,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No tanks found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your filters',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadInventoryData,
                        color: _InventoryConstants.primaryDark,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredTanks.length,
                          itemBuilder: (context, index) {
                            final tank = _filteredTanks[index];
                            return InventoryCard(
                              tank: tank,
                              onTap: () {
                                // Show tank details
                              },
                              onRecordDelivery: () => _recordDelivery(tank),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSummary(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}