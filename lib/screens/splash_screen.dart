import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app.dart';
import '../routes.dart';
import '../theme/palette.dart';
import '../theme/type.dart';

/// "First Light": one star wakes, three lines draw out, the title appears.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
      ..forward()
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _go();
      });
  }

  void _go() {
    if (_left || !mounted) return;
    _left = true;
    Navigator.of(context).pushReplacementNamed(Routes.observatory);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = context.stillSky;
    if (still && _c.value < 0.85) _c.value = 0.85;
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _go,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/art/sky_1.jpg', fit: BoxFit.cover),
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) => CustomPaint(painter: _WakePainter(_c.value)),
            ),
            AnimatedBuilder(
              animation: _c,
              builder: (context, child) {
                final k = Curves.easeOutCubic
                    .transform(((_c.value - 0.45) / 0.35).clamp(0.0, 1.0));
                return Opacity(
                  opacity: k,
                  child: Transform.translate(offset: Offset(0, 10 * (1 - k)), child: child),
                );
              },
              child: Align(
                alignment: const Alignment(0, 0.42),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Brass & Starlight',
                        textAlign: TextAlign.center, style: Lettering.display()),
                    const SizedBox(height: 10),
                    Text('An apprentice of the night sky',
                        style: Lettering.myth(color: Palette.mist)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WakePainter extends CustomPainter {
  _WakePainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.36);
    final pts = [
      c + const Offset(-70, 34),
      c + const Offset(64, -46),
      c + const Offset(26, 74),
    ];
    final draw = ((t - 0.2) / 0.35).clamp(0.0, 1.0);
    final line = Paint()
      ..color = Palette.brass
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < pts.length; i++) {
      final local = ((draw * 3) - i).clamp(0.0, 1.0);
      if (local <= 0) continue;
      canvas.drawLine(c, Offset.lerp(c, pts[i], Curves.easeOutCubic.transform(local))!, line);
      if (local >= 1) _star(canvas, pts[i], 3.6, Palette.starlight);
    }
    final wake = Curves.easeOut.transform((t / 0.25).clamp(0.0, 1.0));
    final pulse = 1 + 0.15 * math.sin(t * math.pi * 4);
    _star(canvas, c, 5.5 * wake * pulse, Palette.brass);
  }

  void _star(Canvas canvas, Offset o, double r, Color col) {
    canvas.drawCircle(
        o,
        r * 4,
        Paint()
          ..shader = RadialGradient(colors: [col.withValues(alpha: 0.5), col.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: o, radius: r * 4)));
    canvas.drawCircle(o, r, Paint()..color = col);
  }

  @override
  bool shouldRepaint(covariant _WakePainter old) => old.t != t;
}
