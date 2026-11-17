import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show immutable;

/// Perfil de chico (RF2): el "usuario" con el que se comunica.
///
/// REQ-ACC-01 (RF-6.6): `accountId` tagea a qué cuenta pertenece el perfil.
/// `null` = legacy (creado antes de las cuentas): sigue visible para
/// cualquier cuenta del dispositivo.
@immutable
final class ChildProfile {
  const ChildProfile({
    required this.id,
    required this.name,
    this.age,
    this.avatarColor,
    this.photoUrl,
    this.accountId,
  });

  final String id;
  final String name;
  final int? age;
  final Color? avatarColor;

  /// Foto del niño: campo proyectado (RF2.12), aún no se usa en v1.
  final String? photoUrl;

  /// Cuenta dueña del perfil (RF-6.6); `null` para los legacy.
  final String? accountId;
}
