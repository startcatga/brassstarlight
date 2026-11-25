import 'dart:math' as math;

import 'night.dart';

/// Shared geometry limits. Stars must stay far enough apart, and lines far
/// enough from other stars, that a finger on a small phone can trace them.
class SkyRules {
  /// Touch radius in normalised units (≈22dp on a 330dp-wide sky square).
  static const hitRadius = 0.067;

  /// Minimum distance between any two stars (figure or loose).
  static const minStarGap = 0.15;

  /// Minimum distance from a line to any star that is not one of its ends.
  static const lineClearance = 0.085;

  /// Everything must sit inside this circle around the centre so any
  /// rotation still fits the sky square.
  static const maxRadius = 0.46;
}

/// Deterministic Park–Miller RNG; identical results on VM and web.
class SeededRng {
  SeededRng(int seed) : _state = (seed.abs() % 2147483646) + 1;

  int _state;

  double next() {
    _state = (_state * 48271) % 2147483647;
    return (_state - 1) / 2147483646;
  }

  double range(double a, double b) => a + (b - a) * next();
  int intRange(int a, int bInclusive) =>
      a + (next() * (bInclusive - a + 1)).floor().clamp(0, bInclusive - a);
}

/// Move a hand-drawn figure (and its decoys) so its bounding box is centred
/// and its farthest point sits at [radius] from the centre.
({List<Pt> stars, List<Pt> decoys}) fitFigure(
  List<Pt> stars,
  List<Pt> decoys, {
  double radius = 0.40,
}) {
  final all = [...stars, ...decoys];
  final minX = all.map((p) => p.x).reduce(math.min);
  final maxX = all.map((p) => p.x).reduce(math.max);
  final minY = all.map((p) => p.y).reduce(math.min);
  final maxY = all.map((p) => p.y).reduce(math.max);
  final c = Pt((minX + maxX) / 2, (minY + maxY) / 2);
  final far = all.map((p) => p.dist(c)).reduce(math.max);
  final s = far == 0 ? 1.0 : radius / far;
  Pt t(Pt p) => Night.centre + (p - c).scale(s);
  return (stars: stars.map(t).toList(), decoys: decoys.map(t).toList());
}

/// Geometry problems with a night, empty when it is fair to trace.
List<String> geometryProblems(Night n) {
  final problems = <String>[];
  final pts = [...n.stars, ...n.decoys];
  for (var i = 0; i < pts.length; i++) {
    if (pts[i].dist(Night.centre) > SkyRules.maxRadius + 1e-9) {
      problems.add('point $i outside sky circle');
    }
    for (var j = i + 1; j < pts.length; j++) {
      if (pts[i].dist(pts[j]) < SkyRules.minStarGap) {
        problems.add('points $i and $j too close');
      }
    }
  }
  for (final e in n.edges) {
    final a = n.stars[e.a], b = n.stars[e.b];
    for (var i = 0; i < pts.length; i++) {
      if (i == e.a || i == e.b) continue;
      if (pts[i].distToSegment(a, b) < SkyRules.lineClearance) {
        problems.add('line ${e.a}-${e.b} passes too close to point $i');
      }
    }
  }
  return problems;
}

/// Edges along an ordered path.
List<Edge> pathEdges(List<int> path) => [
      for (var i = 0; i + 1 < path.length; i++) Edge(path[i], path[i + 1]),
    ];

bool _segmentsCross(Pt a, Pt b, Pt c, Pt d) {
  double cross(Pt o, Pt p, Pt q) =>
      (p.x - o.x) * (q.y - o.y) - (p.y - o.y) * (q.x - o.x);
  final d1 = cross(c, d, a), d2 = cross(c, d, b);
  final d3 = cross(a, b, c), d4 = cross(a, b, d);
  return ((d1 > 0) != (d2 > 0)) && ((d3 > 0) != (d4 > 0));
}

/// Generates figures from a seed. Every result passes [geometryProblems].
class FigureGenerator {
  FigureGenerator(int seed) : _rng = SeededRng(seed);

  final SeededRng _rng;

  Pt _randomPoint() {
    while (true) {
      final p = Pt(_rng.range(0.06, 0.94), _rng.range(0.06, 0.94));
      if (p.dist(Night.centre) <= SkyRules.maxRadius - 0.02) return p;
    }
  }

  bool _fits(Pt p, List<Pt> stars, List<Edge> edges) {
    if (p.dist(Night.centre) > SkyRules.maxRadius - 0.02) return false;
    for (var i = 0; i < stars.length; i++) {
      if (p.dist(stars[i]) < SkyRules.minStarGap + 0.01) return false;
    }
    for (final e in edges) {
      if (p.distToSegment(stars[e.a], stars[e.b]) <
          SkyRules.lineClearance + 0.01) {
        return false;
      }
    }
    return true;
  }

  bool _lineOk(Pt a, Pt b, List<Pt> stars, List<Edge> edges,
      {required int ia, int? ib}) {
    for (var i = 0; i < stars.length; i++) {
      if (i == ia || i == ib) continue;
      if (stars[i].distToSegment(a, b) < SkyRules.lineClearance + 0.01) {
        return false;
      }
    }
    for (final e in edges) {
      if (e.touches(ia) || (ib != null && e.touches(ib))) continue;
      if (_segmentsCross(a, b, stars[e.a], stars[e.b])) return false;
    }
    return true;
  }

  /// A wandering path of [count] stars.
  ({List<Pt> stars, List<int> path}) path(int count) {
    for (var attempt = 0; attempt < 4000; attempt++) {
      final stars = <Pt>[_randomPoint()];
      final edges = <Edge>[];
      var heading = _rng.range(0, 2 * math.pi);
      var ok = true;
      for (var k = 1; k < count && ok; k++) {
        ok = false;
        for (var tries = 0; tries < 40; tries++) {
          final h = heading + _rng.range(-1.9, 1.9);
          final len = _rng.range(0.17, 0.28);
          final last = stars.last;
          final p = Pt(last.x + math.cos(h) * len, last.y + math.sin(h) * len);
          if (!_fits(p, stars, edges)) continue;
          if (!_lineOk(last, p, stars, edges, ia: stars.length - 1)) continue;
          stars.add(p);
          edges.add(Edge(stars.length - 2, stars.length - 1));
          heading = h;
          ok = true;
          break;
        }
      }
      if (ok) {
        return (stars: stars, path: List.generate(count, (i) => i));
      }
    }
    throw StateError('could not generate path of $count');
  }

  /// A connected figure with [count] stars and extra loops, built as one
  /// trail so it can always be drawn in a single stroke.
  ({List<Pt> stars, List<Edge> edges}) trail(int count, int loops) {
    for (var attempt = 0; attempt < 4000; attempt++) {
      final stars = <Pt>[_randomPoint()];
      final edges = <Edge>[];
      var cur = 0;
      var loopsLeft = loops;
      var heading = _rng.range(0, 2 * math.pi);
      var guard = 0;
      while ((stars.length < count || loopsLeft > 0) && guard++ < 200) {
        // Try closing a loop back to an existing star.
        if (loopsLeft > 0 && stars.length >= 3 && _rng.next() < 0.45) {
          final candidates = [
            for (var i = 0; i < stars.length; i++)
              if (i != cur &&
                  !edges.contains(Edge(cur, i)) &&
                  stars[cur].dist(stars[i]) < 0.42 &&
                  _lineOk(stars[cur], stars[i], stars, edges, ia: cur, ib: i))
                i,
          ];
          if (candidates.isNotEmpty) {
            final i = candidates[_rng.intRange(0, candidates.length - 1)];
            edges.add(Edge(cur, i));
            cur = i;
            loopsLeft--;
            continue;
          }
        }
        if (stars.length >= count) {
          if (loopsLeft > 0) continue;
          break;
        }
        var placed = false;
        for (var tries = 0; tries < 40; tries++) {
          final h = heading + _rng.range(-2.2, 2.2);
          final len = _rng.range(0.17, 0.27);
          final from = stars[cur];
          final p = Pt(from.x + math.cos(h) * len, from.y + math.sin(h) * len);
          if (!_fits(p, stars, edges)) continue;
          if (!_lineOk(from, p, stars, edges, ia: cur)) continue;
          stars.add(p);
          edges.add(Edge(cur, stars.length - 1));
          cur = stars.length - 1;
          heading = h;
          placed = true;
          break;
        }
        if (!placed) break;
      }
      if (stars.length == count && loopsLeft == 0) {
        return (stars: stars, edges: edges);
      }
    }
    throw StateError('could not generate trail of $count/$loops');
  }

  /// Loose stars placed clear of every star and line.
  List<Pt> decoys(List<Pt> stars, List<Edge> edges, int count) {
    final out = <Pt>[];
    var guard = 0;
    while (out.length < count && guard++ < 20000) {
      final p = _randomPoint();
      if (!_fits(p, [...stars, ...out], edges)) continue;
      out.add(p);
    }
    return out;
  }
}
