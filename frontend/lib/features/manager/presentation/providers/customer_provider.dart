// lib/features/manager/presentation/providers/customer_provider.dart

import 'package:flutter/material.dart';
import '../../domain/models/customer_model.dart';
import '../../domain/models/customer_tier.dart';
import '../../domain/models/customer_transaction.dart';
import '../../domain/models/points_redemption.dart';
import '../../domain/repositories/customer_repository.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerRepository _repository = CustomerRepository();

  // ── State ──
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  List<CustomerTransaction> _customerTransactions = [];
  final List<PointsRedemption> _redemptions = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;

  // ── Getters ──
  List<Customer> get customers => _customers;
  List<Customer> get filteredCustomers => _filteredCustomers;
  List<CustomerTransaction> get customerTransactions => _customerTransactions;
  List<PointsRedemption> get redemptions => _redemptions;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get hasData => _customers.isNotEmpty;
  String? get errorMessage => _errorMessage;

  // ── Load Customers ──
  Future<void> loadCustomers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _customers = await _repository.getCustomers();
      _filteredCustomers = List.from(_customers);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Load customers error: $e');
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
      _customers = await _repository.getCustomers();
      _filteredCustomers = List.from(_customers);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Refresh customers error: $e');
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  // ── Filter Customers ──
  void filterCustomers(String query) {
    if (query.isEmpty) {
      _filteredCustomers = List.from(_customers);
    } else {
      final lowerQuery = query.toLowerCase();
      _filteredCustomers = _customers.where((c) =>
        c.name.toLowerCase().contains(lowerQuery) ||
        c.phone.contains(query) ||
        (c.email?.toLowerCase().contains(lowerQuery) ?? false) ||
        (c.vehicleNumber?.toLowerCase().contains(lowerQuery) ?? false)
      ).toList();
    }
    notifyListeners();
  }

  // ── Filter by Tier ──
  void filterByTier(String? tierName) {
    if (tierName == null || tierName == 'all' || tierName == 'All Tiers') {
      _filteredCustomers = List.from(_customers);
    } else {
      _filteredCustomers = _customers.where((c) {
        final tierDisplayName = _getTierDisplayName(c.tier);
        return tierDisplayName.toLowerCase() == tierName.toLowerCase();
      }).toList();
    }
    notifyListeners();
  }

  // ── Helper to get tier display name ──
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

  // ── Set Filtered Customers (used by screen) ──
  void setFilteredCustomers(List<Customer> filtered) {
    _filteredCustomers = filtered;
    notifyListeners();
  }

  // ── Create Customer ──
  Future<bool> createCustomer(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.createCustomer(data);
      if (result) {
        await loadCustomers();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Create customer error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Update Customer ──
  Future<bool> updateCustomer(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.updateCustomer(id, data);
      if (result) {
        await loadCustomers();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Update customer error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Adjust Points ──
  Future<bool> adjustPoints(String id, int points) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.adjustPoints(id, points);
      if (result) {
        await loadCustomers();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Adjust points error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Redeem Points ──
  Future<bool> redeemPoints(String id, int points, {String? notes}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.redeemPoints(id, points, notes: notes);
      if (result) {
        await loadCustomers();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Redeem points error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Get Customer by ID ──
  Future<Customer?> getCustomerById(String id) async {
    try {
      return await _repository.getCustomerById(id);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Get customer by ID error: $e');
      notifyListeners();
      return null;
    }
  }

  // ── Search by Phone ──
  Future<Customer?> searchByPhone(String phone) async {
    try {
      return await _repository.searchByPhone(phone);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Search by phone error: $e');
      notifyListeners();
      return null;
    }
  }

  // ── Get Customer Transactions ──
  Future<List<CustomerTransaction>> getCustomerTransactions(String id) async {
    try {
      final result = await _repository.getCustomerTransactions(id);
      _customerTransactions = result.map((json) => 
        CustomerTransaction.fromJson(json as Map<String, dynamic>)
      ).toList();
      return _customerTransactions;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Get customer transactions error: $e');
      notifyListeners();
      return [];
    }
  }

  // ── Clear Error ──
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Reset Filters ──
  void resetFilters() {
    _filteredCustomers = List.from(_customers);
    notifyListeners();
  }
}