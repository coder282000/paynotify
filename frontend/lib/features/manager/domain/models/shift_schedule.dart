import 'shift_assignment.dart';
import 'shift_model.dart';

class ShiftSchedule {
  final String id;
  final String stationId;
  final DateTime weekStarting;
  final Map<String, List<ShiftAssignment>> dailyAssignments;
  final Map<String, DayType> dayTypes;
  final DateTime createdAt;
  DateTime updatedAt;

  ShiftSchedule({
    required this.id,
    required this.stationId,
    required this.weekStarting,
    required this.dailyAssignments,
    required this.dayTypes,
    required this.createdAt,
    required this.updatedAt,
  });

  List<ShiftAssignment> getAssignmentsForDay(String day) {
    return dailyAssignments[day] ?? [];
  }

  DayType getDayType(String day) {
    return dayTypes[day] ?? DayType.working;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'stationId': stationId,
    'weekStarting': weekStarting.toIso8601String(),
    'dailyAssignments': dailyAssignments.map(
      (k, v) => MapEntry(k, v.map((a) => a.toJson()).toList())
    ),
    'dayTypes': dayTypes.map((k, v) => MapEntry(k, v.name)),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ShiftSchedule.fromJson(Map<String, dynamic> json) {
    return ShiftSchedule(
      id: json['id'],
      stationId: json['stationId'],
      weekStarting: DateTime.parse(json['weekStarting']),
      dailyAssignments: (json['dailyAssignments'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(
          k,
          (v as List).map((a) => ShiftAssignment.fromJson(a)).toList()
        ),
      ),
      dayTypes: (json['dayTypes'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, DayType.values.firstWhere((e) => e.name == v))
      ),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}