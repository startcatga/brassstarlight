import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../app.dart';
import '../core/sky_geometry.dart';
import '../data/nights.dart';
import '../routes.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import '../widgets/figure_glyph.dart';
import 'deck_screen.dart';

/// The hub: a rooftop observatory under the sky you are charting. The menu is
/// a handful of small star clusters; sealed constellations gather in gold.
class ObservatoryScreen extends StatefulWidget {
  const ObservatoryScreen({super.key});

  @override
  State<ObservatoryScreen> createState() => _ObservatoryScreenState();
}

class _ObservatoryScreenState extends State<ObservatoryScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _clock = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) => _clock.value = d.inMicroseconds / 1e6)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.read(context).feedback.wantAmbience(true);
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  Future<void> _open(String route, {Object? args}) async {
    AppScope.read(context).feedback.tap();
    await Navigator.of(context).pushNamed(route, arguments: args);
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final p = scope.progress;
    final today = DateTime.now();
    final next = p.nextNightId;
    final streak = p.streakOn(today);
    final dailyDone = p.dailyDoneOn(today);
    final still = context.stillSky;

    final primaryLabel = p.allCharted ? 'Revisit the Atlas Skies' : 'Chart Night $next';
    final primaryCaption = p.allCharted
        ? 'Every night is charted'
        : nights[next - 1].name;

    return Scaffold(
      backgroundColor: Palette.nightInk,
      body: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth, h = c.maxHeight;
        final top = MediaQuery.paddingOf(context).top + 84;
        final skyBottom = h * 0.62;
        final region = skyBottom - top;
        double ry(double f) => top + region * f;

        final items = <_ClusterSpec>[
          _ClusterSpec(
            label: primaryLabel,
            caption: primaryCaption,
            primary: true,
            left: true,
            y: ry(0.0),
            shape: const [Offset(0, 0.7), Offset(0.35, 0.15), Offset(0.7, 0.55), Offset(1, 0.05)],
            onTap: () => _open(p.allCharted ? Routes.log : Routes.deck,
                args: p.allCharted ? 3 : DeckArgs.campaign(next)),
          ),
          _ClusterSpec(
            label: "Tonight's Sky",
            caption: dailyDone
                ? 'Charted · streak $streak'
                : streak > 0
                    ? 'Streak $streak · waiting'
                    : 'A new sky each day',
            left: false,
            y: ry(0.20),
            shape: const [Offset(0, 0.5), Offset(0.5, 0), Offset(1, 0.5), Offset(0.5, 1)],
            onTap: () => _open(Routes.deck, args: DeckArgs.daily(today)),
          ),
          _ClusterSpec(
            label: 'Observation Log',
            caption: 'Every night, by chapter',
            left: true,
            y: ry(0.42),
            shape: const [Offset(0, 0.2), Offset(0.5, 0.2), Offset(1, 0.2), Offset(1, 0.9)],
            onTap: () => _open(Routes.log),
          ),
          _ClusterSpec(
            label: 'Star Atlas',
            caption: '${p.chartedCount} sealed · ${p.seals.length} seals',
            left: false,
            y: ry(0.58),
            shape: const [Offset(0, 0.9), Offset(0.25, 0.1), Offset(0.75, 0.1), Offset(1, 0.9)],
            onTap: () => _open(Routes.atlas),
          ),
          _ClusterSpec(
            label: "Apprentice's Guide",
            caption: 'How the sky is charted',
            left: true,
            y: ry(0.80),
            shape: const [Offset(0.5, 0), Offset(0, 1), Offset(1, 1)],
            onTap: () => _open(Routes.guide),
          ),
          _ClusterSpec(
            label: 'Observatory Tools',
            caption: 'Sound, haptics, motion',
            left: false,
            y: ry(0.96),
            shape: const [Offset(0, 0.5), Offset(0.5, 0.1), Offset(1, 0.5), Offset(0.5, 0.9), Offset(0, 0.5)],
            onTap: () => _open(Routes.tools),
          ),
        ];

        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/art/hub.jpg',
                  fit: BoxFit.cover, alignment: Alignment.bottomCenter),
            ),
            // Sealed constellations gather in the sky.
            ..._sealedFigures(p.completed, w, top - 40, skyBottom),
            if (!still)
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(painter: _NightMotion(_clock)),
                  ),
                ),
              ),
            Positioned(
              left: 20,
              right: 20,
              top: MediaQuery.paddingOf(context).top + 16,
              child: Text('Brass & Starlight', style: Lettering.title()),
            ),
            for (final s in items)
              Positioned(
                left: s.left ? 20 : null,
                right: s.left ? null : 20,
                top: s.y,
                width: math.min(w * 0.62, 280),
                child: _Cluster(spec: s),
              ),
            Positioned(
              left: 20,
              right: 20,
              bottom: MediaQuery.paddingOf(context).bottom + 18,
              child: _Ledger(
                charted: p.chartedCount,
                total: nights.length,
                score: p.lifetimeScore,
                lanterns: p.lanterns,
              ),
            ),
          ],
        );
      }),
    );
  }

  List<Widget> _sealedFigures(Set<int> done, double w, double top, double bottom) {
    final out = <Widget>[];
    for (final id in done) {
      final n = nightById(id);
      if (n == null) continue;
      final r = SeededRng(id * 977);
      const size = 64.0;
      final x = r.range(w * 0.28, w * 0.72 - size);
      final y = r.range(top, bottom - size);
      out.add(Positioned(
        left: x,
        top: y,
        width: size,
        height: size,
        child: IgnorePointer(
          child: Opacity(
            opacity: 0.2,
            child: FigureGlyph(
              night: n,
              lineColor: Palette.brass,
              starColor: Palette.brass,
              lineWidth: 1,
              starRadius: 1.6,
            ),
          ),
        ),
      ));
    }
    return out;
  }
}

class _ClusterSpec {
  const _ClusterSpec({
    required this.label,
    required this.caption,
    required this.left,
    required this.y,
    required this.shape,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final String caption;
  final bool left;
  final double y;
  final List<Offset> shape;
  final VoidCallback onTap;
  final bool primary;
}

class _Cluster extends StatelessWidget {
  const _Cluster({required this.spec});

  final _ClusterSpec spec;

  @override
  Widget build(BuildContext context) {
    final align = spec.left ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    return Semantics(
      button: true,
      label: '${spec.label}. ${spec.caption}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: spec.onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Column(
            crossAxisAlignment: align,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: spec.primary ? 92 : 64,
                height: spec.primary ? 34 : 24,
                child: CustomPaint(
                  painter: _ClusterPainter(spec.shape, spec.primary),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                spec.label,
                textAlign: spec.left ? TextAlign.left : TextAlign.right,
                style: spec.primary
                    ? Lettering.name(color: Palette.brass)
                    : Lettering.label(),
              ),
              const SizedBox(height: 2),
              Text(
                spec.caption,
                textAlign: spec.left ? TextAlign.left : TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Lettering.small(color: Palette.mist),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClusterPainter extends CustomPainter {
  _ClusterPainter(this.shape, this.primary);

  final List<Offset> shape;
  final bool primary;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = [for (final o in shape) Offset(o.dx * size.width, o.dy * size.height)];
    final col = primary ? Palette.brass : Palette.starlight;
    final line = Paint()
      ..color = col.withValues(alpha: 0.55)
      ..strokeWidth = 1.1;
    for (var i = 0; i + 1 < pts.length; i++) {
      canvas.drawLine(pts[i], pts[i + 1], line);
    }
    for (final p in pts.toSet()) {
      final r = primary ? 3.4 : 2.6;
      canvas.drawCircle(
          p,
          r * 3.5,
          Paint()
            ..shader = RadialGradient(
                    colors: [col.withValues(alpha: 0.45), col.withValues(alpha: 0)])
                .createShader(Rect.fromCircle(center: p, radius: r * 3.5)));
      canvas.drawCircle(p, r, Paint()..color = col);
    }
  }

  @override
  bool shouldRepaint(covariant _ClusterPainter old) => false;
}

/// Twinkles and the occasional shooting star.
class _NightMotion extends CustomPainter {
  _NightMotion(this.clock) : super(repaint: clock);

  final ValueNotifier<double> clock;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    final r = SeededRng(42);
    for (var i = 0; i < 26; i++) {
      final x = r.next() * size.width;
      final y = r.next() * size.height * 0.6;
      final phase = r.next() * 6.28;
      final a = (math.sin(t * 0.9 + phase) + 1) / 2;
      canvas.drawCircle(Offset(x, y), 1.1 + a * 0.6,
          Paint()..color = Palette.starlight.withValues(alpha: 0.15 + 0.55 * a));
    }
    // A shooting star every 14 s, lasting 0.9 s.
    final cycle = t % 14;
    if (cycle > 5 && cycle < 5.9) {
      final k = (cycle - 5) / 0.9;
      final n = (t / 14).floor();
      final rr = SeededRng(n * 13 + 1);
      final start = Offset(rr.range(0.2, 0.9) * size.width, rr.range(0.05, 0.3) * size.height);
      final dir = Offset(-0.85, 0.5);
      final head = start + dir * (k * 260);
      final tail = head - dir * 70;
      canvas.drawLine(
          tail,
          head,
          Paint()
            ..shader = LinearGradient(colors: [
              Palette.starlight.withValues(alpha: 0),
              Palette.starlight.withValues(alpha: 0.85 * (1 - k)),
            ]).createShader(Rect.fromPoints(tail, head))
            ..strokeWidth = 1.6
            ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(covariant _NightMotion old) => false;
}

class _Ledger extends StatelessWidget {
  const _Ledger({
    required this.charted,
    required this.total,
    required this.score,
    required this.lanterns,
  });

  final int charted;
  final int total;
  final int score;
  final int lanterns;

  @override
  Widget build(BuildContext context) {
    Widget stat(String value, String label) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: Lettering.number(color: Palette.brass, size: 22)),
            Text(label, style: Lettering.small(color: Palette.mist)),
          ],
        );
    return Semantics(
      label: '$charted of $total nights charted. Lifetime score $score. $lanterns lanterns.',
      excludeSemantics: true,
      child: Row(
        children: [
          Expanded(child: stat('$charted / $total', 'nights charted')),
          Expanded(child: stat(_grouped(score), 'star score')),
          stat('$lanterns', lanterns == 1 ? 'lantern' : 'lanterns'),
        ],
      ),
    );
  }
}

String _grouped(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}
