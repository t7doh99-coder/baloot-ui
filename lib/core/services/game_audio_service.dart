import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

// ══════════════════════════════════════════════════════════════════
//  GAME AUDIO SERVICE — Voice callouts and sound effects
//
//  Two separate strategies:
//
//  Strategy A — VOICE CALLS (playBubble, playYourTurn, etc.)
//    • Single persistent AudioPlayer with ReleaseMode.stop
//    • Calls .stop() before every .play() to reset from completed state
//    • New voice interrupts previous one (intentional behaviour)
//
//  Strategy B — SOUND EFFECTS (playEffect)
//    • Fresh AudioPlayer created on every call
//    • ReleaseMode.release so player auto-disposes when sound ends
//    • Guaranteed to play every time — no shared state, no pool conflicts
//
//  Card Select — DEDICATED PLAYER
//    • Single persistent AudioPlayer for card select/deselect sounds
//    • Stops previous sound before playing new one (no stacking)
//    • Prevents sounds from continuing after match ends
// ══════════════════════════════════════════════════════════════════

class GameAudioService {
  bool _muted = false;

  /// Current language code: 'en' or 'ar'
  String _langCode = 'en';

  bool get isMuted => _muted;
  String get langCode => _langCode;

  /// Dedicated player for card select/deselect — reused to prevent stacking.
  AudioPlayer? _cardSelectPlayer;

  GameAudioService();

  void setMuted(bool muted) {
    _muted = muted;
  }

  void toggleMute() => setMuted(!_muted);

  /// Switch voice pack language. Call this when the user toggles locale.
  void setLanguage(String langCode) {
    _langCode = langCode;
  }

  // ── Bubble key → audio file mapping ──
  static const Map<String, String> _bubbleToFile = {
    'Hakam':  'hokum.mp3',
    'Sun':    'sun.mp3',
    'Pass':   'pass.mp3',
    'PassR2': 'wala.mp3',
    'Double': 'double.mp3',
    'Triple': 'triple.mp3',
    'Four':   'four.mp3',
    'Gahwa':  'ghawa.mp3',
    'Sawa':   'ghawa.mp3',
    'Baloot': 'baloot.mp3',
    'Ashkal': 'ashkal.mp3',
    'Qablak': 'qablak.mp3',
    'Sera':   'sera.mp3',
    '50':     'fifty.mp3',
    '100':    'hundread.mp3',
    '400':    '400.mp3',
    'Akka':   'akka.mp3',
    'Awal':   'awal.mp3',
    'Thani':  'thani.mp3',
    'Qaid':   'locked.mp3',
  };

  // ── Special event clips ──
  static const String _yourTurnFile = 'your_turn.mp3';
  static const String _youWinFile   = 'you_win.mp3';
  static const String _youLoseFile  = 'better_luck_next_time.mp3';
  static const String _wellDoneFile = 'well_done.mp3';
  static const String _kablootFile  = 'kabloot.mp3';
  static const String _ghawaFile    = 'ghawa.mp3';

  /// Dynamic base path — switches between en/ar based on current language.
  String get _basePath => 'audio/$_langCode/voice1';

  /// Play the voice clip associated with a speech bubble key.
  void playBubble(String bubbleKey) {
    if (_muted) return;

    // Handle "Hakam ♠" style keys (strip the suit symbol)
    String key = bubbleKey;
    if (key.startsWith('Hakam ') && key.length > 6) {
      key = 'Hakam';
    }

    String? file = _bubbleToFile[key];

    if (file == null) {
      final k = bubbleKey.toLowerCase();
      if (k.contains('سرا') || k.contains('sera')) {
        file = 'sera.mp3';
      } else if (k.contains('400') || k.contains('أربعمائة')) {
        file = '400.mp3';
      } else if (k.contains('100') || k.contains('مائة')) {
        file = 'hundread.mp3';
      } else if (k.contains('50') || k.contains('خمسون')) {
        file = 'fifty.mp3';
      } else if (k.contains('baloot') || k.contains('بلوت')) {
        file = 'baloot.mp3';
      } else if (k.contains('akka') || k.contains('عكّة') || k.contains('عكة')) {
        file = 'akka.mp3';
      } else if (k.contains('ashkal') || k.contains('أشكال')) {
        file = 'ashkal.mp3';
      } else if (k.contains('qabalk') || k.contains('qablak') || k.contains('قبلك')) {
        file = 'qablak.mp3';
      } else if (k.contains('sun') || k.contains('صن')) {
        file = 'sun.mp3';
      } else if (k.contains('hakam') || k.contains('حكم') || k.contains('hokum')) {
        file = 'hokum.mp3';
      } else if (k.contains('double') || k.contains('دبل') || k.contains('دابل')) {
        file = 'double.mp3';
      } else if (k.contains('triple') || k.contains('تربل')) {
        file = 'triple.mp3';
      } else if (k.contains('four') || k.contains('أربعة')) {
        file = 'four.mp3';
      } else if (k.contains('gahwa') || k.contains('قهوة') || k.contains('ghawa')) {
        file = 'ghawa.mp3';
      } else if (k.contains('passr2') || k.contains('wala') || k.contains('ولا')) {
        file = 'wala.mp3';
      } else if (k.contains('pass') || k.contains('بس')) {
        file = 'pass.mp3';
      } else if (k.contains('awal') || k.contains('أول')) {
        file = 'awal.mp3';
      } else if (k.contains('thani') || k.contains('ثاني')) {
        file = 'thani.mp3';
      } else if (k.contains('qaid') || k.contains('قائد') || k.contains('locked')) {
        file = 'locked.mp3';
      }
    }

    if (file == null) return;
    _playVoice(file);
  }

  void playYourTurn() => _playVoice(_yourTurnFile);
  void playYouWin()   => _playVoice(_youWinFile);
  void playYouLose()  => _playVoice(_youLoseFile);
  void playWellDone() => _playVoice(_wellDoneFile);
  void playKabloot()  => _playVoice(_kablootFile);
  void playGhawa()    => _playVoice(_ghawaFile);

  // Pool of persistent players for voices. Allows overlapping voices (like rapid bot bids)
  // without exhausting the native audio track limit (which happens if we spawn a new player every time).
  final List<AudioPlayer> _voicePlayers = [];
  int _nextVoicePlayerIndex = 0;
  static const int _maxVoicePlayers = 2;

  // ── Voice playback — round-robin pool to allow overlap safely ──
  void _playVoice(String fileName) {
    if (_muted) return;

    try {
      if (_voicePlayers.isEmpty) {
        _voicePlayers.add(AudioPlayer()..setReleaseMode(ReleaseMode.stop));
      } else if (_voicePlayers.length < _maxVoicePlayers &&
          _nextVoicePlayerIndex == 0) {
        _voicePlayers.add(AudioPlayer()..setReleaseMode(ReleaseMode.stop));
      }

      final player = _voicePlayers[_nextVoicePlayerIndex % _voicePlayers.length];
      _nextVoicePlayerIndex = (_nextVoicePlayerIndex + 1) % _voicePlayers.length;

      player.play(AssetSource('$_basePath/$fileName')).catchError((e) {
        debugPrint('[Audio] playVoice error ($fileName): $e');
      });
    } catch (e) {
      debugPrint('[Audio] playVoice setup error ($fileName): $e');
    }
  }

  // ── Card select sound — single player, interrupts previous ──
  /// Play the card select/deselect sound.
  /// Uses a dedicated persistent player: if the previous sound is still
  /// playing, it is stopped first. This prevents sound stacking on rapid taps.
  void playCardSelect() {
    if (_muted) return;

    _cardSelectPlayer ??= AudioPlayer()..setReleaseMode(ReleaseMode.stop);

    // AudioPlayer.play() automatically and safely stops the previous playback
    // at the native level. Calling stop() manually with async chains causes
    // state-machine crashes if the user rapidly spams the card selection.
    _cardSelectPlayer!.play(AssetSource('audio/effects/card select sound.mp3')).catchError((e) {
      debugPrint('[Audio] playCardSelect error: $e');
    });
  }

  // Pool of persistent players for sound effects (cards, UI).
  // Keep this SMALL — spawning many AudioPlayers at once OOMs / stalls
  // native audio on low-end Samsung A-series and can leave the game hung
  // during the opening deal.
  final List<AudioPlayer> _effectPlayers = [];
  int _nextEffectPlayerIndex = 0;
  static const int _maxEffectPlayers = 2;

  // ── Sound effects — round-robin pool to guarantee overlapping without crashing ──
  /// Play a sound effect from the effects folder safely.
  void playEffect(String fileName) {
    if (_muted) return;

    try {
      if (_effectPlayers.isEmpty) {
        // Create one player first; grow lazily up to [_maxEffectPlayers].
        _effectPlayers.add(AudioPlayer()..setReleaseMode(ReleaseMode.stop));
      } else if (_effectPlayers.length < _maxEffectPlayers &&
          _nextEffectPlayerIndex == 0) {
        _effectPlayers.add(AudioPlayer()..setReleaseMode(ReleaseMode.stop));
      }

      final player = _effectPlayers[_nextEffectPlayerIndex % _effectPlayers.length];
      _nextEffectPlayerIndex =
          (_nextEffectPlayerIndex + 1) % _effectPlayers.length;

      player.play(AssetSource('audio/effects/$fileName')).catchError((e) {
        debugPrint('[Audio] playEffect error ($fileName): $e');
      });
    } catch (e) {
      debugPrint('[Audio] playEffect setup error ($fileName): $e');
    }
  }

  /// Play the golden game button touch sound
  void playGoldButton() => playEffect('golen gaem button touch sound.mp3');

  /// Play the normal game button touch sound
  void playNormalButton() => playEffect('normal game button touch sound.mp3');

  /// Stop all currently playing audio immediately.
  void stop() {
    // Stop the dedicated players
    _cardSelectPlayer?.stop();
    for (final player in _voicePlayers) {
      player.stop();
    }
    for (final player in _effectPlayers) {
      player.stop();
    }
  }

  /// Release all audio player resources.
  void dispose() {
    stop();
    _cardSelectPlayer?.dispose();
    _cardSelectPlayer = null;
    
    for (final player in _voicePlayers) {
      player.dispose();
    }
    _voicePlayers.clear();
    
    for (final player in _effectPlayers) {
      player.dispose();
    }
    _effectPlayers.clear();
  }
}
