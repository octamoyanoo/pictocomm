import 'dart:convert';
import 'dart:io';

/// Categoría del seed del backend (REQ-BCK-01).
///
/// Espeja el formato de `CategoryModel` del frontend: `color` viaja como hex
/// `#RRGGBB` e `icon` es un nombre de ícono Material.
/// REQ-BCK-02 (RNF-5.14): `deletedAt` marca el borrado lógico de lo subido.
final class SeedCategory {
  const SeedCategory({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    this.updatedAt,
    this.deletedAt,
    this.names = const {},
  });

  final String id;
  final String name;
  final String color;
  final String icon;

  /// REQ-IDI-01 (RF-4.9): traducciones del nombre por idioma. Opcional:
  /// uploads viejos y categorías custom no la traen (cae al nombre base).
  final Map<String, String> names;

  /// REQ-BCK-02 (RNF-5.10): versión del item para conflictos
  /// last-write-wins. En el seed es `null` (no aplica: no se edita).
  final DateTime? updatedAt;

  /// Borrado lógico (RF-5.15): `null` = vigente. Es `final` para el seed;
  /// los uploads se reemplazan completos (upsert) al mutar.
  final DateTime? deletedAt;

  SeedCategory withDeletedAt(DateTime? when) => SeedCategory(
    id: id,
    name: name,
    color: color,
    icon: icon,
    updatedAt: updatedAt,
    deletedAt: when,
    names: names,
  );

  SeedCategory withUpdatedAt(DateTime? when) => SeedCategory(
    id: id,
    name: name,
    color: color,
    icon: icon,
    updatedAt: when,
    deletedAt: deletedAt,
    names: names,
  );
}

/// Picto del seed del backend (REQ-BCK-01).
///
/// `image` es un nombre de archivo dentro de `data/images/`; la API lo expone
/// como URL absoluta. Las fechas viajan en ISO-8601 UTC (RNF-5.6).
/// REQ-CAT-02 (RNF-3.9): `categoryIds` es una lista — el picto pertenece a 1
/// o más categorías; el `categoryId` de v1 se acepta solo para migrar.
/// REQ-BCK-02 (RNF-5.14): `deletedAt` marca el borrado lógico de lo subido.
final class SeedPicto {
  const SeedPicto({
    required this.id,
    required this.label,
    required this.categoryIds,
    required this.image,
    required this.createdAt,
    required this.updatedAt,
    this.childProfileId,
    this.deletedAt,
    this.labels = const {},
  });

  final String id;
  final String label;
  final List<String> categoryIds;
  final String image;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? childProfileId;

  /// REQ-IDI-01 (RF-4.9): traducciones de la etiqueta por idioma. Opcional:
  /// uploads viejos no la traen (cae a la etiqueta base).
  final Map<String, String> labels;

  /// Borrado lógico (RF-5.14): `null` = vigente.
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  SeedPicto copyWith({
    String? label,
    List<String>? categoryIds,
    String? image,
    String? childProfileId,
    DateTime? updatedAt,
    DateTime? deletedAt,
    Map<String, String>? labels,
  }) {
    return SeedPicto(
      id: id,
      label: label ?? this.label,
      categoryIds: categoryIds ?? this.categoryIds,
      image: image ?? this.image,
      childProfileId: childProfileId ?? this.childProfileId,
      labels: labels ?? this.labels,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt,
    );
  }
}

/// Catálogo en memoria del backend: **seed curado** (REQ-BCK-01, de solo
/// lectura) + **uploads de los dispositivos** (REQ-BCK-02, RNF-5.8).
///
/// - El seed vive en `data/seed.json` y nunca se reescribe.
/// - Lo que suben los dispositivos vive en `data/uploads.json` (mismo
///   formato JSON que el seed, con `deletedAt` opcional) y sobrevive
///   reinicios del server (CA-5.19).
/// - En lectura se mergen ambos: los uploads ganan por id (no deberían
///   chocar, los ids del cliente llevan prefijo `custom-`, RNF-5.15) y los
///   items con `deletedAt` quedan fuera de los listados normales.
final class CatalogStore {
  CatalogStore({
    required List<SeedCategory> seedCategories,
    required List<SeedPicto> seedPictos,
    List<SeedCategory> uploadCategories = const [],
    List<SeedPicto> uploadPictos = const [],
    this.uploadsPath,
  }) : _seedCategories = List.unmodifiable(seedCategories),
       _seedPictos = List.unmodifiable(seedPictos),
       _uploadCategories = [...uploadCategories],
       _uploadPictos = [...uploadPictos];

  /// Carga el seed de [path] y, si [uploadsPath] es distinto de `null`, lo
  /// que subieron los dispositivos. Con archivos inválidos o inexistentes
  /// arranca con esa parte vacía y loguea el error, sin crashear (UC-01.2
  /// alt 1, extendido a uploads).
  factory CatalogStore.loadFrom(String path, {String? uploadsPath, void Function(String message)? onError}) {
    void report(String message) {
      // ignore: avoid_print
      print('pictocomm_backend: $message');
      onError?.call(message);
    }
    try {
      final raw = File(path).readAsStringSync();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final seed = CatalogSeed.fromJson(json);
      final uploads = _loadUploads(uploadsPath, report);
      return CatalogStore(
        seedCategories: seed.categories,
        seedPictos: seed.pictos,
        uploadCategories: uploads.categories,
        uploadPictos: uploads.pictos,
        uploadsPath: uploadsPath,
      );
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

  static CatalogSeed _loadUploads(String? uploadsPath, void Function(String) report) {
    if (uploadsPath == null) {
      return const CatalogSeed(categories: [], pictos: []);
    }
    final file = File(uploadsPath);
    if (!file.existsSync()) {
      return const CatalogSeed(categories: [], pictos: []);
    }
    try {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      return CatalogSeed.fromJson(json);
    } on Object {
      report('uploads inválidos "$uploadsPath": se ignoran y arranca vacío');
      return const CatalogSeed(categories: [], pictos: []);
    }
  }

  factory CatalogStore.empty() => CatalogStore(seedCategories: const [], seedPictos: const []);

  factory CatalogStore.fromJson(Map<String, dynamic> json) {
    final seed = CatalogSeed.fromJson(json);
    return CatalogStore(seedCategories: seed.categories, seedPictos: seed.pictos);
  }

  final List<SeedCategory> _seedCategories;
  final List<SeedPicto> _seedPictos;
  final List<SeedCategory> _uploadCategories;
  final List<SeedPicto> _uploadPictos;

  /// Path de `uploads.json` para persistir lo subido (RNF-5.8); `null` en
  /// tests sin disco.
  final String? uploadsPath;

  // ---- Lecturas (merge seed + uploads, sin borrados) ----

  /// Categorías vigentes: seed + uploads. Las con `deletedAt` quedan fuera
  /// (los dispositivos purgan sus cache con la lista de tumbas de abajo).
  List<SeedCategory> get categories {
    final uploadIds = {for (final category in _uploadCategories) category.id};
    return [
      ..._seedCategories.where((category) => !uploadIds.contains(category.id)),
      ..._uploadCategories,
    ].where((category) => category.deletedAt == null).toList();
  }

  /// Tumbas de categorías (para que los dispositivos purguen su cache, RF-5.15).
  List<SeedCategory> get deletedCategories =>
      [for (final category in _uploadCategories) if (category.deletedAt != null) category];

  /// Pictos vigentes: seed + uploads.
  List<SeedPicto> get pictos {
    final uploadIds = {for (final picto in _uploadPictos) picto.id};
    return [
      ..._seedPictos.where((picto) => !uploadIds.contains(picto.id)),
      ..._uploadPictos,
    ].where((picto) => !picto.isDeleted).toList();
  }

  SeedPicto? pictoById(String id) {
    for (final picto in _uploadPictos) {
      if (picto.id == id) {
        return picto;
      }
    }
    for (final picto in _seedPictos) {
      if (picto.id == id) {
        return picto;
      }
    }
    return null;
  }

  SeedCategory? categoryById(String id) {
    for (final category in _uploadCategories) {
      if (category.id == id) {
        return category;
      }
    }
    for (final category in _seedCategories) {
      if (category.id == id) {
        return category;
      }
    }
    return null;
  }

  /// true si el id pertenece al seed curado (no editable/borrable, RF-5.16).
  bool isSeedPicto(String id) => _seedPictos.any((picto) => picto.id == id);

  bool isSeedCategory(String id) => _seedCategories.any((category) => category.id == id);

  /// RF-5.2 con multi-pertenencia (REQ-CAT-02, RF-3.15): filtra por
  /// pertenencia (un picto multicategoría sale en cada una), por
  /// `updatedAt` posterior a [since] (sync incremental, estricto) y recorta
  /// a [limit]. REQ-BCK-02 (RF-5.14): con `since`, además incluyen los
  /// borrados recientemente (`deletedAt` > since) como tumbas para que cada
  /// dispositivo purgue su cache.
  List<SeedPicto> queryPictos({String? categoryId, DateTime? since, int limit = 100}) {
    final uploadIds = {for (final picto in _uploadPictos) picto.id};
    final merged = [..._seedPictos.where((picto) => !uploadIds.contains(picto.id)), ..._uploadPictos];
    return merged.where((picto) {
      if (categoryId != null && !picto.categoryIds.contains(categoryId)) {
        return false;
      }
      if (picto.isDeleted) {
        // Sin `since` el listado normal no muestra tumbas; con `since` (sync)
        // solo las borradas DESPUÉS del último sync sirven para purgar.
        if (since == null || !picto.deletedAt!.isAfter(since)) {
          return false;
        }
        return true;
      }
      if (since != null && !picto.updatedAt.isAfter(since)) {
        return false;
      }
      return true;
    }).take(limit).toList();
  }

  // ---- Escrituras (solo uploads, RF-5.12 a RF-5.15) ----

  /// Guarda un picto subido con upsert por id. Devuelve false si el id es
  /// del seed (el API responde 403): el seed no se edita desde la app.
  bool upsertPicto(SeedPicto picto) {
    if (isSeedPicto(picto.id)) {
      return false;
    }
    final index = _uploadPictos.indexWhere((existing) => existing.id == picto.id);
    if (index >= 0) {
      _uploadPictos[index] = picto;
    } else {
      _uploadPictos.add(picto);
    }
    _persistUploads();
    return true;
  }

  /// Borrado lógico (RF-5.14): marca `deletedAt`. Idempotente. Devuelve
  /// false si el id es del seed.
  bool deletePicto(String id, {DateTime? when}) {
    final picto = _uploadPictos.where((existing) => existing.id == id).firstOrNull;
    if (picto == null) {
      return !isSeedPicto(id);
    }
    _uploadPictos[_uploadPictos.indexOf(picto)] = picto.copyWith(
      deletedAt: when ?? DateTime.now().toUtc(),
    );
    _persistUploads();
    return true;
  }

  bool upsertCategory(SeedCategory category) {
    if (isSeedCategory(category.id)) {
      return false;
    }
    final index = _uploadCategories.indexWhere((existing) => existing.id == category.id);
    if (index >= 0) {
      _uploadCategories[index] = category;
    } else {
      _uploadCategories.add(category);
    }
    _persistUploads();
    return true;
  }

  bool deleteCategory(String id, {DateTime? when}) {
    final category = _uploadCategories.where((existing) => existing.id == id).firstOrNull;
    if (category == null) {
      return !isSeedCategory(id);
    }
    _uploadCategories[_uploadCategories.indexOf(category)] = category.withDeletedAt(when ?? DateTime.now().toUtc());
    _persistUploads();
    return true;
  }

  /// RNF-5.8: reescribe `uploads.json` con el mismo formato que el seed.
  /// Best-effort: si el disco falla, lo loguea y el estado en memoria queda
  /// igual (los reintentos del server lo volverán a escribir).
  void _persistUploads() {
    final path = uploadsPath;
    if (path == null) {
      return;
    }
    try {
      final file = File(path);
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }
      file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
        'categories': [
          for (final category in _uploadCategories) _categoryJson(category),
        ],
        'pictos': [
          for (final picto in _uploadPictos) _pictoJson(picto),
        ],
      }));
    } on FileSystemException catch (error) {
      // ignore: avoid_print
      print('pictocomm_backend: no se pudo persistir uploads "$path": ${error.message}');
    }
  }

  static Map<String, dynamic> _categoryJson(SeedCategory category) {
    return <String, dynamic>{
      'id': category.id,
      'name': category.name,
      'color': category.color,
      'icon': category.icon,
      if (category.names.isNotEmpty) 'names': category.names,
      'updatedAt': category.updatedAt?.toUtc().toIso8601String(),
      'deletedAt': category.deletedAt?.toUtc().toIso8601String(),
    };
  }

  static Map<String, dynamic> _pictoJson(SeedPicto picto) {
    return <String, dynamic>{
      'id': picto.id,
      'label': picto.label,
      'categoryIds': picto.categoryIds,
      'image': picto.image,
      'childProfileId': picto.childProfileId,
      if (picto.labels.isNotEmpty) 'labels': picto.labels,
      'createdAt': picto.createdAt.toUtc().toIso8601String(),
      'updatedAt': picto.updatedAt.toUtc().toIso8601String(),
      'deletedAt': picto.deletedAt?.toUtc().toIso8601String(),
    };
  }
}

/// Estructura intermedia del parseo (seed o uploads, mismo formato).
final class CatalogSeed {
  const CatalogSeed({required this.categories, required this.pictos});

  final List<SeedCategory> categories;
  final List<SeedPicto> pictos;

  factory CatalogSeed.fromJson(Map<String, dynamic> json) {
    return CatalogSeed(
      categories: [
        for (final item in json['categories'] as List<dynamic>? ?? const <dynamic>[])
          _parseCategory(item as Map<String, dynamic>),
      ],
      pictos: [
        for (final item in json['pictos'] as List<dynamic>? ?? const <dynamic>[])
          _parsePicto(item as Map<String, dynamic>),
      ],
    );
  }

  static SeedCategory _parseCategory(Map<String, dynamic> json) {
    return SeedCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      icon: json['icon'] as String,
      updatedAt: _parseDate(json['updatedAt']),
      deletedAt: _parseDate(json['deletedAt']),
      names: _parseTranslations(json['names']),
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
      deletedAt: _parseDate(json['deletedAt']),
      labels: _parseTranslations(json['labels']),
    );
  }

  /// REQ-IDI-01 (RF-4.10): traducciones opcionales — vacío o ausente = sin
  /// traducir; entradas que no son `String → String` se descartan.
  static Map<String, String> _parseTranslations(Object? value) {
    if (value is Map<dynamic, dynamic>) {
      return {
        for (final entry in value.entries)
          if (entry.key is String && entry.value is String) entry.key as String: entry.value as String,
      };
    }
    return const {};
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value);
    }
    return null;
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
