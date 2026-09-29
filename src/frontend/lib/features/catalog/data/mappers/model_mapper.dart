import 'package:flutter/material.dart' show Color;

import '../../../../core/error/app_exception.dart';
import '../../../profiles/data/models/child_profile_model.dart';
import '../../../profiles/domain/child_profile.dart';
import '../../domain/category.dart';
import '../../domain/picto.dart';
import '../../domain/picto_source.dart';
import '../models/category_model.dart';
import '../models/picto_model.dart';

/// Mapeador entre modelos de data (JSON) y entidades de dominio.
///
/// Separar el mapeo en esta clase mantiene las entidades puras y evita que el
/// datasource escriba lógica de negocio. Cuando llegue el backend, los modelos
/// se deserializan de la respuesta HTTP con el mismo `fromJson`.
abstract final class ModelMapper {
  static Category mapCategory(CategoryModel m) {
    try {
      return Category(
        id: m.id,
        name: m.name,
        assetFolder: m.assetFolder,
        color: Color(m.color),
        sortOrder: m.sortOrder,
      );
    } on Object catch (e) {
      throw ValidationException(
        'Color inválido para la categoría ${m.id}: ${m.color}',
        cause: e,
      );
    }
  }

  static CategoryModel toCategoryModel(Category e) => CategoryModel(
        id: e.id,
        name: e.name,
        assetFolder: e.assetFolder,
        color: e.color.toARGB32(),
        sortOrder: e.sortOrder,
      );

  static Picto mapPicto(PictoModel m) {
    final PictoSource source;
    try {
      source = PictoSource.values.byName(m.source);
    } on Object catch (e) {
      throw ValidationException(
        'Origen de picto desconocido: ${m.source}',
        cause: e,
      );
    }

    return Picto(
      id: m.id,
      label: m.label,
      categoryId: m.categoryId,
      imagePath: m.imagePath,
      source: source,
      audioPath: m.audioPath,
      isFavorite: m.isFavorite,
      createdAt: m.createdAt,
      updatedAt: m.updatedAt,
    );
  }

  static PictoModel toPictoModel(Picto e) => PictoModel(
        id: e.id,
        label: e.label,
        categoryId: e.categoryId,
        imagePath: e.imagePath,
        source: e.source.name,
        audioPath: e.audioPath,
        isFavorite: e.isFavorite,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
      );

  static ChildProfile mapProfile(ChildProfileModel m) {
    try {
      return ChildProfile(
        id: m.id,
        name: m.name,
        color: Color(m.color),
        avatarPath: m.avatarPath,
        categoryOrder: List<String>.unmodifiable(m.categoryOrder),
      );
    } on Object catch (e) {
      throw ValidationException(
        'Color inválido para el perfil ${m.id}: ${m.color}',
        cause: e,
      );
    }
  }

  static ChildProfileModel toProfileModel(ChildProfile e) => ChildProfileModel(
        id: e.id,
        name: e.name,
        color: e.color.toARGB32(),
        avatarPath: e.avatarPath,
        categoryOrder: List<String>.from(e.categoryOrder),
      );
}
