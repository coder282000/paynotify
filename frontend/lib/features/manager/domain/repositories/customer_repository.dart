// lib/features/manager/domain/repositories/customer_repository.dart

import '../../../../core/services/api_service.dart';
import '../models/customer_model.dart';

class CustomerRepository {
  // ── Get All Customers ──
  Future<List<Customer>> getCustomers() async {
    try {
      final response = await ApiService.get('/manager/customers');
      
      if (response['success'] == true) {
        final data = response['data'] as List;
        return data.map((json) => Customer.fromBackendJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load customers: $e');
    }
  }

  // ── Search Customer by Phone ──
  Future<Customer?> searchByPhone(String phone) async {
    try {
      final response = await ApiService.get('/manager/customers/search?phone=$phone');
      
      if (response['success'] == true && response['found'] == true) {
        return Customer.fromBackendJson(response['data']);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to search customer: $e');
    }
  }

  // ── Get Customer by ID ──
  Future<Customer> getCustomerById(String id) async {
    try {
      final response = await ApiService.get('/manager/customers/$id');
      
      if (response['success'] == true) {
        return Customer.fromBackendJson(response['data']);
      }
      throw Exception('Customer not found');
    } catch (e) {
      throw Exception('Failed to get customer: $e');
    }
  }

  // ── Create Customer ──
  Future<bool> createCustomer(Map<String, dynamic> data) async {
    try {
      final response = await ApiService.post('/manager/customers', data);
      return response['success'] == true;
    } catch (e) {
      throw Exception('Failed to create customer: $e');
    }
  }

  // ── Update Customer ──
  Future<bool> updateCustomer(String id, Map<String, dynamic> data) async {
    try {
      final response = await ApiService.put('/manager/customers/$id', data);
      return response['success'] == true;
    } catch (e) {
      throw Exception('Failed to update customer: $e');
    }
  }

  // ── Adjust Points ──
  Future<bool> adjustPoints(String id, int points) async {
    try {
      final response = await ApiService.put('/manager/customers/$id/points', {
        'points': points,
      });
      return response['success'] == true;
    } catch (e) {
      throw Exception('Failed to adjust points: $e');
    }
  }

  // ── Redeem Points ──
  Future<bool> redeemPoints(String id, int points, {String? notes}) async {
    try {
      final response = await ApiService.post('/manager/customers/$id/redeem', {
        'points': points,
        'notes': notes,
      });
      return response['success'] == true;
    } catch (e) {
      throw Exception('Failed to redeem points: $e');
    }
  }

  // ── Get Customer Transactions ──
  Future<List<dynamic>> getCustomerTransactions(String id) async {
    try {
      final response = await ApiService.get('/manager/customers/$id/transactions');
      
      if (response['success'] == true) {
        return response['data'] as List;
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get customer transactions: $e');
    }
  }
}