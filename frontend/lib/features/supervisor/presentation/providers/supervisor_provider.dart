// lib/features/supervisor/presentation/providers/supervisor_provider.dart

import 'package:flutter/material.dart';
import '../../domain/models/supervisor_session.dart';

class SupervisorProvider extends ChangeNotifier {
  SupervisorSession? _currentSession;
  bool _isLoading = false;
  String? _errorMessage;

  SupervisorSession? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void startSession(String supervisorId, String supervisorName) {
    _currentSession = SupervisorSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      supervisorId: supervisorId,
      supervisorName: supervisorName,
      startTime: DateTime.now(),
    );
    notifyListeners();
  }

  void endSession() {
    if (_currentSession != null) {
      _currentSession = SupervisorSession(
        id: _currentSession!.id,
        supervisorId: _currentSession!.supervisorId,
        supervisorName: _currentSession!.supervisorName,
        startTime: _currentSession!.startTime,
        endTime: DateTime.now(),
        interventionsCount: 0,
        isActive: false,
      );
      notifyListeners();
    }
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearErrors() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _currentSession = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}