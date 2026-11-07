class UserProfile {
  final String fullName;
  final String id;
  final String email;
  final String phone;

  const UserProfile({
    required this.fullName,
    required this.id,
    this.email = '',
    this.phone = '',
  });
}
