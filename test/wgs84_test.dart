import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:vrlizate_earth/vrlizate_earth.dart';

Wgs84Coordinate point(double latitude, double longitude, [double height = 0]) =>
    Wgs84Coordinate(
      latitudeDegrees: latitude,
      longitudeDegrees: longitude,
      ellipsoidalHeightMeters: height,
    );

void main() {
  test('WGS84 defining axes and flattening agree with reference values', () {
    expect(Wgs84.semiMajorAxisMeters, 6378137);
    expect(Wgs84.inverseFlattening, 298.257223563);
    expect(Wgs84.semiMinorAxisMeters, closeTo(6356752.314245179, 1e-8));
    final equator = Wgs84.toEcef(point(0, 0));
    expect(equator.x, 6378137);
    expect(equator.y, 0);
    expect(equator.z, 0);
    final east = Wgs84.toEcef(point(0, 90));
    expect(east.x, closeTo(0, 1e-8));
    expect(east.y, 6378137);
    expect(east.z, 0);
    for (final sign in [-1.0, 1.0]) {
      final pole = Wgs84.toEcef(point(sign * 90, 0));
      expect(pole.x, closeTo(0, 1e-8));
      expect(pole.y, 0);
      expect(pole.z, closeTo(sign * 6356752.314245179, 1e-8));
    }
  });

  test('round trips positions, altitudes and hemispheres without drift', () {
    final random = math.Random(1984);
    for (var i = 0; i < 500; i++) {
      final original = point(
        random.nextDouble() * 180 - 90,
        random.nextDouble() * 360 - 180,
        random.nextDouble() * 1012000 - 12000,
      );
      final result = Wgs84.fromEcef(Wgs84.toEcef(original));
      expect(result.latitudeDegrees, closeTo(original.latitudeDegrees, 1e-10));
      expect(
        result.longitudeDegrees,
        closeTo(original.longitudeDegrees, 1e-10),
      );
      expect(
        result.ellipsoidalHeightMeters,
        closeTo(original.ellipsoidalHeightMeters, 1e-6),
      );
    }
  });

  test('supported height boundary round trips are retained', () {
    for (final h in [
      Wgs84Coordinate.minimumHeightMeters,
      Wgs84Coordinate.maximumHeightMeters,
    ]) {
      for (final lat in [-90.0, -45.0, 0.0, 45.0, 90.0]) {
        final result = Wgs84.fromEcef(Wgs84.toEcef(point(lat, 137, h)));
        expect(result.ellipsoidalHeightMeters, closeTo(h, 1e-6));
      }
    }
  });

  test(
    'poles avoid division singularities including exact ECEF-axis poles',
    () {
      for (final latitude in [-90.0, -89.99999999, 89.99999999, 90.0]) {
        final original = point(latitude, 137, 1200);
        final result = Wgs84.fromEcef(Wgs84.toEcef(original));
        expect(result.latitudeDegrees, closeTo(latitude, 1e-10));
        expect(result.ellipsoidalHeightMeters, closeTo(1200, 1e-6));
      }
      for (final sign in [-1.0, 1.0]) {
        final result = Wgs84.fromEcef(
          EarthCenteredPosition(0, 0, sign * (Wgs84.semiMinorAxisMeters + 20)),
        );
        expect(result.latitudeDegrees, sign * 90);
        expect(result.longitudeDegrees, 0);
        expect(result.ellipsoidalHeightMeters, closeTo(20, 1e-6));
      }
    },
  );

  test('antimeridian has a canonical longitude and equivalent ECEF values', () {
    expect(point(0, 180), point(0, -180));
    expect(point(0, 180).hashCode, point(0, -180).hashCode);
    final result = Wgs84.fromEcef(Wgs84.toEcef(point(32, 180, 50)));
    expect(result.longitudeDegrees, -180);
  });

  test('ellipsoid height changes the equatorial radius meter for meter', () {
    final raised = Wgs84.toEcef(point(0, 0, 150));
    expect(raised.x, Wgs84.semiMajorAxisMeters + 150);
    final below = Wgs84.toEcef(point(0, 0, -100));
    expect(below.x, Wgs84.semiMajorAxisMeters - 100);
  });

  test('rejects nonfinite and invalid geographic inputs', () {
    for (final invalid in [
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(() => point(invalid, 0), throwsArgumentError);
      expect(() => point(0, invalid), throwsArgumentError);
      expect(() => point(0, 0, invalid), throwsArgumentError);
    }
    for (final lat in [-90.0001, 90.0001]) {
      expect(() => point(lat, 0), throwsArgumentError);
    }
    for (final lon in [-180.0001, 180.0001]) {
      expect(() => point(0, lon), throwsArgumentError);
    }
    expect(() => point(0, 0, -12001), throwsArgumentError);
    expect(() => point(0, 0, 1000001), throwsArgumentError);
  });

  test('rejects overflowing ECEF values, center, and unsupported height', () {
    for (final invalid in [double.nan, double.infinity, 10000001.0]) {
      expect(() => EarthCenteredPosition(invalid, 0, 0), throwsArgumentError);
      expect(() => EarthCenteredPosition(0, invalid, 0), throwsArgumentError);
      expect(() => EarthCenteredPosition(0, 0, invalid), throwsArgumentError);
    }
    expect(
      () => Wgs84.fromEcef(EarthCenteredPosition(0, 0, 0)),
      throwsArgumentError,
    );
    expect(
      () => Wgs84.fromEcef(EarthCenteredPosition(100, 0, 0)),
      throwsArgumentError,
    );
    expect(
      () => Wgs84.fromEcef(EarthCenteredPosition(9000000, 0, 0)),
      throwsArgumentError,
    );
  });
}
