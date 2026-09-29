import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:pictocomm_app/core/error/app_exception.dart';
import 'package:pictocomm_app/features/catalog/data/mappers/model_mapper.dart';
import 'package:pictocomm_app/features/catalog/data/models/picto_model.dart';
import 'package:pictocomm_app/features/catalog/domain/category.dart';
import 'package:pictocomm_app/features/catalog/domain/picto.dart';
import 'package:pictocomm_app/features/catalog/domain/picto_source.dart';

void main() {
  group('ModelMapper', () {
    test('mapea un PictoModel a la entidad Picto', () {
      final DateTime created = DateTime.utc(2026, 1, 15);

      final Picto picto = ModelMapper.mapPicto(
        PictoModel(
          id: 'p1',
          label: 'perro',
          categoryId: 'animales',
          imagePath: 'assets/images/animales/perro.png',
          source: 'bundled',
          audioPath: 'assets/audio/perro.mp3',
          createdAt: created,
        ),
      );

      expect(picto.id, 'p1');
      expect(picto.label, 'perro');
      expect(picto.source, PictoSource.bundled);
      expect(picto.hasAudio, isTrue);
      expect(picto.createdAt, created);
    });

    test('lanza ValidationException si el origen es desconocido', () {
      expect(
        () => ModelMapper.mapPicto(
          PictoModel(
            id: 'p1',
            label: 'perro',
            categoryId: 'animales',
            imagePath: 'x.png',
            source: 'inventado',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('ida y vuelta a JSON conserva los datos', () {
      final Picto original = Picto(
        id: 'p2',
        label: 'gato',
        categoryId: 'animales',
        imagePath: '/tmp/gato.jpg',
        source: PictoSource.custom,
        isFavorite: true,
        updatedAt: DateTime.utc(2026, 2, 1),
      );

      final Picto roundTrip = ModelMapper.mapPicto(
        PictoModel.fromJson(ModelMapper.toPictoModel(original).toJson()),
      );

      expect(roundTrip, original);
    });

    test('mapea Category con su color y sortOrder', () {
      final Category category = ModelMapper.mapCategory(
        ModelMapper.toCategoryModel(
          const Category(
            id: 'comida',
            name: 'Comida',
            assetFolder: 'comida',
            color: Color(0xFF4CAF50),
            sortOrder: 2,
          ),
        ),
      );

      expect(category.color, const Color(0xFF4CAF50));
      expect(category.sortOrder, 2);
    });
  });

  group('Picto', () {
    test('copyWith no pisa los campos no enviados', () {
      const Picto picto = Picto(
        id: 'p1',
        label: 'perro',
        categoryId: 'animales',
        imagePath: 'perro.png',
        source: PictoSource.custom,
        isFavorite: false,
      );

      final Picto updated = picto.copyWith(isFavorite: true);

      expect(updated.isFavorite, isTrue);
      expect(updated.label, 'perro');
      expect(updated.id, 'p1');
    });

    test('hasAudio es false con audio vacío', () {
      const Picto picto = Picto(
        id: 'p1',
        label: 'perro',
        categoryId: 'animales',
        imagePath: 'perro.png',
        source: PictoSource.bundled,
        audioPath: '',
      );

      expect(picto.hasAudio, isFalse);
    });
  });
}
