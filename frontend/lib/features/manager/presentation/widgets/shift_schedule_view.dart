import 'package:flutter/material.dart';
import '../../domain/models/shift_assignment.dart';
import '../../domain/models/shift_schedule.dart';
import '../../domain/models/shift_model.dart';

class ShiftScheduleView extends StatelessWidget {
  final ShiftSchedule schedule;
  final Map<String, List<ShiftAssignment>> assignments;
  final Function(String, ShiftAssignment) onAssignmentTap;
  final Function(String) onDayTypeTap;

   ShiftScheduleView({
    super.key,
    required this.schedule,
    required this.assignments,
    required this.onAssignmentTap,
    required this.onDayTypeTap,
  });

  final List<String> _daysOfWeek = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _daysOfWeek.length,
      itemBuilder: (context, index) {
        final day = _daysOfWeek[index];
        final dayType = schedule.getDayType(day);
        final dayAssignments = assignments[day] ?? [];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day Header
              InkWell(
                onTap: () => onDayTypeTap(day),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: dayType.color.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              day,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dayType.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                color: dayType.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.edit_outlined,
                        color: dayType.color,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Shift Assignments
              if (dayType == DayType.working)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: dayAssignments.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No shifts assigned',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: dayAssignments.map((assignment) {
                            return _buildAssignmentTile(assignment);
                          }).toList(),
                        ),
                ),
              
              if (dayType != DayType.working)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      dayType == DayType.off ? 'Station Closed' : 'No shifts scheduled',
                      style: TextStyle(
                        color: dayType.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAssignmentTile(ShiftAssignment assignment) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: assignment.shiftType.color.withValues(alpha: 0.1),
        child: Icon(
          assignment.shiftType.icon,
          color: assignment.shiftType.color,
          size: 20,
        ),
      ),
      title: Text(assignment.attendantName),
      subtitle: Text(assignment.shiftType.displayName),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: assignment.status.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          assignment.status.displayName,
          style: TextStyle(
            fontSize: 11,
            color: assignment.status.color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      onTap: () => onAssignmentTap(assignment.id, assignment),
    );
  }
}