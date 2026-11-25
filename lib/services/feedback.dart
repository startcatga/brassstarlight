import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/progress_store.dart';

/// Sound, ambience and haptics, all respecting the Observatory Tools toggles.
class SkyFeedback {
  SkyFeedback(this._progress) {
    _progress.addListener(_syncAmbience);
  }

  /// Tests switch audio off so no platform channels are touched.
  static bool audioEnabled = true;

  final ProgressStore _progress;
  final List<AudioPlayer> _pool = [];
  int _next = 0;
  AudioPlayer? _ambient;
  bool _ambientWanted = false;

  AudioPlayer _player() {
    if (_pool.length < 6) {
      final p = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      _pool.add(p);
      return p;
    }
    _next = (_next + 1) % _pool.length;
    return _pool[_next];
  }

  Future<void> _play(String file, {double volume = 1}) async {
    if (!audioEnabled || !_progress.sounds) return;
    try {
      final p = _player();
      await p.stop();
      await p.play(AssetSource('sfx/$file'), volume: volume);
    } catch (e) {
      debugPrint('sound $file failed: $e');
    }
  }

  Future<void> _haptic(Future<void> Function() f) async {
    if (!audioEnabled || !_progress.haptics) return;
    await f();
  }

  /// [step] is how many stars/lines are linked so far; the chime climbs.
  void starLinked(int step) {
    _play('star_${step.clamp(0, 11)}.wav', volume: 0.8);
    _haptic(HapticFeedback.selectionClick);
  }

  void lineBroken() {
    _play('broken.wav', volume: 0.7);
    _haptic(HapticFeedback.lightImpact);
  }

  void decoyTouched() {
    _play('decoy.wav', volume: 0.8);
    _haptic(HapticFeedback.lightImpact);
  }

  void sealed() {
    _play('seal.wav');
    _haptic(HapticFeedback.mediumImpact);
  }

  void unlocked() => _play('unlock.wav', volume: 0.8);
  void lantern() => _play('lantern.wav', volume: 0.8);
  void page() => _play('page.wav', volume: 0.6);

  void tap() {
    _play('tap.wav', volume: 0.6);
    _haptic(HapticFeedback.selectionClick);
  }

  // ── ambience ──────────────────────────────────────────────────────────
  /// Called by screens that want the night bed (hub, log, deck).
  void wantAmbience(bool on) {
    _ambientWanted = on;
    _syncAmbience();
  }

  void pauseAmbience() => _ambient?.pause();

  Future<void> _syncAmbience() async {
    if (!audioEnabled) return;
    final play = _ambientWanted && _progress.ambience;
    try {
      if (play) {
        if (_ambient == null) {
          final a = AudioPlayer();
          _ambient = a;
          await a.setReleaseMode(ReleaseMode.loop);
          await a.play(AssetSource('sfx/night.ogg'), volume: 0.35);
        } else if (_ambient!.state != PlayerState.playing) {
          await _ambient!.resume();
        }
      } else {
        await _ambient?.pause();
      }
    } catch (e) {
      debugPrint('ambience failed: $e');
    }
  }
}
