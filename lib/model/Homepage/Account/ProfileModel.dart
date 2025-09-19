
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String username;
  final String email;
  final String gender;
  final DateTime dob;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.gender,
    required this.dob,
  });

  factory UserModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      gender: data['gender'] ?? '',
      dob: (data['dob'] as Timestamp?)?.toDate() ?? DateTime(2000, 1, 1),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'username': username,
      'email': email,
      'gender': gender,
      'dob': Timestamp.fromDate(dob),
    };
  }

  UserModel copyWith({
    String? name,
    String? username,
    String? email,
    String? gender,
    DateTime? dob,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
    );
  }
}
