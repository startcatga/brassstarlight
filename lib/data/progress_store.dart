import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/daily.dart';
import '../core/night.dart';
import 'nights.dart';
import 'seals.dart';

class SealOutcome {
  const SealOutcome({
    required this.score,
    required this.flawless,
    required this.firstTime,
    required this.newBest,
    required this.lanternEarned,
    required this.newSeals,
    this.streak = 0,
  });

  final int score;
  final bool flawless;
  final bool firstTime;
  final bool newBest;
  final bool lanternEarned;
  final List<String> newSeals;

  /// Daily streak after this seal (daily sky only).
  final int streak;
}

/// Everything the game remembers. Stored only on this device.
class ProgressStore extends ChangeNotifier {
  ProgressStore(this._prefs);

  static Future<ProgressStore> open() async =>
      ProgressStore(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  static const maxLanterns = 9;
  static const startLanterns = 3;

  static const _completed = 'v2_completed';
  static const _scores = 'v2_scores';
  static const _flawless = 'v2_flawless';
  static const _lanternFree = 'v2_lantern_free';
  static const _lifetime = 'v2_lifetime';
  static const _lanterns = 'v2_lanterns';
  static const _seals = 'v2_seals';
  static const _dailyLast = 'v2_daily_last';
  static const _dailyStreak = 'v2_daily_streak';
  static const _dailyBest = 'v2_daily_best';
  static const _dailyCount = 'v2_daily_count';
  static const _guideSeen = 'v2_guide_seen';
  static const _haptics = 'haptics_enabled';
  static const _sounds = 'sounds_enabled';
  static const _ambience = 'ambience_enabled';
  static const _stillSky = 'still_sky';

  // ── reading ───────────────────────────────────────────────────────────
  Set<int> _ints(String key) =>
      (_prefs.getStringList(key) ?? const []).map(int.parse).toSet();

  Future<void> _setInts(String key, Set<int> v) =>
      _prefs.setStringList(key, (v.toList()..sort()).map((e) => '$e').toList());

  Set<int> get completed => _ints(_completed);
  Set<int> get flawlessNights => _ints(_flawless);
  Set<String> get seals => (_prefs.getStringList(_seals) ?? const []).toSet();

  bool isCompleted(int id) => completed.contains(id);
  bool isUnlocked(int id) => id == 1 || completed.contains(id - 1);
  bool isChapterOpen(int chapter) {
    final first = nightsInChapter(chapter).first;
    return isUnlocked(first.id);
  }

  int chapterCharted(int chapter) =>
      nightsInChapter(chapter).where((n) => isCompleted(n.id)).length;

  int get chartedCount => completed.length;
  int get lifetimeScore => _prefs.getInt(_lifetime) ?? 0;
  int get lanterns => _prefs.getInt(_lanterns) ?? startLanterns;

  Map<int, int> get _scoreMap {
    final raw = _prefs.getString(_scores);
    if (raw == null) return {};
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return m.map((k, v) => MapEntry(int.parse(k), v as int));
  }

  int? bestScore(int id) => _scoreMap[id];
  bool isFlawless(int id) => flawlessNights.contains(id);

  /// First unsealed open night, or the last night once all are charted.
  int get nextNightId {
    for (final n in nights) {
      if (!isCompleted(n.id)) return n.id;
    }
    return nights.last.id;
  }

  bool get allCharted => chartedCount >= nights.length;

  // Daily sky
  String? get dailyLast => _prefs.getString(_dailyLast);
  int get dailyCount => _prefs.getInt(_dailyCount) ?? 0;
  int get dailyBest => _prefs.getInt(_dailyBest) ?? 0;

  /// Streak as it stands today (broken if a day was missed).
  int streakOn(DateTime today) {
    final last = dailyLast;
    if (last == null) return 0;
    final t = dateKey(today);
    final y = dateKey(today.subtract(const Duration(days: 1)));
    if (last == t || last == y) return _prefs.getInt(_dailyStreak) ?? 0;
    return 0;
  }

  bool dailyDoneOn(DateTime today) => dailyLast == dateKey(today);

  // Settings
  bool get haptics => _prefs.getBool(_haptics) ?? true;
  bool get sounds => _prefs.getBool(_sounds) ?? true;
  bool get ambience => _prefs.getBool(_ambience) ?? true;
  bool get stillSky => _prefs.getBool(_stillSky) ?? false;
  bool get guideSeen => _prefs.getBool(_guideSeen) ?? false;

  Future<void> setHaptics(bool v) => _setBool(_haptics, v);
  Future<void> setSounds(bool v) => _setBool(_sounds, v);
  Future<void> setAmbience(bool v) => _setBool(_ambience, v);
  Future<void> setStillSky(bool v) => _setBool(_stillSky, v);
  Future<void> markGuideSeen() => _setBool(_guideSeen, true);

  Future<void> _setBool(String k, bool v) async {
    await _prefs.setBool(k, v);
    notifyListeners();
  }

  // ── lanterns ──────────────────────────────────────────────────────────
  Future<bool> useLantern() async {
    final n = lanterns;
    if (n <= 0) return false;
    await _prefs.setInt(_lanterns, n - 1);
    notifyListeners();
    return true;
  }

  Future<bool> _addLantern() async {
    final n = lanterns;
    if (n >= maxLanterns) return false;
    await _prefs.setInt(_lanterns, n + 1);
    return true;
  }

  // ── sealing ───────────────────────────────────────────────────────────
  Future<SealOutcome> sealNight(
    Night night, {
    required bool flawless,
    required bool usedLantern,
  }) async {
    final firstTime = !isCompleted(night.id);
    final score = calculateScore(
      starCount: night.starCount,
      flawless: flawless,
      chapterBonus: night.finale,
    );

    if (firstTime) await _setInts(_completed, {...completed, night.id});

    final scores = _scoreMap;
    final previous = scores[night.id] ?? 0;
    final newBest = score > previous;
    if (newBest) {
      scores[night.id] = score;
      await _prefs.setString(
          _scores, jsonEncode(scores.map((k, v) => MapEntry('$k', v))));
      await _prefs.setInt(_lifetime, lifetimeScore + score - previous);
    }

    var lantern = false;
    if (flawless && !isFlawless(night.id)) {
      await _setInts(_flawless, {...flawlessNights, night.id});
      lantern = await _addLantern();
    }
    if (!usedLantern) {
      await _setInts(_lanternFree, {..._ints(_lanternFree), night.id});
    }

    final earned = await _checkSeals();
    notifyListeners();
    return SealOutcome(
      score: score,
      flawless: flawless,
      firstTime: firstTime,
      newBest: newBest,
      lanternEarned: lantern,
      newSeals: earned,
    );
  }

  Future<SealOutcome> sealDaily(
    Night night, {
    required bool flawless,
    required DateTime today,
  }) async {
    final already = dailyDoneOn(today);
    var streak = streakOn(today);
    var lantern = false;
    if (!already) {
      streak += 1;
      await _prefs.setString(_dailyLast, dateKey(today));
      await _prefs.setInt(_dailyStreak, streak);
      await _prefs.setInt(_dailyCount, dailyCount + 1);
      if (streak > dailyBest) await _prefs.setInt(_dailyBest, streak);
      lantern = await _addLantern();
    }
    final earned = await _checkSeals();
    notifyListeners();
    return SealOutcome(
      score: calculateScore(
          starCount: night.starCount, flawless: flawless, chapterBonus: false),
      flawless: flawless,
      firstTime: !already,
      newBest: false,
      lanternEarned: lantern,
      newSeals: earned,
      streak: streak,
    );
  }

  Future<List<String>> _checkSeals() async {
    final have = seals;
    final done = completed;
    final free = _ints(_lanternFree);
    final want = <String>{
      if (done.isNotEmpty) 'first',
      for (final c in chapters)
        if (nightsInChapter(c.index).every((n) => done.contains(n.id)))
          'ch${c.index}',
      if (flawlessNights.length >= 5) 'flawless5',
      if (flawlessNights.length >= 20) 'flawless20',
      if (chapters.any((c) =>
          nightsInChapter(c.index).every((n) => free.contains(n.id))))
        'dark',
      if (dailyCount >= 1) 'daily1',
      if (dailyBest >= 3) 'streak3',
      if (dailyBest >= 7) 'streak7',
      if (done.length >= nights.length) 'atlas',
    };
    final fresh = [
      for (final s in sealDefs)
        if (want.contains(s.id) && !have.contains(s.id)) s.id,
    ];
    if (fresh.isNotEmpty) {
      await _prefs.setStringList(_seals, [...have, ...fresh]);
    }
    return fresh;
  }

  /// Forget all progress (settings are kept).
  Future<void> resetProgress() async {
    for (final k in [
      _completed, _scores, _flawless, _lanternFree, _lifetime, _lanterns,
      _seals, _dailyLast, _dailyStreak, _dailyBest, _dailyCount, _guideSeen,
    ]) {
      await _prefs.remove(k);
    }
    notifyListeners();
  }
}
