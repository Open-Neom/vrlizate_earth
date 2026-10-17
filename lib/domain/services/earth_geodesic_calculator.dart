import 'dart:math' as math;

import '../../utils/constants/vr_earth_constants.dart';
import '../../utils/vr_earth_validator.dart';
import '../models/wgs84_coordinate.dart';

/// Spherical/geodesic navigation utilities on the WGS84 mean-radius sphere
/// for surface distances, initial bearings, and destination coordinates.
abstract final class EarthGeodesicCalculator {
  /// Returns the great-circle surface distance in meters between [from] and [to]
  /// using the Haversine formula at mean Earth radius.
  static double haversineDistanceMeters(
    Wgs84Coordinate from,
    Wgs84Coordinate to,
  ) {
    final lat1 =
        from.latitudeDegrees * math.pi / VrEarthConstants.degreesPerHalfTurn;
    final lat2 =
        to.latitudeDegrees * math.pi / VrEarthConstants.degreesPerHalfTurn;
    final dLat = lat2 - lat1;
    final dLon =
        (to.longitudeDegrees - from.longitudeDegrees) *
        math.pi /
        VrEarthConstants.degreesPerHalfTurn;

    final sinDLat = math.sin(dLat * 0.5);
    final sinDLon = math.sin(dLon * 0.5);
    final a =
        (sinDLat * sinDLat +
                math.cos(lat1) * math.cos(lat2) * sinDLon * sinDLon)
            .clamp(0.0, 1.0);
    final c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a));
    return VrEarthConstants.meanEarthRadiusMeters * c;
  }

  /// Returns the forward azimuth (initial bearing) in `[0, 360)` degrees
  /// clockwise from true North from [from] toward [to].
  static double initialBearingDegrees(
    Wgs84Coordinate from,
    Wgs84Coordinate to,
  ) {
    final lat1 =
        from.latitudeDegrees * math.pi / VrEarthConstants.degreesPerHalfTurn;
    final lat2 =
        to.latitudeDegrees * math.pi / VrEarthConstants.degreesPerHalfTurn;
    final dLon =
        (to.longitudeDegrees - from.longitudeDegrees) *
        math.pi /
        VrEarthConstants.degreesPerHalfTurn;

    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    if (x == 0 && y == 0) return 0.0;
    final bearingDegrees =
        math.atan2(y, x) * VrEarthConstants.degreesPerHalfTurn / math.pi;
    final normalized = bearingDegrees % VrEarthConstants.degreesPerFullTurn;
    return normalized < 0
        ? normalized + VrEarthConstants.degreesPerFullTurn
        : normalized;
  }

  /// Computes the destination [Wgs84Coordinate] reached by travelling
  /// [distanceMeters] along [bearingDegrees] (clockwise from North) from [start].
  static Wgs84Coordinate destinationCoordinate({
    required Wgs84Coordinate start,
    required double bearingDegrees,
    required double distanceMeters,
    double? targetHeightMeters,
  }) {
    VrEarthValidator.checkRange(
      bearingDegrees,
      VrEarthConstants.paramBearingDegrees,
      -VrEarthConstants.degreesPerFullTurn,
      VrEarthConstants.degreesPerFullTurn,
    );
    VrEarthValidator.checkRange(
      distanceMeters,
      VrEarthConstants.paramDistanceMeters,
      0.0,
      VrEarthConstants.maxSurfaceDistanceMeters,
    );

    final angularDistance =
        distanceMeters / VrEarthConstants.meanEarthRadiusMeters;
    final bearingRad =
        bearingDegrees * math.pi / VrEarthConstants.degreesPerHalfTurn;
    final lat1 =
        start.latitudeDegrees * math.pi / VrEarthConstants.degreesPerHalfTurn;
    final lon1 =
        start.longitudeDegrees * math.pi / VrEarthConstants.degreesPerHalfTurn;

    final sinLat2 =
        (math.sin(lat1) * math.cos(angularDistance) +
                math.cos(lat1) *
                    math.sin(angularDistance) *
                    math.cos(bearingRad))
            .clamp(-1.0, 1.0);
    final lat2 = math.asin(sinLat2);
    final y =
        math.sin(bearingRad) * math.sin(angularDistance) * math.cos(lat1);
    final x = math.cos(angularDistance) - math.sin(lat1) * sinLat2;
    final lon2 = lon1 + math.atan2(y, x);

    var lonDegrees = lon2 * VrEarthConstants.degreesPerHalfTurn / math.pi;
    while (lonDegrees < VrEarthConstants.minLongitudeDegrees) {
      lonDegrees += VrEarthConstants.degreesPerFullTurn;
    }
    while (lonDegrees >= VrEarthConstants.maxLongitudeDegrees) {
      lonDegrees -= VrEarthConstants.degreesPerFullTurn;
    }

    return Wgs84Coordinate(
      latitudeDegrees: lat2 * VrEarthConstants.degreesPerHalfTurn / math.pi,
      longitudeDegrees: lonDegrees,
      ellipsoidalHeightMeters:
          targetHeightMeters ?? start.ellipsoidalHeightMeters,
    );
  }
}
