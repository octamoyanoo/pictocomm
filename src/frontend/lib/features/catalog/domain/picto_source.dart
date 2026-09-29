/// Origen de la imagen de un [Picto].
///
/// Determina cómo se renderiza en la capa de presentación. Modelar esto como
/// enum en vez de un `bool isLocal` evita el `if (x) Image.file else
/// Image.asset` disperso por los widgets.
enum PictoSource {
  /// Empaquetada en la app, en `assets/images/`. No se puede editar ni borrar.
  bundled,

  /// Importada por la familia desde la cámara o la galería.
  custom,

  /// Servida por el backend. `imagePath` es una URL.
  remote;

  /// `true` si la imagen se resuelve con `Image.asset` en vez de
  /// `Image.file`/`Image.network`.
  bool get isBundled => this == PictoSource.bundled;
}
