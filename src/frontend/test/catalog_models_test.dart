import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:pictocomm/features/catalog/data/models/category_model.dart';
import 'package:pictocomm/features/catalog/data/models/picto_model.dart';

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
}
