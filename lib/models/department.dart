import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The seven Supreme Mall service departments.
///
/// Defined in the Developer Brief (section 4) and scoped for launch in the
/// Phase 1 Roadmap (section 2.2): Shopping, Food and Fresh go live first while
/// the rest are shown as "coming soon" so the platform reads as one product.
class SupremeDepartment {
  const SupremeDepartment({
    required this.id,
    required this.name,
    required this.tagline,
    required this.icon,
    required this.accent,
    required this.openForApplications,
  });

  final String id;
  final String name;
  final String tagline;
  final IconData icon;
  final Color accent;

  /// Phase 1 departments accept merchant applications now; later-phase
  /// departments are shown but waitlisted.
  final bool openForApplications;

  /// "Supreme Shopping" -> "Shopping"
  String get shortName => name.replaceFirst('Supreme ', '');
}

const List<SupremeDepartment> supremeDepartments = <SupremeDepartment>[
  SupremeDepartment(
    id: 'shopping',
    name: 'Supreme Shopping',
    tagline: 'Supermarkets & retail',
    icon: Icons.storefront_outlined,
    accent: AppColors.sky,
    openForApplications: true,
  ),
  SupremeDepartment(
    id: 'food',
    name: 'Supreme Food',
    tagline: 'Restaurants & takeaways',
    icon: Icons.restaurant_menu,
    accent: AppColors.gold,
    openForApplications: true,
  ),
  SupremeDepartment(
    id: 'fresh',
    name: 'Supreme Fresh',
    tagline: 'Farm & market produce',
    icon: Icons.eco_outlined,
    accent: AppColors.emerald,
    openForApplications: true,
  ),
  SupremeDepartment(
    id: 'rides',
    name: 'Supreme Rides',
    tagline: 'Cabs & scheduled trips',
    icon: Icons.local_taxi_outlined,
    accent: AppColors.sky,
    openForApplications: false,
  ),
  SupremeDepartment(
    id: 'boda',
    name: 'Supreme Boda',
    tagline: 'Rider transport & parcels',
    icon: Icons.two_wheeler_outlined,
    accent: AppColors.sky,
    openForApplications: false,
  ),
  SupremeDepartment(
    id: 'errands',
    name: 'Supreme Errands',
    tagline: 'Shopping runs & pick-ups',
    icon: Icons.assignment_outlined,
    accent: AppColors.gold,
    openForApplications: false,
  ),
  SupremeDepartment(
    id: 'home',
    name: 'Supreme Home',
    tagline: 'Repairs & household help',
    icon: Icons.home_repair_service_outlined,
    accent: AppColors.emerald,
    openForApplications: false,
  ),
];

/// Departments that can be selected during business registration today.
List<SupremeDepartment> get phaseOneDepartments =>
    supremeDepartments.where((SupremeDepartment d) => d.openForApplications).toList();
