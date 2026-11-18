import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/app_profile.dart';
import '../../models/department.dart';
import '../../screens/catalogue/storefront_screen.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_bootstrap.dart';
import '../../theme/app_colors.dart';
import '../../widgets/area_picker_sheet.dart';
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
  const CustomerHomeScreen({super.key, this.profile, this.onSignOut});

  /// The signed-in customer, shown in the greeting and on the profile tab.
  final AppProfile? profile;

  /// Ends the session; supplied by [AuthGate].
  final Future<void> Function()? onSignOut;

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  NavTab _tab = NavTab.home;

  /// Chosen delivery area; starts from the saved profile and is written back on
  /// every change so it survives a reinstall.
  String? _area;

  @override
  void initState() {
    super.initState();
    _area = widget.profile?.deliveryArea;
  }

  Future<void> _pickArea() async {
    final String? chosen = await showAreaPicker(context, current: _area);
    if (chosen == null || !mounted || chosen == _area) {
      return;
    }

    final String? previous = _area;
    setState(() => _area = chosen);

    if (!SupabaseBootstrap.isInitialized) {
      return;
    }

    try {
      await SupabaseBootstrap.auth.updateDeliveryArea(chosen);
    } on AuthFailure catch (failure) {
      if (!mounted) {
        return;
      }
      // Do not leave the UI claiming a saved area that the database rejected.
      setState(() => _area = previous);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Could not save your area: ${failure.message}'),
            backgroundColor: const Color(0xFF8E1B12),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          ),
        );
    }
  }

  void _openDepartment(SupremeDepartment department) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext _) => StorefrontScreen(department: department),
      ),
    );
  }

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
                  HomeTab(
                    firstName: widget.profile?.firstName,
                    area: _area,
                    onPickArea: _pickArea,
                    onOpenDepartment: _openDepartment,
                    onOpenCategories: () => _select(NavTab.categories),
                  ),
                  const CategoriesTab(),
                  const OrdersTab(),
                  ProfileTab(profile: widget.profile, onSignOut: widget.onSignOut),
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
