import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app.dart';
import '../core/night.dart';
import '../data/nights.dart';
import '../routes.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import '../widgets/figure_glyph.dart';
import '../widgets/paper.dart';
import 'deck_screen.dart';

/// The Observation Log: one ruled line per night, chapter tabs down the edge.
class LogScreen extends StatefulWidget {
  const LogScreen({this.chapter, super.key});

  final int? chapter;

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  int? _chapter;

  @override
  Widget build(BuildContext context) {
    final p = AppScope.of(context).progress;
    _chapter ??= widget.chapter ?? nightById(p.nextNightId)!.chapter;
    final ch = chapters[_chapter!];
    final list = nightsInChapter(ch.index);

    return PaperPage(
      title: 'Observation Log',
      subtitle: '${p.chartedCount} of ${nights.length} nights charted',
      scroll: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 16),
            child: Column(
              children: [
                for (final c in chapters)
                  _Tab(
                    chapter: c,
                    selected: c.index == ch.index,
                    open: p.isChapterOpen(c.index),
                    charted: p.chapterCharted(c.index),
                    total: nightsInChapter(c.index).length,
                    onTap: () {
                      AppScope.read(context).feedback.page();
                      setState(() => _chapter = c.index);
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: context.stillSky ? 0 : 260),
              child: ListView(
                key: ValueKey(ch.index),
                padding: const EdgeInsets.fromLTRB(16, 16, 20, 40),
                children: [
                  Text('${ch.numeral} · ${ch.name}', style: Lettering.name(color: Palette.ink)),
                  const SizedBox(height: 6),
                  Text(ch.lesson, style: Lettering.small()),
                  const SizedBox(height: 16),
                  const InkRule(indent: 0, alpha: 0.5),
                  for (final n in list) ...[
                    _Entry(night: n),
                    const InkRule(indent: 0, alpha: 0.22),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.chapter,
    required this.selected,
    required this.open,
    required this.charted,
    required this.total,
    required this.onTap,
  });

  final Chapter chapter;
  final bool selected;
  final bool open;
  final int charted;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Palette.ink : (open ? Palette.inkSoft : Palette.inkSoft.withValues(alpha: 0.55));
    return Semantics(
      button: true,
      selected: selected,
      label: 'Chapter ${chapter.numeral}, ${chapter.name}. ${open ? '$charted of $total charted' : 'Not yet open'}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 60,
          height: 84,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: selected ? Palette.brass : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(chapter.numeral, maxLines: 1, style: Lettering.title(color: fg)),
                const SizedBox(height: 4),
                Text(open ? '$charted/$total' : 'closed',
                    maxLines: 1, style: Lettering.number(color: fg, size: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({required this.night});

  final Night night;

  @override
  Widget build(BuildContext context) {
    final p = AppScope.of(context).progress;
    final sealed = p.isCompleted(night.id);
    final open = p.isUnlocked(night.id);
    final flawless = p.isFlawless(night.id);
    final sub = sealed
        ? night.myth
        : open
            ? 'Uncharted · ${_modeWord(night.mode)}'
            : 'Opens when Night ${night.id - 1} is sealed';

    return Semantics(
      button: open,
      label: 'Night ${night.id}, ${sealed || open ? night.name : 'locked'}. ${sealed ? (flawless ? 'Sealed flawlessly' : 'Sealed') : sub}',
      excludeSemantics: true,
      child: InkWell(
        onTap: !open
            ? null
            : () {
                AppScope.read(context).feedback.tap();
                Navigator.of(context).pushNamed(Routes.deck, arguments: DeckArgs.campaign(night.id));
              },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Text('${night.id}',
                      style: Lettering.number(color: Palette.inkSoft, size: 16)),
                ),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Opacity(
                    opacity: sealed ? 1 : (open ? 0.35 : 0.15),
                    child: night.mode == TraceMode.chart && !sealed
                        ? const _Unknown()
                        : FigureGlyph(night: night, lineWidth: 1.1, starRadius: 1.8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(open || sealed ? night.name : 'A night not yet seen',
                          style: Lettering.label(color: open ? Palette.ink : Palette.inkSoft)),
                      const SizedBox(height: 2),
                      Text(sub,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: sealed ? Lettering.myth().copyWith(fontSize: 16) : Lettering.small()),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: sealed ? CustomPaint(painter: WaxSealPainter(flawless: flawless)) : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _modeWord(TraceMode m) => switch (m) {
      TraceMode.guided => 'follow the glowing star',
      TraceMode.chart => 'find it from the chart card',
      TraceMode.oneStroke => 'one unbroken stroke',
    };

/// A question of a figure: three faint stars, no lines.
class _Unknown extends StatelessWidget {
  const _Unknown();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _UnknownPainter());
  }
}

class _UnknownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Palette.brassDeep;
    for (final o in const [Offset(0.25, 0.3), Offset(0.7, 0.25), Offset(0.5, 0.75)]) {
      canvas.drawCircle(Offset(o.dx * size.width, o.dy * size.height), 2, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// A wax seal; flawless seals carry a pressed star.
class WaxSealPainter extends CustomPainter {
  WaxSealPainter({required this.flawless, this.muted = false});

  final bool flawless;
  final bool muted;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final blob = Path();
    for (var i = 0; i <= 24; i++) {
      final a = i / 24 * math.pi * 2;
      final rr = r * (0.9 + 0.08 * math.sin(i * 2.7));
      final pt = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? blob.moveTo(pt.dx, pt.dy) : blob.lineTo(pt.dx, pt.dy);
    }
    blob.close();
    final wax = muted ? Palette.inkSoft.withValues(alpha: 0.25) : Palette.brassDeep;
    canvas.drawPath(blob, Paint()..color = wax);
    canvas.drawCircle(
        c,
        r * 0.62,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = (muted ? Palette.inkSoft : Palette.brass).withValues(alpha: 0.7));
    if (flawless) {
      final star = Path();
      for (var i = 0; i < 10; i++) {
        final a = -math.pi / 2 + i * math.pi / 5;
        final rr = i.isEven ? r * 0.45 : r * 0.2;
        final pt = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
        i == 0 ? star.moveTo(pt.dx, pt.dy) : star.lineTo(pt.dx, pt.dy);
      }
      star.close();
      canvas.drawPath(star, Paint()..color = Palette.brass);
    }
  }

  @override
  bool shouldRepaint(covariant WaxSealPainter old) =>
      old.flawless != flawless || old.muted != muted;
}
