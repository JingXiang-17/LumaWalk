import 'package:flutter_test/flutter_test.dart';

import 'package:lunawalk_frontend/main.dart';

void main() {
  testWidgets('app renders the LumaWalk dashboard shell', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('LumaWalk B2B Developer Telemetry'), findsOneWidget);
    expect(
      find.text('OpenStreetMap walking network • GeoJSON route data'),
      findsOneWidget,
    );
  });
}
