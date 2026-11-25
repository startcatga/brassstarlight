import 'package:flutter_test/flutter_test.dart';
import 'package:brass_and_starlight/core/daily.dart';
import 'package:brass_and_starlight/core/night.dart';
import 'package:brass_and_starlight/core/sky_geometry.dart';
import 'package:brass_and_starlight/core/stroke_solver.dart';
import 'package:brass_and_starlight/core/trace_engine.dart';

Night line3({TraceMode mode = TraceMode.guided, List<Pt> decoys = const []}) => Night(
      id: 1,
      chapter: 0,
      name: 'Test',
      myth: '',
      mode: mode,
      stars: const [Pt(0.2, 0.5), Pt(0.5, 0.5), Pt(0.8, 0.5)],
      edges: pathEdges(const [0, 1, 2]),
      path: const [0, 1, 2],
      decoys: decoys,
    );

void main() {
  const r = SkyRules.hitRadius;

  group('guided', () {
    test('traces in order and completes', () {
      final e = TraceEngine(line3(), hitRadius: r);
      expect(e.guideStar, 0);
      expect(e.start(const Pt(0.2, 0.5)).started, isTrue);
      expect(e.guideStar, 1);
      e.move(const Pt(0.5, 0.5));
      final ev = e.move(const Pt(0.8, 0.5));
      expect(ev.completed, isTrue);
      expect(e.completed, isTrue);
      expect(e.failCount, 0);
    });

    test('fast swipe cannot skip a star', () {
      final e = TraceEngine(line3(), hitRadius: r);
      e.start(const Pt(0.2, 0.5));
      final ev = e.move(const Pt(0.8, 0.5)); // passes through star 1
      expect(ev.completed, isTrue);
    });

    test('starting elsewhere does nothing in guided mode', () {
      final e = TraceEngine(line3(), hitRadius: r);
      expect(e.start(const Pt(0.8, 0.5)).isNone, isTrue);
      expect(e.tracing, isFalse);
    });

    test('lifting early breaks the line and counts a fail', () {
      final e = TraceEngine(line3(), hitRadius: r);
      e.start(const Pt(0.2, 0.5));
      e.move(const Pt(0.5, 0.5));
      expect(e.end().fail, TraceFail.broken);
      expect(e.failCount, 1);
      expect(e.visited, isEmpty);
    });

    test('a lone tap on the first star is not a fail', () {
      final e = TraceEngine(line3(), hitRadius: r);
      e.start(const Pt(0.2, 0.5));
      expect(e.end().isNone, isTrue);
      expect(e.failCount, 0);
    });

    test('touching a decoy breaks the line', () {
      final e = TraceEngine(line3(decoys: const [Pt(0.35, 0.8)]), hitRadius: r);
      e.start(const Pt(0.2, 0.5));
      expect(e.move(const Pt(0.35, 0.8)).fail, TraceFail.decoy);
      expect(e.failCount, 1);
    });

    test('lantern points at the next star', () {
      final e = TraceEngine(line3(), hitRadius: r);
      expect(e.hintStar(), 0);
      e.start(const Pt(0.2, 0.5));
      expect(e.hintStar(), 1);
    });
  });

  group('chart', () {
    test('may begin at either end', () {
      final e = TraceEngine(line3(mode: TraceMode.chart), hitRadius: r);
      expect(e.guideStar, isNull);
      e.start(const Pt(0.8, 0.5));
      e.move(const Pt(0.5, 0.5));
      expect(e.move(const Pt(0.2, 0.5)).completed, isTrue);
    });

    test('a middle star is not a start', () {
      final e = TraceEngine(line3(mode: TraceMode.chart), hitRadius: r);
      expect(e.start(const Pt(0.5, 0.5)).isNone, isTrue);
    });
  });

  group('one stroke', () {
    // Triangle 0-1-2 with a tail 0-3: must start at 0 or 3.
    final n = Night(
      id: 1,
      chapter: 3,
      name: 'Tri',
      myth: '',
      mode: TraceMode.oneStroke,
      stars: const [Pt(0.3, 0.7), Pt(0.5, 0.25), Pt(0.75, 0.7), Pt(0.2, 0.9)],
      edges: [Edge(0, 1), Edge(1, 2), Edge(2, 0), Edge(0, 3)],
    );

    test('solver finds valid starts and a full stroke', () {
      final s = StrokeSolver(n.edges);
      expect(s.validStarts(), [0, 3]);
      final seq = s.solve()!;
      expect(seq.length, n.edges.length + 1);
    });

    test('drawing every line completes', () {
      final e = TraceEngine(n, hitRadius: r);
      final s = n.skyStars;
      e.start(s[3]);
      e.move(s[0]);
      e.move(s[1]);
      e.move(s[2]);
      expect(e.move(s[0]).completed, isTrue);
    });

    test('retracing a line fails', () {
      final e = TraceEngine(n, hitRadius: r);
      final s = n.skyStars;
      e.start(s[3]);
      e.move(s[0]);
      expect(e.move(s[3]).fail, TraceFail.retraced);
    });

    test('a dead end is detected and the lantern still guides', () {
      final e = TraceEngine(n, hitRadius: r);
      final s = n.skyStars;
      e.start(s[1]);
      expect(e.strokeStuck, isTrue); // started at an even star with odd pair elsewhere
      final e2 = TraceEngine(n, hitRadius: r);
      expect(e2.hintStar(), anyOf(0, 3));
    });

    test('impossible figures are rejected by the solver', () {
      // Four odd vertices (a plain square with both diagonals).
      final edges = [Edge(0, 1), Edge(1, 2), Edge(2, 3), Edge(3, 0), Edge(0, 2), Edge(1, 3)];
      expect(StrokeSolver(edges).solve(), isNull);
    });
  });

  group('daily sky', () {
    test('same date gives the same sky; it is fair and solvable', () {
      for (var d = 0; d < 21; d++) {
        final date = DateTime(2026, 11, 1).add(Duration(days: d));
        final a = dailyNight(date);
        final b = dailyNight(date);
        expect(a.name, b.name);
        expect(a.skyStars, b.skyStars);
        expect(geometryProblems(a), isEmpty, reason: dateKey(date));
        final route = a.mode == TraceMode.oneStroke ? StrokeSolver(a.edges).solve()! : a.path;
        final e = TraceEngine(a, hitRadius: r);
        e.start(a.skyStars[route.first]);
        for (final i in route.skip(1)) {
          e.move(a.skyStars[i]);
        }
        expect(e.completed, isTrue, reason: dateKey(date));
      }
    });

    test('the mechanic rotates through the week', () {
      final modes = {
        for (var d = 0; d < 7; d++) dailyNight(DateTime(2026, 11, 2).add(Duration(days: d))).mode,
      };
      expect(modes, containsAll(TraceMode.values));
    });
  });
}
