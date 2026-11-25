import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/night.dart';
import '../theme/palette.dart';

/// A night's figure drawn upright (as on a chart), fitted to its box.
class FigureGlyph extends StatelessWidget {
  const FigureGlyph({
    required this.night,
    this.lineColor = Palette.ink,
    this.starColor = Palette.brassDeep,
    this.lineWidth = 1.4,
    this.starRadius = 2.2,
    this.markEnds = false,
    this.rotated = false,
    this.progress = 1,
    super.key,
  });

  final Night night;
  final Color lineColor;
  final Color starColor;
  final double lineWidth;
  final double starRadius;

  /// Ring the two ends of a path (chart card: where you may begin).
  final bool markEnds;

  /// Draw as it appears in the sky instead of upright.
  final bool rotated;

  /// 0..1 — how many lines to draw (for the seal reveal).
  final double progress;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GlyphPainter(this),
      size: Size.infinite,
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.g);

  final FigureGlyph g;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = g.rotated ? g.night.skyStars : g.night.stars;
    if (pts.isEmpty) return;
    final minX = pts.map((p) => p.x).reduce(math.min);
    final maxX = pts.map((p) => p.x).reduce(math.max);
    final minY = pts.map((p) => p.y).reduce(math.min);
    final maxY = pts.map((p) => p.y).reduce(math.max);
    final w = math.max(maxX - minX, 1e-3), h = math.max(maxY - minY, 1e-3);
    final pad = g.starRadius * 2 + 2;
    final s = math.min((size.width - pad * 2) / w, (size.height - pad * 2) / h);
    final ox = (size.width - w * s) / 2, oy = (size.height - h * s) / 2;
    Offset o(Pt p) => Offset(ox + (p.x - minX) * s, oy + (p.y - minY) * s);

    final edges = g.night.mode == TraceMode.oneStroke
        ? g.night.edges
        : [
            for (var i = 0; i + 1 < g.night.path.length; i++)
              Edge(g.night.path[i], g.night.path[i + 1]),
          ];
    final lit = (edges.length * g.progress).clamp(0, edges.length).toDouble();
    final paint = Paint()
      ..color = g.lineColor
      ..strokeWidth = g.lineWidth
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < lit.floor(); i++) {
      canvas.drawLine(o(pts[edges[i].a]), o(pts[edges[i].b]), paint);
    }
    final part = lit - lit.floor();
    if (part > 0 && lit.floor() < edges.length) {
      final e = edges[lit.floor()];
      final a = o(pts[e.a]), b = o(pts[e.b]);
      canvas.drawLine(a, Offset.lerp(a, b, part)!, paint);
    }
    final dot = Paint()..color = g.starColor;
    for (final p in pts) {
      canvas.drawCircle(o(p), g.starRadius, dot);
    }
    if (g.markEnds && g.night.path.isNotEmpty) {
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = g.starColor;
      for (final i in [g.night.path.first, g.night.path.last]) {
        canvas.drawCircle(o(pts[i]), g.starRadius + 4, ring);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter old) =>
      old.g.night != g.night || old.g.progress != g.progress;
}
