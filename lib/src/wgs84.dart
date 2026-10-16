import 'dart:math' as math;

/// Geographic position on the WGS84 ellipsoid, in degrees and meters.
///
/// Height is above the reference ellipsoid, NOT mean sea level or terrain.
/// A sea-level/orthometric height H requires an external geoid undulation N:
/// h = H + N. No geoid, elevation data, or location sensor is included here.
final class Wgs84Coordinate {
  factory Wgs84Coordinate({
    required double latitudeDegrees,
    required double longitudeDegrees,
    required double ellipsoidalHeightMeters,
  }) {
    _range(latitudeDegrees, 'latitudeDegrees', -90, 90);
    _range(longitudeDegrees, 'longitudeDegrees', -180, 180);
    _range(
      ellipsoidalHeightMeters,
      'ellipsoidalHeightMeters',
      minimumHeightMeters,
      maximumHeightMeters,
    );
    return Wgs84Coordinate._(
      latitudeDegrees,
      longitudeDegrees == 180 ? -180 : longitudeDegrees,
      ellipsoidalHeightMeters,
    );
  }

  const Wgs84Coordinate._(
    this.latitudeDegrees,
    this.longitudeDegrees,
    this.ellipsoidalHeightMeters,
  );

  /// Supported near-Earth layer; deeper interior coordinates are ambiguous.
  static const minimumHeightMeters = -12000.0;
  static const maximumHeightMeters = 1000000.0;

  final double latitudeDegrees;

  /// Canonical range [-180, 180); at a pole, selects the local east direction.
  final double longitudeDegrees;
  final double ellipsoidalHeightMeters;

  @override
  bool operator ==(Object other) =>
      other is Wgs84Coordinate &&
      latitudeDegrees == other.latitudeDegrees &&
      longitudeDegrees == other.longitudeDegrees &&
      ellipsoidalHeightMeters == other.ellipsoidalHeightMeters;

  @override
  int get hashCode =>
      Object.hash(latitudeDegrees, longitudeDegrees, ellipsoidalHeightMeters);
}

/// CPU-side Earth-centered, Earth-fixed (ECEF) meters; never GPU coordinates.
///
/// X points to latitude 0 / longitude 0, Y to latitude 0 / longitude 90 east,
/// and Z to the north pole. Finite bounded values avoid overflowing arithmetic.
/// A valid ECEF tuple is not necessarily within the supported geographic layer.
final class EarthCenteredPosition {
  factory EarthCenteredPosition(double x, double y, double z) {
    for (final (name, value) in [('x', x), ('y', y), ('z', z)]) {
      _range(value, name, -10000000, 10000000);
    }
    return EarthCenteredPosition._(x, y, z);
  }

  const EarthCenteredPosition._(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;
}

/// WGS84 reference ellipsoid conversions, using CPU double precision.
///
/// Constants: NGA WGS84 defining parameters. Cartesian equations and ENU
/// conventions: ESA Navipedia (references and scope in the package README).
abstract final class Wgs84 {
  static const semiMajorAxisMeters = 6378137.0;
  static const inverseFlattening = 298.257223563;
  static const flattening = 1 / inverseFlattening;
  static const semiMinorAxisMeters = semiMajorAxisMeters * (1 - flattening);
  static const eccentricitySquared = flattening * (2 - flattening);

  static EarthCenteredPosition toEcef(Wgs84Coordinate coordinate) {
    final latitude = coordinate.latitudeDegrees * math.pi / 180;
    final longitude = coordinate.longitudeDegrees * math.pi / 180;
    final sinLatitude = math.sin(latitude);
    final cosLatitude = math.cos(latitude);
    final n = _primeVerticalRadius(sinLatitude);
    final h = coordinate.ellipsoidalHeightMeters;
    return EarthCenteredPosition(
      (n + h) * cosLatitude * math.cos(longitude),
      (n + h) * cosLatitude * math.sin(longitude),
      (n * (1 - eccentricitySquared) + h) * sinLatitude,
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
        'position',
        'Earth center is undefined.',
      );
    }
    final longitude = math.atan2(position.y, position.x);
    var latitude = math.atan2(position.z, p * (1 - eccentricitySquared));
    // Rearranging z = (N * (1 - e²) + h) sin(phi) gives this stable
    // fixed-point latitude update without dividing by cos(phi) near a pole.
    var converged = false;
    for (var iteration = 0; iteration < 16; iteration++) {
      final sinLatitude = math.sin(latitude);
      final next = math.atan2(
        position.z +
            eccentricitySquared *
                _primeVerticalRadius(sinLatitude) *
                sinLatitude,
        p,
      );
      if ((next - latitude).abs() < 1e-14) {
        latitude = next;
        converged = true;
        break;
      }
      latitude = next;
    }
    if (!converged) {
      throw ArgumentError.value(
        position,
        'position',
        'Outside geodetic conversion domain.',
      );
    }
    final sinLatitude = math.sin(latitude);
    // Dot with the ellipsoid normal: stable height at both equator and poles.
    var height =
        p * math.cos(latitude) +
        position.z * sinLatitude -
        semiMajorAxisMeters *
            math.sqrt(1 - eccentricitySquared * sinLatitude * sinLatitude);
    // Preserve supported boundary round trips despite sub-micrometer rounding.
    for (final boundary in [
      Wgs84Coordinate.minimumHeightMeters,
      Wgs84Coordinate.maximumHeightMeters,
    ]) {
      if ((height - boundary).abs() < 1e-6) height = boundary;
    }
    return Wgs84Coordinate(
      latitudeDegrees: latitude * 180 / math.pi,
      longitudeDegrees: longitude * 180 / math.pi,
      ellipsoidalHeightMeters: height,
    );
  }

  static double _primeVerticalRadius(double sinLatitude) =>
      semiMajorAxisMeters /
      math.sqrt(1 - eccentricitySquared * sinLatitude * sinLatitude);
}

void _range(double value, String name, double minimum, double maximum) {
  if (!value.isFinite || value < minimum || value > maximum) {
    throw ArgumentError.value(
      value,
      name,
      'Must be finite within [$minimum, $maximum].',
    );
  }
}
