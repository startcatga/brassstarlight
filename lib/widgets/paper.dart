import 'package:flutter/material.dart';

import '../theme/palette.dart';
import '../theme/type.dart';
import 'brass.dart';

/// A full-screen cartographer's page: parchment texture, a back control and a
/// title. Content scrolls beneath.
class PaperPage extends StatelessWidget {
  const PaperPage({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.backLabel = 'Return to the Observatory',
    this.scroll = true,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  final String backLabel;
  final bool scroll;

  @override
  Widget build(BuildContext context) {
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          OctagonButton(
            glyph: Glyph.back,
            label: backLabel,
            onPaper: true,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Lettering.title(color: Palette.ink),
                    semanticsLabel: title),
                if (subtitle != null)
                  Text(subtitle!, style: Lettering.small()),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Palette.parchment,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/art/paper.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 8),
              const InkRule(),
              Expanded(
                child: scroll
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                        child: child,
                      )
                    : child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A thin ink rule, the paper's separator.
class InkRule extends StatelessWidget {
  const InkRule({this.indent = 20, this.alpha = 0.35, super.key});

  final double indent;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: EdgeInsets.symmetric(horizontal: indent),
      color: Palette.brassDeep.withValues(alpha: alpha),
    );
  }
}

/// Small Cinzel heading on paper with generous space above.
class PaperHeading extends StatelessWidget {
  const PaperHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 8),
      child: Text(text, style: Lettering.name(color: Palette.ink)),
    );
  }
}
