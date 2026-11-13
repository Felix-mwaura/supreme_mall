import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../widgets/glass_bottom_nav.dart';
import 'tabs/categories_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/orders_tab.dart';
import 'tabs/profile_tab.dart';

/// The signed-in customer shell: four tabs behind a frosted bottom navigation.
///
/// Each tab is a real screen with its own scroll position, kept alive by an
/// [IndexedStack] so switching tabs never resets what the user was doing.
/// The cart tab is intentionally missing — it needs the orders database, so it
/// lands with the cart/checkout milestone (see [NavTab]).
class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  NavTab _tab = NavTab.home;

  void _select(NavTab tab) {
    if (tab == _tab) {
      return;
    }
    setState(() => _tab = tab);
  }

  @override
  Widget build(BuildContext context) {
    // Light status-bar icons: the dashboard is dark at the top on every tab.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: IndexedStack(
                index: _tab.index,
                children: <Widget>[
                  HomeTab(onOpenCategories: () => _select(NavTab.categories)),
                  const CategoriesTab(),
                  const OrdersTab(),
                  const ProfileTab(),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: GlassBottomNav(
                currentTab: _tab,
                onTabSelected: _select,
                badges: const <NavTab, int>{NavTab.orders: 1},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
