// lib/features/manager/presentation/screens/manager_dashboard.dart

import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/manager_provider.dart';
import '../widgets/kpi_cards.dart';
import '../widgets/quick_actions.dart' as quick;
import '../widgets/alerts_section.dart' as alerts;
import '../widgets/pump_status_table.dart';
import '../widgets/recent_transactions_table.dart';
import '../widgets/sales_chart.dart';
import 'pump_management_screen.dart';
import 'employee_management_screen.dart';
import 'shift_report_screen.dart';
import 'reconciliation_screen.dart';
import 'attendant_performance_screen.dart';
import 'transaction_history_screen.dart';
import 'expense_tracking_screen.dart';
import 'customer_insight_screen.dart';
import 'station_settings_screen.dart';
import 'shift_configuration_screen.dart';
import 'notification_point_screen.dart';
import 'sales_analytics_screen.dart';
import 'fuel_inventory_screen.dart';
import '../../../shared/screens/ai_assistant_screen.dart';
import '../../../auth/presentation/screens/login_screen.dart'; // Added import for LoginScreen

// MARK: - Constants
class _DashboardConstants {
  static const double tabletBreakpoint = 600;
  static const double desktopBreakpoint = 900;
  static const Duration animationDuration = Duration(milliseconds: 400);
  static const Curve animationCurve = Curves.easeInOutCubic;
  static const double sidebarExpandedWidth = 260;
  static const double sidebarCollapsedWidth = 80;
  static const double defaultPadding = 24.0;
  static const double compactPadding = 16.0;
  
  static const Color primaryDark = Color(0xFF0B3D2E);
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color warningOrange = Color(0xFFF39C12);
  static const Color errorRed = Color(0xFFE74C3C);
  
  static const TextStyle headerStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );
  
  static const TextStyle subheaderStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );
}

enum _DashboardState { initial, loading, success, error, empty }

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> 
    with SingleTickerProviderStateMixin {
  
  DateTime _selectedDate = DateTime.now();
  _DashboardState _dashboardState = _DashboardState.initial;
  bool _isSidebarCollapsed = false;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  
  late final AnimationController _animationController;
  late final Animation<double> _widthAnimation;
  late final Animation<double> _opacityAnimation;
  
  Timer? _searchDebounce;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSidebarPreference();
    _loadDashboardData();
  }
  
  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: _DashboardConstants.animationDuration,
    );
    
    _widthAnimation = Tween<double>(
      begin: _DashboardConstants.sidebarExpandedWidth,
      end: _DashboardConstants.sidebarCollapsedWidth,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: _DashboardConstants.animationCurve,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));
  }
  
  Future<void> _loadSidebarPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final collapsed = prefs.getBool('sidebar_collapsed') ?? false;
      if (mounted) {
        setState(() {
          _isSidebarCollapsed = collapsed;
          if (_isSidebarCollapsed) _animationController.value = 1.0;
        });
      }
    } catch (e) {
      debugPrint('Failed to load sidebar preference: $e');
    }
  }
  
  Future<void> _saveSidebarPreference(bool collapsed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sidebar_collapsed', collapsed);
    } catch (e) {
      debugPrint('Failed to save sidebar preference: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // MARK: - Logout Method
  void _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _DashboardConstants.errorRed,
            ),
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );
    
    if (shouldLogout == true && mounted) {
      // Navigate back to login screen and clear all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      
      // Show logout confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully'),
          backgroundColor: _DashboardConstants.accentGreen,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // MARK: - Navigation Methods
  void _navigateToPumpManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PumpManagementScreen(),
      ),
    ).then((_) {
      if (mounted) {
        _loadDashboardData();
      }
    });
  }

  void _navigateToEmployeeManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmployeeManagementScreen(),
      ),
    ).then((_) {
      if (mounted) {
        _loadDashboardData();
      }
    });
  }

  void _navigateToShiftReports() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ShiftReportsScreen(),
      ),
    ).then((_) {
      if (mounted) {
        _loadDashboardData();
      }
    });
  }

  void _navigateToReconciliation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReconciliationScreen(),
      ),
    ).then((_) {
      if (mounted) {
        _loadDashboardData();
      }
    });
  }

  void _navigateToTransactionHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TransactionHistoryScreen(),
      ),
    ).then((_) {
      if (mounted) {
        _loadDashboardData();
      }
    });
  }

  void _navigateToAttendantPerformance() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AttendantPerformanceScreen(),
      ),
    ).then((_) {
      if (mounted) {
        _loadDashboardData();
      }
    });
  }

  void _navigateToExpenseTracking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ExpenseTrackingScreen(),
      ),
    ).then((_) {
      if (mounted) {
        _loadDashboardData();
      }
    });
  }

  void _navigateToCustomerInsight() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomerInsightScreen(),
      ),
    ).then((_) {
      if (mounted) {
        _loadDashboardData();
      }
    });
  }

  void _navigateToStationSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StationSettingsScreen(),
      ),
    ).then((_) {
      if (mounted) {
        _loadDashboardData();
      }
    });
  }

  void _navigateToShiftConfiguration() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ShiftConfigurationScreen(),
      ),
    ).then((_) {
      if (mounted) {
        _loadDashboardData();
      }
    });
  }

  void _navigateToNotificationPoint() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationPointScreen(),
      ),
    ).then((_) {
      if (mounted) {
        _loadDashboardData();
      }
    });
  }

  void _navigateToSalesAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SalesAnalyticsScreen(),
      ),
    ).then((_) {
      if (mounted) {
        _loadDashboardData();
      }
    });
  }

  void _navigateToFuelInventory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FuelInventoryScreen(),
      ),
    ).then((_) {
      if (mounted) {
        _loadDashboardData();
      }
    });
  }

  void _navigateToAIAssistant() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AIAssistantScreen(
          isManager: true,
          managerName: 'Manager',
        ),
      ),
    ).then((_) {
      if (mounted) {
        _loadDashboardData();
      }
    });
  }

  // MARK: - Data Loading with Error Handling
  Future<void> _loadDashboardData({bool showLoader = true}) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (!mounted) return;
      
      if (connectivityResult.contains(ConnectivityResult.none) && 
          connectivityResult.length == 1) {
        setState(() {
          _dashboardState = _DashboardState.error;
          _errorMessage = 'No internet connection. Please check your network.';
        });
        _showErrorSnackBar(_errorMessage!);
        return;
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('Connectivity check error: $e');
    }

    if (showLoader && mounted) {
      setState(() => _dashboardState = _DashboardState.loading);
    }
    
    try {
      final provider = context.read<ManagerProvider>();
      
      await provider.loadDashboardData(_selectedDate).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Request timed out'),
      );
      
      if (!mounted) return;
      
      setState(() {
        _dashboardState = provider.hasData 
            ? _DashboardState.success 
            : _DashboardState.empty;
        _errorMessage = null;
      });
      
      if (showLoader) HapticFeedback.lightImpact();
      
    } catch (e, stackTrace) {
      if (!mounted) return;
      
      debugPrint('Dashboard load error: $e\n$stackTrace');
      
      setState(() {
        _dashboardState = _DashboardState.error;
        _errorMessage = _getErrorMessage(e);
      });
      
      if (showLoader) _showErrorSnackBar(_errorMessage!);
    }
  }
  
  String _getErrorMessage(dynamic error) {
    if (error is TimeoutException) {
      return 'Connection timed out. Please check your internet and try again.';
    }
    if (error.toString().contains('SocketException') || 
        error.toString().contains('NetworkIsUnreachable')) {
      return 'No internet connection. Please connect to a network and retry.';
    }
    if (error.toString().contains('Unauthorized') || 
        error.toString().contains('401')) {
      return 'Session expired. Please log in again.';
    }
    return 'Failed to load dashboard data. Please try again.';
  }
  
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _DashboardConstants.errorRed,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () => _loadDashboardData(),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _DashboardConstants.primaryDark,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate && mounted) {
      setState(() => _selectedDate = picked);
      await _loadDashboardData();
    }
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
    });
    
    if (_isSidebarCollapsed) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    
    _saveSidebarPreference(_isSidebarCollapsed);
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      context.read<ManagerProvider>().filterTransactions(query);
    });
  }

  Future<void> _exportTransactions() async {
    final provider = context.read<ManagerProvider>();
    
    try {
      final List<List<dynamic>> csvData = [
        ['ID', 'Date', 'Time', 'Pump', 'Attendant', 'Amount', 'Method', 'Status'],
        ...provider.recentTransactions.map((txn) => [
          txn.id,
          DateFormat('yyyy-MM-dd').format(txn.time),
          DateFormat('HH:mm').format(txn.time),
          txn.pump,
          txn.attendant,
          txn.amount.toString(),
          txn.type,
          txn.status,
        ]),
      ];
      
      final String csv = const ListToCsvConverter().convert(csvData);
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath = '${tempDir.path}/transactions_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      
      final File file = File(filePath);
      await file.writeAsString(csv);
      
      if (!mounted) return;
      
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'PayNotifyy Transaction Report - ${DateFormat('MMM d, yyyy').format(_selectedDate)}',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export successful!'),
            backgroundColor: _DashboardConstants.accentGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Export error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: _DashboardConstants.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildAIFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _navigateToAIAssistant,
      backgroundColor: _DashboardConstants.accentGreen,
      foregroundColor: Colors.white,
      tooltip: 'AI Assistant',
      elevation: 4,
      child: const Icon(Icons.smart_toy, size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManagerProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > _DashboardConstants.desktopBreakpoint;
    final isTablet = screenWidth > _DashboardConstants.tabletBreakpoint && 
                     screenWidth <= _DashboardConstants.desktopBreakpoint;
    
    return Scaffold(
      appBar: !isDesktop ? _buildMobileAppBar() : null,
      drawer: !isDesktop ? _buildDrawer() : null,
      backgroundColor: Colors.grey.shade50,
      body: Row(
        children: [
          if (isDesktop) RepaintBoundary(child: _buildAnimatedSidebar()),
          Expanded(
            child: _buildMainContent(provider, isDesktop, isTablet),
          ),
        ],
      ),
      floatingActionButton: _buildAIFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
  
  Widget _buildMainContent(ManagerProvider provider, bool isDesktop, bool isTablet) {
    if (_dashboardState == _DashboardState.loading) {
      return _buildLoadingState(isDesktop, isTablet);
    }
    if (_dashboardState == _DashboardState.error) {
      return _buildErrorState();
    }
    if (_dashboardState == _DashboardState.empty) {
      return _buildEmptyState();
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        if (!mounted) return;
        HapticFeedback.mediumImpact();
        await _loadDashboardData();
      },
      color: _DashboardConstants.primaryDark,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 
            _DashboardConstants.defaultPadding : 
            _DashboardConstants.compactPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDesktop, isTablet),
            const SizedBox(height: 24),
            KpiCards(summary: provider.stationSummary, isDesktop: isDesktop, isTablet: isTablet),
            const SizedBox(height: 24),
            quick.QuickActions(onRefresh: _loadDashboardData, isDesktop: isDesktop, isTablet: isTablet),
            const SizedBox(height: 24),
            if (provider.hasAlerts) ...[
              alerts.AlertsSection(alerts: provider.alerts, isDesktop: isDesktop, isTablet: isTablet),
              const SizedBox(height: 24),
            ],
            if (isDesktop || isTablet) ...[
              Text('Sales Overview', style: _DashboardConstants.subheaderStyle),
              const SizedBox(height: 16),
              SalesChart(
                data: provider.salesData,
                height: isDesktop ? 300 : 250,
              ),
              const SizedBox(height: 24),
            ],
            if (isDesktop)
              _buildDesktopContent(provider)
            else if (isTablet)
              _buildTabletContent(provider)
            else
              _buildMobileContent(provider),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLoadingState(bool isDesktop, bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 
          _DashboardConstants.defaultPadding : 
          _DashboardConstants.compactPadding),
      child: Column(
        children: [
          _skeletonLoader(height: 60, width: double.infinity),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: List.generate(
              4,
              (_) => _skeletonLoader(
                width: (MediaQuery.of(context).size.width - 
                    (isDesktop ? 120 : 80)) / (isDesktop ? 4 : 2),
                height: 100,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _skeletonLoader(height: 80, width: double.infinity),
          const SizedBox(height: 24),
          if (isDesktop || isTablet) ...[
            _skeletonLoader(height: 300, width: double.infinity),
            const SizedBox(height: 24),
          ],
          _skeletonLoader(height: 200, width: double.infinity),
        ],
      ),
    );
  }
  
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text('Connection Issue', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_errorMessage ?? 'Unable to load dashboard data', 
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _loadDashboardData(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _DashboardConstants.primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_gas_station_outlined, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text('No Data for Selected Date', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Transactions for ${DateFormat('MMM d, yyyy').format(_selectedDate)} will appear here once attendants start their shifts.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(onPressed: _selectDate, icon: const Icon(Icons.calendar_today), label: const Text('Change Date')),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _loadDashboardData(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(backgroundColor: _DashboardConstants.primaryDark, foregroundColor: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildMobileAppBar() {
    return AppBar(
      title: const Text('Manager Dashboard'),
      backgroundColor: _DashboardConstants.primaryDark,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(icon: const Icon(Icons.calendar_today_outlined), onPressed: _selectDate, tooltip: 'Select Date', constraints: const BoxConstraints(minWidth: 48, minHeight: 48)),
        IconButton(icon: const Icon(Icons.refresh_outlined), onPressed: () => _loadDashboardData(), tooltip: 'Refresh Data', constraints: const BoxConstraints(minWidth: 48, minHeight: 48)),
      ],
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: Container(
        color: _DashboardConstants.primaryDark,
        child: Column(
          children: [
            _buildDrawerHeader(),
            Expanded(child: ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
              _buildDrawerItem(Icons.dashboard, 'Dashboard', isSelected: true),
              _buildDrawerItem(Icons.local_gas_station, 'Pump Management'),
              _buildDrawerItem(Icons.people, 'Employees'),
              _buildDrawerItem(Icons.receipt_long, 'Shift Reports'),
              _buildDrawerItem(Icons.account_balance_wallet, 'Reconciliation'),
              _buildDrawerItem(Icons.history, 'Transaction History'),
              _buildDrawerItem(Icons.bar_chart, 'Attendant Performance'),
              _buildDrawerItem(Icons.money_off, 'Expense Tracking'),
              _buildDrawerItem(Icons.people_alt, 'Customer Insight'),
              _buildDrawerItem(Icons.settings, 'Station Settings'),
              _buildDrawerItem(Icons.schedule, 'Shift Configuration'),
              _buildDrawerItem(Icons.notifications, 'Notifications'),
              _buildDrawerItem(Icons.analytics, 'Sales Analytics'),
              _buildDrawerItem(Icons.inventory, 'Fuel Inventory'),
              _buildDrawerItem(Icons.smart_toy, 'AI Assistant'),
            ])),
            _buildDrawerFooter(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDrawerHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withAlpha(26), shape: BoxShape.circle), child: const Icon(Icons.local_gas_station, color: Colors.white, size: 40)),
          const SizedBox(height: 16),
          const Text('PayNotifyy', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('Manager Dashboard', style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
  
  Widget _buildDrawerItem(IconData icon, String label, {bool isSelected = false}) {
    return Semantics(
      button: true, 
      selected: isSelected, 
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        leading: Icon(icon, color: isSelected ? Colors.white : Colors.white70, size: 24),
        title: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, fontSize: 15)),
        selected: isSelected,
        selectedTileColor: Colors.white.withAlpha(26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minLeadingWidth: 24,
        onTap: () {
          Navigator.pop(context); // Close drawer
          switch (label) {
            case 'Pump Management':
              _navigateToPumpManagement();
              break;
            case 'Employees':
              _navigateToEmployeeManagement();
              break;
            case 'Shift Reports':
              _navigateToShiftReports();
              break;
            case 'Reconciliation':
              _navigateToReconciliation();
              break;
            case 'Transaction History':
              _navigateToTransactionHistory();
              break;
            case 'Attendant Performance':
              _navigateToAttendantPerformance();
              break;
            case 'Expense Tracking':
              _navigateToExpenseTracking();
              break;
            case 'Customer Insight':
              _navigateToCustomerInsight();
              break;
            case 'Station Settings':
              _navigateToStationSettings();
              break;
            case 'Shift Configuration':
              _navigateToShiftConfiguration();
              break;
            case 'Notifications':
              _navigateToNotificationPoint();
              break;
            case 'Sales Analytics':
              _navigateToSalesAnalytics();
              break;
            case 'Fuel Inventory':
              _navigateToFuelInventory();
              break;
            case 'AI Assistant':
              _navigateToAIAssistant();
              break;
            case 'Dashboard':
              // Already on dashboard
              break;
            default:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label coming soon'),
                  duration: const Duration(seconds: 1),
                ),
              );
          }
        },
      ),
    );
  }
  
  // Updated Drawer Footer with working logout button
  Widget _buildDrawerFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withAlpha(51)),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: _DashboardConstants.primaryDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Manager', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                Text('Main Station', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Semantics(
            label: 'Log out',
            child: IconButton(
              icon: Icon(Icons.logout_outlined, color: Colors.white.withAlpha(179), size: 20),
              onPressed: _logout,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSidebar() {
    return AnimatedBuilder(animation: _animationController, builder: (context, child) {
      return Container(
        width: _widthAnimation.value,
        color: _DashboardConstants.primaryDark,
        child: Column(
          children: [
            _buildAnimatedLogo(),
            _buildAnimatedToggleButton(),
            Expanded(child: ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
              _buildAnimatedNavItem(Icons.dashboard, 'Dashboard', isSelected: true),
              _buildAnimatedNavItem(Icons.local_gas_station, 'Pump Management'),
              _buildAnimatedNavItem(Icons.people, 'Employees'),
              _buildAnimatedNavItem(Icons.receipt_long, 'Shift Reports'),
              _buildAnimatedNavItem(Icons.account_balance_wallet, 'Reconciliation'),
              _buildAnimatedNavItem(Icons.history, 'Transaction History'),
              _buildAnimatedNavItem(Icons.bar_chart, 'Attendant Performance'),
              _buildAnimatedNavItem(Icons.money_off, 'Expense Tracking'),
              _buildAnimatedNavItem(Icons.people_alt, 'Customer Insight'),
              _buildAnimatedNavItem(Icons.settings, 'Station Settings'),
              _buildAnimatedNavItem(Icons.schedule, 'Shift Configuration'),
              _buildAnimatedNavItem(Icons.notifications, 'Notifications'),
              _buildAnimatedNavItem(Icons.analytics, 'Sales Analytics'),
              _buildAnimatedNavItem(Icons.inventory, 'Fuel Inventory'),
              _buildAnimatedNavItem(Icons.smart_toy, 'AI Assistant'),
            ])),
            _buildAnimatedUserInfo(),
          ],
        ),
      );
    });
  }
  
  Widget _buildAnimatedLogo() {
    return Container(
      padding: EdgeInsets.all(_isSidebarCollapsed ? 12 : 24),
      child: Row(
        children: [
          AnimatedContainer(duration: _DashboardConstants.animationDuration, curve: Curves.easeInOut, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withAlpha(26), shape: BoxShape.circle), child: AnimatedSwitcher(duration: const Duration(milliseconds: 300), transitionBuilder: (Widget child, Animation<double> animation) => ScaleTransition(scale: animation, child: child), child: Icon(Icons.local_gas_station, key: ValueKey<bool>(_isSidebarCollapsed), color: Colors.white, size: _isSidebarCollapsed ? 30 : 40))),
          if (!_isSidebarCollapsed) ...[
            const SizedBox(width: 12),
            Expanded(child: ExcludeSemantics(child: FadeTransition(opacity: _opacityAnimation, child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('PayNotifyy', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), Text('Manager', style: TextStyle(color: Colors.white70, fontSize: 14))])))),
          ],
        ],
      ),
    );
  }
  
  Widget _buildAnimatedToggleButton() {
    return Container(alignment: Alignment.centerRight, padding: const EdgeInsets.symmetric(horizontal: 8), child: Semantics(label: _isSidebarCollapsed ? 'Expand sidebar' : 'Collapse sidebar', child: IconButton(icon: AnimatedRotation(duration: _DashboardConstants.animationDuration, turns: _isSidebarCollapsed ? 0.5 : 0, child: Icon(Icons.chevron_left, color: Colors.white70, size: 24)), onPressed: _toggleSidebar, tooltip: _isSidebarCollapsed ? 'Expand' : 'Collapse', constraints: const BoxConstraints(minWidth: 40, minHeight: 40))));
  }
  
  Widget _buildAnimatedNavItem(IconData icon, String label, {bool isSelected = false}) {
    return Semantics(
      button: true, 
      selected: isSelected, 
      label: '$label${isSelected ? ", current page" : ""}', 
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), 
        decoration: isSelected ? BoxDecoration(color: Colors.white.withAlpha(26), borderRadius: BorderRadius.circular(8)) : null, 
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: _isSidebarCollapsed ? 16 : 24, vertical: 4), 
          leading: Icon(icon, color: isSelected ? Colors.white : Colors.white70, size: _isSidebarCollapsed ? 28 : 24, semanticLabel: label), 
          title: _isSidebarCollapsed ? null : ExcludeSemantics(child: FadeTransition(opacity: _opacityAnimation, child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, fontSize: 14)))), 
          minLeadingWidth: 24, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), 
          onTap: () {
            switch (label) {
              case 'Pump Management':
                _navigateToPumpManagement();
                break;
              case 'Employees':
                _navigateToEmployeeManagement();
                break;
              case 'Shift Reports':
                _navigateToShiftReports();
                break;
              case 'Reconciliation':
                _navigateToReconciliation();
                break;
              case 'Transaction History':
                _navigateToTransactionHistory();
                break;
              case 'Attendant Performance':
                _navigateToAttendantPerformance();
                break;
              case 'Expense Tracking':
                _navigateToExpenseTracking();
                break;
              case 'Customer Insight':
                _navigateToCustomerInsight();
                break;
              case 'Station Settings':
                _navigateToStationSettings();
                break;
              case 'Shift Configuration':
                _navigateToShiftConfiguration();
                break;
              case 'Notifications':
                _navigateToNotificationPoint();
                break;
              case 'Sales Analytics':
                _navigateToSalesAnalytics();
                break;
              case 'Fuel Inventory':
                _navigateToFuelInventory();
                break;
              case 'AI Assistant':
                _navigateToAIAssistant();
                break;
              case 'Dashboard':
                // Already on dashboard
                break;
              default:
                if (_isSidebarCollapsed && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Opening $label'), 
                      duration: const Duration(milliseconds: 1000), 
                      behavior: SnackBarBehavior.floating, 
                      margin: const EdgeInsets.all(16), 
                      width: 200
                    )
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$label coming soon'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
            }
          }
        )
      )
    );
  }
  
  // Updated Animated User Info with working logout button
  Widget _buildAnimatedUserInfo() {
    return Container(
      padding: EdgeInsets.all(_isSidebarCollapsed ? 12 : 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withAlpha(51)),
        ),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: _DashboardConstants.animationDuration,
            curve: Curves.easeInOut,
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: _DashboardConstants.primaryDark, size: 18),
            ),
          ),
          if (!_isSidebarCollapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: ExcludeSemantics(
                child: FadeTransition(
                  opacity: _opacityAnimation,
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Manager', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      Text('Main Station', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
            ExcludeSemantics(
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: Semantics(
                  label: 'Log out',
                  child: IconButton(
                    icon: Icon(Icons.logout_outlined, color: Colors.white70, size: 20),
                    onPressed: _logout,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDesktop, bool isTablet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Text('Welcome back, Manager!', style: _DashboardConstants.headerStyle.copyWith(fontSize: isDesktop ? 28 : (isTablet ? 26 : 24))), 
              const SizedBox(height: 4), 
              Text(DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate), style: TextStyle(color: Colors.grey.shade600, fontSize: isDesktop ? 16 : 14))
            ]
          )
        ), 
        Row(
          mainAxisSize: MainAxisSize.min, 
          children: [
            if (isDesktop) _buildSearchField(), 
            IconButton(icon: const Icon(Icons.calendar_today_outlined), onPressed: _selectDate, tooltip: 'Select Date', constraints: const BoxConstraints(minWidth: 48, minHeight: 48)), 
            IconButton(icon: const Icon(Icons.refresh_outlined), onPressed: () => _loadDashboardData(), tooltip: 'Refresh Data', constraints: const BoxConstraints(minWidth: 48, minHeight: 48))
          ]
        )
      ]
    );
  }
  
  Widget _buildSearchField() {
    return Container(
      width: 240, 
      margin: const EdgeInsets.only(right: 8), 
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)), 
      child: TextField(
        controller: _searchController, 
        decoration: InputDecoration(
          hintText: 'Search transactions...', 
          hintStyle: TextStyle(color: Colors.grey.shade500), 
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500), 
          border: InputBorder.none, 
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), 
          isDense: true
        ), 
        onChanged: _onSearchChanged, 
        textInputAction: TextInputAction.search
      )
    );
  }

  Widget _buildDesktopContent(ManagerProvider provider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        Expanded(
          flex: 6, 
          child: Column(
            children: [
              Text('Pump Status', style: _DashboardConstants.subheaderStyle), 
              const SizedBox(height: 12), 
              PumpStatusTable(pumps: provider.pumps), 
              const SizedBox(height: 24), 
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                children: [
                  Text('Recent Transactions', style: _DashboardConstants.subheaderStyle), 
                  IconButton(icon: const Icon(Icons.file_download_outlined), tooltip: 'Export to CSV', onPressed: _exportTransactions)
                ]
              ), 
              const SizedBox(height: 12), 
              RecentTransactionsTable(transactions: provider.recentTransactions)
            ]
          )
        ), 
        const SizedBox(width: 24), 
        Expanded(
          flex: 4, 
          child: Column(
            children: [
              Text('Quick Stats', style: _DashboardConstants.subheaderStyle), 
              const SizedBox(height: 12), 
              Card(
                elevation: 2, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                child: Padding(
                  padding: const EdgeInsets.all(16), 
                  child: Column(
                    children: [
                      _buildStatRow('Active Attendants', '${provider.activeAttendants}', Icons.people_outline, Colors.blue), 
                      const Divider(height: 24), 
                      _buildStatRow('Pending Reports', '${provider.pendingReports}', Icons.pending_actions_outlined, _DashboardConstants.warningOrange), 
                      const Divider(height: 24), 
                      _buildStatRow('Low Fuel Alerts', '${provider.lowFuelPumps}', Icons.warning_amber_outlined, _DashboardConstants.errorRed)
                    ]
                  )
                )
              ), 
              const SizedBox(height: 16), 
              Card(
                elevation: 2, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                child: Padding(
                  padding: const EdgeInsets.all(16), 
                  child: Column(
                    children: [
                      const Text('Payment Methods', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)), 
                      const SizedBox(height: 12), 
                      _buildPaymentChart(provider)
                    ]
                  )
                )
              )
            ]
          )
        )
      ]
    );
  }

  Widget _buildTabletContent(ManagerProvider provider) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Expanded(
              flex: 7, 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text('Pump Status', style: _DashboardConstants.subheaderStyle), 
                  const SizedBox(height: 12), 
                  PumpStatusTable(pumps: provider.pumps, isTablet: true)
                ]
              )
            ), 
            const SizedBox(width: 16), 
            Expanded(
              flex: 5, 
              child: Card(
                elevation: 2, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                child: Padding(
                  padding: const EdgeInsets.all(16), 
                  child: Column(
                    children: [
                      Text('Quick Stats', style: _DashboardConstants.subheaderStyle.copyWith(fontSize: 16)), 
                      const SizedBox(height: 12), 
                      _buildStatRow('Active Attendants', '${provider.activeAttendants}', Icons.people_outline, Colors.blue), 
                      const Divider(height: 20), 
                      _buildStatRow('Pending Reports', '${provider.pendingReports}', Icons.pending_actions_outlined, _DashboardConstants.warningOrange), 
                      const Divider(height: 20), 
                      _buildStatRow('Low Fuel Alerts', '${provider.lowFuelPumps}', Icons.warning_amber_outlined, _DashboardConstants.errorRed), 
                      const SizedBox(height: 16), 
                      const Divider(), 
                      const SizedBox(height: 12), 
                      const Text('Payment Methods', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)), 
                      const SizedBox(height: 8), 
                      _buildPaymentChart(provider)
                    ]
                  )
                )
              )
            )
          ]
        ), 
        const SizedBox(height: 24), 
        Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [
                Text('Recent Transactions', style: _DashboardConstants.subheaderStyle), 
                IconButton(icon: const Icon(Icons.file_download_outlined), tooltip: 'Export to CSV', onPressed: _exportTransactions)
              ]
            ), 
            const SizedBox(height: 12), 
            RecentTransactionsTable(transactions: provider.recentTransactions, isMobile: false)
          ]
        )
      ]
    );
  }

  Widget _buildMobileContent(ManagerProvider provider) {
    return Column(
      children: [
        Text('Pump Status', style: _DashboardConstants.subheaderStyle), 
        const SizedBox(height: 12), 
        PumpStatusTable(pumps: provider.pumps, isMobile: true), 
        const SizedBox(height: 24), 
        GridView.count(
          shrinkWrap: true, 
          physics: const NeverScrollableScrollPhysics(), 
          crossAxisCount: 2, 
          mainAxisSpacing: 12, 
          crossAxisSpacing: 12, 
          childAspectRatio: 1.3, 
          children: [
            _buildMobileStatCard('Active Staff', '${provider.activeAttendants}', Icons.people_outline, Colors.blue), 
            _buildMobileStatCard('Pending', '${provider.pendingReports}', Icons.pending_actions_outlined, _DashboardConstants.warningOrange), 
            _buildMobileStatCard('Low Fuel', '${provider.lowFuelPumps}', Icons.warning_amber_outlined, _DashboardConstants.errorRed), 
            _buildMobileStatCard('Total Sales', 'KES ${_formatNumber(provider.mpesaTotal + provider.cashTotal)}', Icons.payments_outlined, _DashboardConstants.accentGreen)
          ]
        ), 
        const SizedBox(height: 24), 
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
          children: [
            Text('Recent Transactions', style: _DashboardConstants.subheaderStyle), 
            IconButton(icon: const Icon(Icons.file_download_outlined), tooltip: 'Export', onPressed: _exportTransactions)
          ]
        ), 
        const SizedBox(height: 12), 
        RecentTransactionsTable(transactions: provider.recentTransactions, isMobile: true)
      ]
    );
  }
  
  Widget _buildMobileStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
      child: InkWell(
        onTap: () {}, 
        borderRadius: BorderRadius.circular(12), 
        child: Padding(
          padding: const EdgeInsets.all(12), 
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, 
            children: [
              Icon(icon, color: color, size: 28), 
              const SizedBox(height: 8), 
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis), 
              Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12), textAlign: TextAlign.center)
            ]
          )
        )
      )
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20), 
              const SizedBox(width: 12), 
              Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 14))
            ]
          ), 
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))
        ]
      )
    );
  }
  
  Widget _buildPaymentChart(ManagerProvider provider) {
    final total = provider.mpesaTotal + provider.cashTotal;
    final mpesaPercentage = total > 0 ? (provider.mpesaTotal / total * 100).clamp(0, 100) : 0;
    final cashPercentage = total > 0 ? (provider.cashTotal / total * 100).clamp(0, 100) : 0;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Container(height: 10, width: double.infinity, decoration: BoxDecoration(color: _DashboardConstants.accentGreen, borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)))), 
                  const SizedBox(height: 8), 
                  const Text('M-Pesa', style: TextStyle(fontSize: 12)), 
                  Text('${mpesaPercentage.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))
                ]
              )
            ), 
            const SizedBox(width: 16), 
            Expanded(
              child: Column(
                children: [
                  Container(height: 10, width: double.infinity, decoration: BoxDecoration(color: Colors.blue, borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)))), 
                  const SizedBox(height: 8), 
                  const Text('Cash', style: TextStyle(fontSize: 12)), 
                  Text('${cashPercentage.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))
                ]
              )
            )
          ]
        )
      ]
    );
  }
  
  Widget _skeletonLoader({double? width, double? height, BorderRadius? borderRadius}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(width: width, height: height, decoration: BoxDecoration(color: Colors.white, borderRadius: borderRadius ?? BorderRadius.circular(8))),
    );
  }
  
  String _formatNumber(double number) => NumberFormat('#,##0').format(number);
}