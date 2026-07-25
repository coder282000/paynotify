// lib/features/manager/presentation/screens/pump_management_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../domain/models/pump_config.dart';
import '../providers/pump_provider.dart';
import '../widgets/pump_edit_dialog.dart';
import '../widgets/pump_add_dialog.dart';
import '../widgets/pump_history_card.dart';
import '../widgets/fuel_price_card.dart';
import '../widgets/price_schedule_dialog.dart';
import '../widgets/pump_status_badge.dart';

// ── MODEL CLASSES ──
class FuelPriceRecord {
  final String id;
  final FuelType fuelType;
  final double price;
  final DateTime effectiveDate;
  final DateTime? scheduledEndDate;
  final String changedBy;
  final String? reason;
  final bool isActive;

  FuelPriceRecord({
    required this.id,
    required this.fuelType,
    required this.price,
    required this.effectiveDate,
    this.scheduledEndDate,
    required this.changedBy,
    this.reason,
    required this.isActive,
  });

  bool get isScheduled => effectiveDate.isAfter(DateTime.now());
}

class ScheduledPriceChange {
  final String id;
  final FuelType fuelType;
  final double oldPrice;
  final double newPrice;
  final DateTime effectiveDate;
  final String createdBy;
  final DateTime createdAt;
  final String? reason;

  ScheduledPriceChange({
    required this.id,
    required this.fuelType,
    required this.oldPrice,
    required this.newPrice,
    required this.effectiveDate,
    required this.createdBy,
    required this.createdAt,
    this.reason,
  });

  bool get isPending => effectiveDate.isAfter(DateTime.now());
  bool get isToday => effectiveDate.day == DateTime.now().day && 
                      effectiveDate.month == DateTime.now().month &&
                      effectiveDate.year == DateTime.now().year;
}

class CurrentFuelPrices {
  final FuelType fuelType;
  final double currentPrice;
  final double? nextPrice;
  final DateTime? nextPriceDate;
  final double priceChange;
  final double percentageChange;

  CurrentFuelPrices({
    required this.fuelType,
    required this.currentPrice,
    this.nextPrice,
    this.nextPriceDate,
    required this.priceChange,
    required this.percentageChange,
  });
}

class PumpManagementScreen extends StatefulWidget {
  const PumpManagementScreen({super.key});

  @override
  State<PumpManagementScreen> createState() => _PumpManagementScreenState();
}

class _PumpManagementScreenState extends State<PumpManagementScreen> 
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  String _searchQuery = '';
  FuelType? _selectedFuelFilter;
  PumpStatus? _selectedStatusFilter;
  bool _isLoading = false;
  String? _errorMessage;
  String _sortBy = 'number';
  bool _sortAscending = true;
  late AnimationController _refreshController;
  
  // ── Data ──
  List<PumpConfig> _pumps = [];
  
  // ── Price management data ──
  final Map<FuelType, List<FuelPriceRecord>> _priceHistory = {};
  final List<ScheduledPriceChange> _scheduledChanges = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadPumpData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  // ── LOAD REAL DATA FROM BACKEND ──
  Future<void> _loadPumpData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final provider = context.read<PumpProvider>();
      await provider.loadPumps();
      
      if (mounted) {
        setState(() {
          _pumps = List.from(provider.allPumps);
          _isLoading = false;
          _buildPriceHistoryFromPumps();
        });
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
      debugPrint('Load pump data error: $e');
    }
  }

  // ── BUILD PRICE HISTORY FROM PUMP DATA ──
  void _buildPriceHistoryFromPumps() {
    _priceHistory.clear();
    
    for (final fuelType in FuelType.values) {
      final pumpsOfType = _pumps.where((p) => p.fuelType == fuelType).toList();
      if (pumpsOfType.isNotEmpty) {
        final latestPrice = pumpsOfType.first.pricePerLiter;
        _priceHistory[fuelType] = [
          FuelPriceRecord(
            id: '${fuelType.name}_current',
            fuelType: fuelType,
            price: latestPrice,
            effectiveDate: DateTime.now().subtract(const Duration(days: 1)),
            changedBy: 'Manager',
            isActive: true,
          ),
        ];
      }
    }
  }

  // ── GET CURRENT PRICES ──
  CurrentFuelPrices _getCurrentPrices(FuelType type) {
    final history = _priceHistory[type] ?? [];
    final current = history.firstWhere(
      (h) => h.isActive,
      orElse: () => FuelPriceRecord(
        id: 'default',
        fuelType: type,
        price: _getDefaultPrice(type),
        effectiveDate: DateTime.now(),
        changedBy: 'System',
        isActive: true,
      ),
    );

    final next = _scheduledChanges.firstWhere(
      (s) => s.fuelType == type && s.isPending,
      orElse: () => ScheduledPriceChange(
        id: '',
        fuelType: type,
        oldPrice: current.price,
        newPrice: current.price,
        effectiveDate: DateTime.now(),
        createdBy: '',
        createdAt: DateTime.now(),
      ),
    );

    final previousPrice = history.length > 1 ? history[1].price : current.price;
    
    final double priceChange = (current.price - previousPrice).toDouble();
    final double percentageChange = previousPrice > 0 
        ? ((priceChange / previousPrice) * 100).toDouble() 
        : 0.0;

    return CurrentFuelPrices(
      fuelType: type,
      currentPrice: current.price.toDouble(),
      nextPrice: next.id.isNotEmpty ? next.newPrice.toDouble() : null,
      nextPriceDate: next.id.isNotEmpty ? next.effectiveDate : null,
      priceChange: priceChange,
      percentageChange: percentageChange,
    );
  }

  double _getDefaultPrice(FuelType type) {
    switch (type) {
      case FuelType.petrol:
        return 180.50;
      case FuelType.diesel:
        return 165.00;
      case FuelType.kerosene:
        return 120.00;
      case FuelType.premium:
        return 195.00;
    }
  }

  // ── UPDATE PRICE IN BACKEND ──
  Future<void> _updatePriceImmediate(FuelType type, double newPrice, String reason) async {
    try {
      final provider = context.read<PumpProvider>();
      
      final pumpsOfType = _pumps.where((p) => p.fuelType == type).toList();
      
      for (final pump in pumpsOfType) {
        final pumpId = int.tryParse(pump.id);
        if (pumpId != null) {
          final success = await provider.updatePrice(pumpId, newPrice);
          if (!success) {
            throw Exception('Failed to update price for ${pump.number}');
          }
        }
      }
      
      final history = _priceHistory[type] ?? [];
      
      final updatedHistory = history.map((r) {
        if (r.isActive) {
          return FuelPriceRecord(
            id: r.id,
            fuelType: r.fuelType,
            price: r.price,
            effectiveDate: r.effectiveDate,
            changedBy: r.changedBy,
            reason: r.reason,
            isActive: false,
          );
        }
        return r;
      }).toList();
      
      updatedHistory.add(
        FuelPriceRecord(
          id: 'price_${DateTime.now().millisecondsSinceEpoch}',
          fuelType: type,
          price: newPrice,
          effectiveDate: DateTime.now(),
          changedBy: 'Manager',
          reason: reason.isNotEmpty ? reason : 'Manual update',
          isActive: true,
        ),
      );
      
      if (mounted) {
        setState(() {
          _priceHistory[type] = updatedHistory;
          _pumps = _pumps.map((pump) {
            if (pump.fuelType == type) {
              return PumpConfig(
                id: pump.id,
                number: pump.number,
                fuelType: pump.fuelType,
                status: pump.status,
                currentAttendantId: pump.currentAttendantId,
                currentAttendantName: pump.currentAttendantName,
                pricePerLiter: newPrice,
                currentReading: pump.currentReading,
                previousReading: pump.previousReading,
                lastReadingDate: pump.lastReadingDate,
                tankCapacity: pump.tankCapacity,
                currentFuelLevel: pump.currentFuelLevel,
                lowFuelThreshold: pump.lowFuelThreshold,
                isActive: pump.isActive,
                priceHistory: [
                  ...pump.priceHistory,
                  PumpPriceHistory(
                    date: DateTime.now(),
                    oldPrice: pump.pricePerLiter,
                    newPrice: newPrice,
                    changedBy: 'Manager',
                  ),
                ],
                maintenanceHistory: pump.maintenanceHistory,
              );
            }
            return pump;
          }).toList();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type.displayName} price updated to KES ${newPrice.toStringAsFixed(2)}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update price: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      debugPrint('Update price error: $e');
    }
  }

  // ── SHOW FUEL PRICE MANAGEMENT ──
  void _showFuelPriceManagement() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2ECC71).withAlpha(26),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.attach_money,
                          color: Color(0xFF2ECC71),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fuel Price Management',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Set prices by fuel type - applies to all pumps',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                
                const Divider(height: 1),
                
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      ...FuelType.values.map((type) {
                        final prices = _getCurrentPrices(type);
                        return FuelPriceCard(
                          fuelType: type,
                          currentPrice: prices.currentPrice,
                          nextPrice: prices.nextPrice,
                          nextPriceDate: prices.nextPriceDate,
                          priceChange: prices.priceChange,
                          percentageChange: prices.percentageChange,
                          onEdit: () => _showPriceDialog(type),
                          onViewHistory: () => _showPriceHistory(type),
                        );
                      }),
                      
                      if (_scheduledChanges.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Scheduled Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._scheduledChanges.map((change) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Icon(
                              change.fuelType.icon,
                              color: change.fuelType.color,
                            ),
                            title: Text(
                              '${change.fuelType.displayName}: KES ${change.oldPrice.toStringAsFixed(2)} → KES ${change.newPrice.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              'Effective: ${DateFormat('dd MMM yyyy').format(change.effectiveDate)}',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => _cancelScheduledChange(change),
                            ),
                          ),
                        )),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPriceDialog(FuelType type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set ${type.displayName} Price'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(type.icon, color: type.color),
              title: const Text('Update Now'),
              subtitle: Text('Change price immediately to all ${type.displayName} pumps'),
              onTap: () {
                Navigator.pop(context);
                _showImmediatePriceDialog(type);
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule, color: Colors.orange),
              title: const Text('Schedule for Later'),
              subtitle: const Text('Set future price change'),
              onTap: () {
                Navigator.pop(context);
                _showScheduleDialog(type);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.blue),
              title: const Text('View History'),
              subtitle: const Text('See price changes over time'),
              onTap: () {
                Navigator.pop(context);
                _showPriceHistory(type);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showImmediatePriceDialog(FuelType type) {
    final priceController = TextEditingController();
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update ${type.displayName} Price'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: type.color.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(type.icon, color: type.color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Current Price'),
                        Text(
                          'KES ${_getCurrentPrices(type).currentPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: type.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'New Price (KES/L)',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Reason for change (optional)',
                prefixIcon: const Icon(Icons.note_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (priceController.text.isEmpty) return;
              final newPrice = double.tryParse(priceController.text);
              if (newPrice == null || newPrice <= 0) return;
              
              _updatePriceImmediate(type, newPrice, reasonController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: type.color,
            ),
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  void _showScheduleDialog(FuelType type) {
    final currentPrices = _getCurrentPrices(type);
    
    showDialog(
      context: context,
      builder: (context) => PriceScheduleDialog(
        fuelType: type,
        currentPrice: currentPrices.currentPrice,
        onSchedule: (newPrice, date, reason) {
          if (mounted) {
            setState(() {
              _scheduledChanges.add(
                ScheduledPriceChange(
                  id: 'sched_${DateTime.now().millisecondsSinceEpoch}',
                  fuelType: type,
                  oldPrice: currentPrices.currentPrice,
                  newPrice: newPrice,
                  effectiveDate: date,
                  createdBy: 'Manager',
                  createdAt: DateTime.now(),
                  reason: reason,
                ),
              );
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Price change scheduled for ${DateFormat('dd MMM yyyy').format(date)}'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _showPriceHistory(FuelType type) {
    final history = _priceHistory[type] ?? [];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              '${type.displayName} Price History',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final record = history[index];
                  return ListTile(
                    leading: Icon(
                      Icons.circle,
                      color: record.isActive ? Colors.green : Colors.grey,
                      size: 12,
                    ),
                    title: Text(
                      'KES ${record.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: record.isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(DateFormat('dd MMM yyyy').format(record.effectiveDate)),
                    trailing: Text(record.changedBy),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _cancelScheduledChange(ScheduledPriceChange change) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Scheduled Change?'),
        content: Text(
          'Cancel price change for ${change.fuelType.displayName} from '
          'KES ${change.oldPrice.toStringAsFixed(2)} to '
          'KES ${change.newPrice.toStringAsFixed(2)}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              if (mounted) {
                setState(() {
                  _scheduledChanges.removeWhere((c) => c.id == change.id);
                });
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Scheduled change cancelled'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  // ── ADD NEW PUMP ──
  void _addNewPump() {
    showDialog(
      context: context,
      builder: (context) => PumpAddDialog(
        onSave: (newPump) async {
          try {
            final provider = context.read<PumpProvider>();
            final success = await provider.createPump({
              'pump_number': newPump.number,
              'fuel_type': newPump.fuelType.backendValue,
              'price_per_liter': newPump.pricePerLiter,
              'tank_capacity': newPump.tankCapacity,
            });
            
            if (success && mounted) {
              await _loadPumpData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${newPump.number} added successfully'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to add pump: ${e.toString()}'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
      ),
    );
  }

  // ── EDIT PUMP ──
  void _editPump(PumpConfig pump) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => PumpEditDialog(pump: pump),
    );
    
    if (result != null && mounted) {
      try {
        final provider = context.read<PumpProvider>();
        final pumpId = int.tryParse(pump.id);
        final updatedPump = result['pump'] as PumpConfig;
        final applyToAll = result['applyToAllSameFuelType'] as bool? ?? false;
        final priceChanged = result['priceChanged'] as bool? ?? false;
        
        if (pumpId != null) {
          // Update status if changed
          if (updatedPump.status != pump.status) {
            await provider.updateStatus(pumpId, updatedPump.status.backendValue);
          }
          
          // Update price if changed
          if (priceChanged && updatedPump.pricePerLiter != pump.pricePerLiter) {
            if (applyToAll) {
              // Apply price to all pumps of same fuel type
              final pumpsOfType = _pumps.where((p) => p.fuelType == updatedPump.fuelType).toList();
              for (final p in pumpsOfType) {
                final id = int.tryParse(p.id);
                if (id != null && id != pumpId) {
                  await provider.updatePrice(id, updatedPump.pricePerLiter);
                }
              }
            }
            // Update the current pump price
            await provider.updatePrice(pumpId, updatedPump.pricePerLiter);
          }
        }
        
        await _loadPumpData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${updatedPump.number} updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update pump: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // ── DELETE PUMP ──
  Future<void> _deletePump(PumpConfig pump) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Deactivate ${pump.number}?'),
        content: Text(
          'Are you sure you want to deactivate ${pump.number}? '
          'This action can be reversed later.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    
    if (confirm == true && mounted) {
      try {
        final provider = context.read<PumpProvider>();
        final pumpId = int.tryParse(pump.id);
        
        if (pumpId != null) {
          final success = await provider.deletePump(pumpId);
          if (success) {
            await _loadPumpData();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${pump.number} deactivated successfully'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to deactivate pump: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // ── GET FILTERED PUMPS ──
  List<PumpConfig> _getFilteredPumps() {
    return _pumps.where((pump) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matches = pump.number.toLowerCase().contains(query) ||
            pump.fuelType.displayName.toLowerCase().contains(query) ||
            (pump.currentAttendantName?.toLowerCase().contains(query) ?? false);
        if (!matches) return false;
      }
      
      if (_selectedFuelFilter != null && pump.fuelType != _selectedFuelFilter) {
        return false;
      }
      
      if (_selectedStatusFilter != null && pump.status != _selectedStatusFilter) {
        return false;
      }
      
      return true;
    }).toList()..sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'number':
          comparison = a.number.compareTo(b.number);
          break;
        case 'price':
          comparison = a.pricePerLiter.compareTo(b.pricePerLiter);
          break;
        case 'fuelLevel':
          comparison = a.currentFuelLevel.compareTo(b.currentFuelLevel);
          break;
        case 'sales':
          comparison = (a.currentReading - (a.previousReading ?? 0))
              .compareTo(b.currentReading - (b.previousReading ?? 0));
          break;
        default:
          comparison = 0;
      }
      return _sortAscending ? comparison : -comparison;
    });
  }

  // ── HELPER WIDGETS ──
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(13),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(51)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── BUILD PUMP CARD ──
  Widget _buildPumpCard(PumpConfig pump) {
    final todaySales = pump.currentReading - (pump.previousReading ?? pump.currentReading);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showPumpDetails(pump),
        onLongPress: () => _editPump(pump),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: pump.fuelType.color.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      pump.fuelType.icon,
                      color: pump.fuelType.color,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              pump.number,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            PumpStatusBadge(status: pump.status, compact: true),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pump.fuelType.displayName,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        if (pump.currentAttendantName != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '👤 ${pump.currentAttendantName}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'KES ${pump.pricePerLiter.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0B3D2E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '/liter',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Fuel Level',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              pump.fuelLevelStatus,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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
                            backgroundColor: pump.fuelLevelColor.withAlpha(26),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              pump.fuelLevelColor,
                            ),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${pump.currentFuelLevel.toStringAsFixed(0)} / ${pump.tankCapacity.toStringAsFixed(0)} L',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Today\'s Sales',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${todaySales.toStringAsFixed(1)} L',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        'KES ${(todaySales * pump.pricePerLiter).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showPumpDetails(pump),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('View'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _editPump(pump),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B3D2E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Deactivate Pump',
                    onPressed: () => _deletePump(pump),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── SHOW PUMP DETAILS ──
  void _showPumpDetails(PumpConfig pump) {
    final todaySales = pump.currentReading - (pump.previousReading ?? pump.currentReading);
    final salesValue = todaySales * pump.pricePerLiter;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 100,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    pump.fuelType.color,
                    pump.fuelType.color.withAlpha(204),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(26),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          pump.fuelType.icon,
                          color: pump.fuelType.color,
                          size: 40,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pump.number,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                    color: Colors.black26,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pump.fuelType.displayName,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withAlpha(230),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PumpStatusBadge(status: pump.status),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      _buildQuickStatWidget(
                        'Price per Liter',
                        'KES ${pump.pricePerLiter.toStringAsFixed(2)}',
                        Icons.attach_money,
                        Colors.white,
                      ),
                      Expanded(
                        child: Container(
                          height: 40,
                          width: 1,
                          color: Colors.white.withAlpha(77),
                        ),
                      ),
                      _buildQuickStatWidget(
                        'Today\'s Sales',
                        '${todaySales.toStringAsFixed(1)} L',
                        Icons.trending_up,
                        Colors.white,
                      ),
                      Expanded(
                        child: Container(
                          height: 40,
                          width: 1,
                          color: Colors.white.withAlpha(77),
                        ),
                      ),
                      _buildQuickStatWidget(
                        'Revenue',
                        'KES ${salesValue.toStringAsFixed(0)}',
                        Icons.account_balance_wallet,
                        Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade50,
                            Colors.cyan.shade50,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.person_outline,
                              color: Colors.blue.shade800,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Attendant',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  pump.currentAttendantName ?? 'No attendant assigned',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (pump.currentAttendantName != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified,
                                    color: Colors.green.shade700,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Active',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: pump.fuelLevelColor.withAlpha(13),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: pump.fuelLevelColor.withAlpha(77),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.local_gas_station,
                                color: pump.fuelLevelColor,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Fuel Level',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: pump.fuelLevelColor,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: pump.fuelLevelColor.withAlpha(26),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  pump.fuelLevelStatus,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: pump.fuelLevelColor,
                                    fontSize: 13,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Current Level',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${pump.currentFuelLevel.toStringAsFixed(0)} L',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: pump.fuelLevelColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Capacity',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${pump.tankCapacity.toStringAsFixed(0)} L',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: LinearProgressIndicator(
                              value: pump.fuelPercentage / 100,
                              backgroundColor: pump.fuelLevelColor.withAlpha(51),
                              valueColor: AlwaysStoppedAnimation<Color>(pump.fuelLevelColor),
                              minHeight: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${pump.fuelPercentage.toStringAsFixed(1)}% remaining',
                            style: TextStyle(
                              fontSize: 13,
                              color: pump.fuelLevelColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.speed,
                                  color: Colors.orange.shade800,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Meter Readings',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricCard(
                                  'Current Reading',
                                  '${pump.currentReading.toStringAsFixed(1)} L',
                                  Icons.speed,
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricCard(
                                  'Opening Reading',
                                  pump.previousReading != null
                                      ? '${pump.previousReading!.toStringAsFixed(1)} L'
                                      : 'Not set',
                                  Icons.play_arrow,
                                  Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Colors.blue.shade700,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Last updated: ${pump.lastReadingDate != null ? DateFormat('dd MMM yyyy, HH:mm').format(pump.lastReadingDate!) : 'Never'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    if (pump.priceHistory.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.history,
                                    color: Colors.purple.shade800,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Price History',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...pump.priceHistory.map((history) => 
                              PumpHistoryCard.price(history)
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    if (pump.maintenanceHistory.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.build,
                                    color: Colors.red.shade800,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Maintenance History',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...pump.maintenanceHistory.map((record) => 
                              PumpHistoryCard.maintenance(record)
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(26),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _editPump(pump);
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit Pump'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: pump.fuelType.color,
                            width: 2,
                          ),
                          foregroundColor: pump.fuelType.color,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Reports coming soon'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.bar_chart_outlined),
                        label: const Text('View Reports'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B3D2E),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
    );
  }

  Widget _buildQuickStatWidget(String label, String value, IconData icon, Color textColor) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: textColor.withAlpha(204),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PumpProvider>();
    final filteredPumps = _getFilteredPumps();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Pump Management'),
        backgroundColor: const Color(0xFF0B3D2E),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          onTap: (index) {
            setState(() {
              if (index == 1) {
                _selectedStatusFilter = PumpStatus.active;
              } else if (index == 2) {
                _selectedStatusFilter = PumpStatus.maintenance;
              } else {
                _selectedStatusFilter = null;
              }
            });
          },
          tabs: const [
            Tab(text: 'All Pumps'),
            Tab(text: 'Active'),
            Tab(text: 'Maintenance'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_outlined),
            tooltip: 'Add Pump',
            onPressed: _addNewPump,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadPumpData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPumpData,
        color: const Color(0xFF0B3D2E),
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ── STATS SUMMARY CARDS ──
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _buildStatCard(
                            'Total',
                            provider.allPumps.length.toString(),
                            Icons.local_gas_station,
                            Colors.blue,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            'Active',
                            provider.activePumps.toString(),
                            Icons.check_circle,
                            Colors.green,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            'Maintenance',
                            provider.maintenancePumps.toString(),
                            Icons.build,
                            Colors.orange,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            'Low Fuel',
                            provider.lowFuelPumps.toString(),
                            Icons.warning,
                            Colors.red,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // ── SEARCH AND FILTER BAR ──
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextField(
                            onChanged: (value) => setState(() => _searchQuery = value),
                            decoration: InputDecoration(
                              hintText: 'Search pumps...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () => setState(() => _searchQuery = ''),
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                FilterChip(
                                  label: const Text('All Fuels'),
                                  selected: _selectedFuelFilter == null,
                                  onSelected: (_) => setState(() {
                                    _selectedFuelFilter = null;
                                  }),
                                ),
                                const SizedBox(width: 8),
                                ...FuelType.values.map((type) {
                                  return FilterChip(
                                    label: Text(type.displayName),
                                    selected: _selectedFuelFilter == type,
                                    onSelected: (selected) => setState(() {
                                      _selectedFuelFilter = selected ? type : null;
                                    }),
                                    avatar: Icon(
                                      type.icon,
                                      color: type.color,
                                      size: 16,
                                    ),
                                  );
                                }),
                                
                                const SizedBox(width: 16),
                                const VerticalDivider(width: 1),
                                const SizedBox(width: 16),
                                
                                PopupMenuButton<String>(
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
                                    });
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'number',
                                      child: Row(
                                        children: [
                                          Icon(
                                            _sortBy == 'number'
                                                ? (_sortAscending
                                                    ? Icons.arrow_upward
                                                    : Icons.arrow_downward)
                                                : Icons.drag_handle,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text('Pump Number'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'price',
                                      child: Row(
                                        children: [
                                          Icon(
                                            _sortBy == 'price'
                                                ? (_sortAscending
                                                    ? Icons.arrow_upward
                                                    : Icons.arrow_downward)
                                                : Icons.attach_money,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text('Price per Liter'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'fuelLevel',
                                      child: Row(
                                        children: [
                                          Icon(
                                            _sortBy == 'fuelLevel'
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
                                      value: 'sales',
                                      child: Row(
                                        children: [
                                          Icon(
                                            _sortBy == 'sales'
                                                ? (_sortAscending
                                                    ? Icons.arrow_upward
                                                    : Icons.arrow_downward)
                                                : Icons.trending_up,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text('Today\'s Sales'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // ── ERROR MESSAGE ──
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
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
                                if (mounted) {
                                  setState(() {
                                    _errorMessage = null;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    
                    // ── RESULTS COUNT ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${filteredPumps.length} pumps found',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedFuelFilter = null;
                              _selectedStatusFilter = null;
                              _searchQuery = '';
                              _tabController.index = 0;
                            });
                          },
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Clear Filters'),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // ── PUMP LIST ──
                    filteredPumps.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 72,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No pumps found',
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
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: filteredPumps.length,
                            itemBuilder: (context, index) {
                              final pump = filteredPumps[index];
                              return _buildPumpCard(pump);
                            },
                          ),
                  ],
                ),
              ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: ElevatedButton.icon(
          onPressed: _showFuelPriceManagement,
          icon: const Icon(Icons.attach_money, size: 20),
          label: const Text(
            'Manage Fuel Prices',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2ECC71),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 4,
            shadowColor: const Color(0xFF2ECC71).withAlpha(77),
          ),
        ),
      ),
    );
  }
}