import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

enum NavTab { home, categories, cart, orders, profile }

/// Floating frosted-glass bottom navigation.
///
/// The bar sits above the content (it is added with a [Stack], not as
/// `Scaffold.bottomNavigationBar`) so the catalogue genuinely scrolls *behind*
/// it — that is what makes the blur read as glass rather than as a painted
/// panel. The selected tab scales up and lifts slightly, with a tinted pill
/// fading in behind it.
///
/// Performance: [BackdropFilter] is the most expensive element on screen for
/// low-end Android GPUs. [enableBlur: false] keeps the exact same look with a
/// flat translucent fill instead of a live blur — useful on weak devices or
/// while scrolling a long catalogue.
class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
    this.cartCount = 0,
    this.enableBlur = true,
  });

  final NavTab currentTab;
  final ValueChanged<NavTab> onTabSelected;
  final int cartCount;
  final bool enableBlur;

  static const List<_TabSpec> _tabs = <_TabSpec>[
    _TabSpec(NavTab.home, 'Home', Icons.home_rounded),
    _TabSpec(NavTab.categories, 'Categories', Icons.grid_view_rounded),
    _TabSpec(NavTab.cart, 'Cart', Icons.shopping_bag_rounded),
    _TabSpec(NavTab.orders, 'Orders', Icons.receipt_long_rounded),
    _TabSpec(NavTab.profile, 'Profile', Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    const BorderRadius radius = BorderRadius.all(Radius.circular(22));

    final Widget bar = Container(
      height: 66,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[AppColors.glassFill, AppColors.glassFillDeep],
        ),
        borderRadius: radius,
        border: Border.all(color: AppColors.glassEdge),
      ),
      child: Row(
        children: _tabs.map((_TabSpec spec) {
          final bool selected = spec.tab == currentTab;
          return Expanded(
            child: _NavButton(
              spec: spec,
              selected: selected,
              badgeCount: spec.tab == NavTab.cart ? cartCount : 0,
              onTap: () {
                if (spec.tab != currentTab) {
                  HapticFeedback.lightImpact();
                  onTabSelected(spec.tab);
                }
              },
            ),
          );
        }).toList(),
      ),
    );

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            borderRadius: radius,
            boxShadow: <BoxShadow>[
              BoxShadow(color: Color(0x66000000), blurRadius: 26, offset: Offset(0, 12)),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: enableBlur
                ? BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: bar,
                  )
                : bar,
          ),
        ),
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec(this.tab, this.label, this.icon);
  final NavTab tab;
  final String label;
  final IconData icon;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.spec,
    required this.selected,
    required this.badgeCount,
    required this.onTap,
  });

  final _TabSpec spec;
  final bool selected;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color ink = selected ? AppColors.inkOnDark : AppColors.inkMutedOnDark;

    return Semantics(
      button: true,
      selected: selected,
      label: spec.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          // The "pop": the whole cell lifts and scales while the pill fades in.
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            offset: selected ? const Offset(0, -0.08) : Offset.zero,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              scale: selected ? 1.06 : 1.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.goldSoft : Colors.transparent,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: selected ? const Color(0x4DD4A017) : Colors.transparent,
                          ),
                        ),
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          scale: selected ? 1.12 : 1.0,
                          child: Icon(spec.icon, size: 20, color: selected ? AppColors.gold : ink),
                        ),
                      ),
                      if (badgeCount > 0)
                        Positioned(
                          right: 4,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            constraints: const BoxConstraints(minWidth: 16),
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              badgeCount > 9 ? '9+' : '$badgeCount',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    spec.label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: 0.1,
                      color: ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
