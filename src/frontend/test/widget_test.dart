import 'package:flutter_test/flutter_test.dart';

import 'package:pictocomm_app/app.dart';
import 'package:pictocomm_app/core/di/injector.dart';

void main() {
  testWidgets('Home screen shows title', (WidgetTester tester) async {
    await tester.pumpWidget(
      PictoCommApp(dependencies: AppDependencies.production()),
    );
    await tester.pumpAndSettle();

    expect(find.text('PictoComm'), findsOneWidget);
  });
}
