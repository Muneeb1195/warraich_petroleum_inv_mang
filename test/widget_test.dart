import 'package:flutter_test/flutter_test.dart';
import 'package:warraich_petroleum/app.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const WarraichPetroleumApp());
    expect(find.text('Warraich Petroleum'), findsOneWidget);
  });
}
