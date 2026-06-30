// lib/features/manager/presentation/widgets/quick_actions.dart

import 'package:flutter/material.dart';
import '../screens/employee_management_screen.dart';
import '../screens/shift_report_screen.dart';
import '../screens/pump_management_screen.dart';
import '../screens/sales_analytics_screen.dart'; // ADD THIS IMPORT

class QuickActions extends StatelessWidget {
  final VoidCallback onRefresh;
  final bool isDesktop;
  final bool isTablet;

  const QuickActions({
    super.key,
    required this.onRefresh,
    required this.isDesktop,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        if (isDesktop)
          Row(
            children: [
              Expanded(child: _buildActionCard(
                icon: Icons.person_add,
                label: 'Add Attendant',
                color: Colors.blue,
                onTap: () => _navigateToEmployeeManagement(context),
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildActionCard(
                icon: Icons.receipt,
                label: 'Review Reports',
                color: Colors.orange,
                onTap: () => _navigateToShiftReports(context),
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildActionCard(
                icon: Icons.settings,
                label: 'Configure Pumps',
                color: Colors.green,
                onTap: () => _navigateToPumpManagement(context),
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildActionCard(
                icon: Icons.bar_chart,
                label: 'View Analytics',
                color: Colors.purple,
                onTap: () => _navigateToSalesAnalytics(context), // CHANGED THIS
              )),
            ],
          )
        else if (isTablet)
          Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildActionCard(
                    icon: Icons.person_add,
                    label: 'Add Attendant',
                    color: Colors.blue,
                    onTap: () => _navigateToEmployeeManagement(context),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _buildActionCard(
                    icon: Icons.receipt,
                    label: 'Review Reports',
                    color: Colors.orange,
                    onTap: () => _navigateToShiftReports(context),
                  )),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildActionCard(
                    icon: Icons.settings,
                    label: 'Configure Pumps',
                    color: Colors.green,
                    onTap: () => _navigateToPumpManagement(context),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _buildActionCard(
                    icon: Icons.bar_chart,
                    label: 'View Analytics',
                    color: Colors.purple,
                    onTap: () => _navigateToSalesAnalytics(context), // CHANGED THIS
                  )),
                ],
              ),
            ],
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionChip(
                icon: Icons.person_add,
                label: 'Add Attendant',
                color: Colors.blue,
                onTap: () => _navigateToEmployeeManagement(context),
              ),
              _buildActionChip(
                icon: Icons.receipt,
                label: 'Review Reports',
                color: Colors.orange,
                onTap: () => _navigateToShiftReports(context),
              ),
              _buildActionChip(
                icon: Icons.settings,
                label: 'Configure Pumps',
                color: Colors.green,
                onTap: () => _navigateToPumpManagement(context),
              ),
              _buildActionChip(
                icon: Icons.bar_chart,
                label: 'View Analytics',
                color: Colors.purple,
                onTap: () => _navigateToSalesAnalytics(context), // CHANGED THIS
              ),
              _buildActionChip(
                icon: Icons.refresh,
                label: 'Refresh',
                color: Colors.grey,
                onTap: onRefresh,
              ),
            ],
          ),
      ],
    );
  }

  // Navigation helper methods
  void _navigateToEmployeeManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmployeeManagementScreen(),
      ),
    );
  }

  void _navigateToShiftReports(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ShiftReportsScreen(),
      ),
    );
  }

  void _navigateToPumpManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PumpManagementScreen(),
      ),
    );
  }

  void _navigateToSalesAnalytics(BuildContext context) { // ADD THIS METHOD
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SalesAnalyticsScreen(),
      ),
    );
  }

 

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      onPressed: onTap,
      backgroundColor: color.withAlpha(26),
    );
  }
}