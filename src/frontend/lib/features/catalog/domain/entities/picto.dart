import 'package:flutter/foundation.dart' show immutable;

enum PictoSource { bundled, custom, remote }

@immutable
final class Picto {
  const Picto({
    required this.id,
    required this.label,
    required this.categoryIds,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
    this.childProfileId,
  });

  final String id;
  final String label;

  /// REQ-CAT-02 (RF-3.13): un picto pertenece a 1 o más categorías.
  ///
  /// La lista vacía es un estado de transición: solo aparece en pictos
  /// custom huérfanos tras borrar su última categoría (RF-3.20, sobreviven
  /// invisibles en las grillas de categoría). Toda creación/edición exige
  /// al menos una.
  final List<String> categoryIds;

  final PictoSource source;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Dueño del picto (RF3.4): los personalizados pertenecen al perfil del
  /// niño activo; el catálogo incluido es `null` porque lo ve cualquier
  /// chico del dispositivo (RF3.5). Los custom previos a RF3 quedan en
  /// `null` y permanecen visibles para todos (RF3.7).
  final String? childProfileId;

  /// RF-3.15: pertenencia — el picto aparece en la categoría si la incluye.
  bool belongsTo(String categoryId) => categoryIds.contains(categoryId);

  Picto copyWith({
    String? label,
    List<String>? categoryIds,
    String? imageUrl,
    String? childProfileId,
    DateTime? updatedAt,
  }) {
    return Picto(
      id: id,
      label: label ?? this.label,
      categoryIds: categoryIds ?? this.categoryIds,
      source: source,
      imageUrl: imageUrl ?? this.imageUrl,
      childProfileId: childProfileId ?? this.childProfileId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
