import 'package:flutter_test/flutter_test.dart';
import 'package:brass_and_starlight/core/night.dart';
import 'package:brass_and_starlight/core/sky_geometry.dart';
import 'package:brass_and_starlight/core/stroke_solver.dart';
import 'package:brass_and_starlight/core/trace_engine.dart';
import 'package:brass_and_starlight/data/nights.dart';

/// Plays a night with the engine by dragging straight through [route].
TraceEngine playRoute(Night n, List<int> route) {
  final e = TraceEngine(n, hitRadius: SkyRules.hitRadius);
  final s = n.skyStars;
  e.start(s[route.first]);
  for (final i in route.skip(1)) {
    e.move(s[i]);
  }
  e.end();
  return e;
}

void main() {
  test('campaign has 40 nights in 4 chapters with ids in order', () {
    expect(nights.length, 40);
    expect(chapters.length, 4);
    expect([for (final c in chapters) nightsInChapter(c.index).length],
        [8, 10, 12, 10]);
    for (var i = 0; i < nights.length; i++) {
      expect(nights[i].id, i + 1);
    }
    for (final c in chapters) {
      final inCh = nightsInChapter(c.index);
      expect(inCh.last.finale, isTrue, reason: 'chapter ${c.name} finale');
      expect(inCh.where((n) => n.finale).length, 1);
    }
  });

  test('names are unique', () {
    expect(nights.map((n) => n.name).toSet().length, nights.length);
  });

  for (final n in nights) {
    test('night ${n.id} ${n.name} geometry is fair', () {
      expect(geometryProblems(n), isEmpty);
    });

    test('night ${n.id} ${n.name} is solvable by tracing', () {
      final List<int> route;
      if (n.mode == TraceMode.oneStroke) {
        final solved = StrokeSolver(n.edges).solve();
        expect(solved, isNotNull);
        route = solved!;
      } else {
        route = n.path;
      }
      final e = playRoute(n, route);
      expect(e.completed, isTrue);
      expect(e.failCount, 0);
    });
  }

  test('chapter mode rules', () {
    for (final n in nightsInChapter(0)) {
      expect(n.mode, TraceMode.guided);
      expect(n.decoys, isEmpty);
    }
    for (final n in nightsInChapter(1)) {
      expect(n.mode, TraceMode.guided);
      expect(n.decoys, isNotEmpty);
    }
    for (final n in nightsInChapter(2)) {
      expect(n.mode, TraceMode.chart);
      expect(n.rotationDegrees, isNot(0));
      expect(n.decoys.length, greaterThanOrEqualTo(4));
    }
    for (final n in nightsInChapter(3)) {
      expect(n.mode, TraceMode.oneStroke);
    }
  });

  test('difficulty ramps across chapters', () {
    double avg(Iterable<num> v) => v.reduce((a, b) => a + b) / v.length;
    final decoys = [
      for (final c in chapters)
        avg(nightsInChapter(c.index).map((n) => n.decoys.length)),
    ];
    for (var i = 1; i < 3; i++) {
      expect(decoys[i], greaterThan(decoys[i - 1]));
    }
    final lines = [
      for (final c in chapters)
        avg(nightsInChapter(c.index).map((n) => n.edges.length)),
    ];
    expect(lines[3], greaterThan(lines[0]));
    final finale = nights.last;
    expect(finale.edges.length,
        greaterThanOrEqualTo(nights.map((n) => n.edges.length).reduce((a, b) => a > b ? a : b)));
  });
}
