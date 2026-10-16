import 'package:test/test.dart';
import 'package:vrlizate_earth/vrlizate_earth.dart';
import 'package:vrlizate_world/vrlizate_world.dart';

Wgs84Coordinate point(double latitude, double longitude, [double height = 0]) =>
    Wgs84Coordinate(
      latitudeDegrees: latitude,
      longitudeDegrees: longitude,
      ellipsoidalHeightMeters: height,
    );

void main() {
  final world = VrWorldAddress(worldId: 'earth', instanceId: 'public-01');

  test('origin is zero and meter axes point east, up and minus north', () {
    final frame = EarthLocalFrame(origin: point(0, 0), world: world);
    expect(frame.project(frame.origin), VrWorldPosition.zero);
    final east = frame.project(point(0, 0.001));
    expect(east.x, closeTo(111.31949079, 1e-6));
    expect(east.z, closeTo(0, 1e-9));
    final north = frame.project(point(0.001, 0));
    expect(north.z, closeTo(-110.57427582, 1e-6));
    expect(north.x, closeTo(0, 1e-9));
    final up = frame.project(point(0, 0, 12));
    expect(up, VrWorldPosition(0, 12, 0));
  });

  test(
    'projection retains Earth curvature instead of flattening constant height',
    () {
      final frame = EarthLocalFrame(origin: point(0, 0), world: world);
      final east = frame.project(point(0, 0.01));
      expect(east.x, closeTo(1113.19490228, 1e-5));
      expect(east.y, closeTo(-0.09714458, 1e-6));
      expect(east.y, lessThan(0));
    },
  );

  test('local round trips work in Mexico, equator, poles and antimeridian', () {
    for (final origin in [
      point(19.4326, -99.1332, 2240),
      point(0, 0),
      point(90, 137),
      point(-90, -50),
      point(0, 179.9999),
    ]) {
      final frame = EarthLocalFrame(origin: origin, world: world);
      for (final local in [
        VrWorldPosition.zero,
        VrWorldPosition(200, 30, -400),
        VrWorldPosition(-123, -50, 875),
        VrWorldPosition(0, 2000, 0),
      ]) {
        final result = frame.project(frame.unproject(local));
        expect(result.distanceTo(local), lessThan(1e-6));
      }
    }
  });

  test(
    'antimeridian traversal remains a short continuous eastward movement',
    () {
      final frame = EarthLocalFrame(origin: point(0, 179.999), world: world);
      final across = frame.project(point(0, -179.999));
      expect(across.x, closeTo(222.63898154, 1e-5));
      expect(across.z, closeTo(0, 1e-7));
      expect(
        frame.unproject(across).longitudeDegrees,
        closeTo(-179.999, 1e-10),
      );
    },
  );

  test('radius is bounded, finite and three-dimensional', () {
    for (final invalid in [0.0, -1.0, double.nan, double.infinity, 20000.01]) {
      expect(
        () => EarthLocalFrame(
          origin: point(0, 0),
          world: world,
          radiusMeters: invalid,
        ),
        throwsArgumentError,
      );
    }
    final frame = EarthLocalFrame(
      origin: point(0, 0),
      world: world,
      radiusMeters: 100,
    );
    expect(frame.contains(VrWorldPosition(100, 0, 0)), isTrue);
    expect(frame.contains(VrWorldPosition(100.001, 0, 0)), isFalse);
    expect(frame.contains(VrWorldPosition(75, 75, 0)), isFalse);
    expect(
      () => frame.unproject(VrWorldPosition(101, 0, 0)),
      throwsArgumentError,
    );
    expect(() => frame.project(point(1, 1)), throwsArgumentError);
    expect(() => frame.project(point(0, 0, 101)), throwsArgumentError);
    expect(() => frame.project(point(0, 180)), throwsArgumentError);
  });

  test('rebase signal precedes radius edge and does not mutate the frame', () {
    final frame = EarthLocalFrame(
      origin: point(0, 0),
      world: world,
      radiusMeters: 100,
    );
    expect(frame.shouldRebase(VrWorldPosition(49, 0, 0)), isFalse);
    expect(frame.shouldRebase(VrWorldPosition(50, 0, 0)), isTrue);
    expect(frame.shouldRebase(VrWorldPosition(0, 0, -60)), isTrue);
    expect(frame.project(frame.origin), VrWorldPosition.zero);
  });

  test('floating-origin conversion preserves canonical position', () {
    final first = EarthLocalFrame(
      origin: point(19.4326, -99.1332, 2240),
      world: world,
    );
    final second = EarthLocalFrame(
      origin: first.unproject(VrWorldPosition(400, 3, -700)),
      world: world,
    );
    final original = VrWorldPosition(-20, 9, -30);
    final rebased = first.rebasePosition(original, target: second);
    final roundTrip = second.rebasePosition(rebased, target: first);
    expect(roundTrip.distanceTo(original), lessThan(1e-6));
    final expected = first.unproject(original);
    final actual = second.unproject(rebased);
    expect(actual.latitudeDegrees, closeTo(expected.latitudeDegrees, 1e-10));
    expect(actual.longitudeDegrees, closeTo(expected.longitudeDegrees, 1e-10));
    expect(
      actual.ellipsoidalHeightMeters,
      closeTo(expected.ellipsoidalHeightMeters, 1e-6),
    );
  });

  test(
    'rebase rejects foreign worlds, foreign instances, and distant regions',
    () {
      final first = EarthLocalFrame(origin: point(0, 0), world: world);
      for (final foreign in [
        VrWorldAddress(worldId: 'other', instanceId: 'public-01'),
        VrWorldAddress(worldId: 'earth', instanceId: 'private-01'),
      ]) {
        final second = EarthLocalFrame(origin: first.origin, world: foreign);
        expect(
          () => first.rebasePosition(VrWorldPosition.zero, target: second),
          throwsArgumentError,
        );
      }
      final distant = EarthLocalFrame(origin: point(1, 1), world: world);
      expect(
        () => first.rebasePosition(VrWorldPosition.zero, target: distant),
        throwsArgumentError,
      );
      expect(
        () => first.rebasePosition(VrWorldPosition(2001, 0, 0), target: first),
        throwsArgumentError,
      );
    },
  );

  test('entity placement uses world identity, validated prototype, and shared pose', () {
    final frame = EarthLocalFrame(origin: point(19, -99, 2200), world: world);
    final local = VrWorldPosition(10, 0, -20);
    final tree = frame.placeEntity(
      id: 'tree-01',
      prototypeId: 'nature.oak',
      coordinate: frame.unproject(local),
      yawRadians: 0.5,
      scale: 2,
    );
    expect(tree.id, 'tree-01');
    expect(tree.prototypeId, 'nature.oak');
    expect(tree.world, world);
    expect(tree.transform.position.distanceTo(local), lessThan(1e-6));
    expect(tree.transform.yawRadians, closeTo(0.5, 1e-10));
    expect(tree.transform.scale, 2);
    expect(
      () => frame.placeEntity(
        id: 'tree',
        prototypeId: '../download.dart',
        coordinate: frame.origin,
      ),
      throwsArgumentError,
    );
  });
}
