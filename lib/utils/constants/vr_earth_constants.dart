abstract final class VrEarthConstants {
  static const double minLatitudeDegrees = -90.0;
  static const double maxLatitudeDegrees = 90.0;
  static const double minLongitudeDegrees = -180.0;
  static const double maxLongitudeDegrees = 180.0;

  static const double minimumHeightMeters = -12000.0;
  static const double maximumHeightMeters = 1000000.0;

  static const double minEcefCoordinateMeters = -10000000.0;
  static const double maxEcefCoordinateMeters = 10000000.0;

  static const double semiMajorAxisMeters = 6378137.0;
  static const double inverseFlattening = 298.257223563;
  static const double flattening = 1.0 / inverseFlattening;
  static const double semiMinorAxisMeters =
      semiMajorAxisMeters * (1.0 - flattening);
  static const double eccentricitySquared = flattening * (2.0 - flattening);
  static const double meanEarthRadiusMeters = 6371008.8;

  static const int maxGeodeticIterations = 16;
  static const double geodeticConvergenceRadians = 1e-14;
  static const double boundarySnapToleranceMeters = 1e-6;
  static const double degreesPerHalfTurn = 180.0;
  static const double degreesPerFullTurn = 360.0;

  static const double defaultFrameRadiusMeters = 2000.0;
  static const double maximumFrameRadiusMeters = 20000.0;
  static const double frameRadiusToleranceMeters = 1e-6;
  static const double rebaseDistanceRatioSquared = 0.25;
  static const double defaultEntityYawRadians = 0.0;
  static const double defaultEntityScale = 1.0;

  static const double maxSurfaceDistanceMeters = 20037508.34;
  static const int maxPoiLabelLength = 160;
  static const String defaultPoiCategory = 'general';
  static const String defaultPoiPrototypeId = 'earth.poi.marker';

  static const String paramLatitudeDegrees = 'latitudeDegrees';
  static const String paramLongitudeDegrees = 'longitudeDegrees';
  static const String paramEllipsoidalHeightMeters = 'ellipsoidalHeightMeters';
  static const String paramPosition = 'position';
  static const String paramRadiusMeters = 'radiusMeters';
  static const String paramTargetWorld = 'target.world';
  static const String paramX = 'x';
  static const String paramY = 'y';
  static const String paramZ = 'z';
  static const String paramBearingDegrees = 'bearingDegrees';
  static const String paramDistanceMeters = 'distanceMeters';
  static const String paramHeadingDegrees = 'headingDegrees';
  static const String paramMagneticDeclinationDegrees =
      'magneticDeclinationDegrees';
  static const String paramYawRadians = 'yawRadians';
  static const String paramLabel = 'label';
  static const String paramCategory = 'category';

  static const String errEarthCenterUndefined = 'Earth center is undefined.';
  static const String errOutsideGeodeticDomain =
      'Outside geodetic conversion domain.';
  static const String errRebaseAcrossWorlds =
      'Cannot rebase across worlds or instances.';
  static const String errOutsideFrameRadius =
      'Outside local frame radius; rebase or stream another region.';
  static const String errPoiLabelEmpty =
      'POI label must be non-empty and <= 160 characters.';
  static const String errPoiCategoryEmpty =
      'POI category must be non-empty and <= 160 characters.';
}
