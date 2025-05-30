class User {
  final int id;
  final String username;
  final String email;
  final String password;
  final String? profilePicturePath;
  final String? token;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    this.profilePicturePath,
    this.token,
  });
}
