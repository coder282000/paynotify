// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:paynotify/features/auth/presentation/screens/login_screen.dart';
import 'package:paynotify/features/auth/presentation/screens/registration_screen.dart';
import 'package:paynotify/features/attendant/presentation/screens/attendant_dashboard.dart';
import 'package:paynotify/features/supervisor/presentation/screens/supervisor_dashboard.dart';
import 'package:paynotify/features/manager/presentation/screens/manager_dashboard.dart';
import 'package:paynotify/features/owner/presentation/screens/owner_dashboard.dart';
import 'package:paynotify/core/providers/auth_provider.dart';
import 'package:paynotify/features/manager/presentation/providers/manager_provider.dart';
import 'package:paynotify/features/manager/presentation/providers/customer_provider.dart'; // ✅ NEW: Import CustomerProvider

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  usePathUrlStrategy(); // ✅ NEW — makes web URLs like /register?token=... work without a #

  // Load .env file
  await dotenv.load();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ManagerProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()), // ✅ NEW: Add CustomerProvider
      ],
      child: MaterialApp(
        title: 'PayNotify',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        initialRoute: '/',
        onGenerateRoute: (settings) {
          // Handle registration screen with token parameter
          // settings.name includes the full path + query string on web,
          // e.g. "/register?token=ABC123" — so match by prefix, then
          // parse the token out of the query string ourselves.
          if (settings.name != null && settings.name!.startsWith('/register')) {
            final uri = Uri.parse(settings.name!);
            final token = uri.queryParameters['token'];
            return MaterialPageRoute(
              builder: (context) => RegistrationScreen(token: token ?? ''),
            );
          }

          // Handle attendant dashboard with required parameters
          if (settings.name == '/attendant-dashboard') {
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => AttendantDashboard(
                selectedPump: args?['selectedPump'] ?? 'Pump 1',
                attendantName: args?['attendantName'] ?? 'Attendant',
              ),
            );
          }

          // Handle supervisor dashboard with required parameters
          if (settings.name == '/supervisor-dashboard') {
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => SupervisorDashboard(
                supervisorName: args?['name'],
                supervisorId: args?['id'],
              ),
            );
          }

          // Handle manager dashboard
          if (settings.name == '/manager-dashboard') {
            return MaterialPageRoute(
              builder: (context) => const ManagerDashboard(),
            );
          }

          // Handle owner dashboard
          if (settings.name == '/owner-dashboard') {
            return MaterialPageRoute(
              builder: (context) => const OwnerDashboard(),
            );
          }

          return null;
        },
        routes: {
          '/': (context) => const LoginScreen(),
          '/login': (context) => const LoginScreen(),
        },
      ),
    );
  }
}