import 'package:flutter/services.dart';

import '../models/category.dart';
import '../models/image_item.dart';

abstract class StorageService {
  Future<List<Category>> loadCategories();

  Future<List<ImageItem>> loadImages(String categoryId);
}

class LocalStorageService implements StorageService {
  const LocalStorageService();

  static const _categories = <Category>[
    Category(id: 'comida', name: 'Comida', iconPath: 'assets/images/comida/'),
    Category(id: 'lugares', name: 'Lugares', iconPath: 'assets/images/lugares/'),
    Category(
        id: 'emociones',
        name: 'Emociones',
        iconPath: 'assets/images/emociones/'),
  ];

  @override
  Future<List<Category>> loadCategories() async {
    final manifest = await _loadManifest();
    return _categories
        .where((c) => manifest.any((path) => path.startsWith(c.iconPath)))
        .toList();
  }

  @override
  Future<List<ImageItem>> loadImages(String categoryId) async {
    final category =
        _categories.firstWhere((c) => c.id == categoryId, orElse: () => _categories.first);
    final manifest = await _loadManifest();
    final paths = manifest
        .where((p) => p.startsWith(category.iconPath))
        .where(_isImageAsset)
        .toList();

    return paths
        .map((path) => ImageItem(
              id: path,
              name: _nameFromPath(path),
              imagePath: path,
              categoryId: categoryId,
            ))
        .toList();
  }

  bool _isImageAsset(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');
  }

  Future<List<String>> _loadManifest() async {
    final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return assetManifest
        .listAssets()
        .where((path) => path.startsWith('assets/images/'))
        .toList();
  }

  String _nameFromPath(String path) {
    final parts = path.split('/');
    final file = parts.last.split('.').first;
    return file.replaceAll('_', ' ').replaceAll('-', ' ');
  }
}