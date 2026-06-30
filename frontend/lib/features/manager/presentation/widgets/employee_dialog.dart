import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/employee_model.dart';
import '../../domain/models/employee_role.dart';
import '../../domain/models/employee_status.dart';

enum DialogMode { add, edit, invite }

class EmployeeDialog extends StatefulWidget {
  final DialogMode mode;
  final Employee? employee;
  final List<Map<String, String>> availablePumps;

  const EmployeeDialog({
    super.key,
    required this.mode,
    this.employee,
    required this.availablePumps,
  });

  @override
  State<EmployeeDialog> createState() => _EmployeeDialogState();
}

class _EmployeeDialogState extends State<EmployeeDialog> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;
  late EmployeeRole _selectedRole;
  late EmployeeStatus _selectedStatus;
  String? _selectedPumpId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.mode == DialogMode.edit && widget.employee != null) {
      _nameController = TextEditingController(text: widget.employee!.name);
      _emailController = TextEditingController(text: widget.employee!.email);
      _phoneController = TextEditingController(text: widget.employee!.phone);
      _notesController = TextEditingController(text: widget.employee!.notes);
      _selectedRole = widget.employee!.role;
      _selectedStatus = widget.employee!.status;
      _selectedPumpId = widget.employee!.assignedPumpId;
    } else {
      _nameController = TextEditingController();
      _emailController = TextEditingController();
      _phoneController = TextEditingController();
      _notesController = TextEditingController();
      _selectedRole = EmployeeRole.attendant;
      _selectedStatus = widget.mode == DialogMode.invite 
          ? EmployeeStatus.pending 
          : EmployeeStatus.active;
      _selectedPumpId = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _getDialogTitle() {
    switch (widget.mode) {
      case DialogMode.add:
        return 'Add Employee';
      case DialogMode.edit:
        return 'Edit Employee';
      case DialogMode.invite:
        return 'Invite Employee';
    }
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty && widget.mode != DialogMode.invite) {
      _showError('Name is required');
      return;
    }
    if (_emailController.text.isEmpty) {
      _showError('Email is required');
      return;
    }
    if (!_emailController.text.contains('@')) {
      _showError('Enter a valid email address');
      return;
    }
    if (_phoneController.text.isEmpty && widget.mode != DialogMode.invite) {
      _showError('Phone number is required');
      return;
    }

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    final employee = Employee(
      id: widget.employee?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      role: _selectedRole,
      status: _selectedStatus,
      assignedPumpId: _selectedPumpId,
      assignedPumpName: widget.availablePumps
          .firstWhere((p) => p['id'] == _selectedPumpId, orElse: () => {})['name'],
      joinDate: widget.employee?.joinDate ?? DateTime.now(),
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    Navigator.pop(context, employee);
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

  @override
  Widget build(BuildContext context) {
    final isInvite = widget.mode == DialogMode.invite;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
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
                      color: const Color(0xFF0B3D2E).withAlpha(26),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isInvite ? Icons.send_outlined : Icons.person_add_outlined,
                      color: const Color(0xFF0B3D2E),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _getDialogTitle(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const Divider(height: 24),
              
              if (!isInvite) ...[
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'e.g., John Doe',
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: isInvite ? 'Email Address' : 'Email Address',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: isInvite ? 'employee@example.com' : 'john@station.com',
                  helperText: isInvite 
                      ? 'An invitation will be sent to this email'
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              
              if (!isInvite) ...[
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: '0712345678',
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              const Text(
                'Role',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: EmployeeRole.values.map((role) {
                  final isSelected = _selectedRole == role;
                  return ChoiceChip(
                    label: Text(role.displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedRole = role);
                      }
                    },
                    avatar: Icon(
                      role.icon,
                      color: isSelected ? Colors.white : role.color,
                      size: 16,
                    ),
                    selectedColor: role.color,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 16),
              
              const Text(
                'Assign Pump (Optional)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPumpId,
                    hint: const Text('Select a pump'),
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('None'),
                      ),
                      ...widget.availablePumps.map((pump) {
                        return DropdownMenuItem(
                          value: pump['id'],
                          child: Text(pump['name']!),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedPumpId = value;
                      });
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              if (!isInvite) ...[
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Notes (Optional)',
                    prefixIcon: const Icon(Icons.note_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'Any additional information...',
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              if (isInvite) ...[
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
                        child: Text(
                          'An invitation email will be sent with a link to download the app and set up their account.',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B3D2E),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(isInvite ? 'Send Invitation' : 'Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}