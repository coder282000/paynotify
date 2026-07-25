// lib/features/manager/domain/repositories/customer_repository.dart
//
// NOTE: Endpoints intentionally point at `/customers`, NOT
// `/manager/customers`. Both technically route to the same
// customerController.js functions today (managerRoutes.js has a
// redundant nested copy), but `/manager/*` is restricted to
// role === 'manager' only — it would 403 for owners, and would also
// 403 for attendants/supervisors if this repository is later reused
// by the point-of-sale customer picker (search/create are explicitly
// allowed for those roles on `/customers`, not on `/manager/customers`).

import '../../../../core/services/api_service.dart';
import '../models/customer_model.dart';

class CustomerRepository {
  // ── Get All Customers ──
  Future<List<Customer>> getCustomers() async {
    try {
      final response = await ApiService.get('/customers');

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
  // Available to attendant/supervisor/manager/owner on the backend —
  // this is the point-of-sale lookup used before linking a sale.
  Future<Customer?> searchByPhone(String phone) async {
    try {
      final encodedPhone = Uri.encodeQueryComponent(phone);
      final response = await ApiService.get('/customers/search?phone=$encodedPhone');

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
      final response = await ApiService.get('/customers/$id');

      if (response['success'] == true) {
        return Customer.fromBackendJson(response['data']);
      }
      throw Exception('Customer not found');
    } catch (e) {
      throw Exception('Failed to get customer: $e');
    }
  }

  // ── Create Customer ──
  // Available to attendant/supervisor/manager/owner on the backend —
  // lets an attendant register a walk-in customer on the spot so the
  // current sale can start earning points immediately.
  Future<bool> createCustomer(Map<String, dynamic> data) async {
    try {
      final response = await ApiService.post('/customers', data);
      return response['success'] == true;
    } catch (e) {
      throw Exception('Failed to create customer: $e');
    }
  }

  // ── Update Customer ──
  Future<bool> updateCustomer(String id, Map<String, dynamic> data) async {
    try {
      final response = await ApiService.put('/customers/$id', data);
      return response['success'] == true;
    } catch (e) {
      throw Exception('Failed to update customer: $e');
    }
  }

  // ── Adjust Points ──
  // Manual add/subtract (promotional bonus or correction). Logged
  // server-side as type='adjustment' — distinct from points earned via
  // a real sale (type='earned') or a genuine redemption (type='redeemed').
  Future<bool> adjustPoints(String id, int points) async {
    try {
      final response = await ApiService.put('/customers/$id/points', {
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
      final response = await ApiService.post('/customers/$id/redeem', {
        'points': points,
        'notes': ?notes,
      });
      return response['success'] == true;
    } catch (e) {
      throw Exception('Failed to redeem points: $e');
    }
  }

  // ── Get Customer Transactions ──
  // Merged purchase + redemption history (see customerController's
  // getCustomerTransactions — camelCase response shape).
  Future<List<dynamic>> getCustomerTransactions(String id) async {
    try {
      final response = await ApiService.get('/customers/$id/transactions');

      if (response['success'] == true) {
        return response['data'] as List;
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get customer transactions: $e');
    }
  }
}