import 'package:flutter/material.dart';

import '../app.dart';
import '../core/night.dart';
import '../data/nights.dart';
import '../data/seals.dart';
import '../routes.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import '../widgets/brass.dart';
import '../widgets/figure_glyph.dart';
import '../widgets/paper.dart';
import 'deck_screen.dart';

/// "Constellation Sealed": the night is inked into the Atlas as a plate.
class SealedScreen extends StatefulWidget {
  const SealedScreen({required this.args, super.key});

  final SealedArgs args;

  @override
  State<SealedScreen> createState() => _SealedScreenState();
}

class _SealedScreenState extends State<SealedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ink;

  @override
  void initState() {
    super.initState();
    _ink = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.stillSky) {
        _ink.value = 1;
      } else {
        _ink.forward();
      }
      final o = widget.args.outcome;
      if (o.newSeals.isNotEmpty || _chapterOpened != null) {
        Future<void>.delayed(const Duration(milliseconds: 900), () {
          if (mounted) AppScope.read(context).feedback.unlocked();
        });
      }
    });
  }

  @override
  void dispose() {
    _ink.dispose();
    super.dispose();
  }

  Chapter? get _chapterOpened {
    final n = widget.args.night;
    if (widget.args.daily || !n.finale || !widget.args.outcome.firstTime) return null;
    return n.chapter + 1 < chapters.length ? chapters[n.chapter + 1] : null;
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.args;
    final n = a.night;
    final o = a.outcome;
    final nextId = n.id + 1;
    final hasNext = !a.daily && nextId <= nights.length;
    final fb = AppScope.read(context).feedback;

    final rows = <(String, String)>[
      ('${n.starCount} stars charted', '${n.starCount * 100}'),
      if (o.flawless) ('Flawless charting', '+${n.starCount * 50}')
      else ('Broken lines along the way', '+0'),
      if (n.finale && !a.daily) ('Chapter finale', '+200'),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop();
      },
      child: PaperPage(
        title: 'Constellation Sealed',
        subtitle: a.daily ? "Tonight's Sky" : 'Night ${n.id} · ${chapters[n.chapter].name}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1.25,
              child: AnimatedBuilder(
                animation: _ink,
                builder: (context, _) => FigureGlyph(
                  night: n,
                  progress: Curves.easeInOutCubic.transform(_ink.value),
                  lineWidth: 2,
                  starRadius: 4,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(n.name, style: Lettering.title(color: Palette.ink)),
            const SizedBox(height: 6),
            Text(n.myth, style: Lettering.myth()),
            const SizedBox(height: 24),
            for (final (label, value) in rows) ...[
              _LedgerRow(label: label, value: value),
              const InkRule(indent: 0, alpha: 0.2),
            ],
            _LedgerRow(label: 'Star score', value: '${o.score}', strong: true),
            if (!a.daily && !o.newBest && !o.firstTime)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Your best for this night stands.', style: Lettering.small()),
              ),
            const SizedBox(height: 20),
            if (a.daily)
              _Note('Daily streak: ${o.streak} ${o.streak == 1 ? 'night' : 'nights'}.'),
            if (o.lanternEarned) const _Note('A lantern is added to your kit.'),
            if (_chapterOpened != null)
              _Note('Chapter ${_chapterOpened!.numeral} opens: ${_chapterOpened!.name}.'),
            for (final id in o.newSeals)
              _Note('Seal earned: ${sealById(id)!.name}. ${sealById(id)!.how}'),
            const SizedBox(height: 28),
            Center(
              child: BrassPlate(
                label: hasNext ? 'Chart Night $nextId' : 'Return to the Observatory',
                onPressed: () {
                  fb.tap();
                  if (hasNext) {
                    Navigator.of(context).pushReplacementNamed(Routes.deck,
                        arguments: DeckArgs.campaign(nextId));
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
            if (hasNext)
              Center(
                child: InkLink(
                  label: 'Return to the Observatory',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.label, required this.value, this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: strong ? Lettering.label(color: Palette.ink) : Lettering.body()),
          ),
          Text(value, style: Lettering.number(size: strong ? 22 : 18)),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 10),
            child: _SealDot(),
          ),
          Expanded(child: Text(text, style: Lettering.body())),
        ],
      ),
    );
  }
}

class _SealDot extends StatelessWidget {
  const _SealDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: const BoxDecoration(color: Palette.brassDeep, shape: BoxShape.circle),
    );
  }
}

/// Used by other screens to show a night's mode in words.
String modeName(TraceMode m) => switch (m) {
      TraceMode.guided => 'Guided',
      TraceMode.chart => 'Chart card',
      TraceMode.oneStroke => 'One stroke',
    };
