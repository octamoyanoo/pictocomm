import 'dart:convert';
import 'dart:typed_data';

/// Data URLs de imágenes locales (RF3.2/RF3.3): los bytes se guardan como
/// `data:<mime>;base64,...` dentro del storage del dispositivo, de modo que
/// la imagen vive en el teléfono y no depende de red después de crearse.
final class DataUrl {
  const DataUrl._();

  /// Decodifica un data URL a bytes. Lanza [FormatException] si no es válido.
  static Uint8List decode(String url) {
    final commaIndex = url.indexOf(',');
    if (!url.startsWith('data:') || commaIndex < 0) {
      throw const FormatException('La imagen no es un data URL válido');
    }
    return base64Decode(url.substring(commaIndex + 1));
  }

  /// Arma un data URL desde bytes; el mime se deduce por extensión.
  static String encode(Uint8List bytes, String mime) => 'data:$mime;base64,${base64Encode(bytes)}';

  /// Devuelve true si [url] es un data URL de imagen.
  static bool isDataUrl(String url) => url.startsWith('data:image/');

  /// REQ-BCK-02 (RF-5.12): parte un data URL en mime + payload base64 para
  /// subirlo al backend. Lanza [FormatException] si no es un data URL de
  /// imagen válido.
  static (String mime, String base64) split(String url) {
    final commaIndex = url.indexOf(',');
    if (!url.startsWith('data:image/') || commaIndex < 0) {
      throw const FormatException('La imagen no es un data URL válido');
    }
    final header = url.substring('data:'.length, commaIndex); // "<mime>;base64"
    final mime = header.split(';').first.trim();
    return (mime, url.substring(commaIndex + 1));
  }
}
