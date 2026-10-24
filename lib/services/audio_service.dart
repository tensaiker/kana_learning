import 'package:flutter_tts/flutter_tts.dart';
import '../utils/tactile_feedback.dart';

/// Centralized audio controller using the device's native speech engine (TTS).
/// Generates authentic Kana pronunciation on the fly without requiring local MP3 assets.
class AudioService {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isInitialized = false;

  /// Lazy-initializes the TTS engine calibrated specifically for Japanese audio output.
  static Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    // Set voice locale to Japanese
    await _flutterTts.setLanguage('ja-JP');

    // Speech rate: 0.45 provides clear, deliberate pronunciation ideal for learners
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // iOS configuration: Route audio to speaker even if hardware mute switch is engaged
    await _flutterTts
        .setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
        ]);

    // Wait for ongoing speech to conclude before subsequent triggers
    await _flutterTts.awaitSpeakCompletion(true);

    _isInitialized = true;
  }

  /// Speaks the given Japanese Kana character (e.g., 'あ', 'カ', 'が', 'ぱ').
  ///
  /// Safe to call repeatedly: interrupts prior unfinished utterances to avoid audio queue lag.
  static Future<void> speakKana(String kana) async {
    // Respect the user's global sound FX toggle
    if (!TactileFeedback.soundEnabled || kana.trim().isEmpty) return;

    try {
      await _ensureInitialized();

      // Halt any ongoing utterance immediately
      await _flutterTts.stop();

      // Synthesize and speak the character
      await _flutterTts.speak(kana);
    } catch (_) {
      // Fail silently if TTS is unsupported or missing engine packages on the host device
    }
  }

  /// Backward-compatible alias for callers still invoking `playKanaAudio`.
  static Future<void> playKanaAudio(String kana) async {
    await speakKana(kana);
  }

  /// Halts speech synthesis and releases active resources.
  static Future<void> dispose() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }
}
