import 'package:flutter/foundation.dart' show immutable;

/// Cuenta del adulto responsable (REQ-ACC-01): la identidad con la que se
/// entra a la app. Vive en el backend; el dispositivo solo guarda la sesión.
///
/// `id` es el `accountId` con el que se tagean los `ChildProfile` (RF-6.6):
/// el selector muestra solo los perfiles de la cuenta logueada.
@immutable
final class UserAccount {
  const UserAccount({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;
}
