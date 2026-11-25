import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app.dart';
import '../core/daily.dart';
import '../core/night.dart';
import '../core/trace_engine.dart';
import '../data/nights.dart';
import '../data/progress_store.dart';
import '../routes.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import '../widgets/brass.dart';
import '../widgets/figure_glyph.dart';
import '../widgets/trace_sky.dart';

class DeckArgs {
  const DeckArgs._(this.nightId, this.date);

  factory DeckArgs.campaign(int id) => DeckArgs._(id, null);
  factory DeckArgs.daily(DateTime date) => DeckArgs._(null, date);

  final int? nightId;
  final DateTime? date;

  bool get isDaily => date != null;
}

class SealedArgs {
  const SealedArgs({required this.night, required this.outcome, this.daily = false});

  final Night night;
  final SealOutcome outcome;
  final bool daily;
}

String modeInstruction(TraceMode m) => switch (m) {
      TraceMode.guided => 'Touch the glowing star, then drag through each star in order.',
      TraceMode.chart => 'Find the chart card figure. Begin at a ringed end.',
      TraceMode.oneStroke => 'Draw every faint line in one stroke. Never the same line twice.',
    };

/// The Observatory Deck: the sky you trace.
class DeckScreen extends StatefulWidget {
  const DeckScreen({required this.args, super.key});

  final DeckArgs args;

  @override
  State<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends State<DeckScreen> with WidgetsBindingObserver {
  late Night _night;
  late TraceEngine _engine;
  int? _hint;
  bool _usedLantern = false;
  bool _paused = false;
  bool _sealing = false;
  String? _message;
  bool _messageIsError = false;
  Timer? _messageTimer;
  Timer? _hintTimer;
  int _shake = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final a = widget.args;
    _night = a.isDaily
        ? dailyNight(a.date!)
        : (nightById(a.nightId!) ?? nights.first);
    _engine = TraceEngine(_night, hitRadius: 0.067);
    final firstOfChapter = !a.isDaily && nightsInChapter(_night.chapter).first.id == _night.id;
    _say(firstOfChapter || a.isDaily
        ? modeInstruction(_night.mode)
        : null, seconds: 7);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageTimer?.cancel();
    _hintTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (!_sealing && mounted) _pause();
      AppScope.read(context).feedback.pauseAmbience();
    } else if (state == AppLifecycleState.resumed) {
      AppScope.read(context).feedback.wantAmbience(true);
    }
  }

  /// Pausing drops an unfinished stroke: the finger-lift that would end it
  /// is ignored while the sky is veiled, so it must not linger after resume.
  /// Not counted as a mistake.
  void _pause() {
    setState(() {
      if (_engine.tracing) {
        _engine.reset();
        // A lit lantern now points at where to begin, so it isn't wasted.
        if (_hint != null) _hint = _engine.hintStar();
      }
      _paused = true;
    });
  }

  void _say(String? text, {bool error = false, int seconds = 3}) {
    _messageTimer?.cancel();
    setState(() {
      _message = text;
      _messageIsError = error;
    });
    if (text != null) {
      _messageTimer = Timer(Duration(seconds: seconds), () {
        if (mounted) setState(() => _message = null);
      });
    }
  }

  void _onEvent(TraceEvent e) {
    final fb = AppScope.read(context).feedback;
    if (e.linked != null && !e.completed) {
      fb.starLinked(_engine.progress - 1);
      if (_hint != null) setState(() => _hint = null);
      if (_message != null && !_messageIsError) _say(null);
    }
    if (e.fail != null) {
      e.fail == TraceFail.decoy ? fb.decoyTouched() : fb.lineBroken();
      setState(() => _shake++);
      _say(
        switch (e.fail!) {
          TraceFail.decoy => 'A wandering star. It is not part of your chart.',
          TraceFail.retraced => 'That line is already drawn. Begin again.',
          TraceFail.noLine => 'No line joins those stars. Begin again.',
          TraceFail.broken => 'The line broke. Trace again.',
        },
        error: true,
      );
    }
    if (e.completed) _seal();
    setState(() {});
  }

  Future<void> _seal() async {
    if (_sealing) return;
    _sealing = true;
    final scope = AppScope.read(context);
    scope.feedback.sealed();
    final flawless = _engine.failCount == 0;
    final SealOutcome outcome;
    if (widget.args.isDaily) {
      outcome = await scope.progress.sealDaily(_night, flawless: flawless, today: widget.args.date!);
    } else {
      outcome = await scope.progress.sealNight(_night, flawless: flawless, usedLantern: _usedLantern);
    }
    if (!mounted) return;
    await Future<void>.delayed(Duration(milliseconds: context.stillSky ? 400 : 1500));
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(Routes.sealed,
        arguments: SealedArgs(night: _night, outcome: outcome, daily: widget.args.isDaily));
  }

  Future<void> _lantern() async {
    final scope = AppScope.read(context);
    if (_engine.strokeStuck) {
      _say('This stroke cannot finish now. Lift your finger and begin again.', seconds: 4);
      return;
    }
    if (_hint != null) return;
    if (scope.progress.lanterns <= 0) {
      _say('No lanterns left. Seal a night without a broken line to earn one.', seconds: 4);
      return;
    }
    final star = _engine.hintStar();
    if (star == null) return;
    if (!await scope.progress.useLantern()) return;
    scope.feedback.lantern();
    _usedLantern = true;
    setState(() => _hint = star);
    _say(_engine.tracing ? 'The lantern lights your next star.' : 'The lantern lights where to begin.');
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _hint = null);
    });
  }

  void _restart() {
    setState(() {
      _engine.restart();
      _hint = null;
      _paused = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final still = context.stillSky;
    final pad = MediaQuery.paddingOf(context);
    final chapter = chapters[_night.chapter];
    final subtitle = widget.args.isDaily
        ? "Tonight's Sky · ${dateKey(widget.args.date!)}"
        : 'Night ${_night.id} · ${chapter.name}';
    final showChart = _night.mode == TraceMode.chart;

    return PopScope(
      canPop: _paused || _sealing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _pause();
      },
      child: Scaffold(
        backgroundColor: Palette.nightInk,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/art/sky_${_night.chapter + 1}.jpg', fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: TraceSky(
                engine: _engine,
                onEvent: _onEvent,
                hintStar: _hint,
                stillSky: still,
                enabled: !_paused && !_sealing,
                semanticsLabel: '${_night.name}. ${modeInstruction(_night.mode)}',
                padding: EdgeInsets.fromLTRB(14, pad.top + 84, 14, pad.bottom + 148),
              ),
            ),
            // Header.
            Positioned(
              left: 20,
              right: 12,
              top: pad.top + 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _night.mode == TraceMode.chart && !_engine.completed
                              ? 'An uncharted figure'
                              : _night.name,
                          style: Lettering.name(),
                        ),
                        const SizedBox(height: 2),
                        Text(subtitle, style: Lettering.small(color: Palette.mist)),
                      ],
                    ),
                  ),
                  OctagonButton(
                    glyph: Glyph.pause,
                    label: 'Stargaze pause',
                    onPressed: _sealing ? null : () {
                      scope.feedback.tap();
                      _pause();
                    },
                  ),
                ],
              ),
            ),
            // Footer: lantern, pips + message, chart card.
            Positioned(
              left: 12,
              right: 12,
              bottom: pad.bottom + 14,
              child: SizedBox(
                height: 124,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    OctagonButton(
                      glyph: Glyph.lantern,
                      label: 'Light a lantern. ${scope.progress.lanterns} left',
                      badge: '${scope.progress.lanterns}',
                      onPressed: _sealing ? null : _lantern,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 240),
                            child: _message == null
                                ? const SizedBox(height: 60)
                                : SizedBox(
                                    key: ValueKey(_message),
                                    height: 60,
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Text(
                                        _message!,
                                        textAlign: TextAlign.center,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: Lettering.small(
                                            color: _messageIsError ? Palette.ember : Palette.starlight),
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 10),
                          _Pips(
                            total: _engine.total,
                            filled: _engine.progress,
                            shake: _shake,
                            still: still,
                          ),
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (showChart)
                      _ChartCard(night: _night)
                    else
                      const SizedBox(width: 52),
                  ],
                ),
              ),
            ),
            if (_paused) _PauseVeil(
              onResume: () => setState(() => _paused = false),
              onRestart: _restart,
              onLeave: () => Navigator.of(context).pop(),
              still: still,
            ),
          ],
        ),
      ),
    );
  }
}

class _Pips extends StatelessWidget {
  const _Pips({required this.total, required this.filled, required this.shake, required this.still});

  final int total;
  final int filled;
  final int shake;
  final bool still;

  @override
  Widget build(BuildContext context) {
    final row = Semantics(
      label: '$filled of $total',
      excludeSemantics: true,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          for (var i = 0; i < total; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled ? Palette.brass : Colors.transparent,
                border: Border.all(
                    color: i < filled ? Palette.brass : Palette.mist, width: 1.2),
              ),
            ),
        ],
      ),
    );
    if (still) return row;
    return TweenAnimationBuilder<double>(
      key: ValueKey(shake),
      tween: Tween(begin: shake == 0 ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 360),
      builder: (context, t, child) => Transform.translate(
        offset: Offset(math.sin(t * math.pi * 4) * 6 * (1 - t), 0),
        child: child,
      ),
      child: row,
    );
  }
}

/// A note clipped to the eyepiece: the upright figure to find.
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.night});

  final Night night;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Chart card. The figure to find, shown upright. Begin at either ringed end.',
      excludeSemantics: true,
      child: Container(
        width: 104,
        height: 104,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Palette.parchment,
          borderRadius: BorderRadius.circular(2),
          boxShadow: const [
            BoxShadow(color: Color(0x88000000), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: FigureGlyph(
          night: night,
          markEnds: true,
          lineWidth: 1.4,
          starRadius: 2.4,
        ),
      ),
    );
  }
}

class _PauseVeil extends StatelessWidget {
  const _PauseVeil({
    required this.onResume,
    required this.onRestart,
    required this.onLeave,
    required this.still,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onLeave;
  final bool still;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: still ? 1 : 0, end: 1),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) => Opacity(opacity: t, child: child),
        child: Container(
          color: Palette.nightInk.withValues(alpha: 0.86),
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Stargaze Pause', style: Lettering.title(), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Clouds pass. The sky will wait.',
                  textAlign: TextAlign.center, style: Lettering.myth(color: Palette.mist)),
              const SizedBox(height: 36),
              Center(child: BrassPlate(label: 'Return to the Sky', onPressed: onResume)),
              const SizedBox(height: 12),
              Center(child: InkLink(label: 'Begin this night again', onPressed: onRestart, color: Palette.starlight)),
              Center(child: InkLink(label: 'Leave the Deck', onPressed: onLeave, color: Palette.starlight)),
            ],
          ),
        ),
      ),
    );
  }
}
