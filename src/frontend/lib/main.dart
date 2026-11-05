import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/di/injector.dart';
import 'core/i18n/locale_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(<DeviceOrientation>[DeviceOrientation.portraitUp]);
  // RF4.4: el idioma de la UI se resuelve ANTES del primer frame; la app
  // arranca siempre en el idioma guardado (RF4.5 fallback: sistema/es).
  final preferences = await SharedPreferences.getInstance();
  final localeController = LocaleController(
    preferences: preferences,
    systemLocale: WidgetsBinding.instance.platformDispatcher.locale,
  );
  runApp(PictoCommApp(dependencies: AppDependencies.bootstrap(), localeController: localeController));
}
