import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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

  test('publishes avatar movement without notifying the whole UI', () async {
    final telemetry = TelemetryProvider(
      client: MockClient((_) async => http.Response('{}', 200)),
    );
    addTearDown(telemetry.dispose);

    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (telemetry.isMapDataLoading && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    telemetry.setSimulationMode(true);

    var stateNotifications = 0;
    telemetry.addListener(() => stateNotifications++);
    telemetry.moveAvatar(0.000001, 0.000001);

    expect(stateNotifications, 0);
    expect(telemetry.avatarPosition.value.latitude, 3.118001);
    expect(telemetry.avatarPosition.value.longitude, 101.623001);
  });

  test('alerts on deviation and recalculates from the current location',
      () async {
    // 1. Create a mock client that fakes Member 2's backend response
    var recalculationRequests = 0;
    final mockClient = MockClient((request) async {
      final requestBody = jsonDecode(request.body) as Map<String, dynamic>;
      final endLat = (requestBody['end_lat'] as num).toDouble();
      final endLng = (requestBody['end_lng'] as num).toDouble();
      if (requestBody['is_recalculation'] == true) {
        recalculationRequests++;
      }
      final dummyJsonResponse = jsonEncode({
        "safe_route_coords": [
          [3.1180, 101.6230],
          [3.1200, 101.6300],
          [endLat, endLng]
        ],
        "safe_distance": 2450.0,
        "direct_route_coords": [
          [3.1180, 101.6230],
          [endLat, endLng]
        ],
        "direct_distance": 2140.0,
        "percentage_lit": 86.0,
        "detour_time_seconds": 310
      });
      return http.Response(dummyJsonResponse, 200,
          headers: {'content-type': 'application/json'});
    });

    // 2. Inject the mock client into the provider
    final telemetry = TelemetryProvider(client: mockClient);
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

    await telemetry.recalculateSafestRoute();
    expect(recalculationRequests, 1);
    expect(telemetry.selectedRouteIndex, 0);
    expect(telemetry.isOffTrack, isFalse);
    expect(telemetry.showOffTrackModal, isFalse);
    expect(telemetry.routePoints, telemetry.safeRoute!.points);

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
