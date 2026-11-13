import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supreme_mall/screens/home/customer_home_screen.dart';
import 'package:supreme_mall/widgets/glass_bottom_nav.dart';

void main() {
  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: CustomerHomeScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('bento dashboard shows every department', (WidgetTester tester) async {
    await pumpHome(tester);

    // Headline + search affordance.
    expect(find.text('Search shops, food, produce'), findsOneWidget);

    // Live departments and later-phase departments share the grid.
    expect(find.text('Food'), findsWidgets);
    expect(find.text('Fresh'), findsWidgets);
    expect(find.text('Rides'), findsOneWidget);
    expect(find.text('Boda'), findsOneWidget);
    expect(find.text('Errands'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);

    // Later-phase tiles are badged, so the grid never over-promises.
    expect(find.text('SOON'), findsNWidgets(4));
  });

  testWidgets('glass nav switches tabs', (WidgetTester tester) async {
    await pumpHome(tester);

    expect(find.text('Arrives in the next milestone'), findsNothing);

    // "Home" also appears as a department tile, so target the nav explicitly.
    await tester.tap(
      find.descendant(of: find.byType(GlassBottomNav), matching: find.text('Cart')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Arrives in the next milestone'), findsOneWidget);
    // Home content is no longer the active body.
    expect(find.text('Search shops, food, produce'), findsNothing);

    await tester.tap(
      find.descendant(of: find.byType(GlassBottomNav), matching: find.text('Home')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Search shops, food, produce'), findsOneWidget);
  });

  testWidgets('active order card is visible', (WidgetTester tester) async {
    await pumpHome(tester);

    expect(find.text('Order #SM-1042 · On the way'), findsOneWidget);
    expect(find.text('Track'), findsOneWidget);
  });
}
