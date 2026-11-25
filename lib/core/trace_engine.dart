import 'night.dart';
import 'stroke_solver.dart';

enum TraceFail {
  /// Lifted the finger or skipped to a star out of order.
  broken,

  /// Touched a loose star that is not part of the figure.
  decoy,

  /// Tried to draw a line that is already drawn (one-stroke).
  retraced,

  /// Moved to a star with no line to it (one-stroke).
  noLine,
}

/// What happened during one input event.
class TraceEvent {
  const TraceEvent._({
    this.linked,
    this.fail,
    this.completed = false,
    this.started = false,
  });

  static const none = TraceEvent._();

  /// Index of a star just linked (or started on).
  final int? linked;
  final TraceFail? fail;
  final bool completed;
  final bool started;

  bool get isNone => linked == null && fail == null && !completed;
}

/// Pure rules for tracing a [Night]. Works in normalised sky coordinates;
/// the caller converts screen positions and supplies the hit radius.
class TraceEngine {
  TraceEngine(this.night, {required this.hitRadius})
      : _solver = StrokeSolver(night.edges);

  final Night night;

  /// Touch radius in normalised units.
  double hitRadius;
  final StrokeSolver _solver;

  final List<int> _visited = [];
  final Set<Edge> _drawn = {};
  List<int> _route = const [];
  bool _tracing = false;
  bool _completed = false;
  int _fails = 0;
  Pt? _finger;

  bool get tracing => _tracing;
  bool get completed => _completed;
  int get failCount => _fails;
  Pt? get finger => _finger;
  List<int> get visited => List.unmodifiable(_visited);
  Set<Edge> get drawnEdges => Set.unmodifiable(_drawn);
  int? get current => _visited.isEmpty ? null : _visited.last;

  /// Progress 0..total for the pip strip.
  int get progress =>
      night.mode == TraceMode.oneStroke ? _drawn.length : _visited.length;
  int get total =>
      night.mode == TraceMode.oneStroke ? night.edges.length : night.path.length;

  /// Star the guide pulse should mark (guided mode only).
  int? get guideStar {
    if (night.mode != TraceMode.guided || _completed) return null;
    if (!_tracing) return night.path.first;
    return night.path[_visited.length];
  }

  /// Hint for a lantern: the star to touch next.
  int? hintStar() {
    if (_completed) return null;
    switch (night.mode) {
      case TraceMode.guided:
      case TraceMode.chart:
        if (!_tracing) return night.path.first;
        return _route[_visited.length];
      case TraceMode.oneStroke:
        if (!_tracing) return _solver.validStarts().first;
        return _solver.nextStar(current!, _drawn);
    }
  }

  /// True when the current one-stroke attempt can no longer finish.
  bool get strokeStuck =>
      night.mode == TraceMode.oneStroke &&
      _tracing &&
      !_solver.canFinish(current, _drawn);

  /// Index of a constellation star (>= 0), a decoy (-1 - i), or null.
  int? _hit(Pt p) {
    var best = hitRadius;
    int? found;
    final s = night.skyStars;
    for (var i = 0; i < s.length; i++) {
      final d = p.dist(s[i]);
      if (d <= best) {
        best = d;
        found = i;
      }
    }
    final dcs = night.skyDecoys;
    for (var i = 0; i < dcs.length; i++) {
      final d = p.dist(dcs[i]);
      if (d < best) {
        best = d;
        found = -1 - i;
      }
    }
    return found;
  }

  void reset() {
    _visited.clear();
    _drawn.clear();
    _tracing = false;
    _finger = null;
  }

  /// Restart the whole night (keeps nothing).
  void restart() {
    reset();
    _completed = false;
    _fails = 0;
  }

  TraceEvent _fail(TraceFail why) {
    // A single tap on a star is not a mistake; only count real attempts.
    final counts = progress > 1 || why == TraceFail.decoy ||
        (night.mode == TraceMode.oneStroke && progress > 0);
    if (counts) _fails++;
    reset();
    return TraceEvent._(fail: why);
  }

  TraceEvent start(Pt p) {
    if (_completed) return TraceEvent.none;
    reset();
    _finger = p;
    final h = _hit(p);
    if (h == null) return TraceEvent.none;
    if (h < 0) return _fail(TraceFail.decoy);

    switch (night.mode) {
      case TraceMode.guided:
        if (h != night.path.first) return TraceEvent.none;
        _route = night.path;
      case TraceMode.chart:
        if (h == night.path.first) {
          _route = night.path;
        } else if (h == night.path.last) {
          _route = night.path.reversed.toList();
        } else {
          return TraceEvent.none;
        }
      case TraceMode.oneStroke:
        _route = const [];
    }
    _tracing = true;
    _visited.add(h);
    return TraceEvent._(linked: h, started: true);
  }

  /// Feed a finger move; samples the path from the previous point so fast
  /// swipes cannot skip a star. Returns the most important event.
  TraceEvent move(Pt p) {
    if (!_tracing || _completed) {
      _finger = p;
      return TraceEvent.none;
    }
    final from = _finger ?? p;
    final dist = from.dist(p);
    final steps = (dist / (hitRadius * 0.4)).ceil().clamp(1, 200);
    var result = TraceEvent.none;
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      final q = Pt(from.x + (p.x - from.x) * t, from.y + (p.y - from.y) * t);
      _finger = q;
      final e = _step(q);
      if (!e.isNone) result = e;
      if (e.fail != null || e.completed) return e;
    }
    return result;
  }

  TraceEvent _step(Pt q) {
    final h = _hit(q);
    if (h == null) return TraceEvent.none;
    if (h < 0) return _fail(TraceFail.decoy);
    final cur = current!;
    if (h == cur) return TraceEvent.none;

    if (night.mode == TraceMode.oneStroke) {
      final e = Edge(cur, h);
      if (!night.edges.contains(e)) return _fail(TraceFail.noLine);
      if (_drawn.contains(e)) return _fail(TraceFail.retraced);
      _drawn.add(e);
      _visited.add(h);
      if (_drawn.length == night.edges.length) {
        _tracing = false;
        _completed = true;
        return TraceEvent._(linked: h, completed: true);
      }
      return TraceEvent._(linked: h);
    }

    final expected = _route[_visited.length];
    if (h == expected) {
      _visited.add(h);
      if (_visited.length == _route.length) {
        _tracing = false;
        _completed = true;
        return TraceEvent._(linked: h, completed: true);
      }
      return TraceEvent._(linked: h);
    }
    if (_visited.contains(h)) return TraceEvent.none;
    return _fail(TraceFail.broken);
  }

  /// Finger lifted.
  TraceEvent end() {
    if (!_tracing || _completed) return TraceEvent.none;
    if (progress <= 1 && night.mode != TraceMode.oneStroke) {
      reset();
      return TraceEvent.none;
    }
    if (night.mode == TraceMode.oneStroke && _drawn.isEmpty) {
      reset();
      return TraceEvent.none;
    }
    return _fail(TraceFail.broken);
  }
}
