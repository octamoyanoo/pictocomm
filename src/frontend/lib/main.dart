import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/di/injector.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Bloquear rotación: el niño no debería girar el dispositivo y perder el
  // tablero. En landscape el layout también se rompería.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(PictoCommApp(dependencies: AppDependencies.production()));
}
