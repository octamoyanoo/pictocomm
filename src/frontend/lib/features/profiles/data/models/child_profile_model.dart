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
    this.photoUrl,
  });

  final String id;
  final String name;
  final int? age;

  /// Color como ARGB entero: JSON no entiende dart:ui, solo números.
  final int? avatarColorValue;

  /// Foto del niño como data URL (RF3.11).
  final String? photoUrl;

  factory ChildProfileModel.fromChild(ChildProfile child) {
    return ChildProfileModel(
      id: child.id,
      name: child.name,
      age: child.age,
      avatarColorValue: child.avatarColor?.toARGB32(),
      photoUrl: child.photoUrl,
    );
  }

  factory ChildProfileModel.fromJson(Map<String, dynamic> json) {
    return ChildProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int?,
      avatarColorValue: json['avatarColorValue'] as int?,
      photoUrl: json['photoUrl'] as String?,
    );
  }

  ChildProfile toChild() {
    return ChildProfile(
      id: id,
      name: name,
      age: age,
      avatarColor: avatarColorValue == null ? null : Color(avatarColorValue!),
      photoUrl: photoUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'age': age,
      'avatarColorValue': avatarColorValue,
      'photoUrl': photoUrl,
    };
  }
}
