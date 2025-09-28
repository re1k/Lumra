import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String gender;
  final DateTime dob;
  final String role;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.gender,
    required this.dob,
    required this.role,
  });

  factory UserModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      id: doc.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      gender: (data['gender'] ?? '').toString().trim().toLowerCase(),
      dob: (data['dob'] as Timestamp?)?.toDate() ?? DateTime(2000, 1, 1),
      role: data['role'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'gender': gender,
      'dob': Timestamp.fromDate(dob),
      'role': role,
    };
  }

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? gender,
    String? email,
    DateTime? dob,
    String? role,
  }) {
    return UserModel(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      role: role ?? this.role,
    );
  }
}
