# Changelog

## 1.0.0

- Architecture refactor to Open Neom standard layout (`lib/utils/constants/`, `lib/domain/models/`, `lib/domain/services/`) with one class per file and centralized constants (`VrEarthConstants`).
- Add `EarthGeodesicCalculator` with Haversine surface distance, initial forward bearing, and spherical destination coordinate calculation.
- Add `EarthCompassAlignment` for converting between magnetic/true compass headings and VRlizate right-handed local ENU yaw.
- Add `EarthPoiNode` and `EarthPoiRegistry` for registering georeferenced Points of Interest, querying by surface distance, and projecting into an `EarthLocalFrame`.
- Add `EarthLocalFrame.containsCoordinate` for non-throwing coordinate bounds checks.
- Preserve 100% backward-compatible barrel exports under `lib/src/` and `lib/vrlizate_earth.dart`.

## 0.1.0 - local preview

- WGS84 coordinates, ECEF conversions, local tangent frames, and entity placement.
