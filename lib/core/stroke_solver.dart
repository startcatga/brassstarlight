import 'night.dart';

/// Solver for one-stroke figures: draw every edge exactly once.
class StrokeSolver {
  StrokeSolver(this.edges);

  final List<Edge> edges;

  /// Can the remaining edges be drawn in one stroke starting at [from]?
  /// If [from] is null, any start is allowed.
  bool canFinish(int? from, Set<Edge> drawn) {
    final remaining = edges.where((e) => !drawn.contains(e)).toList();
    if (remaining.isEmpty) return true;

    final degree = <int, int>{};
    for (final e in remaining) {
      degree[e.a] = (degree[e.a] ?? 0) + 1;
      degree[e.b] = (degree[e.b] ?? 0) + 1;
    }
    final odd = degree.entries.where((e) => e.value.isOdd).map((e) => e.key);
    if (odd.isNotEmpty && odd.length != 2) return false;

    // Connectivity of all vertices that still have edges.
    final start = from ?? remaining.first.a;
    if (!degree.containsKey(start)) return false;
    final seen = <int>{start};
    final stack = [start];
    while (stack.isNotEmpty) {
      final v = stack.removeLast();
      for (final e in remaining) {
        if (e.touches(v)) {
          final w = e.other(v);
          if (seen.add(w)) stack.add(w);
        }
      }
    }
    if (seen.length != degree.length) return false;

    if (from != null && odd.length == 2 && !odd.contains(from)) return false;
    return true;
  }

  /// Stars where a complete stroke can begin.
  List<int> validStarts() {
    final verts = <int>{for (final e in edges) ...[e.a, e.b]}.toList()..sort();
    return verts.where((v) => canFinish(v, const {})).toList();
  }

  /// Next star to move to from [current], or null if stuck/finished.
  int? nextStar(int current, Set<Edge> drawn) {
    for (final e in edges) {
      if (drawn.contains(e) || !e.touches(current)) continue;
      final next = e.other(current);
      if (canFinish(next, {...drawn, e})) return next;
    }
    return null;
  }

  /// A full stroke (sequence of stars) or null if impossible.
  List<int>? solve() {
    final starts = validStarts();
    if (starts.isEmpty) return null;
    var current = starts.first;
    final drawn = <Edge>{};
    final seq = [current];
    while (drawn.length < edges.length) {
      final next = nextStar(current, drawn);
      if (next == null) return null;
      drawn.add(Edge(current, next));
      current = next;
      seq.add(current);
    }
    return seq;
  }
}
