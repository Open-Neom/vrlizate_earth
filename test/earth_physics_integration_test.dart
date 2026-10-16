import 'package:test/test.dart';
import '../tool/earth_physics_example.dart';

void main() {
  test(
    'geographic entity retains identity through local physics and reprojection',
    () {
      final result = simulateGeoreferencedDrop();
      expect(result.entity.id, 'box-01');
      expect(result.entity.world.worldId, 'earth-demo');
      expect(result.entity.world.instanceId, 'local');
      final point = result.entity.transform.position;
      expect(point.x, closeTo(10, 1e-5));
      expect(point.z, closeTo(-20, 1e-5));
      expect(
        point.y,
        closeTo(.5, 1e-6),
        reason: 'The bottom of a 1 m box rests on the plane.',
      );
      expect(
        result.before.ellipsoidalHeightMeters -
            result.after.ellipsoidalHeightMeters,
        closeTo(2.5, 1e-4),
      );
      expect(
        result.after.latitudeDegrees,
        closeTo(result.before.latitudeDegrees, 1e-8),
      );
      expect(
        result.after.longitudeDegrees,
        closeTo(result.before.longitudeDegrees, 1e-8),
      );
    },
  );
}
