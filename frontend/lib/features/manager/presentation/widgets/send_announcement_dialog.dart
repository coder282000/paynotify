import 'package:flutter/material.dart';
import '../../domain/models/appnotification.dart';
import '../../domain/models/notification_rule.dart';

class SendAnnouncementDialog extends StatefulWidget {
  final List<Map<String, String>> availableEmployees;
  final Function(AppNotification) onSend;

  const SendAnnouncementDialog({
    super.key,
    required this.availableEmployees,
    required this.onSend,
  });

  @override
  State<SendAnnouncementDialog> createState() => _SendAnnouncementDialogState();
}

class _SendAnnouncementDialogState extends State<SendAnnouncementDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _messageController;
  
  NotificationPriority _selectedPriority = NotificationPriority.normal;
  List<String> _selectedRecipients = [];
  bool _sendToAll = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSending = true);
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      message: _messageController.text,
      type: NotificationType.systemUpdate,
      priority: _selectedPriority,
      createdAt: DateTime.now(),
      senderId: 'manager_1',
      senderName: 'Manager',
      recipientIds: _sendToAll ? [] : _selectedRecipients,
      recipientNames: _sendToAll ? [] : _getSelectedNames(),
      status: NotificationStatus.delivered,
      isSystemNotification: false,
    );
    
    widget.onSend(notification);
    if (mounted) Navigator.pop(context);
  }

  List<String> _getSelectedNames() {
    return widget.availableEmployees
        .where((e) => _selectedRecipients.contains(e['id']))
        .map((e) => e['name']!)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B3D2E).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.announcement, color: Color(0xFF0B3D2E)),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Send Announcement',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 24),
                
                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 16),
                
                // Message
                TextFormField(
                  controller: _messageController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Message *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.message),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Please enter a message' : null,
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
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                // Recipients
                SwitchListTile(
                  title: const Text('Send to All Employees'),
                  value: _sendToAll,
                  onChanged: (value) {
                    setState(() {
                      _sendToAll = value;
                      if (value) _selectedRecipients = [];
                    });
                  },
                  activeThumbColor: const Color(0xFF0B3D2E),
                  contentPadding: EdgeInsets.zero,
                ),
                
                if (!_sendToAll) ...[
                  const SizedBox(height: 8),
                  const Text('Select Recipients', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(
                      maxHeight: 200,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.availableEmployees.length,
                      itemBuilder: (context, index) {
                        final employee = widget.availableEmployees[index];
                        final isSelected = _selectedRecipients.contains(employee['id']);
                        return CheckboxListTile(
                          title: Text(employee['name']!),
                          subtitle: Text(employee['role'] ?? 'Attendant'),
                          value: isSelected,
                          onChanged: (selected) {
                            setState(() {
                              if (selected == true) {
                                _selectedRecipients.add(employee['id']!);
                              } else {
                                _selectedRecipients.remove(employee['id']);
                              }
                            });
                          },
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        );
                      },
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
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
                        onPressed: _isSending ? null : _send,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B3D2E),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isSending
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text('SEND'),
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
}