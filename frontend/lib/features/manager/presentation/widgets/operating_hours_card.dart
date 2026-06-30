import 'package:flutter/material.dart';
import '../../domain/models/station_settings_model.dart';

class OperatingHoursCard extends StatelessWidget {
  final String day;
  final OperatingHours hours;
  final VoidCallback onTap;

  const OperatingHoursCard({
    super.key,
    required this.day,
    required this.hours,
    required this.onTap,
  });

  

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0B3D2E).withValues(alpha: 0.1),
          child: Text(
            day.substring(0, 1),
            style: const TextStyle(color: Color(0xFF0B3D2E), fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(day),
        subtitle: Text(hours.formattedHours),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: onTap,
        ),
        onTap: onTap,
      ),
    );
  }
}