import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/palette.dart';
import '../theme/type.dart';

/// Primary action: a bevelled brass plate with cut corners.
class BrassPlate extends StatefulWidget {
  const BrassPlate({
    required this.label,
    required this.onPressed,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expand;

  @override
  State<BrassPlate> createState() => _BrassPlateState();
}

class _BrassPlateState extends State<BrassPlate> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: CustomPaint(
            painter: _PlatePainter(pressed: _down, enabled: enabled),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56, minWidth: 160),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                child: Row(
                  mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        style: Lettering.label(
                            color: enabled ? Palette.ink : Palette.inkSoft),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlatePainter extends CustomPainter {
  _PlatePainter({required this.pressed, required this.enabled});

  final bool pressed;
  final bool enabled;

  @override
  void paint(Canvas canvas, Size size) {
    const c = 10.0;
    final path = Path()
      ..moveTo(c, 0)
      ..lineTo(size.width - c, 0)
      ..lineTo(size.width, c)
      ..lineTo(size.width, size.height - c)
      ..lineTo(size.width - c, size.height)
      ..lineTo(c, size.height)
      ..lineTo(0, size.height - c)
      ..lineTo(0, c)
      ..close();
    canvas.drawShadow(path, Palette.nightInk, pressed ? 2 : 6, false);
    final rect = Offset.zero & size;
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: enabled
              ? (pressed
                  ? const [Palette.brassDeep, Palette.brass]
                  : const [Color(0xFFF0D27E), Palette.brass, Palette.brassDeep])
              : const [Palette.mist, Palette.mist],
        ).createShader(rect),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Palette.brassDeep,
    );
  }

  @override
  bool shouldRepaint(covariant _PlatePainter old) =>
      old.pressed != pressed || old.enabled != enabled;
}

/// Quiet text action ("Return to the Observatory").
class InkLink extends StatelessWidget {
  const InkLink({
    required this.label,
    required this.onPressed,
    this.color = Palette.ink,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onPressed,
        radius: 0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Text(
              label,
              style: Lettering.small(color: color).copyWith(
                decoration: TextDecoration.underline,
                decorationColor: color.withValues(alpha: 0.5),
                decorationThickness: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum Glyph { pause, back, lantern, chart }

/// A 48dp octagonal brass control with a drawn glyph.
class OctagonButton extends StatelessWidget {
  const OctagonButton({
    required this.glyph,
    required this.label,
    required this.onPressed,
    this.badge,
    this.onPaper = false,
    super.key,
  });

  final Glyph glyph;
  final String label;
  final VoidCallback? onPressed;
  final String? badge;
  final bool onPaper;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox(
          width: 52,
          height: 52,
          child: CustomPaint(
            painter: _OctagonPainter(glyph, onPressed != null, onPaper),
            child: badge == null
                ? null
                : Align(
                    alignment: const Alignment(1.25, 1.25),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: const BoxDecoration(
                          color: Palette.brass,
                          borderRadius: BorderRadius.all(Radius.circular(2))),
                      child: Text(badge!,
                          style: Lettering.number(color: Palette.ink, size: 14)),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _OctagonPainter extends CustomPainter {
  _OctagonPainter(this.glyph, this.enabled, this.onPaper);

  final Glyph glyph;
  final bool enabled;
  final bool onPaper;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 2;
    final oct = Path();
    for (var i = 0; i < 8; i++) {
      final a = math.pi / 8 + i * math.pi / 4;
      final p = c + Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? oct.moveTo(p.dx, p.dy) : oct.lineTo(p.dx, p.dy);
    }
    oct.close();
    final stroke = enabled
        ? (onPaper ? Palette.brassDeep : Palette.brass)
        : Palette.mist;
    canvas.drawPath(
        oct,
        Paint()
          ..color = onPaper
              ? Palette.parchment
              : Palette.nightInk.withValues(alpha: 0.72));
    canvas.drawPath(
        oct,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = stroke);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = stroke;
    switch (glyph) {
      case Glyph.pause:
        canvas.drawLine(c + const Offset(-4, -7), c + const Offset(-4, 7), p);
        canvas.drawLine(c + const Offset(4, -7), c + const Offset(4, 7), p);
      case Glyph.back:
        final path = Path()
          ..moveTo(c.dx + 3, c.dy - 8)
          ..lineTo(c.dx - 5, c.dy)
          ..lineTo(c.dx + 3, c.dy + 8);
        canvas.drawPath(path, p);
      case Glyph.lantern:
        final body = RRect.fromRectAndRadius(
            Rect.fromCenter(center: c + const Offset(0, 2), width: 12, height: 14),
            const Radius.circular(3));
        canvas.drawRRect(body, p);
        canvas.drawLine(c + const Offset(-4, -5), c + const Offset(4, -5), p);
        canvas.drawArc(Rect.fromCenter(center: c + const Offset(0, -8), width: 8, height: 6),
            math.pi, math.pi, false, p);
        canvas.drawCircle(c + const Offset(0, 2), 2.2,
            Paint()..color = enabled ? Palette.brass : Palette.mist);
      case Glyph.chart:
        final path = Path()
          ..moveTo(c.dx - 8, c.dy + 6)
          ..lineTo(c.dx - 2, c.dy - 6)
          ..lineTo(c.dx + 3, c.dy + 2)
          ..lineTo(c.dx + 8, c.dy - 5);
        canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant _OctagonPainter old) =>
      old.glyph != glyph || old.enabled != enabled;
}
