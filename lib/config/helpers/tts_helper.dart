import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';

class TextToSpeechService {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool canCheck = true;

  // Private constructor to prevent instantiation
  TextToSpeechService._();

  // Initialization method that needs to be called once, typically in main.dart
  static Future<void> initialize() async {
    if (Platform.isIOS) {
      await _flutterTts.setSharedInstance(true);
      await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.duckOthers,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers
          ],
          IosTextToSpeechAudioMode.defaultMode,
      );
    }

    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.525);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.awaitSpeakCompletion(true);

    _flutterTts.setCompletionHandler(() {
      if (!canCheck) {
        canCheck = true;
      }
    });
  }

  // Static method to speak text
  static Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    }
  }

  // Static method to stop speaking
  static Future<void> stop() async {
    await _flutterTts.stop();
  }
}