import 'package:flutter/foundation.dart';

import '../../domain/entities/child_profile.dart';

/// Sesión activa: el chico elegido en el selector (RF2.2).
///
/// Es estado a nivel app y no se persiste: cada apertura de la app
/// arranca en el selector, nunca modo "último chico" (RF2.1).
class SessionProvider extends ChangeNotifier {
  ChildProfile? _activeChild;

  /// Chico de la sesión en curso; null si todavía no se eligió, o si
  /// su perfil fue borrado (RF2.8).
  ChildProfile? get activeChild => _activeChild;

  void setActiveChild(ChildProfile child) {
    _activeChild = child;
    notifyListeners();
  }

  /// Al borrar un perfil, se limpia la sesión si era el chico activo.
  void clearIfDeleted(String id) {
    if (_activeChild?.id == id) {
      _activeChild = null;
      notifyListeners();
    }
  }
}
