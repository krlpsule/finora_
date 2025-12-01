import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _available = false;

  Future<bool> init() async {
    _available = await _speech.initialize();
    return _available;
  }

  void startListening(Function(String) onResult) {
    if (!_available) return;
    _speech.listen(onResult: (result) {
      if (result.finalResult) onResult(result.recognizedWords);
      else onResult(result.recognizedWords);
    });
  }

  void stopListening() {
    _speech.stop();
  }

  bool get isListening => _speech.isListening;
}
