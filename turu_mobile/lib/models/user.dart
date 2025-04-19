class User {
  final int id;
  final String username;
  final String password;
  final String? birthDate;
  final String? gender;

  User({
    required this.id,
    required this.username,
    required this.password,
    this.birthDate,
    this.gender,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      password: json['password'],
      birthDate: json['birth_date'],
      gender: json['gender'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'birth_date': birthDate,
      'gender': gender,
    };
  }
}
