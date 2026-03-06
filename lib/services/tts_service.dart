import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// TTSService - Singleton text-to-speech service for voice feedback
class TTSService {
  static TTSService? _instance;
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  TTSService._();

  static TTSService get instance {
    _instance ??= TTSService._();
    return _instance!;
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45); // Slightly slower for children
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.1); // Slightly higher pitch, friendlier
      _initialized = true;
    } catch (e) {
      debugPrint('TTS init error: $e');
    }
  }

  /// Speak a message aloud
  Future<void> speak(String text) async {
    try {
      await _ensureInitialized();
      await _tts.stop(); // Stop any current speech
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  /// Stop any current speech
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }

  /// Speak "Good job!" encouragement for success
  Future<void> speakSuccess([String? customMessage]) async {
    final messages = [
      'Good job!',
      'Excellent!',
      'Well done!',
      'Fantastic!',
      'You did it!',
    ];
    final msg = customMessage ?? messages[DateTime.now().millisecond % messages.length];
    await speak(msg);
  }

  /// Speak "Try again!" for failure
  Future<void> speakTryAgain([String? customMessage]) async {
    final messages = [
      'Try again!',
      "Don't give up. Try once more!",
      'Almost there! Give it another try.',
      'Keep trying!',
    ];
    final msg = customMessage ?? messages[DateTime.now().millisecond % messages.length];
    await speak(msg);
  }

  /// Pronounce a number word (e.g. "one", "two", "three")
  Future<void> pronounceNumber(int number, String word) async {
    await speak(word);
  }

  void dispose() {
    _tts.stop();
  }
}
