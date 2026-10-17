import 'package:vrlizate_world/vrlizate_world.dart';

import '../../utils/constants/vr_earth_constants.dart';
import '../../utils/vr_earth_validator.dart';
import '../models/earth_poi_node.dart';
import '../models/wgs84_coordinate.dart';
import 'earth_geodesic_calculator.dart';
import 'earth_local_frame.dart';

/// Spatial registry for georeferenced Points of Interest ([EarthPoiNode])
/// supporting surface-distance queries and projection into an [EarthLocalFrame].
final class EarthPoiRegistry {
  final Map<String, EarthPoiNode> _nodes = <String, EarthPoiNode>{};

  int get length => _nodes.length;
  List<EarthPoiNode> get nodes => List.unmodifiable(_nodes.values);

  EarthPoiNode? operator [](String id) => _nodes[id];

  /// Registers [node], throwing a [StateError] if its `id` already exists.
  void register(EarthPoiNode node) {
    if (_nodes.containsKey(node.id)) {
      throw StateError('POI ${node.id} is already registered.');
    }
    _nodes[node.id] = node;
  }

  /// Removes the POI with [id] and returns `true` if it was present.
  bool remove(String id) => _nodes.remove(id) != null;

  /// Clears all registered POIs.
  void clear() => _nodes.clear();

  /// Returns all registered POIs within [radiusMeters] great-circle surface
  /// distance of [center], sorted by ascending surface distance.
  List<EarthPoiNode> queryWithinSurfaceDistanceMeters({
    required Wgs84Coordinate center,
    required double radiusMeters,
    String? category,
  }) {
    VrEarthValidator.checkRange(
      radiusMeters,
      VrEarthConstants.paramRadiusMeters,
      0.0,
      VrEarthConstants.maxSurfaceDistanceMeters,
    );
    final matches = <(EarthPoiNode, double)>[];
    for (final node in _nodes.values) {
      if (category != null && node.category != category) continue;
      final dist = EarthGeodesicCalculator.haversineDistanceMeters(
        center,
        node.coordinate,
      );
      if (dist <= radiusMeters) {
        matches.add((node, dist));
      }
    }
    matches.sort((a, b) {
      final cmp = a.$2.compareTo(b.$2);
      return cmp != 0 ? cmp : a.$1.id.compareTo(b.$1.id);
    });
    return List.unmodifiable([for (final match in matches) match.$1]);
  }

  /// Projects all registered POIs whose coordinates lie inside [frame] into
  /// local [VrWorldEntity] instances.
  List<VrWorldEntity> projectIntoFrame(
    EarthLocalFrame frame, {
    String? category,
  }) {
    final entities = <VrWorldEntity>[];
    for (final node in _nodes.values) {
      if (category != null && node.category != category) continue;
      if (frame.containsCoordinate(node.coordinate)) {
        entities.add(node.toWorldEntity(frame));
      }
    }
    entities.sort((a, b) => a.id.compareTo(b.id));
    return List.unmodifiable(entities);
  }
}
