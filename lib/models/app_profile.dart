/// The signed-in user's row in `public.profiles`.
class AppProfile {
  const AppProfile({
    required this.id,
    required this.fullName,
    required this.role,
    this.phone,
  });

  factory AppProfile.fromMap(Map<String, dynamic> map) {
    return AppProfile(
      id: map['id'] as String,
      fullName: (map['full_name'] as String?) ?? '',
      phone: map['phone'] as String?,
      role: map['role'] as String? ?? 'customer',
    );
  }

  final String id;
  final String fullName;
  final String? phone;

  /// `customer` | `business_owner` | `admin` — enforced in the database.
  final String role;

  bool get isBusiness => role == 'business_owner';
  bool get isAdmin => role == 'admin';

  String get firstName {
    final String trimmed = fullName.trim();
    if (trimmed.isEmpty) {
      return 'there';
    }
    return trimmed.split(' ').first;
  }

  /// "WK" for "Wanjiku Kamau"; falls back to the email's first letter.
  String get initials {
    final List<String> parts =
        fullName.trim().split(RegExp(r'\s+')).where((String p) => p.isNotEmpty).toList();
    if (parts.isEmpty) {
      return 'SM';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}
