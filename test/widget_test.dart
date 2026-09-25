import 'package:flutter_test/flutter_test.dart';
import 'package:snapcart/main.dart';

void main() {
  testWidgets('SnapCartApp basic smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SnapCartApp());
    expect(find.byType(SnapCartApp), findsOneWidget);
  });
}
