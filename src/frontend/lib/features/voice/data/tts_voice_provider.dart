import 'package:flutter_tts/flutter_tts.dart';

import '../../../../core/error/app_exception.dart';
import '../domain/voice_provider.dart';
/// Voz v1 (RF1.10): TTS del sistema, ejecutado en el dispositivo.
///
/// Debe cumplir RF1.11: es solo una de las posibles implementaciones de
/// [VoiceProvider]; ninguna pantalla conoce esta clase.
///
/// Por qué tradicional `class` y no `final`:
/// `flutter_tts` es un plugin con canal de plataforma, por lo que un singleton
/// por instancia es lo esperable; no agrega estado visible más allá del engine.
class TtsVoiceProvider implements VoiceProvider {
  TtsVoiceProvider() {
    _tts.setStartHandler(() => _speaking = true);
    _tts.setCompletionHandler(() => _speaking = false);
    _tts.setErrorHandler((message) => _speaking = false);
    _tts.setCancelHandler(() => _speaking = false);
  }

  final FlutterTts _tts = FlutterTts();

  /// Preferencia de idioma, español con variantes; si ninguna está instalada
  /// se deja la voz configurada en el sistema.
  static const List<String> _languagePreferences = <String>['es-AR', 'es-MX', 'es-ES'];

  /// Ritmo pausado: la audiencia tiene 2 a 5 años (RF1.10).
  static const double _speechRate = 0.5;

  /// `speak()` solo completa cuando la locución termina: es lo que permite
  /// encadenar palabra por palabra en la barra de frase.
  bool _speaking = false;
  bool _configured = false;

  Future<void> _ensureConfigured() async {
    if (_configured) {
      return;
    }
    for (final language in _languagePreferences) {
      if (await _tts.isLanguageAvailable(language) == true) {
        await _tts.setLanguage(language);
        break;
      }
    }
    await _tts.setSpeechRate(_speechRate);
    await _tts.awaitSpeakCompletion(true);
    _configured = true;
  }

  @override
  Future<void> speak(String word) async {
    final text = word.trim();
    if (text.isEmpty) {
      throw const VoiceException('No se puede pronunciar un texto vacío');
    }
    try {
      await _ensureConfigured();
      _speaking = true;
      await _tts.speak(text);
    } on Object catch (error) {
      _speaking = false;
      throw VoiceException('No se pudo pronunciar "$text": $error');
    } finally {
      _speaking = false;
    }
  }

  @override
  Future<void> stop() async {
    if (!_speaking) {
      return;
    }
    await _tts.stop();
  }

  @override
  Future<void> dispose() => _tts.stop();
}
