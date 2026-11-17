import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pictocomm/core/error/app_exception.dart';
import 'package:pictocomm/features/catalog/data/utils/custom_image_compressor.dart';

/// REQ-CAT-01 (pregunta abierta #1, RF-CAT): límite de tamaño de imágenes
/// custom. El helper reescala a máx 1024px y re-encodea (PNG solo si la
/// fuente es PNG con transparencia; sino JPEG q85).
void main() {
  group('CustomImageCompressor', () {
    test('REQ-CAT-01: una imagen 3000x2000 sale con lados <= 1024 y aspecto', () {
      final big = img.Image(width: 3000, height: 2000);
      img.fill(big, color: img.ColorRgb8(200, 30, 30));
      final raw = img.encodePng(big);

      final result = CustomImageCompressor.compress(raw);

      final decoded = img.decodeImage(result.bytes)!;
      expect(decoded.width <= CustomImageCompressor.maxSide, isTrue);
      expect(decoded.height <= CustomImageCompressor.maxSide, isTrue);
      // Mantiene el aspecto 3:2 (redondeo del reescalado).
      expect(decoded.width / decoded.height, closeTo(1.5, 0.01));
      // PNG sin transparencia -> JPEG.
      expect(result.mime, 'image/jpeg');
    });

    test('REQ-CAT-01: una imagen vertical grande sale <= 1024 de alto', () {
      final big = img.Image(width: 800, height: 3000);
      img.fill(big, color: img.ColorRgb8(30, 30, 200));
      final raw = img.encodeJpg(big, quality: 95);

      final result = CustomImageCompressor.compress(raw);

      final decoded = img.decodeImage(result.bytes)!;
      expect(decoded.height, CustomImageCompressor.maxSide);
      expect(decoded.width <= CustomImageCompressor.maxSide, isTrue);
      expect(result.mime, 'image/jpeg');
    });

    test('REQ-CAT-01: un PNG chico con transparencia queda PNG sin reescalar', () {
      final small = img.Image(width: 400, height: 300, numChannels: 4);
      img.fill(small, color: img.ColorRgba8(10, 200, 10, 255));
      small.setPixelRgba(5, 5, 0, 0, 0, 0);
      final raw = img.encodePng(small);

      final result = CustomImageCompressor.compress(raw);

      expect(result.mime, 'image/png');
      expect(img.decodeImage(result.bytes)!.getPixel(5, 5).a, 0);
      final decoded = img.decodeImage(result.bytes)!;
      expect(decoded.width, 400);
      expect(decoded.height, 300);
    });

    test('REQ-CAT-01: un PNG grande con transparencia reescala y queda PNG', () {
      final big = img.Image(width: 2048, height: 1024, numChannels: 4);
      img.fill(big, color: img.ColorRgba8(10, 10, 200, 255));
      big.setPixelRgba(0, 0, 0, 0, 0, 0);
      final raw = img.encodePng(big);

      final result = CustomImageCompressor.compress(raw);

      expect(result.mime, 'image/png');
      final decoded = img.decodeImage(result.bytes)!;
      expect(decoded.width, CustomImageCompressor.maxSide);
      expect(decoded.height <= CustomImageCompressor.maxSide, isTrue);
    });

    test('REQ-CAT-01: una imagen chica no se toca (no reescala)', () {
      final small = img.Image(width: 500, height: 300);
      img.fill(small, color: img.ColorRgb8(255, 200, 0));
      final raw = img.encodePng(small);

      final result = CustomImageCompressor.compress(raw);

      final decoded = img.decodeImage(result.bytes)!;
      expect(decoded.width, 500);
      expect(decoded.height, 300);
    });

    test('REQ-CAT-01: bytes que no decodifican lanzan DataSourceException', () async {
      final invalid = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      await expectLater(
        () async => CustomImageCompressor.compress(invalid),
        throwsA(isA<DataSourceException>()),
      );
    });
  });
}
