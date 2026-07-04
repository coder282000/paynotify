// lib/features/owner/widgets/employee_card.dart
import 'package:flutter/material.dart';
import '../domain/models/employee_model.dart';

class EmployeeCard extends StatelessWidget {
  final OwnerEmployee employee;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onApprove;        // ✅ ADDED
  final VoidCallback? onResendInvite;   // ✅ ADDED

  const EmployeeCard({
    super.key,
    required this.employee,
    this.onTap,
    this.onEdit,
    this.onApprove,                     // ✅ ADDED
    this.onResendInvite,                // ✅ ADDED
  });

  @override
  Widget build(BuildContext context) {
    final bool isPending = employee.status == 'pending';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getRoleColor(employee.roleColorValue).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    employee.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getRoleColor(employee.roleColorValue),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getRoleColor(employee.roleColorValue).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            employee.roleDisplay,
                            style: TextStyle(
                              fontSize: 10,
                              color: _getRoleColor(employee.roleColorValue),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: employee.isActive 
                                ? Colors.green.withValues(alpha: 0.1) 
                                : (isPending 
                                    ? Colors.orange.withValues(alpha: 0.1) 
                                    : Colors.red.withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            employee.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: employee.isActive 
                                  ? Colors.green 
                                  : (isPending 
                                      ? Colors.orange 
                                      : Colors.red),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      employee.email,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Action Buttons (Approve/Resend for pending)
              if (isPending) ...[
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (onApprove != null)
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 22),
                        onPressed: onApprove,
                        tooltip: 'Approve',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    if (onResendInvite != null)
                      IconButton(
                        icon: const Icon(Icons.send_outlined, color: Colors.blue, size: 20),
                        onPressed: onResendInvite,
                        tooltip: 'Resend Invitation',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ],
              // Performance Score (only for active employees)
              if (!isPending) ...[
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            value: employee.performanceScore / 100,
                            strokeWidth: 4,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getPerformanceColor(employee.performanceScore),
                            ),
                          ),
                        ),
                        Text(
                          '${employee.performanceScore.toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Performance',
                      style: TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  ],
                ),
              ],
              // Edit Button
              if (onEdit != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String colorValue) {
    switch (colorValue) {
      case 'purple': return const Color(0xFF9B59B6);
      case 'orange': return const Color(0xFFF39C12);
      case 'green': return const Color(0xFF2ECC71);
      default: return Colors.grey;
    }
  }

  Color _getPerformanceColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}