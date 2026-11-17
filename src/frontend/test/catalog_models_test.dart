import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:pictocomm/features/catalog/data/models/category_model.dart';
import 'package:pictocomm/features/catalog/data/models/picto_model.dart';
import 'package:pictocomm/features/catalog/domain/entities/picto.dart';

void main() {
  test('CategoryModel roundtrip JSON <-> entidad', () {
    final model = CategoryModel.fromJson(const {
      'id': 'bebidas',
      'name': 'Bebidas',
      'color': '#4FC3F7',
      'icon': 'cup',
    });
    final entity = model.toEntity();

    expect(entity.id, 'bebidas');
    expect(entity.name, 'Bebidas');
    expect(entity.color, const Color(0xFF4FC3F7));
    expect(entity.icon, 'cup');

    final json = model.toJson();
    expect(json, {'id': 'bebidas', 'name': 'Bebidas', 'color': '#4fc3f7', 'icon': 'cup', 'custom': false});

    // RF3.9: la categoría persistida es custom; el roundtrip conserva el flag.
    final persistedEntity = const CategoryModel(id: 'talleres', name: 'Talleres', color: 0xFF4FC3F7, icon: 'category', custom: true).toEntity();
    expect(persistedEntity.custom, isTrue);
  });

  test('PictoModel roundtrip JSON <-> entidad', () {
    final model = PictoModel.fromJson(const {
      'id': 'agua-001',
      'label': 'Agua',
      'categoryIds': ['bebidas'],
      'imageUrl': 'https://cdn.example.com/agua.png',
      'source': 'remote',
      'createdAt': '2026-01-01T00:00:00Z',
      'updatedAt': '2026-01-10T00:00:00Z',
    });
    final entity = model.toEntity();

    expect(entity.label, 'Agua');
    // REQ-CAT-02 (RF-3.13): la pertenencia es una lista.
    expect(entity.categoryIds, ['bebidas']);
    expect(entity.belongsTo('bebidas'), isTrue);
    expect(entity.belongsTo('comidas'), isFalse);
    expect(entity.source.name, 'remote');
    expect(entity.createdAt.toUtc(), DateTime.utc(2026, 1, 1));
    expect(entity.updatedAt.toUtc(), DateTime.utc(2026, 1, 10));

    final json = model.toJson();
    expect(json['id'], 'agua-001');
    expect(json['source'], 'remote');
    expect(json['createdAt'], '2026-01-01T00:00:00.000Z');
    expect(json['categoryIds'], ['bebidas']);
  });

  test('PictoModel migra el formato v1 (categoryId único) a categoryIds (RNF-3.8)', () {
    final migrated = PictoModel.fromJson(const {
      'id': 'agua-001',
      'label': 'Agua',
      'categoryId': 'bebidas',
      'imageUrl': 'https://cdn.example.com/agua.png',
      'source': 'remote',
      'createdAt': '2026-01-01T00:00:00Z',
      'updatedAt': '2026-01-10T00:00:00Z',
    });
    expect(migrated.categoryIds, ['bebidas']);

    // El formato nuevo siempre gana si están ambos.
    final both = PictoModel.fromJson(const {
      'id': 'agua-002',
      'label': 'Agua',
      'categoryId': 'bebidas',
      'categoryIds': ['bebidas', 'comidas'],
      'imageUrl': 'https://cdn.example.com/agua.png',
      'source': 'remote',
      'createdAt': '2026-01-01T00:00:00Z',
      'updatedAt': '2026-01-10T00:00:00Z',
    });
    expect(both.categoryIds, ['bebidas', 'comidas']);
  });

  // ---- REQ-IDI-01 (RF-4.9/RF-4.10): etiquetas multilingües ----

  test('PictoModel roundtrip con labels; JSON sin labels queda igual a siempre', () {
    final translated = PictoModel.fromJson(const {
      'id': 'agua-001',
      'label': 'agua',
      'labels': {'en': 'Water', 'pt': 'Água'},
      'categoryIds': ['bebidas'],
      'imageUrl': 'https://cdn.example.com/agua.png',
      'source': 'remote',
      'createdAt': '2026-01-01T00:00:00Z',
      'updatedAt': '2026-01-10T00:00:00Z',
    });
    expect(translated.toEntity().labels, {'en': 'Water', 'pt': 'Água'});
    expect(translated.toJson()['labels'], {'en': 'Water', 'pt': 'Água'});

    // Cache de SharedPreferences / outbox viejos: sin el campo no rompe y
    // el JSON re-serializado no gana claves nuevas (RF-4.10).
    final legacy = PictoModel.fromJson(const {
      'id': 'agua-002',
      'label': 'agua',
      'categoryIds': ['bebidas'],
      'imageUrl': 'https://cdn.example.com/agua.png',
      'source': 'remote',
      'createdAt': '2026-01-01T00:00:00Z',
      'updatedAt': '2026-01-10T00:00:00Z',
    });
    expect(legacy.toEntity().labels, isEmpty);
    expect(legacy.toJson().containsKey('labels'), isFalse);
  });

  test('labelFor: traducción del idioma activo, base español como fallback (RF-4.9/4.10)', () {
    final agua = Picto(
      id: 'agua-001',
      label: 'agua',
      categoryIds: ['bebidas'],
      source: PictoSource.bundled,
      labels: {'es': 'lápiz', 'en': 'Water', 'pt': 'Água'},
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    expect(agua.labelFor('en'), 'Water');
    expect(agua.labelFor('pt'), 'Água');
    expect(agua.labelFor('es'), 'lápiz');
    expect(agua.label, 'agua');

    // Custom sin traducciones: cualquier idioma cae a la base.
    final custom = Picto(
      id: 'custom-1',
      label: 'mamá',
      categoryIds: ['familia'],
      source: PictoSource.custom,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    expect(custom.labelFor('en'), 'mamá');
    expect(custom.labelFor('pt'), 'mamá');
    // Idioma sin entrada: ídem.
    expect(agua.labelFor('fr'), 'agua');
  });

  test('matchesQuery: la búsqueda encuentra por la base o cualquier traducción (RF-4.9)', () {
    final agua = Picto(
      id: 'agua-001',
      label: 'agua',
      categoryIds: ['bebidas'],
      source: PictoSource.bundled,
      labels: {'en': 'Water', 'pt': 'Água'},
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    expect(agua.matchesQuery('agua'), isTrue);
    expect(agua.matchesQuery('water'), isTrue);
    expect(agua.matchesQuery('água'), isTrue);
    expect(agua.matchesQuery('WAT'), isTrue);
    expect(agua.matchesQuery('pan'), isFalse);
    expect(agua.matchesQuery(''), isTrue);
  });

  test('CategoryModel: names en el JSON; nameFor con fallback; búsqueda multilingüe', () {
    final lugares = CategoryModel.fromJson(const {
      'id': 'lugares',
      'name': 'Lugares',
      'color': '#2E86AB',
      'icon': 'place',
      'names': {'en': 'Places', 'pt': 'Lugares'},
    }).toEntity();
    expect(lugares.nameFor('en'), 'Places');
    expect(lugares.nameFor('es'), 'Lugares');
    expect(lugares.matchesQuery('Places'), isTrue);
    expect(lugares.matchesQuery('Lugares'), isTrue);
    expect(lugares.matchesQuery('Comida'), isFalse);

    // Custom sin traducciones: el JSON no gana la clave (exactitud viva en
    // el test del roundtrip de arriba).
    const custom = CategoryModel(id: 'talleres', name: 'Talleres', color: 0xFF4FC3F7, icon: 'category');
    expect(custom.toJson().containsKey('names'), isFalse);
    expect(custom.toEntity().nameFor('en'), 'Talleres');
  });
}
