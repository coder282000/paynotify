// lib/core/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:paynotify/core/services/auth_service.dart';
import 'package:paynotify/core/services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  String? get userRole => _currentUser?['role'];
  
  // Login
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    final result = await AuthService.login(username, password);
    
    if (result['success'] == true) {
      _currentUser = result['user'];
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Load current user from storage
  Future<void> loadCurrentUser() async {
    final userInfo = await ApiService.getUserInfo();
    if (userInfo['id'] != null && userInfo['id']!.isNotEmpty) {
      _currentUser = {
        'id': int.tryParse(userInfo['id'] ?? '0'),
        'name': userInfo['name'],
        'role': userInfo['role'],
        'username': userInfo['username'],
      };
      notifyListeners();
    }
  }
  
  // Logout
  Future<void> logout() async {
    await AuthService.logout();
    _currentUser = null;
    notifyListeners();
  }
  
  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}