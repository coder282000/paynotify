// lib/features/manager/presentation/screens/employee_management_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/models/employee_model.dart';
import '../../domain/models/employee_role.dart';
import '../../domain/models/employee_status.dart';
import '../widgets/employee_dialog.dart';
import '../widgets/employee_card.dart';
import '../providers/manager_provider.dart';

// MARK: - Constants
class _EmployeeConstants {
  static const Color primaryDark = Color(0xFF0B3D2E);
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color warningOrange = Color(0xFFF39C12);
  static const Color errorRed = Color(0xFFE74C3C);
  // ✅ FIX: Removed unused animationDuration
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
}

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() => _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> 
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  String _searchQuery = '';
  EmployeeRole? _selectedRoleFilter;
  EmployeeStatus? _selectedStatusFilter;
  bool _isLoading = false;
  String? _errorMessage;
  String _sortBy = 'name';
  bool _sortAscending = true;
  
  // Pumps from provider
  List<Map<String, String>> _availablePumps = [];

  // Tracks the previous tab index so we only trigger a refresh when we
  // actually *enter* the Pending tab, not on every rebuild.
  int _previousTabIndex = 0;

  // Silently polls for new invitations/registrations while this screen
  // is open. Desktop web has no usable pull-to-refresh gesture (that's
  // a touch drag), so without this the Pending tab can go stale
  // indefinitely with no way to notice new activity.
  Timer? _autoRefreshTimer;
  bool _isSilentRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Rebuild when the tab changes so the Pending tab's combined
    // invitations + approvals view swaps in/out correctly, and
    // silently refresh pending data the moment the Pending tab opens.
    _tabController.addListener(() {
      if (!mounted) return;
      setState(() {});
      if (_tabController.index == 3 && _previousTabIndex != 3) {
        _silentRefresh();
      }
      _previousTabIndex = _tabController.index;
    });
    _loadData();

    // Background poll every 20s so the Pending tab stays current even
    // if the manager just leaves the screen open (e.g. after sending
    // an invite and waiting for the recipient to register).
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) _silentRefresh();
    });
  }
  
  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  /// Refreshes employees + combined pending list without showing the
  /// full-screen loading spinner, so it doesn't interrupt whatever the
  /// manager is currently looking at.
  Future<void> _silentRefresh() async {
    if (_isSilentRefreshing || !mounted) return;
    _isSilentRefreshing = true;
    try {
      final provider = context.read<ManagerProvider>();
      await Future.wait([
        provider.loadEmployees(),
        provider.loadAllPending(),
      ]);
    } catch (e) {
      debugPrint('Silent refresh error: $e');
    } finally {
      _isSilentRefreshing = false;
    }
  }

  // MARK: - Data Loading
  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final provider = context.read<ManagerProvider>();
      
      await Future.wait([
        provider.loadEmployees(),
        // Loads the combined list: invitations not yet registered +
        // registrations awaiting approval. Powers the Pending tab.
        provider.loadAllPending(),
        _loadPumps(),
      ]);
      
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
  
  Future<void> _loadPumps() async {
    try {
      final provider = context.read<ManagerProvider>();
      // ✅ FIX: Removed dead null-aware operator
      _availablePumps = provider.pumps.map((pump) {
        return {
          'id': pump.id,
          'name': pump.number,
        };
      }).toList();
    } catch (e) {
      debugPrint('Load pumps error: $e');
      _availablePumps = [];
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
  List<Employee> _getEmployees() {
    final provider = context.watch<ManagerProvider>();
    return provider.employees;
  }

  // MARK: - Get pure invitations (not yet registered) from Provider
  // These have no `users` row yet, so they can't be represented as an
  // Employee — they're rendered separately in the Pending tab.
  List<Map<String, dynamic>> _getPendingInvitations() {
    final provider = context.watch<ManagerProvider>();
    return provider.pendingInvitations;
  }

  // MARK: - Filtering & Sorting
  List<Employee> _getFilteredEmployees(List<Employee> employees) {
    return employees.where((emp) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matches = emp.name.toLowerCase().contains(query) ||
            emp.email.toLowerCase().contains(query) ||
            emp.phone.contains(query) ||
            (emp.assignedPumpName?.toLowerCase().contains(query) ?? false);
        if (!matches) return false;
      }
      
      // Role filter
      if (_selectedRoleFilter != null && emp.role != _selectedRoleFilter) {
        return false;
      }
      
      // Status filter
      if (_selectedStatusFilter != null && emp.status != _selectedStatusFilter) {
        return false;
      }
      
      // Tab status filter
      if (_tabController.index != 0) {
        switch (_tabController.index) {
          case 1: // Active tab
            if (emp.status != EmployeeStatus.active) return false;
            break;
          case 2: // Inactive tab
            if (emp.status != EmployeeStatus.inactive && 
                emp.status != EmployeeStatus.suspended) {
              return false;
            }
            break;
          case 3: // Pending tab
            if (emp.status != EmployeeStatus.pending) return false;
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
          comparison = a.role.index.compareTo(b.role.index);
          break;
        case 'joinDate':
          comparison = b.joinDate.compareTo(a.joinDate);
          break;
        case 'lastActive':
          if (a.lastActive == null && b.lastActive == null) {
            comparison = 0;
          } else if (a.lastActive == null) {
            comparison = 1;
          } else if (b.lastActive == null) {
            comparison = -1;
          } else {
            comparison = b.lastActive!.compareTo(a.lastActive!);
          }
          break;
        default:
          comparison = 0;
      }
      return _sortAscending ? comparison : -comparison;
    });
  }

  // Applies the same search/role filter to raw invitation maps so the
  // search box and role chips also affect the "Awaiting Registration"
  // section of the Pending tab.
  List<Map<String, dynamic>> _getFilteredInvitations(
    List<Map<String, dynamic>> invitations,
  ) {
    return invitations.where((inv) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final name = (inv['full_name'] ?? inv['fullName'] ?? '').toString().toLowerCase();
        final email = (inv['email'] ?? '').toString().toLowerCase();
        if (!name.contains(query) && !email.contains(query)) return false;
      }

      if (_selectedRoleFilter != null) {
        final role = (inv['role'] ?? '').toString().toLowerCase();
        if (role != _selectedRoleFilter!.name.toLowerCase()) return false;
      }

      return true;
    }).toList();
  }

  // MARK: - Employee Actions
  Future<void> _inviteEmployee() async {
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => EmployeeDialog(
        mode: DialogMode.invite,
        availablePumps: _availablePumps,
      ),
    );
    
    if (result != null && mounted) {
      try {
        final provider = context.read<ManagerProvider>();
        final response = await provider.inviteEmployee(
          email: result['email']!,
          fullName: result['full_name']!,
          role: result['role']!,
          phone: result['phone'],
          assignedPumpId: result['assigned_pump_id'],
          employeeRole: result['employee_role'],
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

  Future<void> _addEmployee() async {
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => EmployeeDialog(
        mode: DialogMode.add,
        availablePumps: _availablePumps,
      ),
    );
    
    if (result != null && mounted) {
      try {
        final provider = context.read<ManagerProvider>();
        final success = await provider.createEmployee(
          name: result['full_name']!,
          email: result['email']!,
          phone: result['phone'] ?? '',
          role: result['role']!,
          assignedPumpId: result['assigned_pump_id'],
        );
        
        if (mounted && success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${result['full_name']} added successfully'),
              backgroundColor: _EmployeeConstants.accentGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Failed to add employee: ${e.toString()}'),
              backgroundColor: _EmployeeConstants.errorRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _editEmployee(Employee employee) async {
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => EmployeeDialog(
        mode: DialogMode.edit,
        employee: employee,
        availablePumps: _availablePumps,
      ),
    );
    
    if (result != null && mounted) {
      try {
        final provider = context.read<ManagerProvider>();
        final success = await provider.updateEmployee(employee.id, result);
        
        if (mounted && success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${result['full_name']} updated successfully'),
              backgroundColor: _EmployeeConstants.accentGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Failed to update employee: ${e.toString()}'),
              backgroundColor: _EmployeeConstants.errorRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _resendInvitation(Employee employee) {
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
                final provider = context.read<ManagerProvider>();
                final success = await provider.resendInvitation(
                  employee.email,
                  employee.name,
                  employee.role.displayName.toLowerCase(),
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

  // Resend for a raw invitation map (pure invitation, no Employee object yet).
  void _resendInvitationRaw(Map<String, dynamic> invitation) {
    final email = (invitation['email'] ?? '').toString();
    final fullName = (invitation['full_name'] ?? invitation['fullName'] ?? '').toString();
    final role = (invitation['role'] ?? '').toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resend Invitation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send invitation again to $email?'),
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
                final provider = context.read<ManagerProvider>();
                final success = await provider.resendInvitation(email, fullName, role);

                if (mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Invitation resent to $email'),
                      backgroundColor: Colors.blue,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  await provider.loadAllPending();
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

  void _approveEmployee(Employee employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            const SizedBox(height: 16),
            const Text(
              'Once approved, the employee will be able to login.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _processApproval(employee, true);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
            ),
            child: const Text('Approve'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _processApproval(employee, false);
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

  Future<void> _processApproval(Employee employee, bool approved) async {
    try {
      final provider = context.read<ManagerProvider>();
      final success = await provider.approveEmployee(employee.id, approved);
      
      if (mounted && success) {
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
          ),
        );
        _loadData();
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

  // MARK: - Employee Details Modal
  void _showEmployeeDetails(Employee employee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
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
                        backgroundColor: employee.role.color.withAlpha(26),
                        child: Text(
                          employee.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: employee.role.color,
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
                                  employee.role.icon,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  employee.role.displayName,
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
                          color: employee.status.color.withAlpha(26),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              employee.status.icon,
                              color: employee.status.color,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              employee.status.displayName,
                              style: TextStyle(
                                color: employee.status.color,
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
                        _buildInfoRow('Role', employee.role.displayName, employee.role.icon),
                        _buildInfoRow(
                          'Join Date',
                          DateFormat('dd MMM yyyy').format(employee.joinDate),
                          Icons.calendar_today_outlined,
                        ),
                        if (employee.lastActive != null)
                          _buildInfoRow(
                            'Last Active',
                            DateFormat('dd MMM yyyy, HH:mm').format(employee.lastActive!),
                            Icons.access_time_outlined,
                          ),
                        if (employee.assignedPumpName != null)
                          _buildInfoRow(
                            'Assigned Pump',
                            employee.assignedPumpName!,
                            Icons.local_gas_station_outlined,
                          ),
                      ]),
                      
                      if (employee.performance != null) ...[
                        const SizedBox(height: 16),
                        _buildInfoSection('Performance', [
                          _buildInfoRow(
                            'Efficiency',
                            '${employee.performance!['efficiency']}%',
                            Icons.trending_up,
                            valueColor: Colors.green,
                          ),
                          _buildInfoRow(
                            'Shortages',
                            'KES ${employee.performance!['shortages']}',
                            Icons.trending_down,
                            valueColor: Colors.red,
                          ),
                          _buildInfoRow(
                            'Excess',
                            'KES ${employee.performance!['excess']}',
                            Icons.trending_up,
                            valueColor: _EmployeeConstants.warningOrange,
                          ),
                        ]),
                      ],
                      
                      if (employee.notes != null && employee.notes!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildInfoSection('Notes', [
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              employee.notes!,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ]),
                      ],
                      
                      if (employee.isPending) ...[
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
                                      'Invitation sent ${DateFormat('dd MMM').format(employee.joinDate)}. ${employee.hasInvitationExpired ? 'Expired' : 'Expires ${DateFormat('dd MMM').format(employee.invitationExpiry!)}'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => _approveEmployee(employee),
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
                      if (employee.status == EmployeeStatus.pending)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _approveEmployee(employee),
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
                            onPressed: () => _editEmployee(employee),
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

  // Section header used in the combined Pending tab list.
  Widget _buildSectionHeader(String title, int count, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            '$title ($count)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // A single pure-invitation row (sent, not yet registered). No Employee
  // object exists yet, so this is a lightweight card rather than
  // reusing EmployeeCard — the only available action is Resend.
  Widget _buildInvitationTile(Map<String, dynamic> invitation) {
    final email = (invitation['email'] ?? '').toString();
    final fullName = (invitation['full_name'] ?? invitation['fullName'] ?? '').toString();
    final role = (invitation['role'] ?? '').toString();
    final stationName = (invitation['station_name'] ?? invitation['stationName'] ?? '').toString();
    final expiresAtRaw = invitation['expires_at'] ?? invitation['expiresAt'];

    String expiryLabel = '';
    if (expiresAtRaw != null) {
      final expiresAt = DateTime.tryParse(expiresAtRaw.toString());
      if (expiresAt != null) {
        final expired = expiresAt.isBefore(DateTime.now());
        expiryLabel = expired
            ? 'Expired ${DateFormat('dd MMM').format(expiresAt)}'
            : 'Expires ${DateFormat('dd MMM, HH:mm').format(expiresAt)}';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.blue.shade50,
              child: Icon(Icons.mail_outline, color: Colors.blue.shade700, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName.isNotEmpty ? fullName : email,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (role.isNotEmpty)
                        Chip(
                          label: Text(role, style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                        ),
                      if (stationName.isNotEmpty)
                        Text(
                          stationName,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                        ),
                      if (expiryLabel.isNotEmpty)
                        Text(
                          expiryLabel,
                          style: TextStyle(
                            color: expiryLabel.startsWith('Expired')
                                ? _EmployeeConstants.errorRed
                                : Colors.grey.shade600,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => _resendInvitationRaw(invitation),
              icon: const Icon(Icons.send, size: 16),
              label: const Text('Resend'),
              style: TextButton.styleFrom(
                foregroundColor: _EmployeeConstants.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable list of Employee cards (used by All/Active/Inactive tabs and
  // the "Awaiting Approval" section of the Pending tab).
  Widget _buildEmployeeListItems(List<Employee> employees) {
    return Column(
      children: employees.map((employee) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: EmployeeCard(
            employee: employee,
            onTap: () => _showEmployeeDetails(employee),
            onEdit: () => _editEmployee(employee),
            onApprove: employee.isPending 
                ? () => _approveEmployee(employee)
                : null,
            onResendInvite: employee.isPending 
                ? () => _resendInvitation(employee)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState({
    String title = 'No employees found',
    String subtitle = 'Try adjusting your filters or add a new employee',
    bool showActions = true,
  }) {
    return Center(
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
            title,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          if (showActions) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: _addEmployee,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Manually'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _EmployeeConstants.primaryDark,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _inviteEmployee,
                  icon: const Icon(Icons.send),
                  label: const Text('Invite by Email'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _EmployeeConstants.primaryDark),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Combined Pending tab body: pure invitations (awaiting registration)
  // above registered employees awaiting approval.
  Widget _buildPendingTabBody(
    List<Employee> pendingRegistrations,
    List<Map<String, dynamic>> pendingInvitations,
  ) {
    if (pendingRegistrations.isEmpty && pendingInvitations.isEmpty) {
      return _buildEmptyState(
        title: 'Nothing pending',
        subtitle: 'Invited employees and registrations awaiting approval will show up here',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await _loadData();
      },
      color: _EmployeeConstants.primaryDark,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (pendingInvitations.isNotEmpty) ...[
            _buildSectionHeader(
              'Awaiting Registration',
              pendingInvitations.length,
              Icons.mail_outline,
              Colors.blue.shade700,
            ),
            ...pendingInvitations.map(_buildInvitationTile),
            const SizedBox(height: 8),
          ],
          if (pendingRegistrations.isNotEmpty) ...[
            _buildSectionHeader(
              'Awaiting Approval',
              pendingRegistrations.length,
              Icons.how_to_reg_outlined,
              _EmployeeConstants.warningOrange,
            ),
            _buildEmployeeListItems(pendingRegistrations),
          ],
        ],
      ),
    );
  }

  // MARK: - Build
  @override
  Widget build(BuildContext context) {
    final employees = _getEmployees();
    final filteredEmployees = _getFilteredEmployees(employees);
    final pendingInvitations = _getFilteredInvitations(_getPendingInvitations());
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > _EmployeeConstants.tabletBreakpoint;
    final isTablet = screenWidth > _EmployeeConstants.mobileBreakpoint && 
                     screenWidth <= _EmployeeConstants.tabletBreakpoint;
    
    if (isDesktop) {
      debugPrint('Desktop layout active');
    } else if (isTablet) {
      debugPrint('Tablet layout active');
    } else {
      debugPrint('Mobile layout active');
    }

    final isPendingTab = _tabController.index == 3;
    
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
              _selectedStatusFilter = null;
            });
          },
          tabs: [
            const Tab(text: 'All'),
            const Tab(text: 'Active'),
            const Tab(text: 'Inactive'),
            Tab(
              text: _getPendingInvitations().isEmpty
                  ? 'Pending'
                  : 'Pending (${_getPendingInvitations().length + filteredEmployees.where((e) => e.status == EmployeeStatus.pending).length})',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh',
            onPressed: _loadData,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Add Employee',
            onPressed: _addEmployee,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          IconButton(
            icon: const Icon(Icons.send_outlined),
            tooltip: 'Invite by Email',
            onPressed: _inviteEmployee,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
        ],
      ),
      body: Column(
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
                
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All Roles'),
                        selected: _selectedRoleFilter == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedRoleFilter = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ...EmployeeRole.values.map((role) {
                        return FilterChip(
                          label: Text(role.displayName),
                          selected: _selectedRoleFilter == role,
                          onSelected: (selected) {
                            setState(() {
                              _selectedRoleFilter = selected ? role : null;
                            });
                          },
                          avatar: Icon(
                            role.icon,
                            color: role == _selectedRoleFilter ? Colors.white : role.color,
                            size: 16,
                          ),
                          selectedColor: role.color,
                          labelStyle: TextStyle(
                            color: _selectedRoleFilter == role ? Colors.white : Colors.black,
                          ),
                        );
                      }),
                      
                      const SizedBox(width: 16),
                      const VerticalDivider(width: 1),
                      const SizedBox(width: 16),
                      
                      PopupMenuButton<String>(
                        icon: Icon(
                          _sortAscending ? Icons.sort : Icons.sort_by_alpha,
                        ),
                        tooltip: 'Sort by',
                        onSelected: (value) {
                          setState(() {
                            if (_sortBy == value) {
                              _sortAscending = !_sortAscending;
                            } else {
                              _sortBy = value;
                              _sortAscending = true;
                            }
                          });
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'name',
                            child: Row(
                              children: [
                                Icon(
                                  _sortBy == 'name'
                                      ? (_sortAscending
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward)
                                      : Icons.sort_by_alpha,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                const Text('Name'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'role',
                            child: Row(
                              children: [
                                Icon(
                                  _sortBy == 'role'
                                      ? (_sortAscending
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward)
                                      : Icons.work_outline,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                const Text('Role'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'joinDate',
                            child: Row(
                              children: [
                                Icon(
                                  _sortBy == 'joinDate'
                                      ? (_sortAscending
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward)
                                      : Icons.calendar_today,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                const Text('Join Date'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'lastActive',
                            child: Row(
                              children: [
                                Icon(
                                  _sortBy == 'lastActive'
                                      ? (_sortAscending
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward)
                                      : Icons.access_time,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                const Text('Last Active'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red.shade700),
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                      });
                    },
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ],
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isPendingTab
                      ? '${pendingInvitations.length + filteredEmployees.length} pending items found'
                      : '${filteredEmployees.length} employees found',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedRoleFilter = null;
                      _selectedStatusFilter = null;
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : isPendingTab
                    ? _buildPendingTabBody(filteredEmployees, pendingInvitations)
                    : filteredEmployees.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: () async {
                              HapticFeedback.mediumImpact();
                              await _loadData();
                            },
                            color: _EmployeeConstants.primaryDark,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredEmployees.length,
                              itemBuilder: (context, index) {
                                final employee = filteredEmployees[index];
                                return EmployeeCard(
                                  employee: employee,
                                  onTap: () => _showEmployeeDetails(employee),
                                  onEdit: () => _editEmployee(employee),
                                  onApprove: employee.isPending 
                                      ? () => _approveEmployee(employee)
                                      : null,
                                  onResendInvite: employee.isPending 
                                      ? () => _resendInvitation(employee)
                                      : null,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _inviteEmployee,
        icon: const Icon(Icons.send),
        label: const Text('Invite Employee'),
        backgroundColor: _EmployeeConstants.primaryDark,
      ),
    );
  }
}