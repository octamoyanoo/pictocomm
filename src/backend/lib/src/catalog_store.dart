import 'dart:convert';
import 'dart:io';

/// Categoría del seed del backend (REQ-BCK-01).
///
/// Espeja el formato de `CategoryModel` del frontend: `color` viaja como hex
/// `#RRGGBB` e `icon` es un nombre de ícono Material.
final class SeedCategory {
  const SeedCategory({required this.id, required this.name, required this.color, required this.icon});

  final String id;
  final String name;
  final String color;
  final String icon;
}

/// Picto del seed del backend (REQ-BCK-01).
///
/// `image` es un nombre de archivo dentro de `data/images/`; la API lo expone
/// como URL absoluta. Las fechas viajan en ISO-8601 UTC (RNF-5.6).
/// REQ-CAT-02 (RNF-3.9): `categoryIds` es una lista — el picto pertenece a 1
/// o más categorías; el `categoryId` de v1 se acepta solo para migrar.
final class SeedPicto {
  const SeedPicto({
    required this.id,
    required this.label,
    required this.categoryIds,
    required this.image,
    required this.createdAt,
    required this.updatedAt,
    this.childProfileId,
  });

  final String id;
  final String label;
  final List<String> categoryIds;
  final String image;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? childProfileId;
}

/// Catálogo en memoria del backend, cargado del seed JSON (RF-5.3).
///
/// No hay base de datos: el seed es la única fuente de verdad del server.
final class CatalogStore {
  CatalogStore({required List<SeedCategory> categories, required List<SeedPicto> pictos})
    : _categories = List.unmodifiable(categories),
      _pictos = List.unmodifiable(pictos);

  /// Carga el seed de [path]. Con un archivo inválido o inexistente arranca
  /// con catálogo vacío y loguea el error, sin crashear (UC-01.2 alt 1).
  factory CatalogStore.loadFrom(String path, {void Function(String message)? onError}) {
    void report(String message) {
      // ignore: avoid_print
      print('pictocomm_backend: $message');
      onError?.call(message);
    }
    try {
      final raw = File(path).readAsStringSync();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return CatalogStore.fromJson(json);
    } on FileSystemException catch (error) {
      report('no se pudo leer el seed "$path": ${error.message}');
      return CatalogStore.empty();
    } on FormatException catch (error) {
      report('seed inválido "$path": ${error.message}');
      return CatalogStore.empty();
    } on TypeError catch (error) {
      report('seed con formato inesperado "$path": $error');
      return CatalogStore.empty();
    }
  }

  factory CatalogStore.fromJson(Map<String, dynamic> json) {
    final categories = [
      for (final item in json['categories'] as List<dynamic>? ?? const <dynamic>[])
        _parseCategory(item as Map<String, dynamic>),
    ];
    final pictos = [
      for (final item in json['pictos'] as List<dynamic>? ?? const <dynamic>[])
        _parsePicto(item as Map<String, dynamic>),
    ];
    return CatalogStore(categories: categories, pictos: pictos);
  }

  factory CatalogStore.empty() => CatalogStore(categories: const [], pictos: const []);

  final List<SeedCategory> _categories;
  final List<SeedPicto> _pictos;

  List<SeedCategory> get categories => _categories;

  List<SeedPicto> get pictos => _pictos;

  SeedPicto? pictoById(String id) {
    for (final picto in _pictos) {
      if (picto.id == id) {
        return picto;
      }
    }
    return null;
  }

  /// RF-5.2 con multi-pertenencia (REQ-CAT-02, RF-3.15): filtra por
  /// pertenencia (un picto multicategoría sale en cada una), por
  /// `updatedAt` posterior a [since] (sync incremental, estricto) y recorta
  /// a [limit].
  List<SeedPicto> queryPictos({String? categoryId, DateTime? since, int limit = 100}) {
    return _pictos.where((picto) {
      if (categoryId != null && !picto.categoryIds.contains(categoryId)) {
        return false;
      }
      if (since != null && !picto.updatedAt.isAfter(since)) {
        return false;
      }
      return true;
    }).take(limit).toList();
  }

  static SeedCategory _parseCategory(Map<String, dynamic> json) {
    return SeedCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      icon: json['icon'] as String,
    );
  }

  static SeedPicto _parsePicto(Map<String, dynamic> json) {
    return SeedPicto(
      id: json['id'] as String,
      label: json['label'] as String,
      categoryIds: _parseCategoryIds(json),
      image: json['image'] as String,
      childProfileId: json['childProfileId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// REQ-CAT-02 (RNF-3.8): `categoryIds` nuevo; `categoryId` de v1 migra a
  /// lista de un elemento.
  static List<String> _parseCategoryIds(Map<String, dynamic> json) {
    final list = json['categoryIds'];
    if (list is List<dynamic>) {
      return [for (final item in list) item as String];
    }
    final legacy = json['categoryId'];
    if (legacy is String) {
      return [legacy];
    }
    throw const FormatException('el picto no trae categoryIds ni categoryId');
  }
}
