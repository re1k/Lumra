import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
 
  final String email;
  final String gender;
  final DateTime dob;
    final String role;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.gender,
    required this.dob,
    required this.role,
  });

  factory UserModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '', 
      email: data['email'] ?? '',
      gender: data['gender'] ?? '',
      dob: (data['dob'] as Timestamp?)?.toDate() ?? DateTime(2000,1,1),
      role: data['rule'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
     
      'email': email,
      'gender': gender,
      'dob': Timestamp.fromDate(dob),
      'role': role, 
    };
  }

  UserModel copyWith({
    String? name,
    String? username,  
    String? email,
    String? gender,
    DateTime? dob,
    String? role,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
     
      email: email ?? this.email,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      role: role ?? this.role,
    );
  }
}
