import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ChatVoiceInput extends ChangeNotifier {
  ChatVoiceInput({required this.onText, required this.onError});

  final ValueChanged<String> onText;
  final ValueChanged<String> onError;
  final _speech = SpeechToText();
  bool _starting = false;
  bool _disposed = false;
  bool _ownsListeners = false;
  int _request = 0;

  bool get starting => _starting;
  bool get listening => _speech.isListening;

  Future<void> toggle(String draft) async {
    if (_starting) return;
    if (listening) {
      try {
        await _speech.stop();
      } catch (_) {
        if (!_disposed) onError('Không thể dừng nhập giọng nói.');
      }
      return;
    }
    final request = ++_request;
    _starting = true;
    notifyListeners();
    try {
      final available = await _speech.initialize(
        options: [SpeechToText.androidNoBluetooth],
      );
      if (_disposed || request != _request) return;
      if (!available) {
        onError(
          'Hãy cấp quyền micro và nhận dạng giọng nói trong cài đặt thiết bị.',
        );
        return;
      }
      _speech.statusListener = (_) {
        if (!_disposed) notifyListeners();
      };
      _speech.errorListener = (error) {
        if (_disposed ||
            request != _request ||
            error.errorMsg == 'error_no_match') {
          return;
        }
        onError(
          'Không nhận được giọng nói. Bạn có thể thử lại hoặc nhập câu hỏi.',
        );
      };
      _ownsListeners = true;
      final locales = await _speech.locales();
      if (_disposed || request != _request) return;
      final vietnamese = locales
          .where((locale) => locale.localeId.toLowerCase().startsWith('vi'))
          .firstOrNull;
      final prefix = draft.trim();
      await _speech.listen(
        listenOptions: SpeechListenOptions(
          localeId: vietnamese?.localeId ?? 'vi_VN',
          listenFor: const Duration(seconds: 20),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
        ),
        onResult: (result) {
          if (_disposed ||
              request != _request ||
              result.recognizedWords.isEmpty) {
            return;
          }
          final text = prefix.isEmpty
              ? result.recognizedWords
              : '$prefix ${result.recognizedWords}';
          onText(String.fromCharCodes(text.runes.take(500)));
        },
      );
    } catch (_) {
      if (!_disposed && request == _request) {
        onError('Không thể mở micro. Bạn có thể tiếp tục nhập bằng bàn phím.');
      }
    } finally {
      if (!_disposed && request == _request) {
        _starting = false;
        notifyListeners();
      }
    }
  }

  void cancel() {
    _request++;
    _starting = false;
    if (_ownsListeners && _speech.isListening) unawaited(_speech.cancel());
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    cancel();
    if (_ownsListeners) {
      _speech.statusListener = null;
      _speech.errorListener = null;
    }
    super.dispose();
  }
}
