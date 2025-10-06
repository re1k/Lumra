import 'package:cloud_firestore/cloud_firestore.dart';

class Activitymodel {
final String id;
final String title;
final String description;
final String category ;
final String time;
final bool isChecked;


Activitymodel({
required this.id,
required this.title,
required this.description,
required this.category,
required this.time,
//required this.isChecked,
 this.isChecked = false,
});

  factory Activitymodel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Activitymodel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      time: data['time'] ?? '',
     // isChecked: data['isChecked'] ?? '',

     isChecked: data['isChecked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'time': time,
      'isChecked': isChecked,
    };
  }


   Activitymodel copyWith({
    String? title,
    String? description,
    String? category,
    String? time,
     bool? isChecked,
  })

  {
    return Activitymodel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      time: time ?? this.time,
       isChecked: isChecked ?? this.isChecked,
  
    );
  }




}