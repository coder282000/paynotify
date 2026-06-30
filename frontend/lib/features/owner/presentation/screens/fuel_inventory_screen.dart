// lib/features/owner/presentation/screens/fuel_inventory_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/owner_provider.dart';
import '../../domain/models/fuel_inventory.dart';

class OwnerFuelInventoryScreen extends StatefulWidget {
  const OwnerFuelInventoryScreen({super.key});

  @override
  State<OwnerFuelInventoryScreen> createState() => _OwnerFuelInventoryScreenState();
}

class _OwnerFuelInventoryScreenState extends State<OwnerFuelInventoryScreen> {
  String _selectedStation = 'all';
  String _selectedFuelType = 'all';
  String _selectedStatus = 'all';

  final List<String> _fuelTypes = ['all', 'petrol', 'diesel', 'kerosene', 'premium'];
  final List<String> _statusFilters = ['all', 'good', 'moderate', 'low', 'critical'];

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    final provider = context.read<OwnerProvider>();
    await provider.loadFuelInventory();
  }

  List<FuelInventory> get _filteredInventory {
    final provider = context.watch<OwnerProvider>();
    final inventory = provider.fuelInventory;
    
    return inventory.where((i) {
      if (_selectedStation != 'all' && i.stationName != _selectedStation) return false;
      if (_selectedFuelType != 'all' && i.fuelType != _selectedFuelType) return false;
      if (_selectedStatus != 'all' && i.status != _selectedStatus) return false;
      return true;
    }).toList();
  }

  double get _totalFuel {
    return _filteredInventory.fold(0.0, (sum, i) => sum + i.currentLevel);
  }

  double get _averagePercentage {
    final filtered = _filteredInventory;
    if (filtered.isEmpty) return 0;
    return filtered.fold(0.0, (sum, i) => sum + i.percentage) / filtered.length;
  }

  int get _criticalCount => _filteredInventory.where((i) => i.status == 'critical').length;
  int get _lowCount => _filteredInventory.where((i) => i.status == 'low').length;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OwnerProvider>();
    final filtered = _filteredInventory;
    final totalFuel = _totalFuel;
    final avgPercentage = _averagePercentage;
    final criticalCount = _criticalCount;
    final lowCount = _lowCount;
    final stations = provider.stations.map((s) => s.stationName).toList();
    final allStations = ['all', ...stations];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel Inventory'),
        backgroundColor: const Color(0xFF0B3D2E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInventory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: provider.isLoadingFuelInventory
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(provider.errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadInventory,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Summary Cards
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'Total Fuel',
                              '${totalFuel.toStringAsFixed(0)}L',
                              Icons.local_gas_station,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'Avg Level',
                              '${avgPercentage.toStringAsFixed(0)}%',
                              Icons.percent,
                              _getStatusColor(avgPercentage),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'Critical',
                              criticalCount.toString(),
                              Icons.warning,
                              Colors.red,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'Low Alert',
                              lowCount.toString(),
                              Icons.info,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Filters
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildFilterDropdown(
                              value: _selectedStation,
                              items: allStations,
                              onChanged: (v) => setState(() => _selectedStation = v!),
                              label: 'Station',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFilterDropdown(
                              value: _selectedFuelType,
                              items: _fuelTypes,
                              onChanged: (v) => setState(() => _selectedFuelType = v!),
                              label: 'Fuel Type',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFilterDropdown(
                              value: _selectedStatus,
                              items: _statusFilters,
                              onChanged: (v) => setState(() => _selectedStatus = v!),
                              label: 'Status',
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Inventory List
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inventory, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('No fuel inventory found'),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                return _buildInventoryCard(item);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryCard(FuelInventory item) {
    final statusColor = _getStatusColor(item.percentage);
    final statusText = _getStatusText(item.status);
    final statusIcon = _getStatusIcon(item.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getFuelColor(item.fuelType).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getFuelIcon(item.fuelType),
                    color: _getFuelColor(item.fuelType),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.stationName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getFuelColor(item.fuelType).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getFuelDisplayName(item.fuelType),
                              style: TextStyle(
                                fontSize: 10,
                                color: _getFuelColor(item.fuelType),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 10, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${item.percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.formattedLevel} / ${item.formattedCapacity}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Fuel Gauge
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Fuel Level',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      'Min: ${item.minThreshold}%',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: item.percentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatusMarker('Critical', 0, 10, Colors.red),
                    const SizedBox(width: 12),
                    _buildStatusMarker('Low', 10, 25, Colors.orange),
                    const SizedBox(width: 12),
                    _buildStatusMarker('Moderate', 25, 50, Colors.yellow.shade700),
                    const SizedBox(width: 12),
                    _buildStatusMarker('Good', 50, 100, Colors.green),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    _showDeliveryDialog(item);
                  },
                  icon: const Icon(Icons.local_shipping, size: 18),
                  label: const Text('Record Delivery'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0B3D2E),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    _showDetailsDialog(item);
                  },
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMarker(String label, double min, double max, Color color) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 9, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(label, style: const TextStyle(fontSize: 12)),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item == 'all' ? 'All $label' : _getDisplayName(item, label),
                style: const TextStyle(fontSize: 12),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  String _getDisplayName(String value, String label) {
    if (label == 'Fuel Type') {
      return _getFuelDisplayName(value);
    }
    return value.toUpperCase();
  }

  void _showDeliveryDialog(FuelInventory item) {
    final amountController = TextEditingController();
    final supplierController = TextEditingController();
    final costController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Record Fuel Delivery - ${item.stationName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Fuel Type: ${_getFuelDisplayName(item.fuelType)}'),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (Liters)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_gas_station),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: supplierController,
              decoration: const InputDecoration(
                labelText: 'Supplier Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: costController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cost per Liter (KES)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.money),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              final cost = double.tryParse(costController.text);
              
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter valid amount'), backgroundColor: Colors.red),
                );
                return;
              }
              
              if (cost == null || cost <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter valid cost per liter'), backgroundColor: Colors.red),
                );
                return;
              }
              
              Navigator.pop(context);
              
              // Call API to record delivery
              final provider = context.read<OwnerProvider>();
              final success = await provider.recordFuelDelivery(
                tankId: item.id,
                amount: amount,
                supplier: supplierController.text,
                costPerLiter: cost,
              );
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Delivery recorded successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadInventory(); // Refresh data
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(provider.errorMessage ?? 'Failed to record delivery'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B3D2E),
            ),
            child: const Text('Record Delivery'),
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(FuelInventory item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${item.stationName} - Fuel Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Fuel Type', _getFuelDisplayName(item.fuelType)),
            const Divider(),
            _detailRow('Current Level', item.formattedLevel),
            _detailRow('Capacity', item.formattedCapacity),
            _detailRow('Percentage', '${item.percentage.toStringAsFixed(1)}%'),
            _detailRow('Min Threshold', '${item.minThreshold}%'),
            _detailRow('Status', _getStatusText(item.status).toUpperCase()),
            const Divider(),
            _detailRow('Estimated Days Left', _getEstimatedDaysLeft(item.percentage)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _getEstimatedDaysLeft(double percentage) {
    final days = (percentage / 10).round();
    if (days <= 0) return 'Less than 1 day';
    if (days == 1) return '1 day';
    return '$days days';
  }

  Color _getStatusColor(double percentage) {
    if (percentage <= 10) return Colors.red;
    if (percentage <= 25) return Colors.orange;
    if (percentage <= 50) return Colors.yellow.shade700;
    return Colors.green;
  }

  Color _getFuelColor(String fuelType) {
    switch (fuelType) {
      case 'petrol': return Colors.orange;
      case 'diesel': return Colors.blue;
      case 'kerosene': return Colors.purple;
      case 'premium': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getFuelIcon(String fuelType) {
    switch (fuelType) {
      case 'petrol': return Icons.local_gas_station;
      case 'diesel': return Icons.local_gas_station;
      case 'kerosene': return Icons.oil_barrel;
      case 'premium': return Icons.star;
      default: return Icons.local_gas_station;
    }
  }

  String _getFuelDisplayName(String fuelType) {
    switch (fuelType) {
      case 'petrol': return 'Petrol';
      case 'diesel': return 'Diesel';
      case 'kerosene': return 'Kerosene';
      case 'premium': return 'Premium';
      default: return fuelType;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'critical': return 'CRITICAL';
      case 'low': return 'LOW';
      case 'moderate': return 'MODERATE';
      default: return 'GOOD';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'critical': return Icons.warning;
      case 'low': return Icons.info;
      case 'moderate': return Icons.remove_circle;
      default: return Icons.check_circle;
    }
  }
}