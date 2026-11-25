import 'dart:math' as math;

/// A point in normalised sky space (0..1 on both axes, centre 0.5/0.5).
class Pt {
  const Pt(this.x, this.y);

  final double x;
  final double y;

  Pt operator +(Pt o) => Pt(x + o.x, y + o.y);
  Pt operator -(Pt o) => Pt(x - o.x, y - o.y);
  Pt scale(double s) => Pt(x * s, y * s);
  double get length => math.sqrt(x * x + y * y);
  double dist(Pt o) => (this - o).length;

  Pt rotateAround(Pt c, double radians) {
    final dx = x - c.x, dy = y - c.y;
    final cs = math.cos(radians), sn = math.sin(radians);
    return Pt(c.x + dx * cs - dy * sn, c.y + dx * sn + dy * cs);
  }

  /// Distance from this point to the segment a–b.
  double distToSegment(Pt a, Pt b) {
    final ab = b - a;
    final len2 = ab.x * ab.x + ab.y * ab.y;
    if (len2 == 0) return dist(a);
    var t = ((x - a.x) * ab.x + (y - a.y) * ab.y) / len2;
    t = t.clamp(0.0, 1.0);
    return dist(Pt(a.x + ab.x * t, a.y + ab.y * t));
  }

  @override
  bool operator ==(Object other) =>
      other is Pt && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Pt(${x.toStringAsFixed(3)}, ${y.toStringAsFixed(3)})';
}

/// How a night is played.
enum TraceMode {
  /// The next star pulses; trace the path in order from star 0.
  guided,

  /// The sky does not mark your stars; a chart card shows the upright figure.
  /// Trace the path from either end.
  chart,

  /// Faint lines show a figure; draw every line once in one stroke.
  oneStroke,
}

/// An undirected line between two stars (by index).
class Edge {
  Edge(int a, int b) : a = math.min(a, b), b = math.max(a, b);

  final int a;
  final int b;

  bool touches(int i) => a == i || b == i;
  int other(int i) => i == a ? b : a;

  @override
  bool operator ==(Object other) =>
      other is Edge && other.a == a && other.b == b;

  @override
  int get hashCode => Object.hash(a, b);

  @override
  String toString() => 'Edge($a-$b)';
}

class Night {
  Night({
    required this.id,
    required this.chapter,
    required this.name,
    required this.myth,
    required this.mode,
    required this.stars,
    required this.edges,
    this.path = const [],
    this.decoys = const [],
    this.rotationDegrees = 0,
    this.finale = false,
  });

  /// 1-based campaign id (0 for the daily sky).
  final int id;

  /// 0-based chapter index.
  final int chapter;
  final String name;
  final String myth;
  final TraceMode mode;

  /// Constellation stars in the upright (unrotated) chart frame.
  final List<Pt> stars;

  /// Lines of the figure.
  final List<Edge> edges;

  /// Ordered star indices for guided/chart modes.
  final List<int> path;

  /// Loose stars, in the same frame as [stars].
  final List<Pt> decoys;
  final double rotationDegrees;
  final bool finale;

  double get _radians => rotationDegrees * math.pi / 180;
  static const centre = Pt(0.5, 0.5);

  late final List<Pt> skyStars =
      stars.map((p) => p.rotateAround(centre, _radians)).toList();
  late final List<Pt> skyDecoys =
      decoys.map((p) => p.rotateAround(centre, _radians)).toList();

  int get starCount => stars.length;
}

/// Score for sealing a night.
int calculateScore({
  required int starCount,
  required bool flawless,
  required bool chapterBonus,
}) {
  var score = 100 * starCount;
  if (flawless) score += 50 * starCount;
  if (chapterBonus) score += 200;
  return score;
}
