// lib/core/services/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  // ─────────────────────────────────────────────
  // BASE URL — Production ready with environment support
  // ─────────────────────────────────────────────
  
  // Get base URL from environment variable or use default
  static String get _baseUrl {
    // For web, use the current host (works with ngrok too!)
    if (kIsWeb) {
      // Use the same host that served the page
      final host = Uri.base.origin;
      return '$host/api';
    }
    
    // For mobile, use environment variable
    return dotenv.env['API_BASE_URL'] ?? 'https://unlatch-joystick-grievance.ngrok-free.dev/api';
  }

  // ─────────────────────────────────────────────
  // Detect if running in development
  // ─────────────────────────────────────────────
  static bool get isDevelopment {
    return dotenv.env['ENVIRONMENT'] == 'development' || kDebugMode;
  }

  static const Duration _timeout = Duration(seconds: 30);
  static const _storage = FlutterSecureStorage();

  // ─────────────────────────────────────────────
  // TOKEN MANAGEMENT
  // ─────────────────────────────────────────────

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }

  static Future<void> saveUserInfo({
    required String id,
    required String name,
    required String role,
    required String username,
  }) async {
    await _storage.write(key: 'user_id', value: id);
    await _storage.write(key: 'user_name', value: name);
    await _storage.write(key: 'user_role', value: role);
    await _storage.write(key: 'username', value: username);
  }

  static Future<Map<String, String>> getUserInfo() async {
    return {
      'id': await _storage.read(key: 'user_id') ?? '',
      'name': await _storage.read(key: 'user_name') ?? '',
      'role': await _storage.read(key: 'user_role') ?? '',
      'username': await _storage.read(key: 'username') ?? '',
    };
  }

  static Future<void> clearAllStorage() async {
    await _storage.deleteAll();
  }

  // ─────────────────────────────────────────────
  // HEADERS
  // ─────────────────────────────────────────────

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, String> get _publicHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  // ─────────────────────────────────────────────
  // HTTP METHODS
  // ─────────────────────────────────────────────

  /// GET request — authenticated
  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final headers = await _authHeaders();
      final uri = Uri.parse('$_baseUrl$endpoint');

      debugPrint('GET $uri');

      final response = await http
          .get(uri, headers: headers)
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// GET request — public (no auth)
  static Future<Map<String, dynamic>> getPublic(String endpoint) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');

      debugPrint('GET (public) $uri');

      final response = await http
          .get(uri, headers: _publicHeaders)
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// POST request — authenticated
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final headers = await _authHeaders();
      final uri = Uri.parse('$_baseUrl$endpoint');

      debugPrint('POST $uri body: ${jsonEncode(body)}');

      final response = await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// POST request — no auth (for login & registration)
  static Future<Map<String, dynamic>> postPublic(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');

      debugPrint('POST (public) $uri body: ${jsonEncode(body)}');

      final response = await http
          .post(uri, headers: _publicHeaders, body: jsonEncode(body))
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// PUT request — authenticated
  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final headers = await _authHeaders();
      final uri = Uri.parse('$_baseUrl$endpoint');

      debugPrint('PUT $uri body: ${jsonEncode(body)}');

      final response = await http
          .put(uri, headers: headers, body: jsonEncode(body))
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// DELETE request — authenticated
  static Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final headers = await _authHeaders();
      final uri = Uri.parse('$_baseUrl$endpoint');

      debugPrint('DELETE $uri');

      final response = await http
          .delete(uri, headers: headers)
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ─────────────────────────────────────────────
  // RESPONSE HANDLER
  // ─────────────────────────────────────────────

  static Map<String, dynamic> _handleResponse(http.Response response) {
    debugPrint('Response [${response.statusCode}]: ${response.body}');

    if (response.body.isEmpty) {
      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'message': response.statusCode >= 200 && response.statusCode < 300 
            ? 'Success' 
            : 'An error occurred',
      };
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, ...decoded};
      }

      if (response.statusCode == 401) {
        return {
          'success': false,
          'message': decoded['message'] ?? 'Session expired. Please log in again.',
          'statusCode': 401,
        };
      }

      if (response.statusCode == 403) {
        return {
          'success': false,
          'message': decoded['message'] ?? 'You do not have permission to perform this action.',
          'statusCode': 403,
        };
      }

      if (response.statusCode == 404) {
        return {
          'success': false,
          'message': decoded['message'] ?? 'Resource not found.',
          'statusCode': 404,
        };
      }

      if (response.statusCode == 422) {
        return {
          'success': false,
          'message': decoded['message'] ?? 'Validation failed.',
          'errors': decoded['errors'],
          'statusCode': 422,
        };
      }

      return {
        'success': false,
        'message': decoded['message'] ?? 'Server error. Please try again later.',
        'statusCode': response.statusCode,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Invalid server response. Please try again.',
        'statusCode': response.statusCode,
      };
    }
  }

  // ─────────────────────────────────────────────
  // ERROR HANDLER
  // ─────────────────────────────────────────────

  static Map<String, dynamic> _handleError(dynamic error) {
    debugPrint('ApiService error: $error');

    final message = error.toString();

    if (message.contains('TimeoutException')) {
      return {
        'success': false,
        'message': 'Connection timed out. Check your internet connection.',
      };
    }

    if (message.contains('SocketException') || message.contains('Connection refused')) {
      return {
        'success': false,
        'message': isDevelopment 
            ? 'Cannot reach server. Make sure the backend is running on port 3000.'
            : 'Cannot reach server. Please check your internet connection.',
      };
    }

    if (message.contains('401')) {
      return {
        'success': false,
        'message': 'Session expired. Please login again.',
        'statusCode': 401,
      };
    }

    if (message.contains('403')) {
      return {
        'success': false,
        'message': 'You do not have permission to perform this action.',
        'statusCode': 403,
      };
    }

    return {
      'success': false,
      'message': isDevelopment 
          ? 'Error: ${error.toString()}'
          : 'An unexpected error occurred. Please try again.',
    };
  }
}