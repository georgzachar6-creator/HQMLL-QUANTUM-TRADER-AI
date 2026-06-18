import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_trader/main.dart';

void main() {
  testWidgets('HQMLL App smoke test — MultiProvider ist in HQMLLApp integriert',
      (WidgetTester tester) async {
    // HQMLLApp enthält jetzt selbst den MultiProvider →
    // kein externer Wrapper notwendig
    await tester.pumpWidget(const HQMLLApp());
    // Kurz pumpen damit Animations-Controller initialisieren
    await tester.pump(const Duration(milliseconds: 100));
    // MaterialApp sollte gefunden werden
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
