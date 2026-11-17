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
  });

  final String id;
  final String label;
  final List<String> categoryIds;
  final String imageUrl;
  final PictoSource source;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? childProfileId;

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
    );
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
    );
  }

  static PictoSource _parseSource(String value) {
    return PictoSource.values.firstWhere((s) => s.name == value);
  }
}
