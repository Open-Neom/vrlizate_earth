import 'package:vrlizate_world/vrlizate_world.dart';

import '../../utils/constants/vr_earth_constants.dart';
import '../services/earth_local_frame.dart';
import 'wgs84_coordinate.dart';

/// A georeferenced Point of Interest (POI) anchored on the WGS84 ellipsoid.
final class EarthPoiNode {
  factory EarthPoiNode({
    required String id,
    required String label,
    required Wgs84Coordinate coordinate,
    String category = VrEarthConstants.defaultPoiCategory,
    String prototypeId = VrEarthConstants.defaultPoiPrototypeId,
    double yawRadians = VrEarthConstants.defaultEntityYawRadians,
    double scale = VrEarthConstants.defaultEntityScale,
  }) {
    VrWorldValidator.validateIdentifier(id, VrWorldConstants.paramId);
    VrWorldValidator.validateIdentifier(
      prototypeId,
      VrWorldConstants.paramPrototypeId,
    );
    final trimmedLabel = label.trim();
    if (trimmedLabel.isEmpty ||
        trimmedLabel.length > VrEarthConstants.maxPoiLabelLength) {
      throw ArgumentError.value(
        label,
        VrEarthConstants.paramLabel,
        VrEarthConstants.errPoiLabelEmpty,
      );
    }
    final trimmedCategory = category.trim();
    if (trimmedCategory.isEmpty ||
        trimmedCategory.length > VrEarthConstants.maxPoiLabelLength) {
      throw ArgumentError.value(
        category,
        VrEarthConstants.paramCategory,
        VrEarthConstants.errPoiCategoryEmpty,
      );
    }
    return EarthPoiNode._(
      id,
      trimmedLabel,
      trimmedCategory,
      coordinate,
      prototypeId,
      yawRadians,
      scale,
    );
  }

  const EarthPoiNode._(
    this.id,
    this.label,
    this.category,
    this.coordinate,
    this.prototypeId,
    this.yawRadians,
    this.scale,
  );

  final String id;
  final String label;
  final String category;
  final Wgs84Coordinate coordinate;
  final String prototypeId;
  final double yawRadians;
  final double scale;

  /// Projects this POI into [frame] and returns a [VrWorldEntity].
  VrWorldEntity toWorldEntity(EarthLocalFrame frame) => frame.placeEntity(
    id: id,
    prototypeId: prototypeId,
    coordinate: coordinate,
    yawRadians: yawRadians,
    scale: scale,
  );

  @override
  bool operator ==(Object other) =>
      other is EarthPoiNode &&
      id == other.id &&
      label == other.label &&
      category == other.category &&
      coordinate == other.coordinate &&
      prototypeId == other.prototypeId &&
      yawRadians == other.yawRadians &&
      scale == other.scale;

  @override
  int get hashCode => Object.hash(
    id,
    label,
    category,
    coordinate,
    prototypeId,
    yawRadians,
    scale,
  );
}
