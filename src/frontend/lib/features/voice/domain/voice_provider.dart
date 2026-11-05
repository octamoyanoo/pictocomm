/// Abstracción de generación de voz del proyecto (RF1.11).
///
/// Interfaz pura: no depende de Flutter, ni de plugins, ni de assets.
/// La UI no conoce el mecanismo concreto (TTS del sistema, audios
/// pre-generados con IA, híbrido), solo este contrato.
///
/// El futuro modo híbrido (RF1.11) se implementa cambiando la clase
/// que satisface esta interfaz en el composition root, sin tocar pantallas.
abstract interface class VoiceProvider {
  /// Pronuncia [word] y completa el future cuando termina de sonar:
  /// permite encadenar palabras para reproducir una frase en orden.
  ///
  /// Puede lanzar [VoiceException] si la voz no está disponible.
  Future<void> speak(String word);

  /// Detiene cualquier locución en curso de forma inmediata.
  Future<void> stop();

  /// Libera recursos del proveedor de voz, si corresponde.
  Future<void> dispose();
}
