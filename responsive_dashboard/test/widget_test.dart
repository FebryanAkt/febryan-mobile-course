// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:responsive_dashboard/main.dart';

void main() {
  testWidgets('DashboardApp smoke test and toggle theme', (WidgetTester tester) async {
    await tester.pumpWidget(const DashboardApp());

    expect(find.text('Student Dashboard'), findsOneWidget);
    expect(find.text('Assignments'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);

    final switchFinder = find.byType(CupertinoSwitch);
    expect(switchFinder, findsOneWidget);

    // Tap switch mode
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
  });
}
