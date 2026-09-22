import 'package:flutter_test/flutter_test.dart';

import 'package:pictocomm_app/main.dart';

void main() {
  testWidgets('Home screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PictoCommApp());
    await tester.pumpAndSettle();

    expect(find.text('PictoComm'), findsOneWidget);
  });
}