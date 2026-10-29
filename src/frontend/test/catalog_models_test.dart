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
    expect(json, {'id': 'bebidas', 'name': 'Bebidas', 'color': '#4fc3f7', 'icon': 'cup'});
  });

  test('PictoModel roundtrip JSON <-> entidad', () {
    final model = PictoModel.fromJson(const {
      'id': 'agua-001',
      'label': 'Agua',
      'categoryId': 'bebidas',
      'imageUrl': 'https://cdn.example.com/agua.png',
      'source': 'remote',
      'createdAt': '2026-01-01T00:00:00Z',
      'updatedAt': '2026-01-10T00:00:00Z',
    });
    final entity = model.toEntity();

    expect(entity.label, 'Agua');
    expect(entity.categoryId, 'bebidas');
    expect(entity.source.name, 'remote');
    expect(entity.createdAt.toUtc(), DateTime.utc(2026, 1, 1));
    expect(entity.updatedAt.toUtc(), DateTime.utc(2026, 1, 10));

    final json = model.toJson();
    expect(json['id'], 'agua-001');
    expect(json['source'], 'remote');
    expect(json['createdAt'], '2026-01-01T00:00:00.000Z');
  });
}
