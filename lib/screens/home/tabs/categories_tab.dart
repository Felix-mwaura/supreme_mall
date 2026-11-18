import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/catalogue.dart';
import '../../../models/department.dart';
import '../../../repositories/catalogue_repository.dart';
import '../../../screens/catalogue/storefront_screen.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/dark_surface.dart';

/// Merchant directory, grouped by department.
///
/// The list is the real approved merchants from `businesses` joined to their
/// departments — not sample data. Tapping a merchant opens the shared
/// [StorefrontScreen] narrowed to that merchant, so there is one storefront
/// implementation for every department.
class CategoriesTab extends StatefulWidget {
  const CategoriesTab({super.key});

  @override
  State<CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<CategoriesTab> {
  static const CatalogueRepository _repository = CatalogueRepository();

  final TextEditingController _search = TextEditingController();
  Timer? _debounce;

  String _query = '';
  String? _departmentId;
  late Future<List<MerchantSummary>> _future = _repository.merchants();

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = _repository.merchants();
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () {
      if (mounted) {
        setState(() => _query = value);
      }
    });
  }

  void _openMerchant(MerchantSummary merchant, SupremeDepartment department) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext _) => StorefrontScreen(
          department: department,
          merchant: merchant,
        ),
      ),
    );
  }

  /// Departments that are live at launch and therefore have storefronts.
  List<SupremeDepartment> get _liveDepartments => supremeDepartments
      .where((SupremeDepartment d) => d.openForApplications)
      .toList(growable: false);

  bool _matchesQuery(MerchantSummary merchant) {
    final String term = _query.trim().toLowerCase();
    if (term.isEmpty) {
      return true;
    }
    return merchant.name.toLowerCase().contains(term) ||
        merchant.area.toLowerCase().contains(term) ||
        merchant.departmentNames.any((String name) => name.toLowerCase().contains(term));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Browse',
                  style: AppText.screenTitle.copyWith(fontSize: 24, color: AppColors.inkOnDark),
                ),
                const SizedBox(height: 4),
                Text(
                  'Approved merchants across Nyeri County',
                  style: AppText.caption.copyWith(fontSize: 11, color: AppColors.inkMutedOnDark),
                ),
                const SizedBox(height: 14),
                DarkSearchField(
                  controller: _search,
                  onChanged: _onSearchChanged,
                  hint: 'Search merchants or areas',
                ),
                const SizedBox(height: 12),
                // Intrinsic height: a fixed-height box clips the chips at
                // large text sizes.
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: <Widget>[
                      DarkChip(
                        label: 'All',
                        selected: _departmentId == null,
                        onTap: () => setState(() => _departmentId = null),
                      ),
                      for (final SupremeDepartment department in _liveDepartments) ...<Widget>[
                        const SizedBox(width: 8),
                        DarkChip(
                          label: department.shortName,
                          selected: _departmentId == department.id,
                          onTap: () => setState(() => _departmentId = department.id),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.gold,
              backgroundColor: AppColors.surface,
              onRefresh: () async {
                _reload();
                try {
                  await _future;
                } catch (_) {
                  // The FutureBuilder renders the failure state.
                }
              },
              child: FutureBuilder<List<MerchantSummary>>(
                future: _future,
                builder: (
                  BuildContext context,
                  AsyncSnapshot<List<MerchantSummary>> snapshot,
                ) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
                      children: <Widget>[
                        for (int i = 0; i < 4; i++)
                          Container(
                            height: 62,
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: darkSurface(radius: 14),
                          ),
                      ],
                    );
                  }

                  if (snapshot.hasError) {
                    final Object error = snapshot.error!;
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(18, 24, 18, 120),
                      children: <Widget>[
                        DarkEmptyState(
                          icon: Icons.cloud_off_rounded,
                          title: 'Could not load merchants',
                          message: error is CatalogueFailure
                              ? error.message
                              : 'Check your connection and try again.',
                        ),
                        AppButton(
                          label: 'Try again',
                          onPressed: _reload,
                          background: AppColors.surface,
                          foreground: AppColors.gold,
                        ),
                      ],
                    );
                  }

                  final List<MerchantSummary> merchants =
                      (snapshot.data ?? const <MerchantSummary>[])
                          .where(_matchesQuery)
                          .toList();

                  if (merchants.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(18, 24, 18, 120),
                      children: <Widget>[
                        DarkEmptyState(
                          icon: _query.isEmpty
                              ? Icons.storefront_outlined
                              : Icons.search_off_rounded,
                          title: _query.isEmpty
                              ? 'No merchants listed yet'
                              : 'Nothing matches "$_query"',
                          message: _query.isEmpty
                              ? 'Businesses appear here once their application is approved.'
                              : 'Try a different name or area.',
                        ),
                      ],
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 130),
                    children: <Widget>[
                      for (final SupremeDepartment department in _liveDepartments)
                        ..._departmentSection(department, merchants),
                      const SizedBox(height: 18),
                      const DarkSectionLabel(label: 'Coming later'),
                      const SizedBox(height: 8),
                      _ComingSoonBlock(
                        departments: supremeDepartments
                            .where((SupremeDepartment d) => !d.openForApplications)
                            .toList(growable: false),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _departmentSection(
    SupremeDepartment department,
    List<MerchantSummary> merchants,
  ) {
    if (_departmentId != null && _departmentId != department.id) {
      return const <Widget>[];
    }
    final List<MerchantSummary> inDepartment = merchants
        .where((MerchantSummary m) => m.sellsIn(department.id))
        .toList(growable: false);
    if (inDepartment.isEmpty) {
      return const <Widget>[];
    }

    return <Widget>[
      Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 8),
        child: Row(
          children: <Widget>[
            Icon(department.icon, size: 14, color: department.accent),
            const SizedBox(width: 7),
            Text(
              department.shortName.toUpperCase(),
              style: AppText.sectionLabel.copyWith(
                fontSize: 9,
                letterSpacing: 1,
                color: department.accent,
              ),
            ),
            const Spacer(),
            Text(
              '${inDepartment.length}',
              style: AppText.caption.copyWith(fontSize: 9.5, color: AppColors.inkMutedOnDark),
            ),
          ],
        ),
      ),
      for (final MerchantSummary merchant in inDepartment) ...<Widget>[
        _MerchantRow(
          merchant: merchant,
          department: department,
          onTap: () => _openMerchant(merchant, department),
        ),
        const SizedBox(height: 8),
      ],
    ];
  }
}

class _MerchantRow extends StatelessWidget {
  const _MerchantRow({
    required this.merchant,
    required this.department,
    required this.onTap,
  });

  final MerchantSummary merchant;
  final SupremeDepartment department;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: darkSurface(radius: 14),
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(department.icon, size: 17, color: department.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    merchant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyTight.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkOnDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    merchant.area.isEmpty
                        ? merchant.departmentsLabel
                        : '${merchant.area} · ${merchant.departmentsLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(
                      fontSize: 9.5,
                      color: AppColors.inkMutedOnDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.inkMutedOnDark),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonBlock extends StatelessWidget {
  const _ComingSoonBlock({required this.departments});

  final List<SupremeDepartment> departments;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: darkSurface(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < departments.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Icon(departments[i].icon, size: 15, color: AppColors.inkMutedOnDark),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    departments[i].shortName,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.inkMutedOnDark),
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
                      letterSpacing: 0.8,
                      color: AppColors.inkMutedOnDark,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
