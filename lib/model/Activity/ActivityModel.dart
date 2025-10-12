import 'package:cloud_firestore/cloud_firestore.dart';

// Activitymodel can represent:
// 1- A shared INITIAL template (from `initialActivities`) where isInitial=true
// 2- A per-user CHATBOT activity (from `users/{uid}/activities`) where isInitial=false
//
// Fields:
// isChecked / checkedAt / expireAt:
//   • For INITIAL templates: these are populated by merging a user's status doc
//     from `users/{uid}/activityStatus/{templateId}` (not on the template doc itself).
//   • For CHATBOT activities → these live directly on the per-user doc.
class Activitymodel {
  // Identity & content
  final String? id; // INITIAL: templateId | CHATBOT: user activity doc id
  final String title;
  final String description;
  final String category;
  final String time;

  // Per-user state
  final bool isChecked;
  final Timestamp? checkedAt;
  final Timestamp? expireAt;

  // Source flag
  final bool isInitial; // true = initial template; false = per-user chatbot

  Activitymodel({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.time,
    this.isChecked = false,
    this.checkedAt,
    this.expireAt,
    this.isInitial = false,
  });

  // Use for per-user CHATBOT docs: `users/{uid}/activities/{docId}`
  factory Activitymodel.fromUserActivityDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return Activitymodel(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      time: (data['time'] ?? '').toString(),
      isChecked: (data['isChecked'] ?? false) is bool
          ? data['isChecked'] as bool
          : false,
      checkedAt: data['checkedAt'] is Timestamp
          ? data['checkedAt'] as Timestamp
          : null,
      expireAt: data['expireAt'] is Timestamp
          ? data['expireAt'] as Timestamp
          : null,
      isInitial: false,
    );
  }

  // Use for shared INITIAL templates: `initialActivities/{templateId}`
  // (Per-user flags are merged later via activityStatus.)
  factory Activitymodel.fromInitialTemplateDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return Activitymodel(
      id: doc.id, // templateId
      title: (data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      time: (data['time'] ?? '').toString(),
      isChecked: false,
      checkedAt: null,
      expireAt: null,
      isInitial: true,
    );
  }

  // For saving a per-user CHATBOT activity doc.
  Map<String, dynamic> toUserActivityJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'time': time,
      'isChecked': isChecked,
      'checkedAt': checkedAt,
      'expireAt': expireAt,
    };
  }

  // For saving a per-user STATUS doc of an INITIAL template: `activityStatus/{templateId}`
  Map<String, dynamic> toStatusJson() {
    return {
      'isChecked': isChecked,
      'checkedAt': checkedAt,
      'expireAt': expireAt,
    };
  }

  // Copier with all fields (handy for small updates)
  Activitymodel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? time,
    bool? isChecked,
    Timestamp? checkedAt,
    Timestamp? expireAt,
    bool? isInitial,
  }) {
    return Activitymodel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      time: time ?? this.time,
      isChecked: isChecked ?? this.isChecked,
      checkedAt: checkedAt ?? this.checkedAt,
      expireAt: expireAt ?? this.expireAt,
      isInitial: isInitial ?? this.isInitial,
    );
  }
}
