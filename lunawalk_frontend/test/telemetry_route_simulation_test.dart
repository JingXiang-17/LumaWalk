import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
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
    telemetry.startNavigation();
    expect(telemetry.isNavigating, isFalse);
    expect(
      telemetry.routeError,
      'Search for and select a destination before navigating.',
    );
    telemetry.setDestination(
      const LatLng(3.1279, 101.6501),
      name: 'UM FSKTM',
    );

    final deadline = DateTime.now().add(const Duration(seconds: 90));
    while (telemetry.safeRoute == null &&
        telemetry.routeError == null &&
        DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    expect(telemetry.routeError, isNull);
    expect(telemetry.safeRoute, isNotNull);
    expect(telemetry.directRoute, isNotNull);
    expect(telemetry.destinationName, 'UM FSKTM');

    telemetry.selectRoute(0);
    expect(telemetry.routePoints, telemetry.safeRoute!.points);
    telemetry.selectRoute(1);
    final selectedRoute = telemetry.routePoints;

    telemetry.startNavigation();
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

    telemetry.moveAvatar(
      telemetry.destinationLat - telemetry.currentLat,
      telemetry.destinationLng - telemetry.currentLng,
    );
    expect(telemetry.hasReachedDestination, isTrue);
    expect(telemetry.isNavigating, isFalse);
    expect(
      telemetry.navigationInstruction,
      'You have reached your destination.',
    );

    final alternateDestination =
        telemetry.safeRoute!.points[telemetry.safeRoute!.points.length ~/ 2];
    telemetry.setDestination(alternateDestination, name: 'Alternate place');
    final rerouteDeadline = DateTime.now().add(const Duration(seconds: 90));
    while (telemetry.safeRoute == null &&
        telemetry.routeError == null &&
        DateTime.now().isBefore(rerouteDeadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    expect(telemetry.routeError, isNull);
    expect(telemetry.safeRoute, isNotNull);
    expect(telemetry.safeRoute!.points.last, alternateDestination);
    expect(telemetry.hasReachedDestination, isFalse);
  });
}
