import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supreme_mall/models/department.dart';
import 'package:supreme_mall/screens/catalogue/storefront_screen.dart';

void main() {
  final SupremeDepartment shopping =
      supremeDepartments.firstWhere((SupremeDepartment d) => d.id == 'shopping');

  testWidgets('storefront reports an empty catalogue instead of inventing items', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: StorefrontScreen(department: shopping)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Supreme Shopping'), findsOneWidget);
    expect(find.text('No listings here yet'), findsOneWidget);
  });

  testWidgets('storefront has a search field scoped to its department', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: StorefrontScreen(department: shopping)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Search shopping'), findsOneWidget);
  });
}
