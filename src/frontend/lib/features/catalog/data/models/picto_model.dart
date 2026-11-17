import '../../domain/entities/picto.dart';

final class PictoModel {
  const PictoModel({
    required this.id,
    required this.label,
    required this.categoryIds,
    required this.imageUrl,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.childProfileId,
    this.deletedAt,
    this.labels = const {},
  });

  final String id;
  final String label;
  final List<String> categoryIds;
  final String imageUrl;
  final PictoSource source;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? childProfileId;

  /// REQ-IDI-01 (RF-4.9): traducciones de la etiqueta por idioma. Opcional:
  /// el cache de SharedPreferences de versiones anteriores (y el outbox
  /// viejo) no traen el campo; la base `label` siempre está.
  final Map<String, String> labels;

  /// REQ-BCK-02 (RF-5.14): tumba del borrado lógico remoto. Llega por el
  /// sync incremental; el repositorio la usa para purgar el cache y nunca
  /// renderiza un picto borrado.
  final DateTime? deletedAt;

  /// REQ-CAT-02 (RNF-3.8): compatibilidad con el formato v1 — si el JSON
  /// trae `categoryId` (un solo string), se migra a una lista de un
  /// elemento. El formato nuevo (`categoryIds`) siempre gana si está.
  factory PictoModel.fromJson(Map<String, dynamic> json) {
    return PictoModel(
      id: json['id'] as String,
      label: json['label'] as String,
      categoryIds: _parseCategoryIds(json),
      imageUrl: json['imageUrl'] as String,
      source: _parseSource(json['source'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      childProfileId: json['childProfileId'] as String?,
      deletedAt: _parseDate(json['deletedAt']),
      labels: _parseLabels(json['labels']),
    );
  }

  /// REQ-IDI-01 (RF-4.10): tolerante — vacío o ausente = sin traducciones.
  static Map<String, String> _parseLabels(Object? value) {
    if (value is Map<dynamic, dynamic>) {
      return {
        for (final entry in value.entries)
          if (entry.key is String && entry.value is String) entry.key as String: entry.value as String,
      };
    }
    return const {};
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value);
    }
    return null;
  }

  static List<String> _parseCategoryIds(Map<String, dynamic> json) {
    final list = json['categoryIds'];
    if (list is List<dynamic>) {
      return [for (final item in list) item as String];
    }
    final legacy = json['categoryId'];
    if (legacy is String) {
      return [legacy];
    }
    throw const FormatException('el picto no trae categoryIds ni categoryId');
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'label': label,
      'categoryIds': categoryIds,
      'imageUrl': imageUrl,
      'source': source.name,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'childProfileId': childProfileId,
      // REQ-IDI-01: solo si hay traducciones — el JSON de un picto sin
      // traducir queda igual al de siempre (cache y outbox viejos OK).
      if (labels.isNotEmpty) 'labels': labels,
      if (deletedAt != null) 'deletedAt': deletedAt!.toUtc().toIso8601String(),
    };
  }

  factory PictoModel.fromEntity(Picto entity) {
    return PictoModel(
      id: entity.id,
      label: entity.label,
      categoryIds: [...entity.categoryIds],
      imageUrl: entity.imageUrl ?? '',
      source: entity.source,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      childProfileId: entity.childProfileId,
      labels: Map.of(entity.labels),
    );
  }

  Picto toEntity() {
    return Picto(
      id: id,
      label: label,
      categoryIds: [...categoryIds],
      imageUrl: imageUrl,
      source: source,
      createdAt: createdAt,
      updatedAt: updatedAt,
      childProfileId: childProfileId,
      labels: Map.of(labels),
    );
  }

  static PictoSource _parseSource(String value) {
    return PictoSource.values.firstWhere((s) => s.name == value);
  }
}
