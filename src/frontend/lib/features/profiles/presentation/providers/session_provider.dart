import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/child_profile.dart';
import '../../domain/repositories/child_profile_repository.dart';

/// Sesión activa: el chico elegido en el selector (RF2.2).
///
/// La app SIEMPRE arranca en el selector, nunca modo "último chico" (RF2.1).
/// REQ-PER-01: igual queda persistido el id del último chico activo de cada
/// cuenta (`pictocomm.last_child_<accountId>`; sin cuenta,
/// `pictocomm.last_child_legacy`), para MARCAR su tarjeta en el selector.
/// La preselección es solo visual: activar la sesión sigue exigiendo el tap.
class SessionProvider extends ChangeNotifier {
  SessionProvider({ChildProfileRepository? childProfileRepository})
      : _childProfileRepository = childProfileRepository; // ignore: prefer_initializing_formals

  /// REQ-PER-01: persistencia de la preselección. `null` en tests sin
  /// storage: el cambio de sesión igual funciona, solo no se recuerda.
  final ChildProfileRepository? _childProfileRepository;

  ChildProfile? _activeChild;

  /// REQ-PER-01: id del último chico activo (persistido por cuenta). No
  /// activa la sesión; el selector lo usa para distinguir su tarjeta.
  String? _lastChildId;

  /// Chico de la sesión en curso; null si todavía no se eligió, o si
  /// su perfil fue borrado (RF2.8).
  ChildProfile? get activeChild => _activeChild;

  /// REQ-PER-01: el último chico activo de la cuenta, para la marca visual
  /// del selector. `null` si nunca hubo (o el chico fue borrado).
  String? get lastChildId => _lastChildId;

  void setActiveChild(ChildProfile child) {
    _activeChild = child;
    // REQ-PER-01: el chico activo pasa a ser el marcado de su cuenta.
    _lastChildId = child.id;
    _persistLastChildId(child.id, child.accountId);
    notifyListeners();
  }

  /// REQ-PER-01: restauración de la preselección (la llama el
  /// ChildrenProvider cuando terminan de cargar los chicos de la cuenta).
  /// Solo marca: NO activa la sesión ni toca la clave persistida acá
  /// (la limpieza del chico borrado la maneja el ChildrenProvider).
  void setLastChildId(String? id) {
    if (_lastChildId == id) {
      return;
    }
    _lastChildId = id;
    notifyListeners();
  }

  /// Al borrar un perfil, se limpia la sesión si era el chico activo.
  /// REQ-PER-01: si además era el chico marcado, la clave persistida se
  /// limpia también (ya no existe a quién preseleccionar).
  void clearIfDeleted(String id) {
    if (_activeChild?.id != id) {
      return;
    }
    final accountId = _activeChild!.accountId;
    final wasMarked = _lastChildId == id;
    _activeChild = null;
    if (wasMarked) {
      _lastChildId = null;
      _persistLastChildId(null, accountId);
    }
    notifyListeners();
  }

  /// REQ-ACC-01 (RF-6.5): al cerrar sesión, el chico activo deja de existir
  /// (el próximo login arranca de nuevo en el selector).
  /// REQ-PER-01: la clave persistida NO se limpia (es por cuenta): si la
  /// misma cuenta vuelve a entrar, su tarjeta reaparece marcada. Solo se
  /// resetea el estado en memoria para que otra cuenta no herede la marca.
  void clear() {
    final hadState = _activeChild != null || _lastChildId != null;
    _activeChild = null;
    _lastChildId = null;
    if (hadState) {
      notifyListeners();
    }
  }

  /// REQ-PER-01: persistencia best-effort, como el sync (RF-5.10): si el
  /// storage falla, la app sigue (solo se pierde la preselección).
  void _persistLastChildId(String? childId, String? accountId) {
    final repository = _childProfileRepository;
    if (repository == null) {
      return;
    }
    unawaited(
      repository.setLastChildId(childId, accountId: accountId).catchError((Object _) {
        // Sin preselección recordada: no rompe el flujo del selector.
      }),
    );
  }
}
