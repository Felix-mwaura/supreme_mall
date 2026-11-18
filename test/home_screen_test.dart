import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supreme_mall/models/app_profile.dart';
import 'package:supreme_mall/screens/home/customer_home_screen.dart';
import 'package:supreme_mall/widgets/glass_bottom_nav.dart';

void main() {
  Future<void> pumpShell(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: CustomerHomeScreen()));
    await tester.pumpAndSettle();
  }

  /// Taps a tab through the floating navigation bar.
  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(of: find.byType(GlassBottomNav), matching: find.text(label)),
    );
    await tester.pumpAndSettle();
  }

  NavTab currentTab(WidgetTester tester) {
    return tester.widget<GlassBottomNav>(find.byType(GlassBottomNav)).currentTab;
  }

  testWidgets('shell opens on Home with the bento grid', (WidgetTester tester) async {
    await pumpShell(tester);

    expect(currentTab(tester), NavTab.home);
    expect(find.text('Search shops, food, produce'), findsOneWidget);
    expect(find.text('Order #SM-1042 · On the way'), findsOneWidget);
    // The area chip invites a choice until the profile supplies one.
    expect(find.text('Choose area'), findsOneWidget);

    // Later-phase departments are present but badged.
    expect(find.text('SOON'), findsWidgets);
  });

  testWidgets('navigation switches between the four tabs', (WidgetTester tester) async {
    await pumpShell(tester);

    await tapTab(tester, 'Categories');
    expect(currentTab(tester), NavTab.categories);
    expect(find.text('Browse'), findsOneWidget);
    // No Supabase in tests, so the directory honestly reports that it has no
    // merchants rather than falling back to sample names.
    expect(find.text('No merchants listed yet'), findsOneWidget);

    await tapTab(tester, 'Orders');
    expect(currentTab(tester), NavTab.orders);
    expect(find.text('Track deliveries and reorder in two taps.'), findsOneWidget);

    await tapTab(tester, 'Profile');
    expect(currentTab(tester), NavTab.profile);
    // No profile injected (signed-out preview shell): neutral identity.
    expect(find.text('Your account'), findsOneWidget);
    expect(find.text('CUSTOMER ACCOUNT'), findsOneWidget);

    await tapTab(tester, 'Home');
    expect(currentTab(tester), NavTab.home);
  });

  testWidgets('service tiles jump to the Categories tab', (WidgetTester tester) async {
    await pumpShell(tester);

    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();

    expect(currentTab(tester), NavTab.categories);
  });

  testWidgets('signed-in profile personalises greeting and identity card', (
    WidgetTester tester,
  ) async {
    const AppProfile profile = AppProfile(
      id: '00000000-0000-0000-0000-000000000001',
      fullName: 'Wanjiku Kamau',
      phone: '+254712345678',
      role: 'customer',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CustomerHomeScreen(
          profile: profile,
          onSignOut: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Karibu tena, Wanjiku'), findsOneWidget);

    await tapTab(tester, 'Profile');
    expect(find.text('Wanjiku Kamau'), findsOneWidget);
    expect(find.text('+254712345678'), findsOneWidget);
    expect(find.text('WK'), findsOneWidget);
  });

  testWidgets('sign out calls the session callback', (WidgetTester tester) async {
    bool signedOut = false;
    const AppProfile profile = AppProfile(
      id: '00000000-0000-0000-0000-000000000001',
      fullName: 'Wanjiku Kamau',
      role: 'customer',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CustomerHomeScreen(
          profile: profile,
          onSignOut: () async {
            signedOut = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tapTab(tester, 'Profile');
    final Finder signOut = find.text('Sign out');
    await tester.ensureVisible(signOut);
    await tester.pumpAndSettle();
    await tester.tap(signOut);
    await tester.pumpAndSettle();

    expect(signedOut, isTrue);
  });

  testWidgets('cart tab is not part of the shell yet', (WidgetTester tester) async {
    await pumpShell(tester);

    expect(
      find.descendant(of: find.byType(GlassBottomNav), matching: find.text('Cart')),
      findsNothing,
    );
    expect(NavTab.values.length, 4);
  });
}
