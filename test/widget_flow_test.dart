import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brass_and_starlight/app.dart';
import 'package:brass_and_starlight/data/nights.dart';
import 'package:brass_and_starlight/data/progress_store.dart';
import 'package:brass_and_starlight/services/feedback.dart';
import 'package:brass_and_starlight/widgets/trace_sky.dart';

Future<void> pumpFor(WidgetTester t, Duration d) async {
  final end = t.binding.clock.now().add(d);
  while (t.binding.clock.now().isBefore(end)) {
    await t.pump(const Duration(milliseconds: 16));
  }
}

Future<ProgressStore> boot(WidgetTester t, {Map<String, Object> prefs = const {}}) async {
  SkyFeedback.audioEnabled = false;
  SharedPreferences.setMockInitialValues(prefs);
  final p = await ProgressStore.open();
  await t.binding.setSurfaceSize(const Size(400, 860));
  await t.pumpWidget(BrassAndStarlightApp(progress: p, feedback: SkyFeedback(p)));
  await pumpFor(t, const Duration(seconds: 3));
  return p;
}

void main() {
  testWidgets('splash leads to the observatory hub', (t) async {
    await boot(t);
    expect(find.text('Brass & Starlight'), findsOneWidget);
    expect(find.text('Chart Night 1'), findsOneWidget);
    expect(find.text("Tonight's Sky"), findsOneWidget);
    expect(find.text('0 / 40'), findsOneWidget);
  });

  testWidgets('trace night 1 by finger and see it sealed', (t) async {
    final p = await boot(t);
    await t.tap(find.text('Chart Night 1'));
    await pumpFor(t, const Duration(milliseconds: 600));
    expect(find.text("The Apprentice's Needle"), findsOneWidget);

    // Drag through the stars using the same layout the sky uses.
    final skyBox = t.renderObject<RenderBox>(find.byType(TraceSky));
    final size = skyBox.size;
    final pad = EdgeInsets.fromLTRB(14, 0 + 84, 14, 0 + 148);
    final layout = SkyLayout(size, pad);
    final night = nights.first;
    final origin = skyBox.localToGlobal(Offset.zero);
    final pts = [for (final i in night.path) origin + layout.toScreen(night.skyStars[i])];
    final g = await t.startGesture(pts.first);
    for (final pt in pts.skip(1)) {
      await g.moveTo(pt);
      await t.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await pumpFor(t, const Duration(seconds: 3));
    expect(find.text('Constellation Sealed'), findsOneWidget);
    expect(p.isCompleted(1), isTrue);
    expect(find.text('Chart Night 2'), findsOneWidget);
  });

  testWidgets('pause and leave the deck', (t) async {
    await boot(t);
    await t.tap(find.text('Chart Night 1'));
    await pumpFor(t, const Duration(milliseconds: 600));
    await t.tap(find.bySemanticsLabel('Stargaze pause'));
    await pumpFor(t, const Duration(milliseconds: 400));
    expect(find.text('Stargaze Pause'), findsOneWidget);
    await t.tap(find.text('Leave the Deck'));
    await pumpFor(t, const Duration(milliseconds: 600));
    expect(find.text('Chart Night 1'), findsOneWidget);
  });

  testWidgets('log, atlas, guide, tools and pledge all open', (t) async {
    await boot(t, prefs: {'v2_completed': ['1', '2']});
    for (final (entry, title) in [
      ('Observation Log', 'Observation Log'),
      ('Star Atlas', 'Star Atlas'),
      ("Apprentice's Guide", "Apprentice's Guide"),
      ('Observatory Tools', 'Observatory Tools'),
    ]) {
      await t.tap(find.text(entry).first);
      await pumpFor(t, const Duration(milliseconds: 600));
      expect(find.text(title), findsWidgets);
      if (title == 'Observatory Tools') {
        await t.tap(find.text("Stargazer's Pledge (privacy)"));
        await pumpFor(t, const Duration(milliseconds: 600));
        expect(find.text('No account or sign-in is needed.'), findsOneWidget);
        await t.tap(find.bySemanticsLabel('Return to Observatory Tools'));
        await pumpFor(t, const Duration(milliseconds: 600));
      }
      await t.tap(find.bySemanticsLabel('Return to the Observatory'));
      await pumpFor(t, const Duration(milliseconds: 600));
    }
    expect(find.text('Chart Night 3'), findsOneWidget);
  });

  testWidgets('reset progress asks first', (t) async {
    final p = await boot(t, prefs: {'v2_completed': ['1']});
    await t.tap(find.text('Observatory Tools'));
    await pumpFor(t, const Duration(milliseconds: 600));
    await t.scrollUntilVisible(find.text('Reset progress'), 200);
    await t.tap(find.text('Reset progress'));
    await pumpFor(t, const Duration(milliseconds: 400));
    expect(find.text('Reset all progress?'), findsOneWidget);
    await t.tap(find.text('Erase everything'));
    await pumpFor(t, const Duration(milliseconds: 400));
    expect(p.chartedCount, 0);
  });

  testWidgets('leaving the app mid-stroke drops the unfinished stroke', (t) async {
    await boot(t);
    await t.tap(find.text('Chart Night 1'));
    await pumpFor(t, const Duration(milliseconds: 600));

    final skyBox = t.renderObject<RenderBox>(find.byType(TraceSky));
    final layout = SkyLayout(skyBox.size, const EdgeInsets.fromLTRB(14, 84, 14, 148));
    final night = nights.first;
    final origin = skyBox.localToGlobal(Offset.zero);
    Offset at(int i) => origin + layout.toScreen(night.skyStars[night.path[i]]);
    final total = night.path.length;

    final g = await t.startGesture(at(0));
    await g.moveTo(at(1));
    await t.pump(const Duration(milliseconds: 16));
    expect(find.bySemanticsLabel('2 of $total'), findsOneWidget);

    // The app goes to the background while the finger is still down.
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await t.pump();
    await g.up();
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await pumpFor(t, const Duration(milliseconds: 400));
    expect(find.text('Stargaze Pause'), findsOneWidget);

    await t.tap(find.text('Return to the Sky'));
    await pumpFor(t, const Duration(milliseconds: 400));
    expect(find.bySemanticsLabel('0 of $total'), findsOneWidget);
  });
}
