import 'package:flutter/foundation.dart' show immutable;

enum PictoSource { bundled, custom, remote }

@immutable
final class Picto {
  const Picto({
    required this.id,
    required this.label,
    required this.categoryId,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
    this.childProfileId,
  });

  final String id;
  final String label;
  final String categoryId;
  final PictoSource source;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Dueño del picto (RF3.4): los personalizados pertenecen al perfil del
  /// niño activo; el catálogo incluido es `null` porque lo ve cualquier
  /// chico del dispositivo (RF3.5). Los custom previos a RF3 quedan en
  /// `null` y permanecen visibles para todos (RF3.7).
  final String? childProfileId;
}
