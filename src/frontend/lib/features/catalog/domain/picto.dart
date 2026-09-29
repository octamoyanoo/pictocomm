import 'picto_source.dart';

/// Una imagen que el niño toca para comunicarse.
///
/// Es la unidad central de la app: puede venir empaquetada, ser una foto
/// familiar importada por los padres, o venir del backend.
class Picto {
  const Picto({
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

  /// Identificador único. Para pictos empaquetados es su ruta de asset, lo que
  /// los hace idempotentes al sincronizar.
  final String id;

  /// Etiqueta legible, usada como texto visible y para accesibilidad.
  final String label;

  /// [Category.id] a la que pertenece.
  final String categoryId;

  /// Ruta de asset, ruta de archivo local o URL, según [source].
  final String imagePath;

  final PictoSource source;

  /// Ruta o URL del audio. `null` significa "sin sonido todavía".
  final String? audioPath;

  final bool isFavorite;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasAudio => audioPath != null && audioPath!.isNotEmpty;

  Picto copyWith({
    String? label,
    String? imagePath,
    String? audioPath,
    bool? isFavorite,
    DateTime? updatedAt,
  }) {
    return Picto(
      id: id,
      label: label ?? this.label,
      categoryId: categoryId,
      imagePath: imagePath ?? this.imagePath,
      source: source,
      audioPath: audioPath ?? this.audioPath,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Picto &&
          other.id == id &&
          other.label == label &&
          other.categoryId == categoryId &&
          other.imagePath == imagePath &&
          other.source == source &&
          other.audioPath == audioPath &&
          other.isFavorite == isFavorite;

  @override
  int get hashCode =>
      Object.hash(id, label, categoryId, imagePath, source, audioPath, isFavorite);

  @override
  String toString() => 'Picto(id: $id, label: $label, source: ${source.name})';
}
