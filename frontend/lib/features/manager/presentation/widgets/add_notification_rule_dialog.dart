// lib/features/manager/presentation/widgets/add_notification_rule_dialog.dart

import 'package:flutter/material.dart';
import '../../domain/models/notification_rule.dart';

class AddNotificationRuleDialog extends StatefulWidget {
  final Function(NotificationRule) onSave;
  final NotificationRule? existingRule; // Added for edit mode

  const AddNotificationRuleDialog({
    super.key,
    required this.onSave,
    this.existingRule,
  });

  @override
  State<AddNotificationRuleDialog> createState() => _AddNotificationRuleDialogState();
}

class _AddNotificationRuleDialogState extends State<AddNotificationRuleDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  NotificationType? _selectedType;
  NotificationPriority _selectedPriority = NotificationPriority.normal;
  List<NotificationChannel> _selectedChannels = [NotificationChannel.inApp];
  List<String> _selectedRecipientRoles = ['manager'];
  double? _thresholdValue;
  bool _sendToAllAttendants = false;
  bool _isSaving = false;

  // Available options
  final List<NotificationType> _notificationTypes = NotificationType.values;
  final List<NotificationChannel> _availableChannels = [
    NotificationChannel.inApp,
    NotificationChannel.sms,
    NotificationChannel.email,
  ];
  final List<String> _availableRoles = [
    'manager',
    'supervisor',
    'attendant',
  ];

  @override
  void initState() {
    super.initState();
    // If editing an existing rule, populate the form
    if (widget.existingRule != null) {
      final rule = widget.existingRule!;
      _selectedType = rule.type;
      _selectedPriority = rule.priority;
      _selectedChannels = List.from(rule.channels);
      _selectedRecipientRoles = List.from(rule.recipientRoles);
      _thresholdValue = rule.thresholdValue;
      _sendToAllAttendants = rule.sendToAllAttendants;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B3D2E).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_active, color: Color(0xFF0B3D2E)),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.existingRule != null ? 'Edit Notification Rule' : 'Add Notification Rule',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 24),
                
                // Notification Type
                const Text('Notification Type *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _notificationTypes.map((type) {
                        final isSelected = _selectedType == type;
                        return FilterChip(
                          label: Text(type.displayName),
                          selected: isSelected,
                          onSelected: widget.existingRule != null 
                              ? null // Disable type change when editing
                              : (selected) {
                                  setState(() {
                                    _selectedType = selected ? type : null;
                                  });
                                },
                          avatar: Icon(
                            type.icon,
                            size: 16,
                            color: isSelected ? Colors.white : type.color,
                          ),
                          selectedColor: type.color,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Priority
                const Text('Priority', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: NotificationPriority.values.map((priority) {
                    final isSelected = _selectedPriority == priority;
                    return ChoiceChip(
                      label: Text(priority.displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedPriority = priority);
                        }
                      },
                      selectedColor: priority.color,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                // Threshold (only for certain types)
                if (_selectedType == NotificationType.lowFuel ||
                    _selectedType == NotificationType.highExpense)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Threshold Value', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: _thresholdValue?.toString(),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: _selectedType == NotificationType.lowFuel 
                              ? 'Alert when fuel level drops below (%)' 
                              : 'Alert when expense exceeds (KES)',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.trending_down),
                          suffixText: _selectedType == NotificationType.lowFuel ? '%' : 'KES',
                        ),
                        onChanged: (value) {
                          _thresholdValue = double.tryParse(value);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                
                // Channels
                const Text('Notification Channels', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _availableChannels.map((channel) {
                    final isSelected = _selectedChannels.contains(channel);
                    return FilterChip(
                      label: Text(channel.displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedChannels.add(channel);
                          } else {
                            _selectedChannels.remove(channel);
                          }
                        });
                      },
                      avatar: Icon(
                        channel.icon,
                        size: 16,
                        color: isSelected ? Colors.white : Colors.grey,
                      ),
                      selectedColor: const Color(0xFF0B3D2E),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                // Recipient Roles
                const Text('Recipient Roles', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _availableRoles.map((role) {
                    final isSelected = _selectedRecipientRoles.contains(role);
                    return FilterChip(
                      label: Text(role.toUpperCase()),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedRecipientRoles.add(role);
                          } else {
                            _selectedRecipientRoles.remove(role);
                          }
                        });
                      },
                      selectedColor: const Color(0xFF0B3D2E),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                // Send to All Attendants
                if (_selectedType == NotificationType.shiftReminder)
                  SwitchListTile(
                    title: const Text('Send to All Attendants'),
                    subtitle: const Text('Notify all attendants instead of specific roles'),
                    value: _sendToAllAttendants,
                    onChanged: (value) {
                      setState(() {
                        _sendToAllAttendants = value;
                        if (value) {
                          _selectedRecipientRoles = ['attendant'];
                        }
                      });
                    },
                    activeTrackColor: const Color(0xFF2ECC71).withValues(alpha: 0.5),
                    activeThumbColor: const Color(0xFF2ECC71),
                    contentPadding: EdgeInsets.zero,
                  ),
                
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFF0B3D2E)),
                        ),
                        child: const Text('CANCEL'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B3D2E),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : Text(widget.existingRule != null ? 'UPDATE RULE' : 'ADD RULE'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() async {
    if (_selectedType == null) {
      _showError('Please select a notification type');
      return;
    }
    
    if (_selectedChannels.isEmpty) {
      _showError('Please select at least one notification channel');
      return;
    }
    
    if (_selectedRecipientRoles.isEmpty && !_sendToAllAttendants) {
      _showError('Please select at least one recipient role');
      return;
    }

    // Add threshold validation
    if ((_selectedType == NotificationType.lowFuel ||
         _selectedType == NotificationType.highExpense) &&
        (_thresholdValue == null || _thresholdValue! <= 0)) {
      _showError('Please enter a valid threshold value');
      return;
    }

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final rule = NotificationRule(
      id: widget.existingRule?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: _selectedType!,
      isEnabled: widget.existingRule?.isEnabled ?? true,
      channels: _selectedChannels,
      recipientRoles: _sendToAllAttendants ? ['attendant'] : _selectedRecipientRoles,
      thresholdValue: _thresholdValue,
      sendToAllAttendants: _sendToAllAttendants,
      priority: _selectedPriority,
    );

    widget.onSave(rule);
    if (mounted) Navigator.pop(context);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}