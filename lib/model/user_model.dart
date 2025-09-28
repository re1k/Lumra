class UserModel {
  final String name;
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final DateTime? dob;
  final String? gender;
  final String? linkedUserId;

  UserModel({
    this.name = '',
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.password = '',
    this.dob,
    this.gender,
    this.linkedUserId,
  });

  UserModel copyWith({
    String? name,
    String? firstName,
    String? lastName,
    String? email,
    String? password,
    DateTime? dob,
    String? gender,
    String? linkedUserId,
  }) {
    return UserModel(
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      password: password ?? this.password,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      linkedUserId: linkedUserId ?? this.linkedUserId,
    );
  }
}
