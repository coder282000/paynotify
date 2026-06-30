// lib/features/manager/presentation/screens/notification_point_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/notification_rule.dart';
import '../../domain/models/appnotification.dart';
import '../widgets/notification_rule_card.dart';
import '../widgets/announcement_card.dart';
import '../widgets/send_announcement_dialog.dart';
import '../widgets/add_notification_rule_dialog.dart';

// MARK: - Constants
class _NotificationConstants {
  static const Color primaryDark = Color(0xFF0B3D2E);
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color warningOrange = Color(0xFFF39C12);
  static const Color errorRed = Color(0xFFE74C3C);
  
  static const Duration animationDuration = Duration(milliseconds: 300);
}

class NotificationPointScreen extends StatefulWidget {
  const NotificationPointScreen({super.key});

  @override
  State<NotificationPointScreen> createState() => _NotificationPointScreenState();
}

class _NotificationPointScreenState extends State<NotificationPointScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Notification Rules
  List<NotificationRule> _rules = [];
  
  // Announcements - Using AppNotification
  List<AppNotification> _announcements = [];
  
  // Available employees for recipient selection
  final List<Map<String, String>> _availableEmployees = [
    {'id': '1', 'name': 'John Mwangi', 'role': 'Attendant'},
    {'id': '2', 'name': 'Sarah Wanjiku', 'role': 'Senior Attendant'},
    {'id': '3', 'name': 'Peter Odhiambo', 'role': 'Attendant'},
    {'id': '4', 'name': 'Grace Akinyi', 'role': 'Supervisor'},
    {'id': '5', 'name': 'Lucy Wambui', 'role': 'Attendant'},
    {'id': '6', 'name': 'David Omondi', 'role': 'Attendant'},
    {'id': '7', 'name': 'Mary Njeri', 'role': 'Senior Attendant'},
    {'id': '8', 'name': 'James Kariuki', 'role': 'Attendant'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      await Future.delayed(_NotificationConstants.animationDuration);
      
      if (!mounted) return;
      
      _rules = _generateMockRules();
      _announcements = _generateMockAnnouncements();
      
      setState(() => _isLoading = false);
      HapticFeedback.lightImpact();
      
    } catch (e, stackTrace) {
      if (!mounted) return;
      debugPrint('Load notifications error: $e\n$stackTrace');
      setState(() {
        _errorMessage = _getErrorMessage(e);
        _isLoading = false;
      });
      _showErrorSnackBar();
    }
  }
  
  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('SocketException')) {
      return 'No internet connection. Please check your network.';
    }
    return 'Failed to load notification settings. Please try again.';
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
        backgroundColor: _NotificationConstants.errorRed,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _loadData,
        ),
      ),
    );
  }

  List<NotificationRule> _generateMockRules() {
    return [
      NotificationRule(
        id: '1',
        type: NotificationType.lowFuel,
        isEnabled: true,
        channels: [NotificationChannel.inApp, NotificationChannel.sms],
        recipientRoles: ['manager', 'supervisor'],
        thresholdValue: 15,
        sendToAllAttendants: false,
        priority: NotificationPriority.high,
      ),
      NotificationRule(
        id: '2',
        type: NotificationType.highExpense,
        isEnabled: true,
        channels: [NotificationChannel.inApp],
        recipientRoles: ['manager'],
        thresholdValue: 50000,
        sendToAllAttendants: false,
        priority: NotificationPriority.normal,
      ),
      NotificationRule(
        id: '3',
        type: NotificationType.employeeClockIn,
        isEnabled: true,
        channels: [NotificationChannel.inApp],
        recipientRoles: ['manager', 'supervisor'],
        sendToAllAttendants: false,
        priority: NotificationPriority.low,
      ),
      NotificationRule(
        id: '4',
        type: NotificationType.shiftReminder,
        isEnabled: false,
        channels: [NotificationChannel.inApp, NotificationChannel.sms],
        recipientRoles: ['attendant'],
        sendToAllAttendants: true,
        priority: NotificationPriority.normal,
      ),
      NotificationRule(
        id: '5',
        type: NotificationType.paymentFailure,
        isEnabled: true,
        channels: [NotificationChannel.inApp, NotificationChannel.email],
        recipientRoles: ['manager', 'supervisor'],
        sendToAllAttendants: false,
        priority: NotificationPriority.high,
      ),
    ];
  }

  List<AppNotification> _generateMockAnnouncements() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: '1',
        title: 'Maintenance Notice',
        message: 'Pump 3 will be under maintenance tomorrow from 8am to 12pm. Please direct customers to other pumps.',
        type: NotificationType.systemUpdate,
        priority: NotificationPriority.high,
        createdAt: now.subtract(const Duration(hours: 2)),
        senderId: 'manager_1',
        senderName: 'Manager',
        recipientIds: [],
        recipientNames: [],
        status: NotificationStatus.delivered,
      ),
      AppNotification(
        id: '2',
        title: 'New Fuel Prices',
        message: 'Fuel prices have been updated. Petrol: KES 180.50, Diesel: KES 165.00.',
        type: NotificationType.systemUpdate,
        priority: NotificationPriority.normal,
        createdAt: now.subtract(const Duration(days: 1)),
        senderId: 'manager_1',
        senderName: 'Manager',
        recipientIds: [],
        recipientNames: [],
        status: NotificationStatus.delivered,
      ),
      AppNotification(
        id: '3',
        title: 'Staff Meeting',
        message: 'There will be a mandatory staff meeting on Friday at 2pm in the office.',
        type: NotificationType.systemUpdate,
        priority: NotificationPriority.high,
        createdAt: now.subtract(const Duration(days: 2)),
        senderId: 'manager_1',
        senderName: 'Manager',
        recipientIds: [],
        recipientNames: [],
        status: NotificationStatus.delivered,
      ),
    ];
  }

  void _toggleRule(NotificationRule rule) {
    setState(() {
      rule.isEnabled = !rule.isEnabled;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${rule.type.displayName} ${rule.isEnabled ? 'enabled' : 'disabled'}'),
        backgroundColor: rule.isEnabled ? _NotificationConstants.accentGreen : _NotificationConstants.warningOrange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _editRule(NotificationRule rule) {
    showDialog(
      context: context,
      builder: (context) => AddNotificationRuleDialog(
        existingRule: rule,
        onSave: (updatedRule) {
          setState(() {
            final index = _rules.indexWhere((r) => r.id == rule.id);
            if (index != -1) {
              _rules[index] = updatedRule;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${updatedRule.type.displayName} rule updated successfully'),
              backgroundColor: _NotificationConstants.accentGreen,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _sendAnnouncement() async {
    await showDialog(
      context: context,
      builder: (context) => SendAnnouncementDialog(
        availableEmployees: _availableEmployees,
        onSend: (notification) {
          setState(() {
            _announcements.insert(0, notification);
          });
        },
      ),
    );
  }

  void _addNotificationRule() {
    showDialog(
      context: context,
      builder: (context) => AddNotificationRuleDialog(
        onSave: (newRule) {
          setState(() {
            _rules.insert(0, newRule);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${newRule.type.displayName} rule added successfully'),
              backgroundColor: _NotificationConstants.accentGreen,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _markAsRead(AppNotification notification) {
    setState(() {
      notification.status = NotificationStatus.read;
    });
  }

  void _deleteAnnouncement(AppNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: Text('Delete "${notification.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _announcements.removeWhere((a) => a.id == notification.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Announcement deleted'),
                  backgroundColor: _NotificationConstants.errorRed,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // MARK: - Floating Action Button Logic
  void _onFloatingActionButtonPressed() {
    if (_tabController.index == 0) {
      // On Notification Rules tab - Add new rule
      _addNotificationRule();
    } else {
      // On Announcements tab - Send announcement
      _sendAnnouncement();
    }
  }

  String _getFloatingActionButtonLabel() {
    return _tabController.index == 0 ? 'Add Rule' : 'Send Announcement';
  }

  IconData _getFloatingActionButtonIcon() {
    return _tabController.index == 0 ? Icons.add : Icons.send;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Notification Point'),
        backgroundColor: _NotificationConstants.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.settings), text: 'Notification Rules'),
            Tab(icon: Icon(Icons.announcement), text: 'Announcements'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
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
                        Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700))),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.red.shade700),
                          onPressed: () => setState(() => _errorMessage = null),
                        ),
                      ],
                    ),
                  ),
                
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Notification Rules Tab
                      _rules.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.notifications_off, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No notification rules',
                                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap + to add your first rule',
                                    style: TextStyle(color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadData,
                              color: _NotificationConstants.primaryDark,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _rules.length,
                                itemBuilder: (context, index) {
                                  final rule = _rules[index];
                                  return NotificationRuleCard(
                                    rule: rule,
                                    onToggle: () => _toggleRule(rule),
                                    onEdit: () => _editRule(rule),
                                  );
                                },
                              ),
                            ),
                      
                      // Announcements Tab
                      Column(
                        children: [
                          if (_announcements.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(Icons.history, size: 16, color: Colors.grey.shade600),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Recent Announcements',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Expanded(
                            child: _announcements.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.announcement_outlined, size: 64, color: Colors.grey.shade400),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No announcements yet',
                                          style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Tap + to send your first announcement',
                                          style: TextStyle(color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: _loadData,
                                    color: _NotificationConstants.primaryDark,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: _announcements.length,
                                      itemBuilder: (context, index) {
                                        final announcement = _announcements[index];
                                        return AnnouncementCard(
                                          notification: announcement,
                                          onTap: () => _markAsRead(announcement),
                                          onDelete: () => _deleteAnnouncement(announcement),
                                          isManager: true,
                                        );
                                      },
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onFloatingActionButtonPressed,
        icon: Icon(_getFloatingActionButtonIcon()),
        label: Text(_getFloatingActionButtonLabel()),
        backgroundColor: _NotificationConstants.primaryDark,
      ),
    );
  }
}