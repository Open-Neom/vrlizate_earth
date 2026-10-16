import 'package:vector_math/vector_math.dart';
import 'package:vrlizate_earth/vrlizate_earth.dart';
import 'package:vrlizate_physics/vrlizate_physics.dart';
import 'package:vrlizate_world/vrlizate_world.dart';

/// Synthetic regional experiment: a box falls onto a flat local plane.
/// The origin is geographic; neither the height nor terrain is surveyed data.
({VrWorldEntity entity, Wgs84Coordinate before, Wgs84Coordinate after})
simulateGeoreferencedDrop() {
  final address = VrWorldAddress(worldId: 'earth-demo', instanceId: 'local');
  final frame = EarthLocalFrame(
    origin: Wgs84Coordinate(
      latitudeDegrees: 19.4326,
      longitudeDegrees: -99.1332,
      ellipsoidalHeightMeters: 2240,
    ),
    world: address,
  );
  final before = frame.unproject(VrWorldPosition(10, 3, -20));
  var entity = frame.placeEntity(
    id: 'box-01',
    prototypeId: 'example.box',
    coordinate: before,
  );
  final registry = VrWorldRegistry(world: address)..add(entity);
  final position = entity.transform.position;
  final body = PhysicsBody(
    transform: PhysicsPose(
      position: Vector3(position.x, position.y, position.z),
    ),
    halfExtents: Vector3.all(.5),
    restitution: 0,
    linearDamping: 0,
  );
  // The host links physics to an existing entity ID, without another identity.
  final bodies = {entity.id: body};
  final simulation = PhysicsWorld<PhysicsBody>()..addBody(body);
  for (var frameIndex = 0; frameIndex < 120; frameIndex++) {
    simulation.update(1 / 60);
    final pose = bodies[entity.id]!.transform.position;
    entity = entity.copyWith(
      transform: entity.transform.copyWith(
        position: VrWorldPosition(pose.x, pose.y, pose.z),
      ),
    );
    registry.update(entity);
  }
  final settled = registry[entity.id]!;
  return (
    entity: settled,
    before: before,
    after: frame.unproject(settled.transform.position),
  );
}

void main() {
  final result = simulateGeoreferencedDrop();
  final point = result.entity.transform.position;
  print('${result.entity.world} / ${result.entity.id}');
  print('Local center after 2 s: (${point.x}, ${point.y}, ${point.z}) m');
  print(
    'Ellipsoidal height: ${result.before.ellipsoidalHeightMeters} → '
    '${result.after.ellipsoidalHeightMeters} m',
  );
  print('Synthetic flat-ground test; no real terrain was downloaded.');
}
