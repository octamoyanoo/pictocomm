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
  });

  final String id;
  final String label;
  final String categoryId;
  final PictoSource source;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
}
