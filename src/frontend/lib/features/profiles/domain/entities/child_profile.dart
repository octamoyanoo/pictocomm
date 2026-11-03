import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show immutable;

@immutable
final class ChildProfile {
  const ChildProfile({required this.id, required this.name, this.age, this.avatarColor});

  final String id;
  final String name;
  final int? age;
  final Color? avatarColor;
}
