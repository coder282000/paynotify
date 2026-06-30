// lib/core/services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class AuthService {
  // ─────────────────────────────────────────────
  // LOGIN
  // ─────────────────────────────────────────────

  /// Calls POST /api/auth/login
  /// Returns: { success, user, message }
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final response = await ApiService.postPublic('/auth/login', {
      'username': username.trim(),
      'password': password,
    });

    if (response['success'] == true) {
      // ✅ FIX: Extract from 'data' object (backend response structure)
      final data = response['data'] as Map<String, dynamic>?;
      final token = data?['token'] as String?;
      final user = data?['user'] as Map<String, dynamic>?;

      if (token == null || user == null) {
        debugPrint('Login failed: Missing token or user in response');
        debugPrint('Response structure: $response');
        return {
          'success': false,
          'message': 'Invalid response from server.',
        };
      }

      // Persist token and user info in secure storage
      await ApiService.saveToken(token);
      await ApiService.saveUserInfo(
        id: user['id']?.toString() ?? '',
        name: user['fullName']?.toString() ?? user['username']?.toString() ?? '',
        role: user['role']?.toString() ?? '',
        username: user['username']?.toString() ?? '',
      );

      debugPrint('Login success: ${user['username']} (${user['role']})');

      return {
        'success': true,
        'user': user,
        'token': token,
      };
    }

    // Login failed
    return {
      'success': false,
      'message': response['message'] ?? 'Login failed. Check your credentials.',
    };
  }

  // ─────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────

  /// Calls POST /api/auth/logout then clears local storage
  static Future<void> logout() async {
    try {
      // Tell the backend to invalidate the session
      await ApiService.post('/auth/logout', {});
    } catch (e) {
      // Even if the server call fails, clear local storage
      debugPrint('Logout server call failed: $e');
    } finally {
      await ApiService.clearAllStorage();
      debugPrint('Local session cleared');
    }
  }

  // ─────────────────────────────────────────────
  // GET CURRENT USER
  // ─────────────────────────────────────────────

  /// Calls GET /api/auth/me to verify the token is still valid
  /// and refresh user data from server
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await ApiService.get('/auth/me');

    if (response['success'] == true) {
      // ✅ FIX: Extract from 'data' object
      final user = response['data'] as Map<String, dynamic>?;
      if (user != null) {
        // Refresh stored user info
        await ApiService.saveUserInfo(
          id: user['id']?.toString() ?? '',
          name: user['fullName']?.toString() ?? user['username']?.toString() ?? '',
          role: user['role']?.toString() ?? '',
          username: user['username']?.toString() ?? '',
        );
      }
      return {'success': true, 'user': user};
    }

    return {
      'success': false,
      'message': response['message'] ?? 'Failed to fetch user.',
    };
  }

  // ─────────────────────────────────────────────
  // SESSION CHECK
  // ─────────────────────────────────────────────

  /// Checks if a token exists in storage (fast, offline check)
  static Future<bool> isLoggedIn() async {
    final token = await ApiService.getToken();
    return token != null && token.isNotEmpty;
  }

  /// Full session check: token exists AND is still valid on server
  static Future<bool> isSessionValid() async {
    final hasToken = await isLoggedIn();
    if (!hasToken) return false;

    final result = await getCurrentUser();
    return result['success'] == true;
  }
}