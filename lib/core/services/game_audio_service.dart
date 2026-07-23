import 'package:audioplayers/audioplayers.dart';

// ══════════════════════════════════════════════════════════════════
//  GAME AUDIO SERVICE — Voice callouts for game actions
//
//  Plays short voice clips (English or Arabic) when players bid,
//  declare projects, or trigger other game events. Clips live in:
//    • assets/audio/en/voice1/  (English pack)
//    • assets/audio/ar/voice1/  (Arabic pack)
//
//  Both packs share identical filenames so switching language
//  only changes the base path.
// ══════════════════════════════════════════════════════════════════

class GameAudioService {
  final AudioPlayer _player = AudioPlayer();
  bool _muted = false;

  /// Current language code: 'en' or 'ar'
  String _langCode = 'en';

  bool get isMuted => _muted;
  String get langCode => _langCode;

  void setMuted(bool muted) {
    _muted = muted;
    if (muted) _player.stop();
  }

  void toggleMute() => setMuted(!_muted);

  /// Switch voice pack language. Call this when the user toggles locale.
  /// Both 'en' and 'ar' voice packs use the same filenames.
  void setLanguage(String langCode) {
    _langCode = langCode;
  }

  // ── Bubble key → audio file mapping ──
  // Keys match the English tokens passed to GameProvider._showBubble()
  static const Map<String, String> _bubbleToFile = {
    'Hakam':  'hokum.mp3',
    'Sun':    'sun.mp3',
    'Pass':   'pass.mp3',
    'PassR2': 'pass.mp3',      // Same clip for both pass types
    'Double': 'double.mp3',
    'Triple': 'triple.mp3',
    'Four':   'four.mp3',
    'Baloot': 'baloot.mp3',
    'Ashkal': 'ashkal.mp3',
    'Sera':   'sera.mp3',
    '50':     'fifty.mp3',
    '100':    'hundread.mp3',
    '400':    '400.mp3',
    'Akka':   'akka.mp3',
    'Awal':   'awal.mp3',
    'Thani':  'thani.mp3',
    'Qaid':   'locked.mp3',    // "Locked" voice for leading a trick
  };

  // ── Special event clips (not tied to bubble keys) ──
  static const String _yourTurnFile         = 'your_turn.mp3';
  static const String _youWinFile           = 'you_win.mp3';
  static const String _youLoseFile          = 'better_luck_next_time.mp3';
  static const String _wellDoneFile         = 'well_done.mp3';
  static const String _kablootFile          = 'kabloot.mp3';
  static const String _ghawaFile            = 'ghawa.mp3';

  /// Dynamic base path — switches between en/ar based on current language.
  String get _basePath => 'audio/$_langCode/voice1';

  /// Play the voice clip associated with a speech bubble key.
  /// Silently no-ops if the key has no mapped file or audio is muted.
  void playBubble(String bubbleKey) {
    if (_muted) return;

    // Handle "Hakam ♠" style keys (strip the suit symbol)
    String key = bubbleKey;
    if (key.startsWith('Hakam ') && key.length > 6) {
      key = 'Hakam';
    }

    String? file = _bubbleToFile[key];

    // Robust fuzzy & substring matching for Arabic tokens, suit suffixes,
    // compound declarations ('Sera & 50'), and custom bidding tokens ('Qabalk')
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
      } else if (k.contains('sun') || k.contains('صن') || k.contains('qabalk') || k.contains('قبلك')) {
        file = 'sun.mp3';
      } else if (k.contains('hakam') || k.contains('حكم') || k.contains('hokum')) {
        file = 'hokum.mp3';
      } else if (k.contains('double') || k.contains('دبل') || k.contains('دابل')) {
        file = 'double.mp3';
      } else if (k.contains('triple') || k.contains('تربل')) {
        file = 'triple.mp3';
      } else if (k.contains('four') || k.contains('أربعة')) {
        file = 'four.mp3';
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
    _playAsset(file);
  }

  /// Play "Your turn" notification.
  void playYourTurn() => _playAsset(_yourTurnFile);

  /// Play "You win!" victory clip.
  void playYouWin() => _playAsset(_youWinFile);

  /// Play "Better luck next time" defeat clip.
  void playYouLose() => _playAsset(_youLoseFile);

  /// Play "Well done" positive reinforcement.
  void playWellDone() => _playAsset(_wellDoneFile);

  /// Play "Kabloot" when a kaboot penalty is triggered.
  void playKabloot() => _playAsset(_kablootFile);

  /// Play "Ghawa" social/celebration voice clip.
  void playGhawa() => _playAsset(_ghawaFile);

  void _playAsset(String fileName) {
    if (_muted) return;
    // Stop any currently playing clip to avoid overlap
    _player.stop();
    _player.play(AssetSource('$_basePath/$fileName'));
  }

  /// Stop any currently playing audio clip immediately.
  void stop() {
    _player.stop();
  }

  /// Release the audio player resources.
  void dispose() {
    _player.dispose();
  }
}
