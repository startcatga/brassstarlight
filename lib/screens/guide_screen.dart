import 'package:flutter/material.dart';

import '../app.dart';
import '../core/night.dart';
import '../core/sky_geometry.dart';
import '../core/trace_engine.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import '../widgets/brass.dart';
import '../widgets/figure_glyph.dart';
import '../widgets/paper.dart';
import '../widgets/trace_sky.dart';

Night _demo(TraceMode mode, List<Pt> stars, {List<Edge>? edges, List<Pt> decoys = const [], double rot = 0}) {
  final path = List.generate(stars.length, (i) => i);
  return Night(
    id: 0,
    chapter: 0,
    name: 'Practice',
    myth: '',
    mode: mode,
    stars: stars,
    edges: edges ?? pathEdges(path),
    path: mode == TraceMode.oneStroke ? const [] : path,
    decoys: decoys,
    rotationDegrees: rot,
  );
}

final _guided = _demo(TraceMode.guided, const [Pt(0.2, 0.7), Pt(0.5, 0.3), Pt(0.8, 0.65)]);
final _chart = _demo(
  TraceMode.chart,
  const [Pt(0.25, 0.3), Pt(0.5, 0.55), Pt(0.78, 0.35)],
  decoys: const [Pt(0.3, 0.8), Pt(0.72, 0.78)],
  rot: 90,
);
final _stroke = _demo(
  TraceMode.oneStroke,
  const [Pt(0.2, 0.75), Pt(0.5, 0.2), Pt(0.8, 0.75), Pt(0.5, 0.9) ],
  edges: [Edge(0, 1), Edge(1, 2), Edge(2, 0), Edge(0, 3)],
);

/// The Apprentice's Guide: three small skies to practise on.
class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = AppScope.read(context).progress;
    if (!progress.guideSeen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => progress.markGuideSeen());
    }
    return PaperPage(
      title: "Apprentice's Guide",
      subtitle: 'Practise here; nothing is recorded',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Each night shows a figure hidden among the stars. Charting it seals it into your Star Atlas.',
            style: Lettering.body(),
          ),
          const PaperHeading('1 · Follow the glowing star'),
          Text('Touch the star with the brass ring, then drag through each star in order without lifting.',
              style: Lettering.body()),
          const SizedBox(height: 12),
          _Practice(night: _guided),
          const PaperHeading('2 · Mind the wandering stars'),
          Text('From the second chapter, loose stars sit between yours. Touch one and the line breaks. Curve around them.',
              style: Lettering.body()),
          const PaperHeading('3 · Read the chart card'),
          Text('In the third chapter your stars are no longer marked. The chart card shows the figure upright; in the sky it is turned. Begin at either ringed end.',
              style: Lettering.body()),
          const SizedBox(height: 12),
          _Practice(night: _chart, card: true),
          const PaperHeading('4 · One unbroken line'),
          Text('In the last chapter, faint lines show the whole figure. Draw every line in one stroke, never the same line twice. Not every star is a good place to begin.',
              style: Lettering.body()),
          const SizedBox(height: 12),
          _Practice(night: _stroke),
          const PaperHeading('Lanterns'),
          Text('A lantern lights the next star, or where to begin. You start with three and earn one for each night sealed without a broken line, and one for each Tonight\'s Sky. You can carry nine.',
              style: Lettering.body()),
          const PaperHeading("Tonight's Sky"),
          Text('A new sky every day, the same for every apprentice. Chart it on consecutive days to build a streak.',
              style: Lettering.body()),
          const PaperHeading('Seals'),
          Text('Twelve seals mark what you have done: chapters charted, clean lines, nights of watching. Find them in the Star Atlas.',
              style: Lettering.body()),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Practice extends StatefulWidget {
  const _Practice({required this.night, this.card = false});

  final Night night;
  final bool card;

  @override
  State<_Practice> createState() => _PracticeState();
}

class _PracticeState extends State<_Practice> {
  late TraceEngine _engine = TraceEngine(widget.night, hitRadius: 0.067);
  String? _note;

  void _event(TraceEvent e) {
    final fb = AppScope.read(context).feedback;
    if (e.linked != null && !e.completed) fb.starLinked(_engine.progress - 1);
    if (e.fail != null) {
      fb.lineBroken();
      setState(() => _note = e.fail == TraceFail.decoy
          ? 'A wandering star. Try again.'
          : 'The line broke. Try again.');
    }
    if (e.completed) {
      fb.sealed();
      setState(() => _note = 'Sealed. Well charted.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1.15,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset('assets/art/sky_${widget.night.mode.index + 1}.jpg',
                      fit: BoxFit.cover),
                ),
                Positioned.fill(
                  child: TraceSky(
                    engine: _engine,
                    onEvent: _event,
                    stillSky: context.stillSky,
                    padding: const EdgeInsets.all(14),
                    semanticsLabel: 'Practice sky',
                  ),
                ),
                if (widget.card)
                  Positioned(
                    right: 10,
                    top: 10,
                    width: 70,
                    height: 70,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      color: Palette.parchment,
                      child: FigureGlyph(night: widget.night, markEnds: true, starRadius: 2),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: Row(
            children: [
              Expanded(child: Text(_note ?? '', style: Lettering.small())),
              if (_engine.completed || _engine.failCount > 0)
                InkLink(
                  label: 'Try again',
                  onPressed: () => setState(() {
                    _engine = TraceEngine(widget.night, hitRadius: 0.067);
                    _note = null;
                  }),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
