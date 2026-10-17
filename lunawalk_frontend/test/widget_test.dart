import 'package:flutter_test/flutter_test.dart';

import 'package:lunawalk_frontend/main.dart';

void main() {
  testWidgets('app renders the LunaWalk dashboard shell', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('LunaWalk B2B Developer Telemetry'), findsOneWidget);
    expect(find.textContaining('POST /v1/directions'), findsOneWidget);
  });
}
