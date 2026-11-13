import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

    // Later-phase departments are present but badged.
    expect(find.text('SOON'), findsWidgets);
  });

  testWidgets('navigation switches between the four tabs', (WidgetTester tester) async {
    await pumpShell(tester);

    await tapTab(tester, 'Categories');
    expect(currentTab(tester), NavTab.categories);
    expect(find.text('Browse'), findsOneWidget);
    expect(find.text('Chieni Supermarket'), findsWidgets);

    await tapTab(tester, 'Orders');
    expect(currentTab(tester), NavTab.orders);
    expect(find.text('Track deliveries and reorder in two taps.'), findsOneWidget);

    await tapTab(tester, 'Profile');
    expect(currentTab(tester), NavTab.profile);
    expect(find.text('Wanjiku Kamau'), findsOneWidget);

    await tapTab(tester, 'Home');
    expect(currentTab(tester), NavTab.home);
  });

  testWidgets('service tiles jump to the Categories tab', (WidgetTester tester) async {
    await pumpShell(tester);

    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();

    expect(currentTab(tester), NavTab.categories);
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
