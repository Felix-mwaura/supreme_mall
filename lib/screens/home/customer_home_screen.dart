import 'package:flutter/material.dart';

import '../../models/department.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/glass_bottom_nav.dart';

/// Customer dashboard — "Bento" direction.
///
/// Navy is the canvas; content lives on raised surfaces and the seven
/// departments are laid out as a bento grid: one hero tile, three medium live
/// tiles (Shopping, Food, Fresh) and four small "soon" tiles. The frosted
/// navigation floats above the content so catalogues scroll behind it.
///
/// Deliberately self-contained dark surfaces rather than a global dark
/// [ThemeData]: the auth flow is still light, and the appearance toggle
/// (System / Light / Dark) lands with the token pass in a later milestone.
class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  NavTab _tab = NavTab.home;

  static const int _cartCount = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: _tab == NavTab.home
                ? const _HomeBody()
                : _TabPlaceholder(tab: _tab),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GlassBottomNav(
              currentTab: _tab,
              cartCount: _cartCount,
              onTabSelected: (NavTab tab) => setState(() => _tab = tab),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

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
            const _TopBar(),
            const SizedBox(height: 22),
            Text(
              'Karibu tena',
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
            const _SearchField(),
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
            _BentoTile(department: live[0], wide: true, height: 96),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(child: _BentoTile(department: live[1], height: 108)),
                const SizedBox(width: 10),
                Expanded(child: _BentoTile(department: live[2], height: 108)),
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
                Text(
                  'See all',
                  style: AppText.caption.copyWith(fontSize: 10.5, color: AppColors.sky),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 108,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const <Widget>[
                  _MerchantCard(
                    name: 'Nyeri Fresh Mart',
                    department: 'Shopping',
                    detail: 'Kimathi Way · 20 min',
                    rating: '4.7',
                    accent: AppColors.sky,
                    icon: Icons.storefront_rounded,
                  ),
                  SizedBox(width: 10),
                  _MerchantCard(
                    name: 'Mama Ngina Cafe',
                    department: 'Food',
                    detail: 'Town centre · 25 min',
                    rating: '4.8',
                    accent: AppColors.gold,
                    icon: Icons.restaurant_rounded,
                  ),
                  SizedBox(width: 10),
                  _MerchantCard(
                    name: 'Karatina Greens',
                    department: 'Fresh',
                    detail: 'Market day · 40 min',
                    rating: '4.6',
                    accent: AppColors.emerald,
                    icon: Icons.eco_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.fromLTRB(11, 9, 9, 9),
              decoration: _glassDecoration(radius: 100),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.place_outlined, size: 14, color: AppColors.sky),
                  const SizedBox(width: 6),
                  Text(
                    'Nyeri Town',
                    style: AppText.caption.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkOnDark,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.expand_more, size: 14, color: AppColors.inkMutedOnDark),
                ],
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

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _glassDecoration(radius: 16),
      child: Row(
        children: <Widget>[
          const Icon(Icons.search_rounded, size: 19, color: AppColors.inkMutedOnDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Search shops, food, produce',
              style: AppText.bodyTight.copyWith(color: AppColors.inkMutedOnDark),
            ),
          ),
          const Icon(Icons.tune_rounded, size: 17, color: AppColors.inkMutedOnDark),
        ],
      ),
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
  });

  final SupremeDepartment department;
  final double height;
  final bool wide;
  final bool compact;

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

    return Container(
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

class _MerchantCard extends StatelessWidget {
  const _MerchantCard({
    required this.name,
    required this.department,
    required this.detail,
    required this.rating,
    required this.accent,
    required this.icon,
  });

  final String name;
  final String department;
  final String detail;
  final String rating;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                child: Icon(icon, size: 14, color: accent),
              ),
              const Spacer(),
              const Icon(Icons.star_rounded, size: 12, color: AppColors.gold),
              const SizedBox(width: 2),
              Text(
                rating,
                style: AppText.caption.copyWith(fontSize: 9.5, color: AppColors.inkOnDark),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.cardTitle.copyWith(fontSize: 11.5, color: AppColors.inkOnDark),
          ),
          const SizedBox(height: 2),
          Text(
            department,
            style: AppText.caption.copyWith(fontSize: 9, color: accent),
          ),
          const SizedBox(height: 1),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption.copyWith(fontSize: 8.8, color: AppColors.inkMutedOnDark),
          ),
        ],
      ),
    );
  }
}

class _TabPlaceholder extends StatelessWidget {
  const _TabPlaceholder({required this.tab});

  final NavTab tab;

  String get _label {
    switch (tab) {
      case NavTab.categories:
        return 'Categories';
      case NavTab.cart:
        return 'Cart';
      case NavTab.orders:
        return 'Orders';
      case NavTab.profile:
        return 'Profile';
      case NavTab.home:
        return 'Home';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.construction_rounded, size: 30, color: AppColors.inkMutedOnDark),
            const SizedBox(height: 12),
            Text(
              _label,
              style: AppText.screenTitle.copyWith(fontSize: 17, color: AppColors.inkOnDark),
            ),
            const SizedBox(height: 5),
            Text(
              'Arrives in the next milestone',
              style: AppText.caption.copyWith(color: AppColors.inkMutedOnDark),
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _glassDecoration({required double radius}) {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.hairlineDark),
  );
}
