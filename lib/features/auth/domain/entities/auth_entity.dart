class AuthEntity {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String? country;
  final String? bio;
  final String role;
  final String? profilePic;
  final List<String> savedUniversities;
  final String? token;
  final String? password; // only used on submit

  AuthEntity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.country,
    this.bio,
    this.role = 'user',
    this.profilePic,
    this.savedUniversities = const [],
    this.token,
    this.password,
  });
}
