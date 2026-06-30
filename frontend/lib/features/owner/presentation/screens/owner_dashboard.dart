// lib/features/owner/presentation/screens/owner_dashboard.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/owner_provider.dart';
import '../../domain/models/station_summary_model.dart';
import '../../widgets/station_card.dart';
import 'all_stations_overview.dart';
import 'station_details_screen.dart';
import 'add_station_screen.dart';
import 'employee_management_screen.dart';
import 'expense_tracking_screen.dart';
import 'subscription_screen.dart';
import 'fuel_inventory_screen.dart';
import 'profit_analytics_screen.dart';
import 'business_analytics_screen.dart';
import 'package:paynotify/core/services/auth_service.dart';
import 'package:paynotify/features/auth/presentation/screens/login_screen.dart';

// MARK: - Constants
class _OwnerConstants {
  static const double tabletBreakpoint = 600;
  static const double desktopBreakpoint = 900;
  static const Duration animationDuration = Duration(milliseconds: 400);
  static const Curve animationCurve = Curves.easeInOutCubic;
  static const double defaultPadding = 24.0;
  static const double compactPadding = 16.0;
  
  static const Color primaryDark = Color(0xFF0B3D2E);
  static const Color accentGreen = Color(0xFF2ECC71);
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

enum OwnerDashboardState { initial, loading, success, error, empty }

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardViewState();
}

class _OwnerDashboardViewState extends State<OwnerDashboard> 
    with SingleTickerProviderStateMixin {
  
  OwnerDashboardState _dashboardState = OwnerDashboardState.initial;
  String? _errorMessage;
  bool _isSidebarCollapsed = false;
  
  late final AnimationController _animationController;
  late final Animation<double> _widthAnimation;
  late final Animation<double> _opacityAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDashboardData();
  }
  
  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: _OwnerConstants.animationDuration,
    );
    
    _widthAnimation = Tween<double>(
      begin: 260,
      end: 80,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: _OwnerConstants.animationCurve,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _dashboardState = OwnerDashboardState.loading;
      _errorMessage = null;
    });
    
    try {
      final provider = Provider.of<OwnerProvider>(context, listen: false);
      
      await Future.wait([
        provider.loadStations(),
        provider.loadAllStationsSummary(),
      ]).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Request timed out'),
      );
      
      if (!mounted) return;
      
      setState(() {
        _dashboardState = provider.stations.isNotEmpty 
            ? OwnerDashboardState.success 
            : OwnerDashboardState.empty;
        _errorMessage = null;
      });
      
      HapticFeedback.lightImpact();
      
    } catch (e) {
      if (!mounted) return;
      
      debugPrint('Owner dashboard load error: $e');
      
      setState(() {
        _dashboardState = OwnerDashboardState.error;
        _errorMessage = _getErrorMessage(e);
      });
      
      _showErrorSnackBar(_errorMessage!);
    }
  }
  
  String _getErrorMessage(dynamic error) {
    if (error is TimeoutException) {
      return 'Connection timed out. Please check your internet and try again.';
    }
    if (error.toString().contains('SocketException')) {
      return 'No internet connection. Please connect to a network and retry.';
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
        backgroundColor: _OwnerConstants.errorRed,
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

  void _toggleSidebar() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
    });
    
    if (_isSidebarCollapsed) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

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
              backgroundColor: _OwnerConstants.errorRed,
            ),
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );
    
    if (shouldLogout == true && mounted) {
      await AuthService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OwnerProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > _OwnerConstants.desktopBreakpoint;
    final isTablet = screenWidth > _OwnerConstants.tabletBreakpoint && 
                     screenWidth <= _OwnerConstants.desktopBreakpoint;
    
    return Scaffold(
      appBar: !isDesktop ? _buildMobileAppBar() : null,
      drawer: !isDesktop ? _buildDrawer() : null,
      backgroundColor: Colors.grey.shade50,
      body: Row(
        children: [
          if (isDesktop) _buildAnimatedSidebar(),
          Expanded(
            child: _buildMainContent(provider, isDesktop, isTablet),
          ),
        ],
      ),
    );
  }
  
  AppBar _buildMobileAppBar() {
    return AppBar(
      title: const Text('Business Overview'),
      backgroundColor: _OwnerConstants.primaryDark,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_outlined),
          onPressed: () => _loadDashboardData(),
          tooltip: 'Refresh Data',
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
      ],
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: Container(
        color: _OwnerConstants.primaryDark,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildDrawerHeader(),
            _buildDrawerItem(Icons.dashboard, 'Dashboard', isSelected: true),
            _buildDrawerItem(Icons.business, 'All Stations'),
            _buildDrawerItem(Icons.add_business, 'Add Station'),
            _buildDivider(),
            _buildDrawerItem(Icons.people, 'Employee Management'),
            _buildDrawerItem(Icons.receipt, 'Expense Tracking'),
            _buildDrawerItem(Icons.analytics, 'Business Analytics'),
            _buildDrawerItem(Icons.trending_up, 'Profit Analytics'),
            _buildDrawerItem(Icons.local_gas_station, 'Fuel Inventory'),
            _buildDrawerItem(Icons.subscriptions, 'Subscriptions'),
            _buildDrawerItem(Icons.settings, 'Settings'),
            _buildDivider(),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.business_center, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'PayNotify',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Owner Portal',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDrawerItem(IconData icon, String label, {bool isSelected = false}) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.white : Colors.white70),
      title: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white70)),
      selected: isSelected,
      selectedTileColor: Colors.white.withAlpha(26),
      onTap: () {
        Navigator.pop(context);
        _navigateTo(label);
      },
    );
  }
  
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
            child: Icon(Icons.person, color: _OwnerConstants.primaryDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Business Owner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                Text('Owner Account', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout_outlined, color: Colors.white70),
            onPressed: _logout,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDivider() {
    return const Divider(color: Colors.white24, thickness: 1);
  }
  
  Widget _buildAnimatedSidebar() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          width: _widthAnimation.value,
          color: _OwnerConstants.primaryDark,
          child: Column(
            children: [
              _buildAnimatedLogo(),
              _buildAnimatedToggleButton(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildAnimatedNavItem(Icons.dashboard, 'Dashboard', true),
                    _buildAnimatedNavItem(Icons.business, 'All Stations'),
                    _buildAnimatedNavItem(Icons.add_business, 'Add Station'),
                    const Divider(color: Colors.white24, height: 16),
                    _buildAnimatedNavItem(Icons.people, 'Employees'),
                    _buildAnimatedNavItem(Icons.receipt, 'Expenses'),
                    _buildAnimatedNavItem(Icons.analytics, 'Analytics'),
                    _buildAnimatedNavItem(Icons.trending_up, 'Profit'),
                    _buildAnimatedNavItem(Icons.local_gas_station, 'Fuel'),
                    _buildAnimatedNavItem(Icons.subscriptions, 'Subscriptions'),
                    _buildAnimatedNavItem(Icons.settings, 'Settings'),
                  ],
                ),
              ),
              _buildAnimatedUserInfo(),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildAnimatedLogo() {
    return Container(
      padding: EdgeInsets.all(_isSidebarCollapsed ? 12 : 24),
      child: Row(
        children: [
          AnimatedContainer(
            duration: _OwnerConstants.animationDuration,
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.business_center,
              color: Colors.white,
              size: _isSidebarCollapsed ? 30 : 40,
            ),
          ),
          if (!_isSidebarCollapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PayNotify', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Owner', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildAnimatedToggleButton() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: IconButton(
        icon: AnimatedRotation(
          duration: _OwnerConstants.animationDuration,
          turns: _isSidebarCollapsed ? 0.5 : 0,
          child: Icon(Icons.chevron_left, color: Colors.white70),
        ),
        onPressed: _toggleSidebar,
        tooltip: _isSidebarCollapsed ? 'Expand' : 'Collapse',
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    );
  }
  
  Widget _buildAnimatedNavItem(IconData icon, String label, [bool isSelected = false]) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: isSelected
          ? BoxDecoration(
              color: Colors.white.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.white : Colors.white70),
        title: _isSidebarCollapsed
            ? null
            : FadeTransition(
                opacity: _opacityAnimation,
                child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white70)),
              ),
        onTap: () => _navigateTo(label),
        minLeadingWidth: 24,
      ),
    );
  }
  
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
          const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: _OwnerConstants.primaryDark, size: 18),
          ),
          if (!_isSidebarCollapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Owner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    Text('Business Owner', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
            ),
            FadeTransition(
              opacity: _opacityAnimation,
              child: IconButton(
                icon: Icon(Icons.logout_outlined, color: Colors.white70, size: 20),
                onPressed: _logout,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  // FIXED: All navigations now include proper Provider wrapping
  void _navigateTo(String screen) {
    switch (screen) {
      case 'All Stations':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider(
              create: (_) => OwnerProvider(),
              child: const AllStationsOverview(),
            ),
          ),
        );
        break;
      case 'Add Station':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider(
              create: (_) => OwnerProvider(),
              child: const AddStationScreen(),
            ),
          ),
        );
        break;
      case 'Employees':
      case 'Employee Management':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider(
              create: (_) => OwnerProvider(),
              child: const EmployeeManagementScreen(),
            ),
          ),
        );
        break;
      case 'Expenses':
      case 'Expense Tracking':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider(
              create: (_) => OwnerProvider(),
              child: const ExpenseTrackingScreen(),
            ),
          ),
        );
        break;
      case 'Analytics':
      case 'Business Analytics':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider(
              create: (_) => OwnerProvider(),
              child: const BusinessAnalyticsScreen(),
            ),
          ),
        );
        break;
      case 'Profit':
      case 'Profit Analytics':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider(
              create: (_) => OwnerProvider(),
              child: const ProfitAnalyticsScreen(),
            ),
          ),
        );
        break;
      case 'Fuel':
      case 'Fuel Inventory':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider(
              create: (_) => OwnerProvider(),
              child: const OwnerFuelInventoryScreen(),
            ),
          ),
        );
        break;
      case 'Subscriptions':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider(
              create: (_) => OwnerProvider(),
              child: const SubscriptionScreen(),
            ),
          ),
        );
        break;
      case 'Settings':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings coming soon'), duration: Duration(seconds: 1)),
        );
        break;
      case 'Dashboard':
      default:
        // Already on dashboard
        break;
    }
  }

  Widget _buildMainContent(OwnerProvider provider, bool isDesktop, bool isTablet) {
    if (_dashboardState == OwnerDashboardState.loading) {
      return _buildLoadingState(isDesktop, isTablet);
    }
    if (_dashboardState == OwnerDashboardState.error) {
      return _buildErrorState();
    }
    if (_dashboardState == OwnerDashboardState.empty) {
      return _buildEmptyState();
    }
    
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: _OwnerConstants.primaryDark,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isDesktop ? _OwnerConstants.defaultPadding : _OwnerConstants.compactPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDesktop, isTablet),
            const SizedBox(height: 24),
            _buildGlobalStatsCard(provider),
            const SizedBox(height: 24),
            _buildTimeRangeSelector(provider),
            const SizedBox(height: 16),
            _buildStationsSection(provider, isDesktop),
            const SizedBox(height: 24),
            _buildRecentActivitySection(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLoadingState(bool isDesktop, bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? _OwnerConstants.defaultPadding : _OwnerConstants.compactPadding),
      child: Column(
        children: [
          _skeletonLoader(height: 60, width: double.infinity),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: List.generate(4, (_) => _skeletonLoader(width: 150, height: 100)),
          ),
          const SizedBox(height: 24),
          _skeletonLoader(height: 300, width: double.infinity),
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
            Text(_errorMessage ?? 'Unable to load dashboard data', textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _loadDashboardData(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _OwnerConstants.primaryDark,
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
            Icon(Icons.business_outlined, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            const Text('No Stations Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Get started by adding your first station', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider(
                    create: (_) => OwnerProvider(),
                    child: const AddStationScreen(),
                  ),
                ),
              ),
              icon: const Icon(Icons.add_business),
              label: const Text('Add Station'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _OwnerConstants.accentGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
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
              Text(
                'Welcome back, Owner!',
                style: _OwnerConstants.headerStyle.copyWith(
                  fontSize: isDesktop ? 28 : (isTablet ? 26 : 24),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                style: TextStyle(color: Colors.grey.shade600, fontSize: isDesktop ? 16 : 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildGlobalStatsCard(OwnerProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_OwnerConstants.primaryDark, Color(0xFF1A5D4A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildStatItem('Today\'s Sales', 'KES ${NumberFormat('#,##0').format(provider.totalTodaySales)}', Icons.trending_up)),
                Expanded(child: _buildStatItem('Monthly Sales', 'KES ${NumberFormat('#,##0').format(provider.totalMonthlySales)}', Icons.calendar_month)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatItem('Active Pumps', provider.totalActivePumps.toString(), Icons.local_gas_station)),
                Expanded(child: _buildStatItem('Active Staff', provider.totalAttendants.toString(), Icons.people)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatItem('Today\'s Transactions', provider.todayTransactions.toString(), Icons.receipt)),
                Expanded(child: _buildStatItem('Active Stations', provider.stations.where((s) => s.isActive).length.toString(), Icons.business)),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70), textAlign: TextAlign.center),
      ],
    );
  }
  
  Widget _buildTimeRangeSelector(OwnerProvider provider) {
    final ranges = ['Today', 'Week', 'Month', 'Year'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: ranges.map((range) {
          final isSelected = provider.selectedTimeRange == range;
          return Expanded(
            child: GestureDetector(
              onTap: () => provider.setTimeRange(range),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? _OwnerConstants.primaryDark : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    range,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildStationsSection(OwnerProvider provider, bool isDesktop) {
    final displayStations = isDesktop ? provider.stations : provider.stations.take(3).toList();
    
    if (provider.stations.isEmpty) {
      return const Center(child: Text('No stations found'));
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Your Stations', style: _OwnerConstants.subheaderStyle),
            if (!isDesktop && provider.stations.length > 3)
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider(
                      create: (_) => OwnerProvider(),
                      child: const AllStationsOverview(),
                    ),
                  ),
                ),
                child: const Text('See All'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...displayStations.map((station) {
          final summary = provider.stationSummaries.firstWhere(
            (s) => s.stationId == station.id,
            orElse: () => StationSummary(
              stationId: station.id,
              stationName: station.stationName,
              stationCode: station.stationCode,
              todaySales: 0,
              weeklySales: 0,
              monthlySales: 0,
              yearlySales: 0,
              lastMonthSales: 0,
              salesGrowth: 0,
              todayTransactions: 0,
              totalTransactions: 0,
              averageTransactionValue: 0,
              cashTotal: 0,
              cardTotal: 0,
              mpesaTotal: 0,
              totalPumps: 0,
              activePumps: 0,
              pumpsUnderMaintenance: 0,
              totalAttendants: 0,
              activeAttendants: 0,
              pendingShiftReports: 0,
              totalFuelInventory: 0,
              lowFuelAlerts: 0,
              attendantPerformanceScore: 0,
              customerSatisfaction: 0,
              lastUpdated: DateTime.now(),
            ),
          );
          return StationCard(
            station: station,
            summary: summary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider(
                    create: (_) => OwnerProvider(),
                    child: StationDetailsScreen(
                      stationId: station.id,
                      stationName: station.stationName,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }
  
  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Activity', style: _OwnerConstants.subheaderStyle),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.attach_money, color: Colors.white),
            ),
            title: const Text('Cash Sale at Westlands Station'),
            subtitle: Text('KES 5,000 • ${DateFormat('HH:mm').format(DateTime.now())}'),
            trailing: const Chip(
              label: Text('Completed'),
              backgroundColor: Colors.green,
              labelStyle: TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _skeletonLoader({double? width, double? height}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}