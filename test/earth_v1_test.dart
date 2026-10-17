import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:vrlizate_earth/vrlizate_earth.dart';
import 'package:vrlizate_world/vrlizate_world.dart';

void main() {
  group('EarthGeodesicCalculator', () {
    test('computes Haversine distance, initial bearing, and destination coordinate', () {
      final origin = Wgs84Coordinate(
        latitudeDegrees: 19.4326,
        longitudeDegrees: -99.1332,
        ellipsoidalHeightMeters: 2240,
      );

      final northTarget = EarthGeodesicCalculator.destinationCoordinate(
        start: origin,
        bearingDegrees: 0,
        distanceMeters: 500,
      );

      final distance = EarthGeodesicCalculator.haversineDistanceMeters(
        origin,
        northTarget,
      );
      expect(distance, closeTo(500.0, 1e-3));

      final bearing = EarthGeodesicCalculator.initialBearingDegrees(
        origin,
        northTarget,
      );
      expect(bearing, closeTo(0.0, 1e-4));

      final eastTarget = EarthGeodesicCalculator.destinationCoordinate(
        start: origin,
        bearingDegrees: 90,
        distanceMeters: 250,
      );
      expect(
        EarthGeodesicCalculator.initialBearingDegrees(origin, eastTarget),
        closeTo(90.0, 1e-2),
      );
    });
  });

  group('EarthCompassAlignment', () {
    test('converts between compass heading degrees and local ENU right-handed yaw', () {
      final north = EarthCompassAlignment(headingDegrees: 0);
      expect(north.trueBearingDegrees, closeTo(0.0, 1e-9));
      expect(north.localYawRadians, closeTo(0.0, 1e-9));

      final east = EarthCompassAlignment(headingDegrees: 90);
      expect(east.localYawRadians, closeTo(-math.pi / 2, 1e-9));

      final fromYaw = EarthCompassAlignment.fromLocalYawRadians(
        -math.pi / 2,
        magneticDeclinationDegrees: 5.0,
      );
      expect(fromYaw.trueBearingDegrees, closeTo(90.0, 1e-6));
      expect(fromYaw.headingDegrees, closeTo(85.0, 1e-6));
    });
  });

  group('EarthPoiRegistry', () {
    test('registers POIs, queries by surface distance, and projects into EarthLocalFrame', () {
      final origin = Wgs84Coordinate(
        latitudeDegrees: 19.4326,
        longitudeDegrees: -99.1332,
        ellipsoidalHeightMeters: 2240,
      );
      final frame = EarthLocalFrame(
        origin: origin,
        world: VrWorldAddress(worldId: 'earth.plaza', instanceId: 'local'),
        radiusMeters: 1000,
      );

      final nearCoord = EarthGeodesicCalculator.destinationCoordinate(
        start: origin,
        bearingDegrees: 0,
        distanceMeters: 150,
      );
      final farCoord = EarthGeodesicCalculator.destinationCoordinate(
        start: origin,
        bearingDegrees: 180,
        distanceMeters: 5000,
      );

      final registry = EarthPoiRegistry()
        ..register(
          EarthPoiNode(
            id: 'poi.near',
            label: 'Near Stage',
            category: 'stage',
            coordinate: nearCoord,
          ),
        )
        ..register(
          EarthPoiNode(
            id: 'poi.far',
            label: 'Distant Tower',
            category: 'landmark',
            coordinate: farCoord,
          ),
        );

      final within1km = registry.queryWithinSurfaceDistanceMeters(
        center: origin,
        radiusMeters: 1000,
      );
      expect(within1km.map((n) => n.id), equals(['poi.near']));

      final projected = registry.projectIntoFrame(frame);
      expect(projected.length, equals(1));
      expect(projected.single.id, equals('poi.near'));
      expect(projected.single.transform.position.z, lessThan(-140));
    });
  });
}
