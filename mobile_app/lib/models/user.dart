class AppUser {
  final int userId;
  final String fullName;
  final String email;
  final String role;

  AppUser({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      userId: json['user_id'],
      fullName: json['full_name'],
      email: json['email'],
      role: json['role'] ?? 'user',
    );
  }
}
