import 'package:flutter/material.dart';

import '../../../data/demo_data.dart';
import '../../../models/department.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text.dart';
import '../../../widgets/dark_surface.dart';

/// Categories tab — browse the departments and the businesses inside them.
///
/// This is deliberately a *directory*, not the storefront: picking a merchant
/// here will open its storefront (next milestone), which renders the retail /
/// menu / produce template for that business type.
class CategoriesTab extends StatefulWidget {
  const CategoriesTab({super.key});

  @override
  State<CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<CategoriesTab> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  String _departmentFilter = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<SupremeDepartment> get _liveDepartments =>
      supremeDepartments.where((SupremeDepartment d) => d.openForApplications).toList();

  List<SupremeDepartment> get _soonDepartments =>
      supremeDepartments.where((SupremeDepartment d) => !d.openForApplications).toList();

  bool _matches(DemoMerchant merchant, String departmentName) {
    if (_departmentFilter != 'all' && merchant.departmentId != _departmentFilter) {
      return false;
    }
    if (_query.trim().isEmpty) {
      return true;
    }
    final String needle = _query.toLowerCase();
    return merchant.name.toLowerCase().contains(needle) ||
        merchant.area.toLowerCase().contains(needle) ||
        departmentName.toLowerCase().contains(needle);
  }

  @override
  Widget build(BuildContext context) {
    final List<SupremeDepartment> visibleDepartments = _liveDepartments
        .where((SupremeDepartment d) => _departmentFilter == 'all' || d.id == _departmentFilter)
        .toList();

    final bool nothingFound = visibleDepartments.every(
      (SupremeDepartment d) => merchantsFor(d.id).where((DemoMerchant m) {
        return _matches(m, d.shortName);
      }).isEmpty,
    );

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 130),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Browse',
              style: AppText.screenTitle.copyWith(fontSize: 24, color: AppColors.inkOnDark),
            ),
            const SizedBox(height: 4),
            Text(
              'Every Supreme Mall department in one place.',
              style: AppText.caption.copyWith(color: AppColors.inkMutedOnDark),
            ),
            const SizedBox(height: 16),
            DarkSearchField(
              controller: _search,
              hint: 'Search businesses or areas',
              onChanged: (String value) => setState(() => _query = value),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  DarkChip(
                    label: 'All',
                    selected: _departmentFilter == 'all',
                    onTap: () => setState(() => _departmentFilter = 'all'),
                  ),
                  for (final SupremeDepartment d in _liveDepartments) ...<Widget>[
                    const SizedBox(width: 8),
                    DarkChip(
                      label: d.shortName,
                      icon: d.icon,
                      selected: _departmentFilter == d.id,
                      onTap: () => setState(() => _departmentFilter = d.id),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (nothingFound)
              const DarkEmptyState(
                icon: Icons.search_off_rounded,
                title: 'No matches',
                message: 'Try a different business name or area — or clear the filters.',
              )
            else
              for (final SupremeDepartment department in visibleDepartments) ...<Widget>[
                if (merchantsFor(department.id)
                    .where((DemoMerchant m) => _matches(m, department.shortName))
                    .isNotEmpty) ...<Widget>[
                  _DepartmentHeader(department: department),
                  const SizedBox(height: 9),
                  for (final DemoMerchant merchant in merchantsFor(department.id).where(
                    (DemoMerchant m) => _matches(m, department.shortName),
                  ))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _MerchantRow(merchant: merchant, department: department),
                    ),
                  const SizedBox(height: 12),
                ],
              ],

            const SizedBox(height: 6),
            const DarkSectionLabel(label: 'Coming soon'),
            for (final SupremeDepartment department in _soonDepartments)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _SoonRow(department: department),
              ),
          ],
        ),
      ),
    );
  }
}

class _DepartmentHeader extends StatelessWidget {
  const _DepartmentHeader({required this.department});

  final SupremeDepartment department;

  @override
  Widget build(BuildContext context) {
    final int count = merchantsFor(department.id).length;
    return Row(
      children: <Widget>[
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.hairlineDark),
          ),
          child: Icon(department.icon, size: 14, color: department.accent),
        ),
        const SizedBox(width: 9),
        Text(
          department.name,
          style: AppText.cardTitle.copyWith(fontSize: 13, color: AppColors.inkOnDark),
        ),
        const SizedBox(width: 8),
        Text(
          '$count',
          style: AppText.caption.copyWith(fontSize: 10, color: AppColors.inkMutedOnDark),
        ),
      ],
    );
  }
}

class _MerchantRow extends StatelessWidget {
  const _MerchantRow({required this.merchant, required this.department});

  final DemoMerchant merchant;
  final SupremeDepartment department;

  void _open(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${merchant.name} · ${department.shortName} storefront opens in the next milestone.',
            style: const TextStyle(fontSize: 12.5),
          ),
          backgroundColor: AppColors.surfaceRaised,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: darkSurface(radius: 16),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.hairlineDark),
              ),
              child: Icon(department.icon, size: 19, color: department.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          merchant.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.cardTitle.copyWith(
                            fontSize: 12.5,
                            color: AppColors.inkOnDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: merchant.isOpen ? AppColors.emerald : AppColors.inkMutedOnDark,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    merchant.priceNote ?? department.tagline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(fontSize: 9.5, color: AppColors.inkMutedOnDark),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: <Widget>[
                      const Icon(Icons.star_rounded, size: 11, color: AppColors.gold),
                      const SizedBox(width: 2),
                      Text(
                        merchant.rating.toStringAsFixed(1),
                        style: AppText.caption.copyWith(fontSize: 9, color: AppColors.inkOnDark),
                      ),
                      Text(
                        '  ·  ${merchant.area}  ·  ${merchant.deliveryMinutes} min',
                        style: AppText.caption.copyWith(fontSize: 9, color: AppColors.inkMutedOnDark),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.inkMutedOnDark),
          ],
        ),
      ),
    );
  }
}

class _SoonRow extends StatelessWidget {
  const _SoonRow({required this.department});

  final SupremeDepartment department;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: darkSurface(radius: 14),
      child: Row(
        children: <Widget>[
          Icon(department.icon, size: 17, color: AppColors.inkMutedOnDark),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  department.shortName,
                  style: AppText.cardTitle.copyWith(fontSize: 12, color: AppColors.inkOnDark),
                ),
                const SizedBox(height: 1),
                Text(
                  department.tagline,
                  style: AppText.caption.copyWith(fontSize: 9, color: AppColors.inkMutedOnDark),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              'SOON',
              style: AppText.sectionLabel.copyWith(
                fontSize: 7,
                letterSpacing: 0.7,
                color: AppColors.inkMutedOnDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
