import 'package:flutter/material.dart';
import '../../domain/models/shift_model.dart';

class DayTypeDialog extends StatelessWidget {
  final String day;
  final DayType currentType;
  final Function(DayType) onSave;

  const DayTypeDialog({
    super.key,
    required this.day,
    required this.currentType,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    DayType selectedType = currentType;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: 350,
        child: StatefulBuilder(
          builder: (context, setState) {
            return Column(
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
                      child: const Icon(Icons.calendar_today, color: Color(0xFF0B3D2E)),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Set Day Type: $day',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 24),
                const Text('Select day type:', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: DayType.values.map((type) {
                    final isSelected = selectedType == type;
                    return ChoiceChip(
                      label: Text(type.displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            selectedType = type;
                          });
                        }
                      },
                      selectedColor: type.color,
                      backgroundColor: type.color.withValues(alpha: 0.1),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : type.color,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      avatar: Icon(
                        _getIconForType(type),
                        size: 16,
                        color: isSelected ? Colors.white : type.color,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                if (selectedType != DayType.working)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selectedType.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: selectedType.color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(_getIconForType(selectedType), size: 20, color: selectedType.color),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getDescriptionForType(selectedType),
                            style: TextStyle(fontSize: 12, color: selectedType.color),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                        onPressed: () {
                          onSave(selectedType);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B3D2E),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('SAVE'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  IconData _getIconForType(DayType type) {
    switch (type) {
      case DayType.working:
        return Icons.work;
      case DayType.off:
        return Icons.beach_access;
      case DayType.leave:
        return Icons.holiday_village;
      case DayType.holiday:
        return Icons.celebration;
    }
  }

  String _getDescriptionForType(DayType type) {
    switch (type) {
      case DayType.working:
        return 'Regular working day with shifts';
      case DayType.off:
        return 'Station closed - no shifts assigned';
      case DayType.leave:
        return 'Employee on leave - no shifts';
      case DayType.holiday:
        return 'Public holiday - special rates apply';
    }
  }
}