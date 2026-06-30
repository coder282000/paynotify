// lib/features/supervisor/domain/models/supervisor_session.dart

class SupervisorSession {
  final String id;
  final String supervisorId;
  final String supervisorName;
  final DateTime startTime;
  final DateTime? endTime;
  final int interventionsCount;
  final bool isActive;

  const SupervisorSession({
    required this.id,
    required this.supervisorId,
    required this.supervisorName,
    required this.startTime,
    this.endTime,
    this.interventionsCount = 0,
    this.isActive = true,
  });

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  String get durationFormatted {
    final diff = duration;
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }
}