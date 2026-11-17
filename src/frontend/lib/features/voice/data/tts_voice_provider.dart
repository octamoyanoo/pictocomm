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

  /// Idioma pedido por la UI (RF1.11); español por defecto hasta que la
  /// pantalla lo aplique antes de la primera reproducción.
  String _languageCode = 'es';

  /// Preferencia de idioma por código de UI (RF1.11): variantes regionales
  /// en orden de preferencia. Si ninguna variante del idioma está instalada
  /// se deja la voz configurada en el sistema, sin error.
  static const Map<String, List<String>> _languagePreferences = <String, List<String>>{
    'es': <String>['es-AR', 'es-MX', 'es-ES'],
    'en': <String>['en-US', 'en-GB'],
    'pt': <String>['pt-BR', 'pt-PT'],
  };

  /// Ritmo pausado: la audiencia tiene 2 a 5 años (RF1.10).
  static const double _speechRate = 0.5;

  /// `speak()` solo completa cuando la locución termina: es lo que permite
  /// encadenar palabra por palabra en la barra de frase.
  bool _speaking = false;
  bool _configured = false;

  @override
  Future<void> setLanguage(String languageCode) async {
    if (!_languagePreferences.containsKey(languageCode)) {
      return;
    }
    _languageCode = languageCode;
    if (_configured) {
      await _applyLanguage();
    }
  }

  /// Aplica el idioma pedido probando sus variantes en orden. Silencioso
  /// por diseño (RF1.11): sin variantes instaladas (o sin engine accesible
  /// todavía) se conserva la voz del sistema; el error real lo reporta
  /// `speak` si corresponde.
  Future<void> _applyLanguage() async {
    for (final language in _languagePreferences[_languageCode] ?? const <String>[]) {
      try {
        if (await _tts.isLanguageAvailable(language) == true) {
          await _tts.setLanguage(language);
          return;
        }
      } on Object {
        return;
      }
    }
  }

  Future<void> _ensureConfigured() async {
    if (_configured) {
      return;
    }
    await _applyLanguage();
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
