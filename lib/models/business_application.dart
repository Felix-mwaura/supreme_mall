/// Business approval states — mirrors the `public.business_status` enum.
enum BusinessStatus {
  pending,
  approved,
  rejected,
  suspended;

  static BusinessStatus fromDb(Object? value) {
    switch (value) {
      case 'approved':
        return BusinessStatus.approved;
      case 'rejected':
        return BusinessStatus.rejected;
      case 'suspended':
        return BusinessStatus.suspended;
      default:
        return BusinessStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case BusinessStatus.pending:
        return 'Pending review';
      case BusinessStatus.approved:
        return 'Approved';
      case BusinessStatus.rejected:
        return 'Rejected';
      case BusinessStatus.suspended:
        return 'Suspended';
    }
  }

  /// Only an approved business can list products and accept orders.
  bool get canSell => this == BusinessStatus.approved;
}

/// A merchant's row in `public.businesses` plus its departments.
class BusinessApplication {
  const BusinessApplication({
    required this.id,
    required this.name,
    required this.status,
    required this.area,
    required this.departments,
    this.rejectionReason,
  });

  factory BusinessApplication.fromMap(Map<String, dynamic> map) {
    final List<dynamic> departmentRows =
        (map['business_departments'] as List<dynamic>?) ?? const <dynamic>[];

    return BusinessApplication(
      id: map['id'] as String,
      name: (map['name'] as String?) ?? 'Your business',
      status: BusinessStatus.fromDb(map['status']),
      area: (map['area'] as String?) ?? '',
      rejectionReason: map['rejection_reason'] as String?,
      departments: departmentRows
          .map((dynamic row) {
            final Map<String, dynamic> dept =
                (row as Map<String, dynamic>)['departments'] as Map<String, dynamic>? ??
                    <String, dynamic>{};
            return (dept['name'] as String?) ?? (dept['id'] as String?) ?? '';
          })
          .where((String name) => name.isNotEmpty)
          .toList(),
    );
  }

  final String id;
  final String name;
  final BusinessStatus status;
  final String area;
  final List<String> departments;
  final String? rejectionReason;
}
