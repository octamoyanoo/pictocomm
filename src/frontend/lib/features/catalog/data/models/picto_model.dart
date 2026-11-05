import '../../domain/entities/picto.dart';

final class PictoModel {
  const PictoModel({
    required this.id,
    required this.label,
    required this.categoryId,
    required this.imageUrl,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.childProfileId,
  });

  final String id;
  final String label;
  final String categoryId;
  final String imageUrl;
  final PictoSource source;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? childProfileId;

  factory PictoModel.fromJson(Map<String, dynamic> json) {
    return PictoModel(
      id: json['id'] as String,
      label: json['label'] as String,
      categoryId: json['categoryId'] as String,
      imageUrl: json['imageUrl'] as String,
      source: _parseSource(json['source'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      childProfileId: json['childProfileId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'label': label,
      'categoryId': categoryId,
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
      categoryId: entity.categoryId,
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
      categoryId: categoryId,
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
