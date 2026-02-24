// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rider_app/app/rider_app.dart';

void main() {
  testWidgets('Shows login after splash', (WidgetTester tester) async {
    await tester.pumpWidget(const RiderApp());

    expect(find.byIcon(Icons.delivery_dining), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 950));

    expect(find.text('Welcome, rider'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
