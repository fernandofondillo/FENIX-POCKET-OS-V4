// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fenix_pocket_os/main.dart';

void main() {
  testWidgets('Fénix V4 arranca sin crashear', (WidgetTester tester) async {
    await tester.pumpWidget(const FenixApp());
    // No asserts duros: el objetivo es que la app arranque en el test
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}