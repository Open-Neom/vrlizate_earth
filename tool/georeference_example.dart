import 'package:vrlizate_earth/vrlizate_earth.dart';
import 'package:vrlizate_world/vrlizate_world.dart';

void main() {
  // Mexico City horizontal coordinates; the height/objects are synthetic.
  // This example makes no claim to surveyed terrain or a real-world tree.
  final origin = Wgs84Coordinate(
    latitudeDegrees: 19.4326,
    longitudeDegrees: -99.1332,
    ellipsoidalHeightMeters: 2240,
  );
  final frame = EarthLocalFrame(
    origin: origin,
    world: VrWorldAddress(worldId: 'earth-demo', instanceId: 'local'),
  );
  final geographic = frame.unproject(VrWorldPosition(10, 0, -20));
  final tree = frame.placeEntity(
    id: 'tree-01',
    prototypeId: 'nature.oak',
    coordinate: geographic,
  );
  final local = tree.transform.position;
  print(
    '${tree.id} in ${tree.world}: '
    'east ${local.x.toStringAsFixed(3)} m, '
    'up ${local.y.toStringAsFixed(3)} m, '
    'north ${(-local.z).toStringAsFixed(3)} m',
  );
  print(
    'Geographic: ${geographic.latitudeDegrees}, '
    '${geographic.longitudeDegrees}; ellipsoidal height '
    '${geographic.ellipsoidalHeightMeters.toStringAsFixed(3)} m',
  );
  final reconstructed = frame.project(geographic);
  print(
    'Round-trip error: '
    '${reconstructed.distanceTo(VrWorldPosition(10, 0, -20))} m',
  );
}
