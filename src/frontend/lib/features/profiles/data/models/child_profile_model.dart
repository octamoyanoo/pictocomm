import 'dart:ui' show Color;

import '../../domain/entities/child_profile.dart';

/// Serialización de [ChildProfile] para almacenamiento local (RF2.11).
/// El formato JSON queda listo para el backend sin cambiar el dominio.
final class ChildProfileModel {
  const ChildProfileModel({
    required this.id,
    required this.name,
    required this.avatarColorValue,
    this.age,
  });

  final String id;
  final String name;
  final int? age;

  /// Color como ARGB entero: JSON no entiende dart:ui, solo números.
  final int? avatarColorValue;

  factory ChildProfileModel.fromChild(ChildProfile child) {
    return ChildProfileModel(
      id: child.id,
      name: child.name,
      age: child.age,
      avatarColorValue: child.avatarColor?.toARGB32(),
    );
  }

  factory ChildProfileModel.fromJson(Map<String, dynamic> json) {
    return ChildProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int?,
      avatarColorValue: json['avatarColorValue'] as int?,
    );
  }

  ChildProfile toChild() {
    return ChildProfile(
      id: id,
      name: name,
      age: age,
      avatarColor: avatarColorValue == null ? null : Color(avatarColorValue!),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'age': age,
      'avatarColorValue': avatarColorValue,
    };
  }
}
