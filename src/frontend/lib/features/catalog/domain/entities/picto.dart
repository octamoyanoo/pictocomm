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
    this.labels = const {},
  });

  final String id;

  /// Etiqueta base (español): fallback y contenido del catálogo/custom.
  final String label;

  /// REQ-IDI-01 (RF-4.9): traducciones de la etiqueta por código de idioma
  /// (`{'en': 'Water', 'pt': 'Água'}`). El español vive en [label]; este
  /// mapa es opcional (pictos custom y contenido viejo vienen vacíos) y
  /// `labelFor` cae al base cuando no hay entrada para el idioma activo.
  final Map<String, String> labels;

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

  /// REQ-IDI-01 (RF-4.9/RF-4.10): etiqueta para el idioma activo, con la
  /// base en español como fallback (custom, contenido sin traducir).
  String labelFor(String languageCode) => labels[languageCode] ?? label;

  /// Búsqueda de pictos (RF de gestión): encuentra por la etiqueta del
  /// idioma activo **o** por cualquier traducción, y también por la base.
  bool matchesQuery(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }
    return label.toLowerCase().contains(normalized) ||
        labels.values.any((label) => label.toLowerCase().contains(normalized));
  }

  Picto copyWith({
    String? label,
    List<String>? categoryIds,
    String? imageUrl,
    String? childProfileId,
    DateTime? updatedAt,
    Map<String, String>? labels,
  }) {
    return Picto(
      id: id,
      label: label ?? this.label,
      categoryIds: categoryIds ?? this.categoryIds,
      source: source,
      imageUrl: imageUrl ?? this.imageUrl,
      childProfileId: childProfileId ?? this.childProfileId,
      labels: labels ?? this.labels,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
