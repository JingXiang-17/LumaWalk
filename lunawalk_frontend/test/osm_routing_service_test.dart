import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lunawalk_frontend/services/osm_routing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('calculates safe and direct routes from the bundled OSM GeoJSON',
      () async {
    final routing = OsmRoutingService();
    const origin = LatLng(3.1180, 101.6230);
    const destination = LatLng(3.1279, 101.6501);

    final routes = await routing.findRoutes(
      origin: origin,
      destination: destination,
      safetyWeight: 2.5,
      avoidUnlit: true,
      prioritizeHavens: true,
    );
    final havens = await routing.loadSafeHavens();

    // Confirm both route choices are calculated from the real network.
    expect(routes.direct.distanceMeters,
        lessThanOrEqualTo(routes.safe.distanceMeters));
    expect(routes.safe.points, isNot(equals(routes.direct.points)));
    expect(routes.safe.points.length, greaterThan(2));
    expect(routes.direct.points.length, greaterThan(2));
    expect(routes.safe.distanceMeters, greaterThan(0));
    expect(routes.direct.distanceMeters, greaterThan(0));
    expect(routes.safe.points.first.latitude, closeTo(origin.latitude, 0.01));
    expect(routes.safe.points.last.latitude, destination.latitude);
    expect(routes.safe.lightingScore, inInclusiveRange(0, 1));
    expect(havens, isNotEmpty);
    expect(havens.map((haven) => haven.classification).toSet(), contains('A'));
  });
}
