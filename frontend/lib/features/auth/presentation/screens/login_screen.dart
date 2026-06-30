import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:paynotify/core/services/auth_service.dart';


import 'package:paynotify/features/attendant/presentation/screens/pump_selection_screen.dart';
import 'package:paynotify/features/manager/presentation/screens/manager_dashboard.dart';
import 'package:paynotify/features/manager/presentation/providers/manager_provider.dart';
import 'package:paynotify/features/supervisor/presentation/screens/supervisor_dashboard.dart';
import 'package:paynotify/features/supervisor/presentation/providers/supervisor_provider.dart';
import 'package:paynotify/features/owner/presentation/screens/owner_dashboard.dart';
import 'package:paynotify/features/owner/presentation/providers/owner_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _login() async {
    final username = _usernameController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter username and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call backend login API
      final result = await AuthService.login(username, password);
      
      if (!mounted) return;

      if (result['success'] == true) {
        final user = result['user'];
        final role = user['role'];
        final name = user['name'];
        final id = user['id'].toString();

        if (role == 'owner') {
          // Navigate to owner dashboard
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider<OwnerProvider>(
                create: (_) => OwnerProvider(),
                child: const OwnerDashboard(),
              ),
            ),
            (route) => false,
          );
        } else if (role == 'manager') {
          // Navigate to manager dashboard
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider<ManagerProvider>(
                create: (_) => ManagerProvider(),
                child: const ManagerDashboard(),
              ),
            ),
            (route) => false,
          );
        } else if (role == 'supervisor') {
          // Initialize supervisor session
          final supervisorProvider = Provider.of<SupervisorProvider>(context, listen: false);
          supervisorProvider.startSession(id, name);
          
          // Navigate to supervisor dashboard
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => SupervisorDashboard(
                supervisorName: name,
                supervisorId: id,
              ),
            ),
            (route) => false,
          );
        } else {
          // Navigate to pump selection for attendant
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => PumpSelectionScreen(
                attendantName: name,
              ),
            ),
            (route) => false,
          );
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Login failed. Please check your credentials.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error. Please check your network and try again.';
        _isLoading = false;
      });
      debugPrint('Login error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.local_gas_station, 
                  size: 100, 
                  color: Color(0xFF0B3D2E)
                ),
                const SizedBox(height: 24),
                const Text(
                  'PayNotify', 
                  style: TextStyle(
                    fontSize: 32, 
                    fontWeight: FontWeight.bold, 
                    color: Color(0xFF0B3D2E)
                  )
                ),
                const SizedBox(height: 6),
                const Text(
                  'Petrol Station Payment Assistant', 
                  style: TextStyle(
                    fontSize: 14, 
                    color: Colors.grey
                  )
                ),
                const SizedBox(height: 32),
                
                // Username Field
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () => FocusScope.of(context).nextFocus(),
                ),
                const SizedBox(height: 12),
                
                // Password Field
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                ),
                
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!, 
                    style: const TextStyle(color: Colors.red, fontSize: 13)
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Login Button
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B3D2E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Login', 
                            style: TextStyle(fontSize: 16, color: Colors.white)
                          ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Demo Accounts Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Demo Accounts',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '👑 Owner: owner / owner123',
                        style: TextStyle(fontSize: 11, color: Color(0xFF9B59B6)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '👔 Manager: manager / manager123',
                        style: TextStyle(fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '🛡️ Supervisors: supervisor1/super123, supervisor2/super456, mike/super789',
                        style: TextStyle(fontSize: 11, color: Color(0xFF9C27B0)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '⛽ Attendants: john/pump1, mary/pump2, peter/pump3, grace/pump4',
                        style: TextStyle(fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '✓ Connected to Backend API',
                          style: TextStyle(fontSize: 10, color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}