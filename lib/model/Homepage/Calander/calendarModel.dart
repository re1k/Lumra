import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarEvent {
  final String id;                 // Firestore doc id (event ID)
  final String title;              // Event title
  final DateTime start;            // Start time
  final DateTime end;              // End time
  final List<String> participants; // ADHD + Linked caregiver (if found)

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.participants,
  });

  //From firestore
  factory CalendarEvent.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CalendarEvent(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      start: (data['start'] as Timestamp).toDate(),
      end:   (data['end']   as Timestamp).toDate(),
      participants: List<String>.from(data['participants'] ?? const <String>[]),
    );
  }

  //To firestore
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'start': Timestamp.fromDate(start), //convert back to timestamp
      'end':   Timestamp.fromDate(end),
      'participants': participants,
    };
  }

  //Takes only the date without the time to group the events of the same date in the same day
  DateTime get dayKey => DateTime(start.year, start.month, start.day);

//   CalendarEvent copyWith({
//     String? title,
//     DateTime? start,
//     DateTime? end,
//     List<String>? participants,
//   }) {
//     return CalendarEvent(
//       id: id,
//       title: title ?? this.title,
//       start: start ?? this.start,
//       end: end ?? this.end,
//       participants: participants ?? this.participants,
//     );
//   }
}
