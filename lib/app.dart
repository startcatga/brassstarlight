import 'package:flutter/material.dart';

import 'data/progress_store.dart';
import 'routes.dart';
import 'screens/atlas_screen.dart';
import 'screens/deck_screen.dart';
import 'screens/guide_screen.dart';
import 'screens/log_screen.dart';
import 'screens/observatory_screen.dart';
import 'screens/pledge_screen.dart';
import 'screens/sealed_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/tools_screen.dart';
import 'services/feedback.dart';
import 'theme/type.dart';

final routeObserver = RouteObserver<ModalRoute<void>>();

class BrassAndStarlightApp extends StatelessWidget {
  const BrassAndStarlightApp({
    required this.progress,
    required this.feedback,
    super.key,
  });

  final ProgressStore progress;
  final SkyFeedback feedback;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      progress: progress,
      feedback: feedback,
      child: MaterialApp(
        title: 'Brass & Starlight',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        navigatorObservers: [routeObserver],
        initialRoute: Routes.splash,
        onGenerateRoute: (s) {
          final Widget page = switch (s.name) {
            Routes.observatory => const ObservatoryScreen(),
            Routes.log => LogScreen(chapter: s.arguments as int?),
            Routes.deck => DeckScreen(args: s.arguments! as DeckArgs),
            Routes.sealed => SealedScreen(args: s.arguments! as SealedArgs),
            Routes.atlas => const AtlasScreen(),
            Routes.guide => const GuideScreen(),
            Routes.tools => const ToolsScreen(),
            Routes.pledge => const PledgeScreen(),
            _ => const SplashScreen(),
          };
          return PageRouteBuilder<void>(
            settings: s,
            transitionDuration: const Duration(milliseconds: 340),
            reverseTransitionDuration: const Duration(milliseconds: 260),
            pageBuilder: (_, _, _) => page,
            transitionsBuilder: (context, a, _, child) {
              final still = AppScope.of(context).progress.stillSky ||
                  MediaQuery.of(context).disableAnimations;
              final curved = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
              if (still) return FadeTransition(opacity: curved, child: child);
              return FadeTransition(
                opacity: curved,
                child: ScaleTransition(
                  scale: Tween(begin: 1.03, end: 1.0).animate(curved),
                  child: child,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AppScope extends InheritedNotifier<ProgressStore> {
  const AppScope({
    required this.progress,
    required this.feedback,
    required super.child,
    super.key,
  }) : super(notifier: progress);

  final ProgressStore progress;
  final SkyFeedback feedback;

  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  static AppScope read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!;
}

extension StillSky on BuildContext {
  /// True when motion should be reduced (setting or system).
  bool get stillSky =>
      AppScope.of(this).progress.stillSky ||
      MediaQuery.of(this).disableAnimations;
}
