import '../../domain/entities/category.dart';
import '../../domain/entities/picto.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/picto_repository.dart';
import '../datasources/local_catalog_data_source.dart';
import '../datasources/remote_catalog_data_source.dart';

final class LocalPictoRepository implements CategoryRepository, PictoRepository {
  LocalPictoRepository({required this.localDataSource, required this.remoteDataSource});

  final LocalCatalogDataSource localDataSource;

  final RemoteCatalogDataSource remoteDataSource;

  @override
  Future<List<Category>> getCategories() async {
    final assets = await localDataSource.bundledImageAssets();
    final categoryIds = <String>{};
    for (final asset in assets) {
      final categoryId = _assetCategory(asset);
      if (categoryId != null) {
        categoryIds.add(categoryId);
      }
    }
    return categoryIds.map((id) => Category(id: id, name: _humanize(id))).toList();
  }

  @override
  Future<List<Picto>> getPictos({String? categoryId}) async {
    final assets = await localDataSource.bundledImageAssets();
    final pictos = <Picto>[];
    for (final asset in assets) {
      final parsed = _parseAsset(asset);
      if (parsed == null) {
        continue;
      }
      final (pictoId, assetCategory, label) = parsed;
      if (categoryId != null && assetCategory != categoryId) {
        continue;
      }
      pictos.add(
        Picto(
          id: pictoId,
          label: label,
          categoryId: assetCategory,
          source: PictoSource.bundled,
          imageUrl: asset,
          createdAt: _epoch,
          updatedAt: _epoch,
        ),
      );
    }
    return pictos;
  }

  @override
  Future<Picto?> getPicto(String id) async {
    final pictos = await getPictos();
    for (final picto in pictos) {
      if (picto.id == id) {
        return picto;
      }
    }
    return null;
  }

  static final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  (String id, String categoryId, String label)? _parseAsset(String asset) {
    final categoryId = _assetCategory(asset);
    if (categoryId == null) {
      return null;
    }
    final filename = asset.split('/').last;
    final dotIndex = filename.lastIndexOf('.');
    final label = dotIndex <= 0 ? filename : filename.substring(0, dotIndex);
    return (asset, categoryId, label);
  }

  String? _assetCategory(String asset) {
    final segments = asset.split('/');
    if (segments.length < 4) {
      return null;
    }
    return segments[2];
  }

  String _humanize(String id) {
    final words = id.split('-').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1));
    return words.join(' ');
  }
}
