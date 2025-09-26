class UserModel {
  final String name;
  final String email;
  final String password;
  final DateTime? dob;
  final String? gender;
  final String? linkedUserId;

  UserModel({
    this.name = '',
    this.email = '',
    this.password = '',
    this.dob,
    this.gender,
    this.linkedUserId,
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? password,
    DateTime? dob,
    String? gender,
    String? linkedUserId,
  }) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      linkedUserId: linkedUserId ?? this.linkedUserId,
    );
  }
}
