/// Validation helpers for WGS84 coordinates, ECEF coordinates, and local Earth frames.
abstract final class VrEarthValidator {
  static void checkRange(
    double value,
    String name,
    double minimum,
    double maximum,
  ) {
    if (!value.isFinite || value < minimum || value > maximum) {
      throw ArgumentError.value(
        value,
        name,
        'Must be finite within [$minimum, $maximum].',
      );
    }
  }
}
