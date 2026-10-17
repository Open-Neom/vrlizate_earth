import '../../utils/constants/vr_earth_constants.dart';
import '../../utils/vr_earth_validator.dart';

/// CPU-side Earth-centered, Earth-fixed (ECEF) meters; never GPU coordinates.
///
/// X points to latitude 0 / longitude 0, Y to latitude 0 / longitude 90 east,
/// and Z to the north pole. Finite bounded values avoid overflowing arithmetic.
/// A valid ECEF tuple is not necessarily within the supported geographic layer.
final class EarthCenteredPosition {
  factory EarthCenteredPosition(double x, double y, double z) {
    for (final (name, value) in [
      (VrEarthConstants.paramX, x),
      (VrEarthConstants.paramY, y),
      (VrEarthConstants.paramZ, z),
    ]) {
      VrEarthValidator.checkRange(
        value,
        name,
        VrEarthConstants.minEcefCoordinateMeters,
        VrEarthConstants.maxEcefCoordinateMeters,
      );
    }
    return EarthCenteredPosition._(x, y, z);
  }

  const EarthCenteredPosition._(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  @override
  bool operator ==(Object other) =>
      other is EarthCenteredPosition &&
      x == other.x &&
      y == other.y &&
      z == other.z;

  @override
  int get hashCode => Object.hash(x, y, z);
}
