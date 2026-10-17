import 'dart:math' as math;

import '../../utils/constants/vr_earth_constants.dart';
import '../../utils/vr_earth_validator.dart';

/// Aligns a geographic or magnetic compass heading (`0° = North`, `90° = East`)
/// with VRlizate's local right-handed ENU yaw (`0 rad = -Z North`, `-pi/2 rad = +X East`).
final class EarthCompassAlignment {
  factory EarthCompassAlignment({
    required double headingDegrees,
    double magneticDeclinationDegrees = 0.0,
  }) {
    VrEarthValidator.checkRange(
      headingDegrees,
      VrEarthConstants.paramHeadingDegrees,
      -VrEarthConstants.degreesPerFullTurn,
      VrEarthConstants.degreesPerFullTurn,
    );
    VrEarthValidator.checkRange(
      magneticDeclinationDegrees,
      VrEarthConstants.paramMagneticDeclinationDegrees,
      VrEarthConstants.minLongitudeDegrees,
      VrEarthConstants.maxLongitudeDegrees,
    );
    return EarthCompassAlignment._(
      _normalizeHeading(headingDegrees),
      magneticDeclinationDegrees,
    );
  }

  /// Creates an [EarthCompassAlignment] from a local ENU right-handed yaw in radians.
  factory EarthCompassAlignment.fromLocalYawRadians(
    double yawRadians, {
    double magneticDeclinationDegrees = 0.0,
  }) {
    if (!yawRadians.isFinite) {
      throw ArgumentError.value(
        yawRadians,
        VrEarthConstants.paramYawRadians,
        'Must be finite.',
      );
    }
    final trueHeading = _normalizeHeading(
      -yawRadians * VrEarthConstants.degreesPerHalfTurn / math.pi,
    );
    final magneticHeading = _normalizeHeading(
      trueHeading - magneticDeclinationDegrees,
    );
    return EarthCompassAlignment(
      headingDegrees: magneticHeading,
      magneticDeclinationDegrees: magneticDeclinationDegrees,
    );
  }

  const EarthCompassAlignment._(
    this.headingDegrees,
    this.magneticDeclinationDegrees,
  );

  /// Normalized compass heading in `[0, 360)` degrees clockwise from North.
  final double headingDegrees;

  /// Magnetic declination in degrees (`+` east, `-` west) added to [headingDegrees].
  final double magneticDeclinationDegrees;

  /// True geographic bearing in `[0, 360)` degrees clockwise from true North.
  double get trueBearingDegrees =>
      _normalizeHeading(headingDegrees + magneticDeclinationDegrees);

  /// Local right-handed Y-up yaw in radians (`0 = -Z North`, `-pi/2 = +X East`).
  double get localYawRadians =>
      -trueBearingDegrees * math.pi / VrEarthConstants.degreesPerHalfTurn;

  static double _normalizeHeading(double degrees) {
    final mod = degrees % VrEarthConstants.degreesPerFullTurn;
    return mod < 0 ? mod + VrEarthConstants.degreesPerFullTurn : mod;
  }

  @override
  bool operator ==(Object other) =>
      other is EarthCompassAlignment &&
      headingDegrees == other.headingDegrees &&
      magneticDeclinationDegrees == other.magneticDeclinationDegrees;

  @override
  int get hashCode => Object.hash(headingDegrees, magneticDeclinationDegrees);
}
