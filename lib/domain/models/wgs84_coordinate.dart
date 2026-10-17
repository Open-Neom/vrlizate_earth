import '../../utils/constants/vr_earth_constants.dart';
import '../../utils/vr_earth_validator.dart';

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
    VrEarthValidator.checkRange(
      latitudeDegrees,
      VrEarthConstants.paramLatitudeDegrees,
      VrEarthConstants.minLatitudeDegrees,
      VrEarthConstants.maxLatitudeDegrees,
    );
    VrEarthValidator.checkRange(
      longitudeDegrees,
      VrEarthConstants.paramLongitudeDegrees,
      VrEarthConstants.minLongitudeDegrees,
      VrEarthConstants.maxLongitudeDegrees,
    );
    VrEarthValidator.checkRange(
      ellipsoidalHeightMeters,
      VrEarthConstants.paramEllipsoidalHeightMeters,
      minimumHeightMeters,
      maximumHeightMeters,
    );
    return Wgs84Coordinate._(
      latitudeDegrees,
      longitudeDegrees == VrEarthConstants.maxLongitudeDegrees
          ? VrEarthConstants.minLongitudeDegrees
          : longitudeDegrees,
      ellipsoidalHeightMeters,
    );
  }

  const Wgs84Coordinate._(
    this.latitudeDegrees,
    this.longitudeDegrees,
    this.ellipsoidalHeightMeters,
  );

  /// Supported near-Earth layer; deeper interior coordinates are ambiguous.
  static const double minimumHeightMeters =
      VrEarthConstants.minimumHeightMeters;
  static const double maximumHeightMeters =
      VrEarthConstants.maximumHeightMeters;

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
