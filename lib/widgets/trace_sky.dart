import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/night.dart';
import '../core/sky_geometry.dart';
import '../core/trace_engine.dart';
import '../theme/palette.dart';

/// Maps normalised sky space to a square on screen.
class SkyLayout {
  SkyLayout(Size size, EdgeInsets padding) {
    final area = padding.deflateRect(Offset.zero & size);
    side = math.max(1, math.min(area.width, area.height));
    origin = Offset(area.left + (area.width - side) / 2,
        area.top + (area.height - side) / 2);
  }

  late final double side;
  late final Offset origin;

  Offset toScreen(Pt p) => origin + Offset(p.x * side, p.y * side);
  Pt toSky(Offset o) => Pt((o.dx - origin.dx) / side, (o.dy - origin.dy) / side);

  /// Touch radius: about 26dp, never larger than the fairness limit.
  double get hitRadius => math.min(26 / side, SkyRules.hitRadius);
}

/// The interactive sky: draws a [Night] and feeds finger input to [engine].
class TraceSky extends StatefulWidget {
  const TraceSky({
    required this.engine,
    required this.onEvent,
    this.padding = EdgeInsets.zero,
    this.hintStar,
    this.stillSky = false,
    this.enabled = true,
    this.semanticsLabel,
    super.key,
  });

  final TraceEngine engine;
  final void Function(TraceEvent event) onEvent;
  final EdgeInsets padding;

  /// Star lit by a lantern, if any.
  final int? hintStar;
  final bool stillSky;
  final bool enabled;
  final String? semanticsLabel;

  @override
  State<TraceSky> createState() => _TraceSkyState();
}

class _Bloom {
  _Bloom(this.at, this.t0, this.color);
  final Pt at;
  final double t0;
  final Color color;
}

class _TraceSkyState extends State<TraceSky>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _clock = ValueNotifier<double>(0);
  final List<_Bloom> _blooms = [];
  List<Pt> _broken = const [];
  double _brokenT0 = -10;
  int? _decoyFlash;
  double _decoyT0 = -10;
  double? _sealT0;
  SkyLayout? _layout;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) => _clock.value = d.inMicroseconds / 1e6)
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  double get _now => _clock.value;

  void _handle(TraceEvent e, List<Pt> beforePath) {
    final n = widget.engine.night;
    if (e.linked != null) {
      _blooms.add(_Bloom(n.skyStars[e.linked!], _now,
          e.completed ? Palette.brass : Palette.traceBlue));
      if (_blooms.length > 12) _blooms.removeAt(0);
    }
    if (e.fail != null) {
      _broken = beforePath;
      _brokenT0 = _now;
    }
    if (e.fail == TraceFail.decoy && widget.engine.finger != null) {
      final f = widget.engine.finger!;
      var best = double.infinity;
      for (var i = 0; i < n.skyDecoys.length; i++) {
        final d = f.dist(n.skyDecoys[i]);
        if (d < best) {
          best = d;
          _decoyFlash = i;
        }
      }
      _decoyT0 = _now;
    }
    if (e.completed) _sealT0 = _now;
    if (!e.isNone) widget.onEvent(e);
  }

  List<Pt> _currentPath() {
    final s = widget.engine.night.skyStars;
    final pts = [for (final i in widget.engine.visited) s[i]];
    final f = widget.engine.finger;
    if (widget.engine.tracing && f != null) pts.add(f);
    return pts;
  }

  void _down(Offset local) {
    final l = _layout;
    if (l == null || !widget.enabled) return;
    widget.engine.hitRadius = l.hitRadius;
    final before = _currentPath();
    _handle(widget.engine.start(l.toSky(local)), before);
    setState(() {});
  }

  void _move(Offset local) {
    final l = _layout;
    if (l == null || !widget.enabled) return;
    final before = _currentPath();
    _handle(widget.engine.move(l.toSky(local)), before);
  }

  void _up() {
    if (!widget.enabled) return;
    final before = _currentPath();
    _handle(widget.engine.end(), before);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final size = Size(c.maxWidth, c.maxHeight);
      _layout = SkyLayout(size, widget.padding);
      return Semantics(
        label: widget.semanticsLabel,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) => _down(e.localPosition),
          onPointerMove: (e) => _move(e.localPosition),
          onPointerUp: (_) => _up(),
          onPointerCancel: (_) => _up(),
          child: RepaintBoundary(
            child: CustomPaint(
              size: size,
              painter: _SkyPainter(
                engine: widget.engine,
                layout: _layout!,
                clock: _clock,
                state: this,
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _SkyPainter extends CustomPainter {
  _SkyPainter({
    required this.engine,
    required this.layout,
    required this.clock,
    required this.state,
  }) : super(repaint: clock);

  final TraceEngine engine;
  final SkyLayout layout;
  final ValueNotifier<double> clock;
  final _TraceSkyState state;

  Night get night => engine.night;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    final still = state.widget.stillSky;
    final stars = night.skyStars;
    Offset sc(Pt p) => layout.toScreen(p);

    final glow = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final line = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Seal flare: lines flash brass in sequence after completion.
    final sealT = state._sealT0 == null ? null : t - state._sealT0!;

    // Ghost figure for one-stroke nights.
    if (night.mode == TraceMode.oneStroke) {
      final drawn = engine.drawnEdges;
      for (final e in night.edges) {
        final a = sc(stars[e.a]), b = sc(stars[e.b]);
        if (drawn.contains(e) || engine.completed) continue;
        line
          ..color = Palette.starlight.withValues(alpha: 0.22)
          ..strokeWidth = 1.6;
        _dashed(canvas, a, b, line);
      }
      final seq = engine.visited;
      for (var i = 0; i + 1 < seq.length; i++) {
        _drawLit(canvas, sc(stars[seq[i]]), sc(stars[seq[i + 1]]), i, sealT,
            line, glow);
      }
    } else {
      final seq = engine.visited;
      for (var i = 0; i + 1 < seq.length; i++) {
        _drawLit(canvas, sc(stars[seq[i]]), sc(stars[seq[i + 1]]), i, sealT,
            line, glow);
      }
    }

    // Live tail to the finger.
    final f = engine.finger;
    if (engine.tracing && f != null && engine.current != null) {
      final a = sc(stars[engine.current!]);
      final b = sc(f);
      glow
        ..color = Palette.traceBlue.withValues(alpha: 0.35)
        ..strokeWidth = 7;
      canvas.drawLine(a, b, glow);
      line
        ..color = Palette.traceBlue
        ..strokeWidth = 2.6;
      canvas.drawLine(a, b, line);
    }

    // A broken line falls and fades.
    final bt = t - state._brokenT0;
    if (bt < 0.45 && state._broken.length > 1) {
      final k = bt / 0.45;
      final drop = still ? 0.0 : 14 * k * k;
      final p = Path();
      for (var i = 0; i < state._broken.length; i++) {
        final o = sc(state._broken[i]) + Offset(0, drop);
        i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
      }
      line
        ..color = Palette.ember.withValues(alpha: (1 - k) * 0.9)
        ..strokeWidth = 2.4;
      canvas.drawPath(p, line);
    }

    // Loose stars.
    for (var i = 0; i < night.skyDecoys.length; i++) {
      _star(canvas, sc(night.skyDecoys[i]), Palette.starlight, 4.4, t, i + 50,
          still);
    }
    final dt = t - state._decoyT0;
    if (state._decoyFlash != null &&
        dt < 0.7 &&
        state._decoyFlash! < night.skyDecoys.length) {
      final o = sc(night.skyDecoys[state._decoyFlash!]);
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Palette.ember.withValues(alpha: 1 - dt / 0.7);
      canvas.drawCircle(o, 12 + dt * 10, ring);
    }

    // Figure stars.
    final visited = engine.visited.toSet();
    final lit = engine.completed
        ? {for (var i = 0; i < stars.length; i++) i}
        : visited;
    for (var i = 0; i < stars.length; i++) {
      final on = lit.contains(i);
      _star(canvas, sc(stars[i]), on ? Palette.brass : Palette.starlight,
          on ? 5.6 : 4.4, t, i, still,
          flare: sealT != null && sealT < 1.6);
    }

    // Guide pulse (chapter I–II).
    final g = engine.guideStar;
    if (g != null) {
      final phase = still ? 0.5 : (t % 1.6) / 1.6;
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Palette.brass.withValues(alpha: 0.85 * (1 - phase) + 0.1);
      canvas.drawCircle(sc(stars[g]), 10 + 12 * phase, ring);
    }

    // Lantern hint.
    final h = state.widget.hintStar;
    if (h != null && h < stars.length) {
      final o = sc(stars[h]);
      final warm = Paint()
        ..shader = RadialGradient(colors: [
          Palette.brass.withValues(alpha: 0.45),
          Palette.brass.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: o, radius: 34));
      canvas.drawCircle(o, 34, warm);
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = Palette.brass;
      final spin = still ? 0.0 : t * 0.8;
      for (var k = 0; k < 8; k++) {
        final a0 = spin + k * math.pi / 4;
        canvas.drawArc(Rect.fromCircle(center: o, radius: 18), a0, math.pi / 8,
            false, ring);
      }
    }

    // Touch blooms.
    for (final b in state._blooms) {
      final bt = t - b.t0;
      if (bt > 0.4) continue;
      final k = bt / 0.4;
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * (1 - k) + 0.5
        ..color = b.color.withValues(alpha: 1 - k);
      canvas.drawCircle(sc(b.at), still ? 14 : 7 + 18 * Curves.easeOut.transform(k), ring);
    }
  }

  void _drawLit(Canvas canvas, Offset a, Offset b, int index, double? sealT,
      Paint line, Paint glow) {
    final done = engine.completed;
    var colour = done ? Palette.brass : Palette.traceBlue;
    var glowAlpha = 0.35;
    if (done && sealT != null) {
      final local = (sealT - index * 0.06).clamp(0.0, 1.0);
      glowAlpha = 0.35 + 0.5 * math.sin(local * math.pi);
      colour = Color.lerp(Palette.starlight, Palette.brass, local)!;
    }
    glow
      ..color = colour.withValues(alpha: glowAlpha)
      ..strokeWidth = 8;
    canvas.drawLine(a, b, glow);
    line
      ..color = colour
      ..strokeWidth = done ? 3 : 2.6;
    canvas.drawLine(a, b, line);
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Paint p) {
    final d = (b - a).distance;
    if (d == 0) return;
    final dir = (b - a) / d;
    const dash = 7.0, gap = 6.0;
    var s = 10.0;
    while (s < d - 10) {
      final e = math.min(s + dash, d - 10);
      canvas.drawLine(a + dir * s, a + dir * e, p);
      s += dash + gap;
    }
  }

  void _star(Canvas canvas, Offset o, Color c, double r, double t, int seed,
      bool still, {bool flare = false}) {
    final tw = still ? 1.0 : 0.85 + 0.15 * math.sin(t * 1.7 + seed * 1.3);
    final halo = Paint()
      ..shader = RadialGradient(colors: [
        c.withValues(alpha: 0.42 * tw),
        c.withValues(alpha: 0),
      ]).createShader(Rect.fromCircle(center: o, radius: r * 3.4));
    canvas.drawCircle(o, r * (flare ? 4.2 : 3.4), halo);
    canvas.drawCircle(o, r * (flare ? 1.2 : 1.0), Paint()..color = c);
  }

  @override
  bool shouldRepaint(covariant _SkyPainter old) => true;
}
