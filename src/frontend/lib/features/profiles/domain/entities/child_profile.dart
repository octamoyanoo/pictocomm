import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show immutable;

@immutable
final class ChildProfile {
  const ChildProfile({
    required this.id,
    required this.name,
    this.age,
    this.avatarColor,
    this.photoUrl,
  });

  final String id;
  final String name;
  final int? age;
  final Color? avatarColor;

  /// Foto del niño: campo proyectado (RF2.12), aún no se usa en v1.
  final String? photoUrl;
}
