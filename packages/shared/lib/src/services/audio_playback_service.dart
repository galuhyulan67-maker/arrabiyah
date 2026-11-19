import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AudioPlaybackService {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _player = AudioPlayer();
  bool _slowMode = false;
  bool _isPlaying = false;

  bool get isSlowMode => _slowMode;
  bool get isPlaying => _isPlaying;

  Future<void> init() async {
    await _tts.setLanguage('ar-SA');
    await _applyRate();
  }

  Future<void> setSlowMode(bool slow) async {
    _slowMode = slow;
    await _applyRate();
  }

  Future<void> _applyRate() async {
    final rate = _slowMode ? 0.35 : 0.5;
    await _tts.setSpeechRate(rate);
    await _player.setPlaybackRate(_slowMode ? 0.7 : 1.0);
  }

  Future<void> playItem({required String arabicText, String? audioUrl}) async {
    await stop();
    _isPlaying = true;
    if (audioUrl != null && audioUrl.isNotEmpty) {
      await _player.play(UrlSource(audioUrl));
      await _player.onPlayerComplete.first;
    } else {
      await _tts.speak(arabicText);
    }
    _isPlaying = false;
  }

  Future<void> playAll(List<({String arabicText, String? audioUrl})> items,
      {void Function(int index)? onIndexChanged}) async {
    await stop();
    for (int i = 0; i < items.length; i++) {
      onIndexChanged?.call(i);
      await playItem(arabicText: items[i].arabicText, audioUrl: items[i].audioUrl);
    }
    onIndexChanged?.call(-1);
  }

  Future<void> stop() async {
    _isPlaying = false;
    await _tts.stop();
    await _player.stop();
  }
}
