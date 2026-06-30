// lib/features/owner/presentation/screens/employee_management_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/models/employee_model.dart';
import '../providers/owner_provider.dart';
import '../../domain/models/station_model.dart';

// MARK: - Constants
class _EmployeeConstants {
  static const Color primaryDark = Color(0xFF0B3D2E);
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color warningOrange = Color(0xFFF39C12);
  static const Color errorRed = Color(0xFFE74C3C);
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
}

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() => _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> 
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedStationFilter = 'all';
  String _selectedRoleFilter = 'all';
  String _selectedStatusFilter = 'all';
  bool _isLoading = false;
  String? _errorMessage;
  final String _sortBy = 'name';
  final bool _sortAscending = true;
  
  // Available stations from provider
  List<Station> _stations = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // MARK: - Data Loading
  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final provider = context.read<OwnerProvider>();
      
      await Future.wait([
        provider.loadEmployees(),
        provider.loadStations(),
      ]);
      
      _stations = provider.stations;
      
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      HapticFeedback.lightImpact();
      
    } catch (e, stackTrace) {
      if (!mounted) return;
      debugPrint('Load employees error: $e\n$stackTrace');
      setState(() {
        _errorMessage = _getErrorMessage(e);
        _isLoading = false;
      });
      _showErrorSnackBar();
    }
  }
  
  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('SocketException') || 
        error.toString().contains('NetworkIsUnreachable')) {
      return 'No internet connection. Please check your network.';
    }
    if (error.toString().contains('Unauthorized') || 
        error.toString().contains('401')) {
      return 'Session expired. Please log in again.';
    }
    return 'Failed to load employees. Please try again.';
  }
  
  void _showErrorSnackBar() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(_errorMessage ?? 'An error occurred')),
          ],
        ),
        backgroundColor: _EmployeeConstants.errorRed,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _loadData,
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // MARK: - Get Employees from Provider
  List<OwnerEmployee> _getEmployees() {
    final provider = context.watch<OwnerProvider>();
    return provider.employees;
  }

  // MARK: - Filtering & Sorting
  List<OwnerEmployee> _getFilteredEmployees(List<OwnerEmployee> employees) {
    return employees.where((emp) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matches = emp.name.toLowerCase().contains(query) ||
            emp.email.toLowerCase().contains(query) ||
            emp.phone.contains(query) ||
            emp.stationName.toLowerCase().contains(query);
        if (!matches) return false;
      }
      
      // Station filter
      if (_selectedStationFilter != 'all' && emp.stationId != _selectedStationFilter) {
        return false;
      }
      
      // Role filter
      if (_selectedRoleFilter != 'all' && emp.role != _selectedRoleFilter) {
        return false;
      }
      
      // Status filter
      if (_selectedStatusFilter != 'all' && emp.status != _selectedStatusFilter) {
        return false;
      }
      
      // Tab status filter
      if (_tabController.index != 0) {
        switch (_tabController.index) {
          case 1: // Active tab
            if (emp.status != 'active') return false;
            break;
          case 2: // Inactive tab
            if (emp.status != 'inactive' && emp.status != 'suspended') return false;
            break;
          case 3: // Pending tab
            if (emp.status != 'pending') return false;
            break;
        }
      }
      
      return true;
    }).toList()..sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'role':
          comparison = a.role.compareTo(b.role);
          break;
        case 'joinDate':
          comparison = b.joinDate.compareTo(a.joinDate);
          break;
        case 'station':
          comparison = a.stationName.compareTo(b.stationName);
          break;
        default:
          comparison = 0;
      }
      return _sortAscending ? comparison : -comparison;
    });
  }

  // MARK: - Employee Actions
  Future<void> _inviteEmployee() async {
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => _InviteEmployeeDialog(
        stations: _stations,
      ),
    );
    
    if (result != null && mounted) {
      try {
        final provider = context.read<OwnerProvider>();
        final response = await provider.inviteEmployee(
          email: result['email']!,
          fullName: result['full_name']!,
          role: result['role']!,
          phone: result['phone'],
          stationId: result['station_id'] != null ? int.parse(result['station_id']) : null,
          assignedPumpId: result['assigned_pump_id'] != null ? int.parse(result['assigned_pump_id']) : null,
        );
        
        if (mounted && response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('✅ Invitation sent to ${result['email']}'),
                  const SizedBox(height: 4),
                  const Text(
                    'They will receive an email with registration link and app download instructions.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              backgroundColor: _EmployeeConstants.accentGreen,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'VIEW PENDING',
                textColor: Colors.white,
                onPressed: () {
                  _tabController.index = 3;
                  setState(() {});
                },
              ),
            ),
          );
          _loadData();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${response['message'] ?? 'Failed to send invitation'}'),
              backgroundColor: _EmployeeConstants.errorRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Failed to send invitation: ${e.toString()}'),
              backgroundColor: _EmployeeConstants.errorRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // ✅ UPDATED: now accepts optional sheetContext so the details bottom sheet
  // (if this was opened from there) can be closed automatically after approval
  void _approveEmployee(OwnerEmployee employee, {BuildContext? sheetContext}) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Approve ${employee.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Approve this employee registration?'),
            const SizedBox(height: 8),
            Text(
              'Email: ${employee.email}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            Text(
              'Station: ${employee.stationName}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 16),
            const Text(
              'Once approved, the employee will be able to login.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // ✅ Close confirm dialog first
              Navigator.pop(dialogContext);
              // ✅ Then process approval, passing sheetContext through
              _processApproval(employee, true, sheetContext: sheetContext);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
            ),
            child: const Text('Approve'),
          ),
          TextButton(
            onPressed: () {
              // ✅ Close confirm dialog first
              Navigator.pop(dialogContext);
              // ✅ Then process rejection, passing sheetContext through
              _processApproval(employee, false, sheetContext: sheetContext);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  // ✅ UPDATED: closes the details bottom sheet (if provided) right after
  // a successful approval/rejection, before showing the snackbar
  Future<void> _processApproval(
    OwnerEmployee employee,
    bool approved, {
    BuildContext? sheetContext,
  }) async {
    try {
      final provider = context.read<OwnerProvider>();
      final success = await provider.approveEmployee(employee.id, approved);

      // ✅ Close the details bottom sheet, if this approval was triggered from it
      if (sheetContext != null &&
          sheetContext.mounted &&
          Navigator.of(sheetContext).canPop()) {
        Navigator.of(sheetContext).pop();
      }

      if (mounted && success) {
        // ✅ Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approved 
                  ? '✅ ${employee.name} has been approved! They can now login.' 
                  : '❌ ${employee.name} has been rejected.',
            ),
            backgroundColor: approved 
                ? _EmployeeConstants.accentGreen 
                : _EmployeeConstants.errorRed,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // ✅ Refresh the list
        _loadData();
      } else if (mounted) {
        // ✅ Show error if approval failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to ${approved ? 'approve' : 'reject'} ${employee.name}'),
            backgroundColor: _EmployeeConstants.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to process: ${e.toString()}'),
            backgroundColor: _EmployeeConstants.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _resendInvitation(OwnerEmployee employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resend Invitation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send invitation again to ${employee.email}?'),
            const SizedBox(height: 8),
            const Text(
              'They will receive a new email with registration link and app download instructions.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final provider = context.read<OwnerProvider>();
                final success = await provider.resendInvitation(
                  employee.email,
                  employee.name,
                  employee.role,
                );
                
                if (mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Invitation resent to ${employee.email}'),
                      backgroundColor: Colors.blue,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Failed to resend: ${e.toString()}'),
                      backgroundColor: _EmployeeConstants.errorRed,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _EmployeeConstants.primaryDark,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  // MARK: - Employee Details
  void _showEmployeeDetails(OwnerEmployee employee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          final roleColor = _getRoleColor(employee.roleColorValue);
          final isPending = employee.status == 'pending';
          
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: roleColor.withAlpha(26),
                        child: Text(
                          employee.name[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: roleColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employee.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  _getRoleIcon(employee.role),
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  employee.roleDisplay,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: employee.isActive 
                              ? Colors.green.withAlpha(26)
                              : (isPending 
                                  ? Colors.blue.withAlpha(26)
                                  : Colors.red.withAlpha(26)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              employee.isActive 
                                  ? Icons.check_circle
                                  : (isPending 
                                      ? Icons.hourglass_empty
                                      : Icons.cancel),
                              color: employee.isActive 
                                  ? Colors.green
                                  : (isPending 
                                      ? Colors.blue
                                      : Colors.red),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              employee.status.toUpperCase(),
                              style: TextStyle(
                                color: employee.isActive 
                                    ? Colors.green
                                    : (isPending 
                                        ? Colors.blue
                                        : Colors.red),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                Divider(color: Colors.grey.shade200),
                
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildInfoSection('Contact Information', [
                        _buildInfoRow('Email', employee.email, Icons.email_outlined),
                        _buildInfoRow('Phone', employee.phone, Icons.phone_outlined),
                      ]),
                      
                      const SizedBox(height: 16),
                      
                      _buildInfoSection('Employment Details', [
                        _buildInfoRow('Role', employee.roleDisplay, _getRoleIcon(employee.role)),
                        _buildInfoRow('Station', employee.stationName, Icons.business_outlined),
                        _buildInfoRow(
                          'Join Date',
                          DateFormat('dd MMM yyyy').format(employee.joinDate),
                          Icons.calendar_today_outlined,
                        ),
                        _buildInfoRow(
                          'Performance Score',
                          employee.formattedPerformanceScore,
                          Icons.star_outlined,
                          valueColor: _getPerformanceColor(employee.performanceScore),
                        ),
                      ]),
                      
                      if (isPending) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Registration Pending Approval',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'This employee has registered but needs approval.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                // ✅ pass this builder's own context (the sheet's context)
                                onPressed: () => _approveEmployee(employee, sheetContext: context),
                                child: const Text('Approve'),
                              ),
                              TextButton(
                                onPressed: () => _resendInvitation(employee),
                                child: const Text('Resend'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (isPending)
                        Expanded(
                          child: OutlinedButton.icon(
                            // ✅ pass this builder's own context (the sheet's context)
                            onPressed: () => _approveEmployee(employee, sheetContext: context),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Review'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: _EmployeeConstants.primaryDark),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Navigate to edit
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: _EmployeeConstants.primaryDark),
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.analytics_outlined),
                          label: const Text('Performance'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _EmployeeConstants.primaryDark,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // MARK: - Helper Widgets
  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MARK: - Helper Methods
  Color _getRoleColor(String colorValue) {
    switch (colorValue) {
      case 'purple': return const Color(0xFF9B59B6);
      case 'orange': return const Color(0xFFF39C12);
      case 'green': return const Color(0xFF2ECC71);
      default: return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'manager': return Icons.manage_accounts;
      case 'supervisor': return Icons.shield_outlined;
      case 'attendant': return Icons.person_outline;
      default: return Icons.person_outline;
    }
  }

  Color _getPerformanceColor(double? score) {
    if (score == null) return Colors.grey;
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }

  // MARK: - Build
  @override
  Widget build(BuildContext context) {
    final employees = _getEmployees();
    final filteredEmployees = _getFilteredEmployees(employees);
    
    final stationNames = ['all', ...employees.map((e) => e.stationName).toSet()];
    final roleNames = ['all', 'manager', 'supervisor', 'attendant'];
    final statusNames = ['all', 'active', 'inactive', 'pending', 'suspended'];
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Employee Management'),
        backgroundColor: _EmployeeConstants.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          onTap: (index) {
            setState(() {
              _selectedStatusFilter = 'all';
            });
          },
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Inactive'),
            Tab(text: 'Pending'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.send_outlined),
            tooltip: 'Invite by Email',
            onPressed: _inviteEmployee,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextField(
                            onChanged: (value) => setState(() => _searchQuery = value),
                            decoration: InputDecoration(
                              hintText: 'Search employees...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () => setState(() => _searchQuery = ''),
                                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            textInputAction: TextInputAction.search,
                          ),
                          const SizedBox(height: 12),
                          
                          Row(
                            children: [
                              Expanded(
                                child: _buildFilterDropdown(
                                  value: _selectedStationFilter,
                                  items: stationNames,
                                  onChanged: (v) => setState(() => _selectedStationFilter = v!),
                                  label: 'Station',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildFilterDropdown(
                                  value: _selectedRoleFilter,
                                  items: roleNames,
                                  onChanged: (v) => setState(() => _selectedRoleFilter = v!),
                                  label: 'Role',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildFilterDropdown(
                                  value: _selectedStatusFilter,
                                  items: statusNames,
                                  onChanged: (v) => setState(() => _selectedStatusFilter = v!),
                                  label: 'Status',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _EmployeeConstants.primaryDark.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatChip('Total', filteredEmployees.length, Colors.blue),
                          _buildStatChip('Active', filteredEmployees.where((e) => e.isActive).length, Colors.green),
                          _buildStatChip('Pending', filteredEmployees.where((e) => e.status == 'pending').length, _EmployeeConstants.warningOrange),
                          _buildStatChip('Managers', filteredEmployees.where((e) => e.isManager).length, Colors.purple),
                        ],
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${filteredEmployees.length} employees found',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedStationFilter = 'all';
                                _selectedRoleFilter = 'all';
                                _selectedStatusFilter = 'all';
                                _searchQuery = '';
                                _tabController.index = 0;
                              });
                            },
                            icon: const Icon(Icons.clear_all),
                            label: const Text('Clear Filters'),
                          ),
                        ],
                      ),
                    ),
                    
                    Expanded(
                      child: filteredEmployees.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 72,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No employees found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try adjusting your filters',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadData,
                              color: _EmployeeConstants.primaryDark,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredEmployees.length,
                                itemBuilder: (context, index) {
                                  final employee = filteredEmployees[index];
                                  final roleColor = _getRoleColor(employee.roleColorValue);
                                  final isPending = employee.status == 'pending';
                                  
                                  final performanceScore = employee.performanceScore;
                                  
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: InkWell(
                                      onTap: () => _showEmployeeDetails(employee),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: roleColor.withAlpha(26),
                                              child: Text(
                                                employee.name[0].toUpperCase(),
                                                style: TextStyle(
                                                  color: roleColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    employee.name,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${employee.roleDisplay} • ${employee.stationName}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: employee.isActive 
                                                        ? Colors.green.withAlpha(26)
                                                        : (isPending 
                                                            ? Colors.orange.withAlpha(26)
                                                            : Colors.red.withAlpha(26)),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    employee.status.toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w600,
                                                      color: employee.isActive 
                                                          ? Colors.green
                                                          : (isPending 
                                                              ? Colors.orange
                                                              : Colors.red),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.star,
                                                      size: 12,
                                                      color: _getPerformanceColor(performanceScore),
                                                    ),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      employee.formattedPerformanceScore,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  // MARK: - Helper Widgets
  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item == 'all' ? 'All $label' : item,
                style: const TextStyle(fontSize: 12),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }
}

// MARK: - Invite Employee Dialog
class _InviteEmployeeDialog extends StatefulWidget {
  final List<Station> stations;

  const _InviteEmployeeDialog({
    required this.stations,
  });

  @override
  State<_InviteEmployeeDialog> createState() => _InviteEmployeeDialogState();
}

class _InviteEmployeeDialogState extends State<_InviteEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String _selectedRole = 'attendant';
  String? _selectedStationId;
  String? _selectedPumpId;
  
  List<Map<String, String>> _availablePumps = [];

  @override
  void initState() {
    super.initState();
    if (widget.stations.isNotEmpty) {
      _selectedStationId = widget.stations.first.id.toString();
      _updatePumps();
    }
  }

  void _updatePumps() {
    _availablePumps = [
      {'id': '1', 'name': 'Pump 1'},
      {'id': '2', 'name': 'Pump 2'},
      {'id': '3', 'name': 'Pump 3'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final roles = ['attendant', 'supervisor', 'manager'];
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Invite Employee',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Send an invitation email to register as an employee',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email address';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work_outline),
                ),
                items: roles.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role[0].toUpperCase() + role.substring(1)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedRole = value!);
                },
              ),
              const SizedBox(height: 12),
              
              if (widget.stations.length > 1)
                DropdownButtonFormField<String>(
                  initialValue: _selectedStationId,
                  decoration: const InputDecoration(
                    labelText: 'Station *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                  items: widget.stations.map((station) {
                    return DropdownMenuItem(
                      value: station.id.toString(),
                      child: Text(station.stationName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStationId = value!;
                      _updatePumps();
                    });
                  },
                ),
              
              if (widget.stations.length > 1) const SizedBox(height: 12),
              
              DropdownButtonFormField<String>(
                initialValue: _selectedPumpId,
                decoration: const InputDecoration(
                  labelText: 'Assign Pump (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_gas_station_outlined),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('None'),
                  ),
                  ..._availablePumps.map((pump) {
                    return DropdownMenuItem(
                      value: pump['id'],
                      child: Text(pump['name']!),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() => _selectedPumpId = value);
                },
              ),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B3D2E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Send Invitation'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, {
        'email': _emailController.text.trim(),
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': _selectedRole,
        'station_id': _selectedStationId,
        'assigned_pump_id': _selectedPumpId,
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}