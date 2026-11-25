import 'package:flutter/material.dart';

import '../theme/type.dart';
import '../widgets/paper.dart';

/// In-game privacy policy. Deliberately names no developer, company, email,
/// website or address: the store listing carries contact details.
class PledgeScreen extends StatelessWidget {
  const PledgeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget p(String t) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(t, style: Lettering.body()),
        );
    Widget bullet(String t) => Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, right: 10),
                child: Container(width: 5, height: 5, color: const Color(0xFF9C7A22)),
              ),
              Expanded(child: Text(t, style: Lettering.body())),
            ],
          ),
        );

    return PaperPage(
      title: "Stargazer's Pledge",
      subtitle: 'Privacy Policy',
      backLabel: 'Return to Observatory Tools',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          p('Brass & Starlight does not collect, store or share any personal information.'),
          bullet('No data is collected from you or your device.'),
          bullet('No account or sign-in is needed.'),
          bullet('No analytics or tracking.'),
          bullet('No device permissions are requested.'),
          const PaperHeading('What stays on your device'),
          p('Your progress is saved only on this device: the nights you have charted, '
              'your scores, lanterns, seals, daily streak, and your Observatory Tools '
              'settings. It never leaves your phone.'),
          const PaperHeading('Deleting your data'),
          p('Use "Reset progress" in Observatory Tools, clear the app\'s data in your '
              'phone\'s settings, or uninstall the game.'),
          const PaperHeading('Children'),
          p('The game is not directed at children under 13 and collects no data from anyone.'),
          const PaperHeading('Questions or support'),
          p("Please use the developer contact details shown on this game's Google Play store listing."),
        ],
      ),
    );
  }
}
