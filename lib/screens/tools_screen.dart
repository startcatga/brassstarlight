import 'package:flutter/material.dart';

import '../app.dart';
import '../routes.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import '../widgets/brass.dart';
import '../widgets/paper.dart';

/// Observatory Tools: the settings page.
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final p = scope.progress;
    return PaperPage(
      title: 'Observatory Tools',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Toggle(
            title: 'Deck sounds',
            detail: 'Chimes as stars link, and the seal.',
            value: p.sounds,
            onChanged: (v) => p.setSounds(v),
          ),
          const InkRule(indent: 0, alpha: 0.2),
          _Toggle(
            title: 'Night ambience',
            detail: 'A quiet wind and distant chimes.',
            value: p.ambience,
            onChanged: (v) => p.setAmbience(v),
          ),
          const InkRule(indent: 0, alpha: 0.2),
          _Toggle(
            title: 'Hearth haptics',
            detail: 'A small vibration as you trace.',
            value: p.haptics,
            onChanged: (v) => p.setHaptics(v),
          ),
          const InkRule(indent: 0, alpha: 0.2),
          _Toggle(
            title: 'Still sky',
            detail: 'Less motion: no drifting, pulsing or shaking.',
            value: p.stillSky,
            onChanged: (v) => p.setStillSky(v),
          ),
          const InkRule(indent: 0, alpha: 0.2),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: InkLink(
              label: "Stargazer's Pledge (privacy)",
              onPressed: () => Navigator.of(context).pushNamed(Routes.pledge),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: InkLink(
              label: 'Font licences',
              onPressed: () => showLicensePage(
                context: context,
                applicationName: 'Brass & Starlight',
              ),
            ),
          ),
          const SizedBox(height: 28),
          const InkRule(indent: 0, alpha: 0.35),
          const PaperHeading('Begin a new apprenticeship'),
          Text(
            'Erase every sealed night, score, lantern, seal and streak on this device. Your tool settings stay.',
            style: Lettering.body(),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: InkLink(
              label: 'Reset progress',
              color: Palette.emberInk,
              onPressed: () => _confirmReset(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Palette.parchment,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        title: Text('Reset all progress?', style: Lettering.name(color: Palette.ink)),
        content: Text(
          'Every sealed night, score, lantern, seal and streak will be erased. This cannot be undone.',
          style: Lettering.body(),
        ),
        actions: [
          InkLink(label: 'Keep my Atlas', onPressed: () => Navigator.pop(ctx, false)),
          InkLink(
              label: 'Erase everything',
              color: Palette.emberInk,
              onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (yes == true && context.mounted) {
      await AppScope.read(context).progress.resetProgress();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Palette.ink,
          content: Text('Progress erased. A fresh sky awaits.',
              style: Lettering.small(color: Palette.parchment)),
        ));
      }
    }
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.title,
    required this.detail,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String detail;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Lettering.label(color: Palette.ink)),
                    const SizedBox(height: 2),
                    Text(detail, style: Lettering.small()),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Palette.parchment,
                activeTrackColor: Palette.brassDeep,
                inactiveThumbColor: Palette.inkSoft,
                inactiveTrackColor: Palette.parchment,
                trackOutlineColor: WidgetStateProperty.all(Palette.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
