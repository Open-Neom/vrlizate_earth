# vrlizate_earth

Pure Dart Earth georeferencing for the VRlizate SDK. Depends only on
`vrlizate_world`; the generic world module does not depend on Earth.

This first version provides WGS84 ellipsoidal coordinates, CPU-side ECEF
conversion, bounded local frames, and placement of existing world entities.
It is a coordinate foundation, not a terrain renderer or a copy of the planet.
No elevation maps, satellite images, ecosystems, location permissions, remote
services, physics simulation, or native plugins are included.

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
final tree = frame.placeEntity(
  id: 'tree-01',
  prototypeId: 'nature.oak', // A factory registered by the host.
  coordinate: frame.unproject(VrWorldPosition(10, 0, -20)),
);
// tree.transform.position is approximately (10, 0, -20) meters.
```

`dart run tool/georeference_example.dart` demonstrates placement and round trips
without Flutter. `dart run tool/earth_physics_example.dart` additionally links a
geographic entity to local physics and reprojects its resulting pose. Physics is
only a development dependency for this example/test, not a runtime dependency of
Earth. A renderer and collision system can consume the same resulting
entity; this module neither draws a tree nor downloads its model.

## Coordinate contract

- Geographic input is latitude/longitude in degrees and **ellipsoidal height**
  in meters. Latitude accepts [-90, 90]; longitude accepts [-180, 180] and
  normalizes +180 to -180. Nonfinite/out-of-range values are rejected.
- Height is relative to the WGS84 ellipsoid, not mean sea level or terrain.
  To convert orthometric height H, a separate geoid model must provide N so that
  h = H + N. This package does not assume those heights are interchangeable.
- Supported heights are -12,000 through 1,000,000 meters. This is an intentional
  near-Earth layer, not an interior-Earth or orbital mechanics library.
- ECEF X points toward the equator at Greenwich, Y toward 90° east, and Z toward
  the north pole. Global ECEF meters remain in CPU doubles and canonical storage.
- Local VR coordinates use **+X east, +Y up, -Z north**. Up is the ellipsoid
  normal at the origin. Projection rotates an ECEF difference; Earth curvature
  is retained in local Y rather than flattened into a constant-height plane.
- Poles and the antimeridian are supported. At an exact ECEF-axis pole longitude
  is undefined and canonicalized to zero; a geographic pole origin's specified
  longitude selects the otherwise arbitrary east/north tangent orientation.
- `VrWorldAddress` still identifies a world AND an instance. A local position is
  meaningful only together with that address and its geographic frame origin.
  Frame metadata must accompany network/local data when origins can differ.

The ellipsoid constants are WGS84, but there is no epoch, tectonic deformation,
datum transformation, geoid correction, or surveying accuracy guarantee.

## Floating origins and streaming

`EarthLocalFrame` defaults to a **2 km radius**, bounded at **20 km**. The radius
is three-dimensional chord distance, not surface distance. Both project and
unproject reject points outside that sphere (with a one-micrometer rounding
tolerance). This cap is a precision policy, not a device rendering capability.

`shouldRebase` signals when the viewer is halfway to the edge. The host can
create a new frame at the viewer's canonical geographic position and convert
nearby objects with `oldFrame.rebasePosition(position, target: newFrame)`.
Rebasing across different worlds or instances is rejected. The host must switch
camera, all entity poses, meshes, colliders, physics, and network interpretation
atomically. **The API converts only position**: orientation, velocity, and gravity
also require rotation between tangent frames; they are not updated implicitly.

Retain canonical geographic/ECEF data and derive nearby render positions from
it. Share prototypes/geometry and stream visible regional data instead of
building one mesh at planet-sized float coordinates. A height-preserving
geographic surface is curved, so terrain geometry and physics contacts must
eventually represent that curvature. Region data providers, tiles, terrain LOD,
biomes, vegetation, fauna, oceans, atmosphere and astronomical lighting are
future layers that consume this coordinate contract.

## Primary references

- [NGA WGS84 defining parameters](https://earth-info.nga.mil/index.php?action=wgs84&dir=wgs84):
  equatorial semi-major axis 6,378,137 meters and reciprocal flattening
  298.257223563.
- [ESA Navipedia: ellipsoidal/Cartesian conversion](https://gssc.esa.int/navipedia/index.php/Ellipsoidal_and_Cartesian_Coordinates_Conversion):
  geodetic/ECEF equations. The inverse here uses an equivalent stable iterative
  latitude equation and normal-projected height to avoid pole singularities.
- [ESA Navipedia: ECEF/ENU transformation](https://gssc.esa.int/navipedia/index.php/Transformations_between_ECEF_and_ENU_coordinates):
  tangent basis and rotation equations.
- [NGA Earth Gravitational Model](https://earth-info.nga.mil/geograv): distinction
  between the geoid and reference ellipsoid.

## Validation

```sh
dart pub get
dart analyze
dart test
```

Tests cover reference ellipsoid axes, geographic/ECEF round trips across the
planet, both poles, antimeridian continuity, local axis orientation and units,
curvature, finite/domain validation, radius limits, entity placement, and
floating-origin invariants and instance isolation.
