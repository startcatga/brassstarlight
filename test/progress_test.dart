import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brass_and_starlight/core/daily.dart';
import 'package:brass_and_starlight/core/night.dart';
import 'package:brass_and_starlight/data/nights.dart';
import 'package:brass_and_starlight/data/progress_store.dart';

Future<ProgressStore> fresh([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return ProgressStore.open();
}

void main() {
  test('score formula', () {
    expect(calculateScore(starCount: 5, flawless: false, chapterBonus: false), 500);
    expect(calculateScore(starCount: 5, flawless: true, chapterBonus: false), 750);
    expect(calculateScore(starCount: 5, flawless: true, chapterBonus: true), 950);
  });

  test('new apprentice: night 1 open, 3 lanterns, nothing sealed', () async {
    final p = await fresh();
    expect(p.isUnlocked(1), isTrue);
    expect(p.isUnlocked(2), isFalse);
    expect(p.lanterns, ProgressStore.startLanterns);
    expect(p.nextNightId, 1);
    expect(p.isChapterOpen(1), isFalse);
  });

  test('sealing unlocks the next night and earns a seal + lantern', () async {
    final p = await fresh();
    final o = await p.sealNight(nights[0], flawless: true, usedLantern: false);
    expect(o.firstTime, isTrue);
    expect(o.lanternEarned, isTrue);
    expect(o.newSeals, contains('first'));
    expect(p.isUnlocked(2), isTrue);
    expect(p.lanterns, 4);
    expect(p.lifetimeScore, o.score);
  });

  test('replaying only counts improvements to the lifetime score', () async {
    final p = await fresh();
    final a = await p.sealNight(nights[0], flawless: false, usedLantern: false);
    final b = await p.sealNight(nights[0], flawless: true, usedLantern: false);
    expect(b.newBest, isTrue);
    expect(p.lifetimeScore, b.score);
    final c = await p.sealNight(nights[0], flawless: false, usedLantern: false);
    expect(c.newBest, isFalse);
    expect(p.lifetimeScore, b.score);
    expect(a.score, lessThan(b.score));
  });

  test('finishing a chapter opens the next and earns its seal', () async {
    final p = await fresh();
    for (final n in nightsInChapter(0)) {
      await p.sealNight(n, flawless: false, usedLantern: false);
    }
    expect(p.isChapterOpen(1), isTrue);
    expect(p.seals, containsAll(['ch0', 'dark']));
  });

  test('lanterns are spent and capped', () async {
    final p = await fresh({'v2_lanterns': 1});
    expect(await p.useLantern(), isTrue);
    expect(await p.useLantern(), isFalse);
    final q = await fresh({'v2_lanterns': ProgressStore.maxLanterns});
    final o = await q.sealNight(nights[0], flawless: true, usedLantern: false);
    expect(o.lanternEarned, isFalse);
    expect(q.lanterns, ProgressStore.maxLanterns);
  });

  test('daily streak grows on consecutive days and resets after a gap', () async {
    final p = await fresh();
    final d1 = DateTime(2026, 11, 10);
    final o1 = await p.sealDaily(dailyNight(d1), flawless: true, today: d1);
    expect(o1.streak, 1);
    final again = await p.sealDaily(dailyNight(d1), flawless: true, today: d1);
    expect(again.streak, 1);
    expect(again.lanternEarned, isFalse);
    final d2 = d1.add(const Duration(days: 1));
    final d3 = d2.add(const Duration(days: 1));
    await p.sealDaily(dailyNight(d2), flawless: true, today: d2);
    final o3 = await p.sealDaily(dailyNight(d3), flawless: true, today: d3);
    expect(o3.streak, 3);
    expect(p.seals, containsAll(['daily1', 'streak3']));
    final later = d3.add(const Duration(days: 3));
    expect(p.streakOn(later), 0);
    expect(p.dailyBest, 3);
  });

  test('reset erases progress but keeps settings', () async {
    final p = await fresh();
    await p.setSounds(false);
    await p.sealNight(nights[0], flawless: true, usedLantern: false);
    await p.resetProgress();
    expect(p.chartedCount, 0);
    expect(p.lanterns, ProgressStore.startLanterns);
    expect(p.seals, isEmpty);
    expect(p.sounds, isFalse);
  });
}
