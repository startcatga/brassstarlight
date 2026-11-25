import 'package:flutter/material.dart';

import '../app.dart';
import '../core/night.dart';
import '../data/nights.dart';
import '../data/seals.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import '../widgets/figure_glyph.dart';
import '../widgets/paper.dart';
import 'log_screen.dart';

/// The Star Atlas: every sealed constellation, plus your Seals.
class AtlasScreen extends StatefulWidget {
  const AtlasScreen({super.key});

  @override
  State<AtlasScreen> createState() => _AtlasScreenState();
}

class _AtlasScreenState extends State<AtlasScreen> {
  bool _seals = false;

  @override
  Widget build(BuildContext context) {
    final p = AppScope.of(context).progress;
    final w = MediaQuery.sizeOf(context).width;
    final columns = w < 340 ? 1 : (w > 700 ? 3 : 2);

    Widget toggle(String label, bool on, VoidCallback tap) => Semantics(
          button: true,
          selected: on,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: tap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.only(right: 24, top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Lettering.label(color: on ? Palette.ink : Palette.inkSoft)),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 2,
                      width: on ? 40 : 0,
                      color: Palette.brassDeep,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

    return PaperPage(
      title: 'Star Atlas',
      subtitle: '${p.chartedCount} sealed · ${p.flawlessNights.length} flawless · best streak ${p.dailyBest}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(children: [
            toggle('Constellations', !_seals, () => setState(() => _seals = false)),
            toggle('Seals ${p.seals.length}/${sealDefs.length}', _seals, () => setState(() => _seals = true)),
          ]),
          const SizedBox(height: 20),
          if (!_seals)
            for (final c in chapters) ...[
              PaperHeading('${c.numeral} · ${c.name}'),
              GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 24,
                crossAxisSpacing: 20,
                childAspectRatio: columns == 1 ? 1.5 : 0.6,
                children: [
                  for (final n in nightsInChapter(c.index)) _Plate(night: n),
                ],
              ),
            ]
          else
            for (final s in sealDefs) ...[
              _SealRow(def: s, earned: p.seals.contains(s.id)),
              const InkRule(indent: 0, alpha: 0.2),
            ],
        ],
      ),
    );
  }
}

class _Plate extends StatelessWidget {
  const _Plate({required this.night});

  final Night night;

  @override
  Widget build(BuildContext context) {
    final p = AppScope.of(context).progress;
    final sealed = p.isCompleted(night.id);
    final best = p.bestScore(night.id);
    return Semantics(
      label: sealed
          ? '${night.name}. ${night.myth} Best score ${best ?? 0}.'
          : 'Night ${night.id}, uncharted.',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: sealed
                      ? FigureGlyph(night: night, lineWidth: 1.4, starRadius: 2.6)
                      : Center(
                          child: Text('Uncharted',
                              style: Lettering.myth(color: Palette.inkSoft.withValues(alpha: 0.6))),
                        ),
                ),
                if (sealed && p.isFlawless(night.id))
                  Positioned(
                    right: 0,
                    top: 0,
                    width: 24,
                    height: 24,
                    child: CustomPaint(painter: WaxSealPainter(flawless: true)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(sealed ? night.name : 'Night ${night.id}',
              maxLines: 2,
              style: Lettering.label(color: sealed ? Palette.ink : Palette.inkSoft)),
          if (sealed) ...[
            const SizedBox(height: 2),
            Text(night.myth,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Lettering.myth().copyWith(fontSize: 15)),
            const SizedBox(height: 4),
            Text('${best ?? 0}', style: Lettering.number(color: Palette.brassDeep, size: 16)),
          ],
        ],
      ),
    );
  }
}

class _SealRow extends StatelessWidget {
  const _SealRow({required this.def, required this.earned});

  final SealDef def;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${def.name}. ${def.how} ${earned ? 'Earned.' : 'Not yet earned.'}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CustomPaint(painter: WaxSealPainter(flawless: earned, muted: !earned)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(def.name, style: Lettering.label(color: earned ? Palette.ink : Palette.inkSoft)),
                  const SizedBox(height: 2),
                  Text(def.how, style: Lettering.small()),
                ],
              ),
            ),
            if (earned) Text('Earned', style: Lettering.small(color: Palette.brassDeep)),
          ],
        ),
      ),
    );
  }
}
