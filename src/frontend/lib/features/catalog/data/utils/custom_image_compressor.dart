import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../../../core/error/app_exception.dart';

/// REQ-CAT-01 (pregunta abierta #1, RF-3.2/RF-3.3): límite de tamaño de las
/// imágenes de pictos personalizados. Los bytes se persisten como data URL en
/// el storage del dispositivo (ver `DataUrl`) y viajan al backend por el
/// outbox (REQ-BCK-02), así que hay que comprimirlos antes de guardarlos:
/// una foto de cámara o una imagen web pueden pesar megas y el storage y la
/// subida no están para eso.
///
/// Este helper es el **único punto** por donde pasan los bytes de una imagen
/// custom: galería, cámara y URL bajada (ver `AddPictoScreen`).
final class CustomImageCompressor {
  const CustomImageCompressor._();

  /// REQ-CAT-01 (RF-CAT): lado mayor máximo, en píxeles, de una imagen custom
  /// persistida. Suficiente para las cards y el detalle; mantiene el data URL
  /// en un tamaño razonable.
  static const int maxSide = 1024;

  /// Calidad de re-encodeo JPEG para lo que no necesita transparencia.
  static const int _jpegQuality = 85;

  /// Firma inicial de un archivo PNG.
  static const List<int> _pngMagic = [0x89, 0x50, 0x4E, 0x47];

  /// Comprime los bytes crudos de una imagen elegida (galería, cámara o URL
  /// bajada) y los devuelve listos para persistir en data URL:
  ///
  /// - Si el lado mayor supera [maxSide], reescala manteniendo el aspecto.
  /// - Si la fuente es PNG **con transparencia**, sale PNG (conserva el
  ///   alpha); en cualquier otro caso sale JPEG a calidad [_jpegQuality],
  ///   que es lo más liviano para subir al backend.
  ///
  /// Devuelve los bytes comprimidos con el mime correcto
  /// (`image/png` o `image/jpeg`). Lanza [DataSourceException] si los bytes
  /// no decodifican como imagen (formato no soportado o archivo corrupto).
  static ({Uint8List bytes, String mime}) compress(Uint8List raw) {
    final decoded = img.decodeImage(raw);
    if (decoded == null) {
      throw const DataSourceException('Los bytes no son una imagen válida');
    }
    final resized = _resizeIfNeeded(decoded);
    final needsPng = _isPng(raw) && _usesTransparency(resized);
    final bytes = needsPng
        ? img.encodePng(resized)
        : img.encodeJpg(resized, quality: _jpegQuality);
    return (bytes: bytes, mime: needsPng ? 'image/png' : 'image/jpeg');
  }

  /// Reescala a máx [maxSide] en el lado mayor, manteniendo el aspecto:
  /// `copyResize` calcula el lado opuesto cuando se le pasa uno solo.
  static img.Image _resizeIfNeeded(img.Image image) {
    if (math.max(image.width, image.height) <= maxSide) {
      return image;
    }
    return image.width >= image.height
        ? img.copyResize(image, width: maxSide)
        : img.copyResize(image, height: maxSide);
  }

  static bool _isPng(Uint8List bytes) {
    if (bytes.length < _pngMagic.length) {
      return false;
    }
    for (var i = 0; i < _pngMagic.length; i++) {
      if (bytes[i] != _pngMagic[i]) {
        return false;
      }
    }
    return true;
  }

  /// true si el decodificado tiene transparencia real (algún pixel con alpha
  /// distinto de opaco). Si no hay canal alpha no hace falta escanear.
  static bool _usesTransparency(img.Image image) {
    if (image.numChannels < 4) {
      return false;
    }
    for (final pixel in image) {
      if (pixel.a != 255) {
        return true;
      }
    }
    return false;
  }
}
