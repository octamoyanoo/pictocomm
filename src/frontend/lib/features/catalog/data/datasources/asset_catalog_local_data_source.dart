import 'package:flutter/material.dart' show Color;
import 'package:flutter/services.dart' show AssetManifest, rootBundle;

import '../../../../core/error/app_exception.dart';
import '../../domain/category.dart';
import '../../domain/picto.dart';
import '../../domain/picto_source.dart';
import '../mappers/model_mapper.dart';
import '../models/picto_model.dart';
import 'catalog_local_data_source.dart';

/// Fuente local basada en `AssetManifest`.
///
/// - Categorías: fijas, y solo se exponen las que tienen al menos un asset.
/// - Pictos empaquetados: se listan del manifest filtrando
///   `assets/images/<assetFolder>/`.
/// - Pictos propios: se inyectan con [extraPictos], hoy vacío. Al agregar
///   persistencia real (SharedPrefs, sqflite, isar) se conecta ahí sin tocar el
///   repositorio.
class AssetCatalogLocalDataSource implements CatalogLocalDataSource {
  AssetCatalogLocalDataSource({this.extraPictos = const <Picto>[]});

  /// Pictos propios que aporta otra capa (p. ej. los importados de la galería
  /// o los descargados del backend y cacheados).
  final List<Picto> extraPictos;

  /// Paleta de las categorías, en el orden en que se muestran.
  static final List<Category> _baseCategories = <Category>[
    Category(
      id: 'comida',
      name: 'Comida',
      assetFolder: 'comida',
      color: const Color(0xFF4CAF50),
      sortOrder: 0,
    ),
    Category(
      id: 'lugares',
      name: 'Lugares',
      assetFolder: 'lugares',
      color: const Color(0xFF2196F3),
      sortOrder: 1,
    ),
    Category(
      id: 'emociones',
      name: 'Emociones',
      assetFolder: 'emociones',
      color: const Color(0xFFFFA726),
      sortOrder: 2,
    ),
  ];

  @override
  Future<List<Category>> getCategories() async {
    try {
      final manifest = await _loadImageManifest();
      final present = _baseCategories.where((Category c) {
        final prefix = 'assets/images/${c.assetFolder}/';
        return manifest.any((String p) => p.startsWith(prefix));
      }).toList()
        ..sort((Category a, Category b) => a.sortOrder.compareTo(b.sortOrder));
      return present;
    } on Object catch (e) {
      throw StorageException('No se pudieron cargar las categorías', cause: e);
    }
  }

  @override
  Future<List<Picto>> getPictosByCategory(String categoryId) async {
    final Category? cat = _baseCategories
        .where((Category c) => c.id == categoryId)
        .firstOrNull;
    if (cat == null) {
      throw NotFoundException('No existe la categoría $categoryId');
    }

    final List<String> manifest = await _loadImageManifest();
    final String prefix = 'assets/images/${cat.assetFolder}/';

    final List<String> bundledPaths = manifest
        .where((String p) => p.startsWith(prefix) && _isImageAsset(p))
        .toList()
      ..sort((String a, String b) => a.compareTo(b));

    final List<Picto> bundled = bundledPaths
        .map(
          (String path) => ModelMapper.mapPicto(
            PictoModel(
              id: path,
              label: _labelFromPath(path),
              categoryId: cat.id,
              imagePath: path,
              source: PictoSource.bundled.name,
            ),
          ),
        )
        .toList();

    final List<Picto> extra = extraPictos
        .where((Picto p) => p.categoryId == cat.id)
        .toList()
      ..sort(
        (Picto a, Picto b) =>
            a.label.toLowerCase().compareTo(b.label.toLowerCase()),
      );

    return <Picto>[...bundled, ...extra];
  }

  @override
  Future<Picto> saveCustomPicto(Picto picto) async {
    if (picto.source == PictoSource.bundled) {
      throw const ValidationException(
        'Los pictos empaquetados no se pueden modificar.',
      );
    }
    final idx = extraPictos.indexWhere((Picto p) => p.id == picto.id);
    if (idx == -1) {
      extraPictos.add(picto);
    } else {
      extraPictos[idx] = picto;
    }
    return picto;
  }

  @override
  Future<void> deleteCustomPicto(String id) async {
    final idx = extraPictos.indexWhere((Picto p) => p.id == id);
    if (idx == -1) {
      throw NotFoundException('No existe el picto $id');
    }
    extraPictos.removeAt(idx);
  }

  @override
  Future<bool> toggleFavorite(String id) async {
    final idx = extraPictos.indexWhere((Picto p) => p.id == id);
    if (idx != -1) {
      final Picto p = extraPictos[idx];
      final bool next = !p.isFavorite;
      extraPictos[idx] = p.copyWith(isFavorite: next, updatedAt: DateTime.now());
      return next;
    }

    // Los empaquetados no tienen dónde persistirse todavía: cuando exista la
    // capa de almacenamiento se consulta acá.
    throw const UnimplementedFeatureException(
      'Marcar favoritos en pictos empaquetados requiere la capa de persistencia.',
    );
  }

  Future<List<String>> _loadImageManifest() async {
    final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return assetManifest
        .listAssets()
        .where((String path) => path.startsWith('assets/images/'))
        .toList();
  }

  bool _isImageAsset(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp');
  }

  /// `assets/images/comida/manzana-verde.png` -> "manzana verde".
  String _labelFromPath(String path) {
    final file = path.split('/').last;
    final name = file.split('.').first;
    return name.replaceAll('_', ' ').replaceAll('-', ' ');
  }
}
