import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Idioma de la interfaz (RF4): decisión transversal del dispositivo, no de
/// una feature. El adulto lo elige en Perfil (RF4.2), se persiste local y la
/// app arranca siempre en el idioma guardado (RF4.4); sin configuración,
/// usa el idioma del sistema si está soportado y cae al español (RF4.5).
///
/// No conoce la UI: solo guarda el `Locale` concreto. El MaterialApp lo lee
/// y el cambio aplica al instante (RF4.3) porque `notifyListeners` reconstruye
/// el árbol por encima de las rutas.
final class LocaleController extends ChangeNotifier {
  LocaleController({required this.preferences, required Locale systemLocale}) {
    _locale = _load() ?? _resolveDefault(systemLocale);
  }

  /// Sin persistencia, para arranques de prueba (tests): español fijo, los
  /// `setLanguage` no tocan storage.
  LocaleController.ephemeral() : preferences = null {
    _locale = const Locale('es');
  }

  static const String _storageKey = 'pictocomm.ui_locale';

  /// Códigos soportados (RF4.1): español (default), inglés y portugués.
  static const Set<String> supportedLanguageCodes = <String>{'es', 'en', 'pt'};

  final SharedPreferences? preferences;

  Locale _locale = const Locale('es');

  Locale get locale => _locale;

  String get languageCode => _locale.languageCode;

  bool isSupported(String code) => supportedLanguageCodes.contains(code);

  void setLanguage(String code) {
    if (!isSupported(code) || _locale.languageCode == code) {
      return;
    }
    _locale = Locale(code);
    preferences?.setString(_storageKey, code);
    notifyListeners();
  }

  Locale? _load() {
    final code = preferences?.getString(_storageKey);
    if (code == null || !supportedLanguageCodes.contains(code)) {
      return null;
    }
    return Locale(code);
  }

  Locale _resolveDefault(Locale? systemLocale) {
    final code = systemLocale?.languageCode;
    if (code != null && supportedLanguageCodes.contains(code)) {
      return Locale(code);
    }
    return const Locale('es');
  }
}
