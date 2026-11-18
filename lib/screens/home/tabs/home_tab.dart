import 'package:flutter/material.dart';

import 'package:supreme_mall/models/catalogue.dart';
import 'package:supreme_mall/models/department.dart';
import 'package:supreme_mall/repositories/catalogue_repository.dart';
import 'package:supreme_mall/screens/catalogue/storefront_screen.dart';
import 'package:supreme_mall/theme/app_colors.dart';
import 'package:supreme_mall/theme/app_text.dart';
import 'package:supreme_mall/widgets/dark_surface.dart';

/// Home tab of the customer shell — the "Bento" service grid.
///
/// Navy is the canvas; content lives on raised surfaces and the seven
/// departments are laid out as a bento grid: one hero tile, three medium live
/// tiles (Shopping, Food, Fresh) and four small "soon" tiles. The frosted
/// navigation floats above the content so catalogues scroll behind it.
///
/// Deliberately self-contained dark surfaces rather than a global dark
/// [ThemeData]: the auth flow is still light, and the appearance toggle
/// (System / Light / Dark) lands with the token pass in a later milestone.
class HomeTab extends StatelessWidget {
  const HomeTab({
    super.key,
    this.onOpenCategories,
    this.firstName,
    this.area,
    this.onPickArea,
    this.onOpenDepartment,
  });

  /// Switches the shell to the Categories tab ("See all").
  final VoidCallback? onOpenCategories;

  /// Signed-in customer's first name, for a personal greeting.
  final String? firstName;

  /// Delivery area the customer picked, and how to change it.
  final String? area;
  final VoidCallback? onPickArea;

  /// Opens a live department's storefront. Falls back to the Categories tab.
  final ValueChanged<SupremeDepartment>? onOpenDepartment;

  /// A live tile always ends up in that department's storefront: the shell
  /// supplies the callback, and the tab can still open it on its own (tests,
  /// or any future screen that embeds the dashboard).
  /// The search bar on Home is a doorway, not a second search engine: tapping
  /// it opens the merchant directory, where the query actually filters live
  /// data. Without the shell's callback the Shopping storefront is the closest
  /// equivalent, and it carries the same search field.
  VoidCallback _openSearch(BuildContext context) {
    return () {
      final VoidCallback? open = onOpenCategories;
      if (open != null) {
        open();
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext _) => StorefrontScreen(
            department: supremeDepartments.firstWhere(
              (SupremeDepartment d) => d.id == 'shopping',
              orElse: () => supremeDepartments.first,
            ),
          ),
        ),
      );
    };
  }

  VoidCallback _openDepartment(BuildContext context, SupremeDepartment department) {
    return () {
      final ValueChanged<SupremeDepartment>? open = onOpenDepartment;
      if (open != null) {
        open(department);
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext _) => StorefrontScreen(department: department),
        ),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    final List<SupremeDepartment> live =
        supremeDepartments.where((SupremeDepartment d) => d.openForApplications).toList();
    final List<SupremeDepartment> soon =
        supremeDepartments.where((SupremeDepartment d) => !d.openForApplications).toList();

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 130),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _TopBar(area: area, onPickArea: onPickArea),
            const SizedBox(height: 22),
            Text(
              firstName == null ? 'Karibu tena' : 'Karibu tena, $firstName',
              style: AppText.caption.copyWith(color: AppColors.inkMutedOnDark, fontSize: 12.5),
            ),
            const SizedBox(height: 5),
            Text.rich(
              TextSpan(
                style: AppText.display.copyWith(
                  fontSize: 25,
                  height: 1.18,
                  color: AppColors.inkOnDark,
                ),
                children: const <TextSpan>[
                  TextSpan(text: 'What do you need\n'),
                  TextSpan(text: 'today?', style: TextStyle(color: AppColors.gold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Inert field inside a tappable shell: a tap cannot raise a
            // keyboard that types into nothing, and the card still announces
            // itself as a button to screen readers.
            Semantics(
              button: true,
              label: 'Search merchants',
              child: GestureDetector(
                onTap: _openSearch(context),
                behavior: HitTestBehavior.opaque,
                child: const IgnorePointer(child: DarkSearchField()),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                Text(
                  'SERVICES',
                  style: AppText.sectionLabel.copyWith(
                    color: AppColors.inkMutedOnDark,
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                Text(
                  '3 live now',
                  style: AppText.caption.copyWith(fontSize: 10, color: AppColors.gold),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Bento: hero (Shopping), two medium (Food, Fresh).
            _BentoTile(
              department: live[0],
              wide: true,
              height: 96,
              onTap: _openDepartment(context, live[0]),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: _BentoTile(
                    department: live[1],
                    height: 108,
                    onTap: _openDepartment(context, live[1]),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _BentoTile(
                    department: live[2],
                    height: 108,
                    onTap: _openDepartment(context, live[2]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Four small tiles for the later-phase departments.
            for (int i = 0; i < soon.length; i += 2) ...<Widget>[
              Row(
                children: <Widget>[
                  Expanded(child: _BentoTile(department: soon[i], height: 82, compact: true)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: i + 1 < soon.length
                        ? _BentoTile(department: soon[i + 1], height: 82, compact: true)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
              if (i + 2 < soon.length) const SizedBox(height: 10),
            ],

            const SizedBox(height: 22),
            const _ActiveOrderCard(),
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                Text(
                  'NEAR YOU',
                  style: AppText.sectionLabel.copyWith(
                    color: AppColors.inkMutedOnDark,
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onOpenCategories,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    'See all',
                    style: AppText.caption.copyWith(fontSize: 10.5, color: AppColors.sky),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            NearYouRow(
              onOpenMerchant: (MerchantSummary merchant, SupremeDepartment department) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext _) => StorefrontScreen(
                      department: department,
                      merchant: merchant,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({this.area, this.onPickArea});

  final String? area;
  final VoidCallback? onPickArea;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: onPickArea,
              behavior: HitTestBehavior.opaque,
              // 48 dp touch target; the visible pill stays compact.
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(11, 9, 9, 9),
                  decoration: _glassDecoration(radius: 100),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.place_outlined, size: 14, color: AppColors.sky),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 130),
                        child: Text(
                          area ?? 'Choose area',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.caption.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkOnDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.expand_more,
                        size: 14,
                        color: AppColors.inkMutedOnDark,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 40,
          height: 40,
          decoration: _glassDecoration(radius: 100),
          child: Stack(
            children: <Widget>[
              const Center(
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 19,
                  color: AppColors.inkOnDark,
                ),
              ),
              Positioned(
                right: 9,
                top: 9,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One bento cell. Live departments get their accent tint; later-phase
/// departments stay monochrome with a "soon" badge so the grid never promises
/// a service that is not running yet.
class _BentoTile extends StatelessWidget {
  const _BentoTile({
    required this.department,
    required this.height,
    this.wide = false,
    this.compact = false,
    this.onTap,
  });

  final SupremeDepartment department;
  final double height;
  final bool wide;
  final bool compact;
  final VoidCallback? onTap;

  // Explicit const tints so no runtime colour maths is needed.
  static const Map<String, Color> _tint = <String, Color>{
    'shopping': Color(0x333498DB),
    'food': Color(0x33D4A017),
    'fresh': Color(0x3327AE60),
  };
  static const Map<String, Color> _edge = <String, Color>{
    'shopping': Color(0x5C3498DB),
    'food': Color(0x5CD4A017),
    'fresh': Color(0x5C27AE60),
  };

  @override
  Widget build(BuildContext context) {
    final bool live = department.openForApplications;
    final Color accent = live ? department.accent : AppColors.inkMutedOnDark;
    final double chipSize = wide ? 42 : (compact ? 28 : 34);

    final Widget tile = Container(
      height: height,
      padding: EdgeInsets.all(compact ? 11 : 14),
      decoration: BoxDecoration(
        color: live ? null : AppColors.surface,
        gradient: live
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[_tint[department.id] ?? AppColors.surface, AppColors.surface],
              )
            : null,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: live ? (_edge[department.id] ?? AppColors.hairlineDark) : AppColors.hairlineDark,
        ),
      ),
      child: wide
          ? Row(
              children: <Widget>[
                _IconChip(icon: department.icon, accent: accent, size: chipSize, tinted: live),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        department.shortName,
                        style: AppText.cardTitle.copyWith(
                          fontSize: 15.5,
                          color: AppColors.inkOnDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '12 stores open near you',
                        style: AppText.caption.copyWith(
                          fontSize: 10,
                          color: AppColors.inkMutedOnDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, size: 17, color: accent),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _IconChip(icon: department.icon, accent: accent, size: chipSize, tinted: live),
                const Spacer(),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        department.shortName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.cardTitle.copyWith(
                          fontSize: compact ? 11.5 : 12.5,
                          color: AppColors.inkOnDark,
                        ),
                      ),
                    ),
                    if (!live)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
                const SizedBox(height: 1),
                Text(
                  live ? department.tagline : 'Coming in a later phase',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(
                    fontSize: 8.8,
                    color: AppColors.inkMutedOnDark,
                  ),
                ),
              ],
            ),
    );

    if (onTap == null) {
      return tile;
    }
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: tile,
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({
    required this.icon,
    required this.accent,
    required this.size,
    required this.tinted,
  });

  final IconData icon;
  final Color accent;
  final double size;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: tinted ? AppColors.glassEdge : AppColors.hairlineDark),
      ),
      child: Icon(icon, size: size * 0.52, color: accent),
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.hairlineDark),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Order #SM-1042 · On the way',
                  style: AppText.caption.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkOnDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Nyeri Fresh Mart · rider Brian, 12 min',
                  style: AppText.caption.copyWith(fontSize: 9.5, color: AppColors.inkMutedOnDark),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.goldSoft,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: const Color(0x4DD4A017)),
            ),
            child: Text(
              'Track',
              style: AppText.caption.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Near you" strip: approved merchants from the database.
///
/// Loads once, keeps its own loading/empty/error state, and shows nothing at
/// all rather than a fake name if the catalogue is unreachable.
class NearYouRow extends StatefulWidget {
  const NearYouRow({super.key, required this.onOpenMerchant});

  final void Function(MerchantSummary merchant, SupremeDepartment department) onOpenMerchant;

  @override
  State<NearYouRow> createState() => _NearYouRowState();
}

class _NearYouRowState extends State<NearYouRow> {
  static const CatalogueRepository _repository = CatalogueRepository();
  late Future<List<MerchantSummary>> _future = _repository.merchants(limit: 8);

  @override
  Widget build(BuildContext context) {
    // Height allows for a 130 % text setting, which the cards clamp to: a
    // taller strip beats a RenderFlex overflow on the home screen.
    return SizedBox(
      height: 124,
      child: FutureBuilder<List<MerchantSummary>>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<List<MerchantSummary>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                for (int i = 0; i < 3; i++)
                  Container(
                    width: 156,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
              ],
            );
          }

          final List<MerchantSummary> merchants = snapshot.data ?? const <MerchantSummary>[];
          if (snapshot.hasError || merchants.isEmpty) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.hairlineDark),
              ),
              child: Text(
                snapshot.hasError
                    ? 'Merchants could not load. Pull to refresh later.'
                    : 'No approved merchants near you yet.',
                style: AppText.caption.copyWith(fontSize: 10.5, color: AppColors.inkMutedOnDark),
              ),
            );
          }

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: merchants.length,
            separatorBuilder: (BuildContext _, int __) => const SizedBox(width: 10),
            itemBuilder: (BuildContext context, int index) {
              final MerchantSummary merchant = merchants[index];
              final SupremeDepartment department = supremeDepartments.firstWhere(
                (SupremeDepartment d) => merchant.sellsIn(d.id),
                orElse: () => supremeDepartments.first,
              );
              return _MerchantCard(
                merchant: merchant,
                department: department,
                onTap: () => widget.onOpenMerchant(merchant, department),
              );
            },
          );
        },
      ),
    );
  }
}

class _MerchantCard extends StatelessWidget {
  const _MerchantCard({
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
      // The strip has a fixed height, so the labels are clamped to the size
      // that height was measured against.
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: Container(
          width: 156,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.hairlineDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(department.icon, size: 14, color: department.accent),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 13,
                    color: AppColors.inkMutedOnDark,
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                merchant.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.cardTitle.copyWith(fontSize: 11.5, color: AppColors.inkOnDark),
              ),
              const SizedBox(height: 2),
              Text(
                department.shortName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption.copyWith(fontSize: 9, color: department.accent),
              ),
              const SizedBox(height: 1),
              Text(
                merchant.area,
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
      ),
    );
  }
}
