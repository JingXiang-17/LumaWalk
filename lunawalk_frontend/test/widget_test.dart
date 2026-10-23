import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:lunawalk_frontend/main.dart';
import 'package:lunawalk_frontend/providers/telemetry_provider.dart';
import 'package:lunawalk_frontend/widgets/mobile_app_shell.dart';

void main() {
  testWidgets('app renders the LumaWalk dashboard shell', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('LumaWalk B2B Developer Telemetry'), findsOneWidget);
    expect(
      find.text('OpenStreetMap walking network • GeoJSON route data'),
      findsOneWidget,
    );
  });

  testWidgets('safety check-in is shown across the app shell', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.ensureVisible(find.text('Simulation Mode'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simulation Mode'));
    await tester.pump();

    final shellContext = tester.element(find.byType(MobileAppShell));
    Provider.of<TelemetryProvider>(shellContext, listen: false)
        .simulateWalkGpsDrift();
    await tester.pump();

    expect(find.text('Are you okay?'), findsOneWidget);
    expect(find.text("I'm Safe"), findsOneWidget);

    await tester.tap(find.text("I'm Safe"));
    await tester.pump();
    expect(find.text('Are you okay?'), findsNothing);
  });
}
