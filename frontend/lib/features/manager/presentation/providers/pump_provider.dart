// lib/features/manager/presentation/providers/pump_provider.dart

import 'package:flutter/material.dart';
import '../../domain/models/pump_config.dart';
import '../../../../core/services/pump_service.dart';

class PumpProvider extends ChangeNotifier {
  // ─────────────────────────────────────────────
  // DEPENDENCY INJECTION
  // ─────────────────────────────────────────────
  final PumpService _pumpService;

  PumpProvider({PumpService? pumpService})
      : _pumpService = pumpService ?? PumpService();

  // ─────────────────────────────────────────────
  // DATA
  // ─────────────────────────────────────────────
  List<PumpConfig> _pumps = [];
  List<PumpConfig> _filteredPumps = [];
  PumpConfig? _selectedPump;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;

  // ── Getters ──
  List<PumpConfig> get pumps => _filteredPumps.isNotEmpty ? _filteredPumps : _pumps;
  List<PumpConfig> get allPumps => _pumps;
  PumpConfig? get selectedPump => _selectedPump;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get hasData => _pumps.isNotEmpty;
  String? get errorMessage => _errorMessage;

  // ── Stats ──
  int get activePumps => _pumps.where((p) => p.status == PumpStatus.active).length;
  int get maintenancePumps => _pumps.where((p) => p.status == PumpStatus.maintenance).length;
  int get inactivePumps => _pumps.where((p) => p.status == PumpStatus.inactive).length;
  int get lowFuelPumps => _pumps.where((p) => p.needsMaintenance).length;
  double get totalTodaySales => _pumps.fold(0, (sum, p) => sum + p.fuelUsedToday);

  // ── Load Pumps ──
  Future<void> loadPumps() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _pumpService.getManagerPumps();
      _pumps = response.map((json) => PumpConfig.fromBackendJson(json)).toList();
      _filteredPumps = List.from(_pumps);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Load pumps error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Refresh ──
  Future<void> refresh() async {
    _isRefreshing = true;
    notifyListeners();

    try {
      final response = await _pumpService.getManagerPumps();
      _pumps = response.map((json) => PumpConfig.fromBackendJson(json)).toList();
      _filteredPumps = List.from(_pumps);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Refresh pumps error: $e');
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  // ── Filter Pumps ──
  void filterByStatus(PumpStatus? status) {
    if (status == null) {
      _filteredPumps = List.from(_pumps);
    } else {
      _filteredPumps = _pumps.where((p) => p.status == status).toList();
    }
    notifyListeners();
  }

  void filterByFuelType(FuelType? fuelType) {
    if (fuelType == null) {
      _filteredPumps = List.from(_pumps);
    } else {
      _filteredPumps = _pumps.where((p) => p.fuelType == fuelType).toList();
    }
    notifyListeners();
  }

  void searchPumps(String query) {
    if (query.isEmpty) {
      _filteredPumps = List.from(_pumps);
    } else {
      final lowerQuery = query.toLowerCase();
      _filteredPumps = _pumps.where((p) =>
        p.number.toLowerCase().contains(lowerQuery) ||
        p.fuelType.displayName.toLowerCase().contains(lowerQuery) ||
        (p.currentAttendantName?.toLowerCase().contains(lowerQuery) ?? false)
      ).toList();
    }
    notifyListeners();
  }

  // ── Select Pump ──
  Future<void> selectPump(int id) async {
    try {
      final response = await _pumpService.getManagerPumpById(id);
      if (response != null) {
        _selectedPump = PumpConfig.fromBackendJson(response);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Select pump error: $e');
      notifyListeners();
    }
  }

  // ── Create Pump ──
  Future<bool> createPump(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _pumpService.createManagerPump(
        pumpNumber: data['pump_number'],
        fuelType: data['fuel_type'],
        pricePerLiter: data['price_per_liter'],
        tankCapacity: data['tank_capacity'] ?? 10000,
      );
      if (response != null) {
        await loadPumps();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Create pump error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Update Status ──
  Future<bool> updateStatus(int id, String status) async {
    try {
      final success = await _pumpService.updateManagerPumpStatus(id, status);
      if (success) {
        await loadPumps();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Update status error: $e');
      return false;
    }
  }

  // ── Update Price ──
  Future<bool> updatePrice(int id, double price) async {
    try {
      final success = await _pumpService.updateManagerFuelPrice(id, price);
      if (success) {
        await loadPumps();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Update price error: $e');
      return false;
    }
  }

  // ── Delete Pump ──
  Future<bool> deletePump(int id) async {
    try {
      final success = await _pumpService.deleteManagerPump(id);
      if (success) {
        await loadPumps();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Delete pump error: $e');
      return false;
    }
  }

  // ── Get Performance ──
  Future<Map<String, dynamic>?> getPerformance(int id, {String period = 'today'}) async {
    try {
      return await _pumpService.getPumpPerformance(id, period: period);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Get performance error: $e');
      return null;
    }
  }

  // ── Clear Error ──
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Reset Filters ──
  void resetFilters() {
    _filteredPumps = List.from(_pumps);
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // DISPOSE
  // ─────────────────────────────────────────────
  @override
  void dispose() {
    _pumpService.dispose();
    super.dispose();
  }
}