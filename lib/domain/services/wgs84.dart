import 'dart:math' as math;

import '../../utils/constants/vr_earth_constants.dart';
import '../models/earth_centered_position.dart';
import '../models/wgs84_coordinate.dart';

/// WGS84 reference ellipsoid conversions, using CPU double precision.
///
/// Constants: NGA WGS84 defining parameters. Cartesian equations and ENU
/// conventions: ESA Navipedia (references and scope in the package README).
abstract final class Wgs84 {
  static const double semiMajorAxisMeters =
      VrEarthConstants.semiMajorAxisMeters;
  static const double inverseFlattening = VrEarthConstants.inverseFlattening;
  static const double flattening = VrEarthConstants.flattening;
  static const double semiMinorAxisMeters =
      VrEarthConstants.semiMinorAxisMeters;
  static const double eccentricitySquared =
      VrEarthConstants.eccentricitySquared;

  static EarthCenteredPosition toEcef(Wgs84Coordinate coordinate) {
    final latitude =
        coordinate.latitudeDegrees *
        math.pi /
        VrEarthConstants.degreesPerHalfTurn;
    final longitude =
        coordinate.longitudeDegrees *
        math.pi /
        VrEarthConstants.degreesPerHalfTurn;
    final sinLatitude = math.sin(latitude);
    final cosLatitude = math.cos(latitude);
    final n = _primeVerticalRadius(sinLatitude);
    final h = coordinate.ellipsoidalHeightMeters;
    return EarthCenteredPosition(
      (n + h) * cosLatitude * math.cos(longitude),
      (n + h) * cosLatitude * math.sin(longitude),
      (n * (1.0 - eccentricitySquared) + h) * sinLatitude,
    );
  }

  /// Converts points in the supported near-Earth layer, including the poles.
  /// Exact ECEF-axis poles have canonical longitude zero; longitude at a pole
  /// cannot be recovered uniquely. Rejects Earth's center and unsupported height.
  static Wgs84Coordinate fromEcef(EarthCenteredPosition position) {
    final p = math.sqrt(position.x * position.x + position.y * position.y);
    if (p == 0 && position.z == 0) {
      throw ArgumentError.value(
        position,
        VrEarthConstants.paramPosition,
        VrEarthConstants.errEarthCenterUndefined,
      );
    }
    final longitude = math.atan2(position.y, position.x);
    var latitude = math.atan2(position.z, p * (1.0 - eccentricitySquared));
    var converged = false;
    for (
      var iteration = 0;
      iteration < VrEarthConstants.maxGeodeticIterations;
      iteration++
    ) {
      final sinLatitude = math.sin(latitude);
      final next = math.atan2(
        position.z +
            eccentricitySquared *
                _primeVerticalRadius(sinLatitude) *
                sinLatitude,
        p,
      );
      if ((next - latitude).abs() <
          VrEarthConstants.geodeticConvergenceRadians) {
        latitude = next;
        converged = true;
        break;
      }
      latitude = next;
    }
    if (!converged) {
      throw ArgumentError.value(
        position,
        VrEarthConstants.paramPosition,
        VrEarthConstants.errOutsideGeodeticDomain,
      );
    }
    final sinLatitude = math.sin(latitude);
    var height =
        p * math.cos(latitude) +
        position.z * sinLatitude -
        semiMajorAxisMeters *
            math.sqrt(1.0 - eccentricitySquared * sinLatitude * sinLatitude);
    for (final boundary in [
      Wgs84Coordinate.minimumHeightMeters,
      Wgs84Coordinate.maximumHeightMeters,
    ]) {
      if ((height - boundary).abs() <
          VrEarthConstants.boundarySnapToleranceMeters) {
        height = boundary;
      }
    }
    return Wgs84Coordinate(
      latitudeDegrees:
          latitude * VrEarthConstants.degreesPerHalfTurn / math.pi,
      longitudeDegrees:
          longitude * VrEarthConstants.degreesPerHalfTurn / math.pi,
      ellipsoidalHeightMeters: height,
    );
  }

  static double _primeVerticalRadius(double sinLatitude) =>
      semiMajorAxisMeters /
      math.sqrt(1.0 - eccentricitySquared * sinLatitude * sinLatitude);
}
