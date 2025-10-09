import 'package:cloud_firestore/cloud_firestore.dart';

class ReminderModel {
  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final List<String> participants;
  final String createdBy;
  final DateTime createdAt;

  const ReminderModel({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.participants,
    required this.createdBy,
    required this.createdAt,
  });

  factory ReminderModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;

    return ReminderModel(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      start: (data['start'] as Timestamp).toDate(),
      end: (data['end'] as Timestamp).toDate(),
      participants: List<String>.from(data['participants'] ?? const <String>[]),
      createdBy: (data['created_by'] ?? '') as String,
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  String get timeRange {
    final startTime = _formatTime(start);
    final endTime = _formatTime(end);
    return '$startTime - $endTime';
  }

  String get dateTimeRange {
    final startDate = _formatDate(start);
    final startTime = _formatTime(start);
    final endTime = _formatTime(end);
    return '$startDate $startTime - $endTime';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final reminderDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (reminderDate == today) {
      return 'Today';
    } else if (reminderDate == tomorrow) {
      return 'Tomorrow';
    } else {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[dateTime.weekday - 1];
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'participants': participants,
      'created_by': createdBy,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
