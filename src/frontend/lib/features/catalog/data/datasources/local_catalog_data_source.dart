import 'package:flutter/services.dart';

final class LocalCatalogDataSource {
  const LocalCatalogDataSource();

  static const String _assetPrefix = 'assets/images/';
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
