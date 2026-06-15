import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warraich_petroleum/app.dart';

void main() {
  testWidgets('App renders dashboard', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: WarraichPetroleumApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Dashboard'), findsNWidgets(2));
  });
}
