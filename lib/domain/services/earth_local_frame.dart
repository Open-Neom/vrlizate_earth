import 'dart:math' as math;

import 'package:vrlizate_world/vrlizate_world.dart';

import '../../utils/constants/vr_earth_constants.dart';
import '../models/earth_centered_position.dart';
import '../models/wgs84_coordinate.dart';
import 'wgs84.dart';

/// A bounded Cartesian neighborhood with a georeferenced origin.
///
/// Mapping to VRlizate is +X east, +Y ellipsoid-normal up, -Z north (ENU).
/// Coordinates are ECEF differences rotated into a tangent frame, not a flat
/// map projection: Earth curvature remains in the local Y component.
final class EarthLocalFrame {
  factory EarthLocalFrame({
    required Wgs84Coordinate origin,
    required VrWorldAddress world,
    double radiusMeters = VrEarthConstants.defaultFrameRadiusMeters,
  }) {
    if (!radiusMeters.isFinite ||
        radiusMeters <= 0 ||
        radiusMeters > maximumRadiusMeters) {
      throw ArgumentError.value(
        radiusMeters,
        VrEarthConstants.paramRadiusMeters,
        'Must be > 0 and <= $maximumRadiusMeters.',
      );
    }
    return EarthLocalFrame._(origin, world, radiusMeters);
  }

  EarthLocalFrame._(this.origin, this.world, this.radiusMeters)
    : _originEcef = Wgs84.toEcef(origin),
      _sinLatitude = math.sin(
        origin.latitudeDegrees * math.pi / VrEarthConstants.degreesPerHalfTurn,
      ),
      _cosLatitude = math.cos(
        origin.latitudeDegrees * math.pi / VrEarthConstants.degreesPerHalfTurn,
      ),
      _sinLongitude = math.sin(
        origin.longitudeDegrees * math.pi / VrEarthConstants.degreesPerHalfTurn,
      ),
      _cosLongitude = math.cos(
        origin.longitudeDegrees * math.pi / VrEarthConstants.degreesPerHalfTurn,
      );

  /// Policy bound, not a claim that all phones can render a 20 km scene.
  static const double maximumRadiusMeters =
      VrEarthConstants.maximumFrameRadiusMeters;

  final Wgs84Coordinate origin;
  final VrWorldAddress world;

  /// Three-dimensional straight-line/chord distance, not surface distance.
  final double radiusMeters;
  final EarthCenteredPosition _originEcef;
  final double _sinLatitude;
  final double _cosLatitude;
  final double _sinLongitude;
  final double _cosLongitude;

  VrWorldPosition project(Wgs84Coordinate coordinate) =>
      _projectEcef(Wgs84.toEcef(coordinate));

  Wgs84Coordinate unproject(VrWorldPosition position) =>
      Wgs84.fromEcef(_toEcef(position));

  /// True when a local position lies within this frame's render/simulation bound.
  bool contains(VrWorldPosition position) =>
      position.distanceSquaredTo(VrWorldPosition.zero) <=
      (radiusMeters + VrEarthConstants.frameRadiusToleranceMeters) *
          (radiusMeters + VrEarthConstants.frameRadiusToleranceMeters);

  /// True when [coordinate] projects within this frame's radius without throwing.
  bool containsCoordinate(Wgs84Coordinate coordinate) {
    final ecef = Wgs84.toEcef(coordinate);
    final dx = ecef.x - _originEcef.x;
    final dy = ecef.y - _originEcef.y;
    final dz = ecef.z - _originEcef.z;
    final maxR = radiusMeters + VrEarthConstants.frameRadiusToleranceMeters;
    return (dx * dx + dy * dy + dz * dz) <= maxR * maxR;
  }

  /// The host can begin an atomic floating-origin change before hitting the edge.
  /// This does not move objects, load data, or mutate this frame.
  bool shouldRebase(VrWorldPosition viewerPosition) =>
      viewerPosition.distanceSquaredTo(VrWorldPosition.zero) >=
      radiusMeters * radiusMeters * VrEarthConstants.rebaseDistanceRatioSquared;

  /// Converts a position into another origin in the SAME world and instance.
  VrWorldPosition rebasePosition(
    VrWorldPosition position, {
    required EarthLocalFrame target,
  }) {
    if (world != target.world) {
      throw ArgumentError.value(
        target.world,
        VrEarthConstants.paramTargetWorld,
        VrEarthConstants.errRebaseAcrossWorlds,
      );
    }
    return target._projectEcef(_toEcef(position));
  }

  /// Resolves a host-registered prototype at a geographic location.
  VrWorldEntity placeEntity({
    required String id,
    required String prototypeId,
    required Wgs84Coordinate coordinate,
    double yawRadians = VrEarthConstants.defaultEntityYawRadians,
    double scale = VrEarthConstants.defaultEntityScale,
  }) => VrWorldEntity(
    id: id,
    prototypeId: prototypeId,
    world: world,
    transform: VrWorldTransform(
      position: project(coordinate),
      yawRadians: yawRadians,
      scale: scale,
    ),
  );

  VrWorldPosition _projectEcef(EarthCenteredPosition position) {
    final dx = position.x - _originEcef.x;
    final dy = position.y - _originEcef.y;
    final dz = position.z - _originEcef.z;
    final east = -_sinLongitude * dx + _cosLongitude * dy;
    final north =
        -_sinLatitude * _cosLongitude * dx -
        _sinLatitude * _sinLongitude * dy +
        _cosLatitude * dz;
    final up =
        _cosLatitude * _cosLongitude * dx +
        _cosLatitude * _sinLongitude * dy +
        _sinLatitude * dz;
    final local = VrWorldPosition(east, up, -north);
    _checkBounds(local);
    return local;
  }

  EarthCenteredPosition _toEcef(VrWorldPosition position) {
    _checkBounds(position);
    final east = position.x;
    final north = -position.z;
    final up = position.y;
    return EarthCenteredPosition(
      _originEcef.x -
          _sinLongitude * east -
          _sinLatitude * _cosLongitude * north +
          _cosLatitude * _cosLongitude * up,
      _originEcef.y +
          _cosLongitude * east -
          _sinLatitude * _sinLongitude * north +
          _cosLatitude * _sinLongitude * up,
      _originEcef.z + _cosLatitude * north + _sinLatitude * up,
    );
  }

  void _checkBounds(VrWorldPosition position) {
    if (!contains(position)) {
      throw ArgumentError.value(
        position,
        VrEarthConstants.paramPosition,
        VrEarthConstants.errOutsideFrameRadius,
      );
    }
  }
}
