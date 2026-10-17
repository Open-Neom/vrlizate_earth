# vrlizate_earth

Pure Dart Earth georeferencing, geodesic navigation, compass alignment, and local POI projection for the VRlizate SDK. Depends only on `vrlizate_world`; the generic world module does not depend on Earth.

> Current version: **1.0.0**. See [CHANGELOG.md](CHANGELOG.md).

## Use

```dart
import 'package:vrlizate_earth/vrlizate_earth.dart';
import 'package:vrlizate_world/vrlizate_world.dart';

final origin = Wgs84Coordinate(
  latitudeDegrees: 19.4326,
  longitudeDegrees: -99.1332,
  ellipsoidalHeightMeters: 2240, // Synthetic sample height, not surveyed terrain.
);
final frame = EarthLocalFrame(
  origin: origin,
  world: VrWorldAddress(worldId: 'earth-demo', instanceId: 'local'),
);

final pois = EarthPoiRegistry()
  ..register(
    EarthPoiNode(
      id: 'poi-stage',
      label: 'Plaza Stage',
      category: 'music',
      coordinate: EarthGeodesicCalculator.destinationCoordinate(
        start: origin,
        bearingDegrees: 45,
        distanceMeters: 120,
      ),
    ),
  );

final entities = pois.projectIntoFrame(frame);
final compass = EarthCompassAlignment(
  headingDegrees: 90,
  magneticDeclinationDegrees: 4.5,
);
```

`dart run tool/georeference_example.dart` demonstrates placement and round trips
without Flutter. `dart run tool/earth_physics_example.dart` additionally links a
geographic entity to local physics and reprojects its resulting pose.

## Coordinate contract

- Geographic input is latitude/longitude in degrees and **ellipsoidal height**
  in meters. Latitude accepts [-90, 90]; longitude accepts [-180, 180] and
  normalizes +180 to -180. Nonfinite/out-of-range values are rejected.
- Height is relative to the WGS84 ellipsoid, not mean sea level or terrain.
  Supported heights are -12,000 through 1,000,000 meters.
- ECEF X points toward the equator at Greenwich, Y toward 90° east, and Z toward
  the north pole. Global ECEF meters remain in CPU doubles and canonical storage.
- Local VR coordinates use **+X east, +Y up, -Z north**. Up is the ellipsoid
  normal at the origin. Projection rotates an ECEF difference; Earth curvature
  is retained in local Y rather than flattened into a constant-height plane.
- `EarthGeodesicCalculator` provides Haversine surface distance, forward bearing,
  and destination coordinate calculation on the mean-radius sphere.
- `EarthCompassAlignment` bridges device compass bearings (`0° = North`, `90° = East`)
  and magnetic declination with right-handed local ENU yaw (`0 rad = -Z North`).
- `EarthPoiNode` and `EarthPoiRegistry` manage georeferenced Points of Interest and
  project visible nodes into an `EarthLocalFrame`.

## Floating origins and streaming

`EarthLocalFrame` defaults to a **2 km radius**, bounded at **20 km**. The radius
is three-dimensional chord distance, not surface distance. Both project and
unproject reject points outside that sphere (with a one-micrometer rounding
tolerance). `containsCoordinate` checks whether a `Wgs84Coordinate` lies within
the frame before projecting.

`shouldRebase` signals when the viewer is halfway to the edge. The host can
create a new frame at the viewer's canonical geographic position and convert
nearby objects with `oldFrame.rebasePosition(position, target: newFrame)`.

## Validation

```sh
flutter analyze
flutter test
```
