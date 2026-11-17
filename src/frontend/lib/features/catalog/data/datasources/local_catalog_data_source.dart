import 'dart:convert' show jsonDecode;

import 'package:flutter/services.dart';

/// REQ-IDI-01 (RF-4.9): traducciones del catálogo incluido, leídas del
/// manifiesto `assets/catalog_labels.json`. Claves = slug del asset
/// (id del picto / id de la categoría); valores = mapa `idioma → texto`.
final class BundledLabels {
  const BundledLabels({required this.pictos, required this.categories});

  final Map<String, Map<String, String>> pictos;
  final Map<String, Map<String, String>> categories;

  factory BundledLabels.fromJson(Map<String, dynamic> json) {
    return BundledLabels(
      pictos: _parseSection(json['pictos']),
      categories: _parseSection(json['categories']),
    );
  }

  static Map<String, Map<String, String>> _parseSection(Object? section) {
    if (section is! Map<dynamic, dynamic>) {
      return const {};
    }
    return {
      for (final entry in section.entries)
        if (entry.key is String && entry.value is Map<dynamic, dynamic>)
          entry.key as String: {
            for (final translation in (entry.value as Map<dynamic, dynamic>).entries)
              if (translation.key is String && translation.value is String)
                translation.key as String: translation.value as String,
          },
    };
  }
}

final class LocalCatalogDataSource {
  const LocalCatalogDataSource();

  static const String _assetPrefix = 'assets/images/';
  static const String _labelsAsset = 'assets/catalog_labels.json';
  static const List<String> _imageExtensions = ['.png', '.webp'];

  Future<List<String>> bundledImageAssets() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = manifest.listAssets();
      return assets
          .where(_isCatalogImage)
          .toList()
        ..sort();
    } on Object {
      return const <String>[];
    }
  }

  /// REQ-IDI-01 (RF-4.9): traducciones del catálogo incluido, indexadas por
  /// slug (id del picto / id de la categoría). Si el manifiesto falta o está
  /// roto devuelve mapas vacíos: sin traducciones la app sigue igual (los
  /// labels caen a la base).
  Future<BundledLabels> bundledLabels() async {
    try {
      final raw = await rootBundle.loadString(_labelsAsset);
      return BundledLabels.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return const BundledLabels(pictos: {}, categories: {});
    }
  }

  bool _isCatalogImage(String asset) {
    if (!asset.startsWith(_assetPrefix)) {
      return false;
    }
    for (final extension in _imageExtensions) {
      if (asset.endsWith(extension)) {
        return true;
      }
    }
    return false;
  }
}
