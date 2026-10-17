import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunawalk_frontend/providers/telemetry_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const locationChannel = MethodChannel('flutter.baseflow.com/geolocator');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(locationChannel, (call) async => false);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(locationChannel, null);
  });

  test('keeps a selected route fixed and alerts when simulation strays',
      () async {
    final telemetry = TelemetryProvider();
    addTearDown(telemetry.dispose);
    telemetry.setSimulationMode(true);

    await telemetry.triggerNavigationApiCall();
    expect(telemetry.isNavigating, isFalse);

    telemetry.selectRoute(0);
    expect(telemetry.routePoints, hasLength(3));
    telemetry.selectRoute(1);
    final selectedRoute = telemetry.routePoints;

    await telemetry.triggerNavigationApiCall();
    telemetry.moveAvatar(0.002, 0.002);

    expect(telemetry.isNavigating, isTrue);
    expect(telemetry.showOffTrackModal, isTrue);
    expect(telemetry.routePoints, selectedRoute);
    telemetry.selectRoute(0);
    expect(telemetry.selectedRouteIndex, 1);
    expect(telemetry.routePoints, selectedRoute);

    telemetry.dismissOffTrackModal();
    telemetry.moveAvatar(0.0001, 0.0001);
    expect(telemetry.showOffTrackModal, isFalse);

    telemetry.moveAvatar(-0.0021, -0.0021);
    expect(telemetry.isOffTrack, isFalse);
    expect(telemetry.showBackOnTrackBanner, isTrue);
  });
}
