import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' hide Category;

import '../../domain/entities/child_profile.dart';
import '../../domain/repositories/child_profile_repository.dart';
import 'session_provider.dart';

sealed class ChildrenState {
  const ChildrenState();
}

final class ChildrenLoadingState extends ChildrenState {
  const ChildrenLoadingState();
}

final class ChildrenLoadedState extends ChildrenState {
  const ChildrenLoadedState({required this.children});

  final List<ChildProfile> children;

  bool get isEmpty => children.isEmpty;
}

final class ChildrenFailureState extends ChildrenState {
  const ChildrenFailureState(this.message);

  final String message;
}

final /// REQ-ACC-01 (RF-6.6): los chicos que muestra dependen de la cuenta
/// logueada. `accountId` se inyecta al crear el provider (la ruta lo toma
/// del `AuthProvider`); `null` = sin sesión (gestión, ve todo).
class ChildrenProvider extends ChangeNotifier {
  ChildrenProvider({
    required this.childProfileRepository,
    this.accountId,
    this.sessionProvider,
  });

  final ChildProfileRepository childProfileRepository;

  /// Cuenta logueada cuyos perfiles gestiona este provider (RF-6.6).
  final String? accountId;

  /// REQ-PER-01: al cargar los chicos de la cuenta, restaura la marca del
  /// último chico activo en el [SessionProvider] de la app. `null` en tests
  /// que prueban el provider aislado: la carga funciona igual.
  final SessionProvider? sessionProvider;

  ChildrenState _state = const ChildrenLoadingState();

  ChildrenState get state => _state;

  Future<void> load() async {
    _state = const ChildrenLoadingState();
    notifyListeners();
    try {
      final children = await childProfileRepository.getChildren(accountId: accountId);
      // REQ-PER-01: con los chicos de la cuenta en mano se valida la marca
      // (si el chico persistido ya no existe, la clave queda limpia).
      await _restoreLastChild(children);
      _state = ChildrenLoadedState(children: children);
    } on Object catch (error) {
      _state = ChildrenFailureState(error.toString());
    }
    notifyListeners();
  }

  /// REQ-PER-01: restaura la preselección del último chico activo de la
  /// cuenta. NO activa la sesión (RF2.1): solo marca su tarjeta en el
  /// selector. Como los children ya vienen filtrados por cuenta (RF-6.6),
  /// una cuenta nunca preselecciona el chico de otra.
  Future<void> _restoreLastChild(List<ChildProfile> children) async {
    final session = sessionProvider;
    if (session == null) {
      return;
    }
    final lastId = await childProfileRepository.getLastChildId(accountId: accountId);
    if (lastId != null && children.every((child) => child.id != lastId)) {
      // El chico marcado fue borrado (quizás en otra sesión): sin marca y
      // fuera la clave persistida para que no quede basura.
      session.setLastChildId(null);
      try {
        await childProfileRepository.setLastChildId(null, accountId: accountId);
      } on Object catch (_) {
        // Best-effort (RF-5.10): quedará sin marca hasta la próxima carga.
      }
      return;
    }
    session.setLastChildId(lastId);
  }

  Future<ChildProfile> createChild(String name, int? age, int? avatarColorValue, String? photoUrl) async {
    // El color viaja como ARGB int para no arrastrar dart:ui a las llamadas
    // de alto nivel; el repositorio decide cómo persistirlo.
    final created = await childProfileRepository.createChild(
      ChildProfile(
        id: '',
        name: name,
        age: age,
        avatarColor: avatarColorValue == null ? null : Color(avatarColorValue),
        photoUrl: photoUrl,
      ),
      accountId: accountId,
    );
    await load();
    return created;
  }

  Future<void> deleteChild(String id) async {
    await childProfileRepository.deleteChild(id);
    await load();
  }
}
