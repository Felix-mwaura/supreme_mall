import 'package:flutter_test/flutter_test.dart';
import 'package:supreme_mall/main.dart';

void main() {
  testWidgets('home screen offers both account paths', (WidgetTester tester) async {
    await tester.pumpWidget(const SupremeMallApp());

    expect(find.text('SUPREME MALL'), findsOneWidget);
    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Sign up as a customer'), findsOneWidget);
    expect(find.text('Sign up as a business'), findsOneWidget);
  });

  testWidgets('customer path opens the customer sign-up form', (WidgetTester tester) async {
    await tester.pumpWidget(const SupremeMallApp());

    final Finder cta = find.text('Create customer account');
    await tester.ensureVisible(cta);
    await tester.pumpAndSettle();
    await tester.tap(cta);
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('CUSTOMER ACCOUNT'), findsOneWidget);
  });

  testWidgets('business path opens the business application form', (WidgetTester tester) async {
    await tester.pumpWidget(const SupremeMallApp());

    final Finder cta = find.text('Register my business');
    await tester.ensureVisible(cta);
    await tester.pumpAndSettle();
    await tester.tap(cta);
    await tester.pumpAndSettle();

    expect(find.text('Register your business'), findsOneWidget);
    expect(find.text('What does your business sell?'), findsOneWidget);
    expect(find.text('BUSINESS ACCOUNT'), findsOneWidget);
  });

  testWidgets('customer form validates empty fields', (WidgetTester tester) async {
    await tester.pumpWidget(const SupremeMallApp());

    final Finder cta = find.text('Create customer account');
    await tester.ensureVisible(cta);
    await tester.pumpAndSettle();
    await tester.tap(cta);
    await tester.pumpAndSettle();

    final Finder submit = find.text('Create account');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('Enter your full name'), findsOneWidget);
    expect(find.text('Enter your phone number'), findsOneWidget);
  });
}
