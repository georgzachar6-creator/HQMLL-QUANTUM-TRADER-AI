import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_trader/main.dart';

void main() {
  testWidgets('HQMLL App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HQMLLApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
