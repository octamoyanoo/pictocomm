import 'dart:convert';

/// Modelo inmutable para serializar [Picto] a JSON.
class PictoModel {
  const PictoModel({
    required this.id,
    required this.label,
    required this.categoryId,
    required this.imagePath,
    required this.source,
    this.audioPath,
    this.isFavorite = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String label;
  final String categoryId;
  final String imagePath;

  /// `PictoSource.name`. Se guarda como String y no como enum para que el JSON
  /// sea legible y compatible con un backend en otro lenguaje.
  final String source;
  final String? audioPath;
  final bool isFavorite;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PictoModel.fromJson(Map<String, dynamic> json) => PictoModel(
        id: json['id'] as String,
        label: json['label'] as String,
        categoryId: json['categoryId'] as String,
        imagePath: json['imagePath'] as String,
        source: json['source'] as String,
        audioPath: json['audioPath'] as String?,
        isFavorite: json['isFavorite'] as bool? ?? false,
        createdAt: _parseDate(json['createdAt']),
        updatedAt: _parseDate(json['updatedAt']),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'label': label,
        'categoryId': categoryId,
        'imagePath': imagePath,
        'source': source,
        if (audioPath != null) 'audioPath': audioPath,
        'isFavorite': isFavorite,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  static DateTime? _parseDate(Object? raw) =>
      raw is String ? DateTime.tryParse(raw) : null;

  static List<PictoModel> fromJsonList(String source) {
    final List<dynamic> list = json.decode(source) as List<dynamic>;
    return list
        .whereType<Map<String, dynamic>>()
        .map(PictoModel.fromJson)
        .toList();
  }
}
