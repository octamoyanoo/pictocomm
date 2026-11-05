import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pictocomm/app.dart';
import 'package:pictocomm/core/error/app_exception.dart';
import 'package:pictocomm/features/catalog/domain/entities/picto.dart';
import 'package:pictocomm/features/voice/domain/voice_provider.dart';

import 'helpers/fakes.dart';

/// Voz de prueba con registro de reproducciones (contrato de `VoiceProvider`).
/// `speak` completa de inmediato, para testing determinista del orden.
final class RecordingVoice implements VoiceProvider {
  final List<String> _words = [];

  List<String> get spokenWords => List.unmodifiable(_words);

  int stops = 0;

  void reset() {
    _words.clear();
    stops = 0;
  }

  @override
  Future<void> speak(String word) async {
    if (word.trim().isEmpty) {
      throw const VoiceException('No se puede pronunciar un texto vacío');
    }
    _words.add(word);
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> dispose() async {}
}

/// Picto custom de prueba (el errorBuilder muestra placeholder si la imagen
/// mínima no decodifica; el label siempre está).
Picto testPicto(String label) {
  final now = DateTime.now().toUtc();
  return Picto(
    id: 'test-$label',
    label: label,
    categoryId: 'test-category',
    source: PictoSource.custom,
    imageUrl: 'data:image/png;base64,iVBORw0KGgo=',
    createdAt: now,
    updatedAt: now,
  );
}

/// RF1 — Comunicación: barra de frase, Play bajo demanda, basuras y feedback
/// visual del toque (RF1.2–RF1.9).
///
/// La voz va detrás de la abstracción `VoiceProvider` (RF1.10/1.11): la UI
/// solo la conoce por contrato. Si algún camino de UI llamara al TTS al tocar
/// un picto, `spokenWords` se llenaría y los tests de RF1.2 lo detectarían.
void main() {
  final voice = RecordingVoice();
  const comunicarTab = Key('bottom_nav_/comunicar');

  Future<void> goCommunicate(WidgetTester tester) async {
    voice.reset();
    await tester.pumpWidget(
      PictoCommApp(
        dependencies: fakeDependencies(
          children: [testChildProfile()],
          pictos: [testPicto('banana'), testPicto('manzana'), testPicto('leche')],
          voiceProvider: voice,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('login_email')), 'casa@pictocomm.app');
    await tester.enterText(find.byKey(const Key('login_password')), 'secreta123');
    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nina'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(comunicarTab));
    await tester.pumpAndSettle();
    expect(find.text('Comunicar'), findsWidgets);
  }

  testWidgets('RF1.2: tocar un picto NO emite sonido; lo agrega a la barra y lo destaca', (tester) async {
    await goCommunicate(tester);
    expect(find.text('Toca pictogramas para armar tu frase'), findsOneWidget);

    await tester.tap(find.text('manzana'));
    await tester.pump();

    // Feedback visual del toque (picto destacado en la grilla).
    expect(find.byKey(const Key('picto_highlighted')), findsOneWidget);
    // Aparición en la barra (chip): card + chip.
    expect(find.text('manzana'), findsNWidgets(2));
    // El único canal de confirmación NO es el sonido: nadie llamó a speak().
    expect(voice.spokenWords, isEmpty);

    // El destaque es transitorio (el timer del flash corre en el reloj fake).
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const Key('picto_highlighted')), findsNothing);
  });

  testWidgets('RF1.3/1.4: la barra mantiene el orden de selección', (tester) async {
    await goCommunicate(tester);

    await tester.tap(find.text('banana'));
    await tester.pump();
    await tester.tap(find.text('manzana'));
    await tester.pump();
    await tester.tap(find.text('leche'));
    await tester.pump(const Duration(milliseconds: 500)); // expira el flash del tap
    await tester.pumpAndSettle();

    // Cada picto está card + chip (isla sin límite aparente, RF1.4).
    expect(find.text('banana'), findsNWidgets(2));
    expect(find.text('manzana'), findsNWidgets(2));
    expect(find.text('leche'), findsNWidgets(2));
    // El orden real de la tira es el de selección (RF1.3): los chips de la
    // tira (primeros en el árbol) quedan de izquierda a derecha en orden.
    final bananaX = tester.getCenter(find.text('banana').first).dx;
    final manzanaX = tester.getCenter(find.text('manzana').first).dx;
    final lecheX = tester.getCenter(find.text('leche').first).dx;
    expect(bananaX, lessThan(manzanaX));
    expect(manzanaX, lessThan(lecheX));
    expect(voice.spokenWords, isEmpty); // construir no habla
  });

  testWidgets('RF1.5/1.6: Play reproduce en orden con la voz, bajo demanda', (tester) async {
    await goCommunicate(tester);

    await tester.tap(find.text('banana'));
    await tester.pump();
    await tester.tap(find.text('manzana'));
    await tester.pumpAndSettle();

    expect(voice.spokenWords, isEmpty);
    await tester.tap(find.byTooltip('Reproducir frase'));
    await tester.pumpAndSettle();

    // Orden de selección (RF1.6) y palabra por palabra (RF1.5).
    expect(voice.spokenWords, <String>['banana', 'manzana']);
  });

  testWidgets('RF1.7: tras reproducir la barra se mantiene (reproducible de nuevo)', (tester) async {
    await goCommunicate(tester);

    await tester.tap(find.text('banana'));
    await tester.pump();
    await tester.tap(find.text('manzana'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Reproducir frase'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();

    // La barra sigue: los chips siguen en la tira.
    expect(find.text('banana'), findsNWidgets(2));
    expect(find.text('manzana'), findsNWidgets(2));

    // Reproducir de nuevo: dos palabras más, mismas.
    await tester.tap(find.byTooltip('Reproducir frase'));
    await tester.pumpAndSettle();
    expect(voice.spokenWords, <String>['banana', 'manzana', 'banana', 'manzana']);
  });

  testWidgets('RF1.9: la mini-basura quita un picto individual de la barra', (tester) async {
    await goCommunicate(tester);

    await tester.tap(find.text('banana'));
    await tester.pump();
    await tester.tap(find.text('manzana'));
    await tester.pumpAndSettle();

    // Las mini-basuras de los chips están antes de la basura global en el
    // árbol (la tira se construye antes de la fila de acciones).
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();

    // Solo quedó manzana en la tira; banana volvió a ser solo la card.
    expect(find.text('banana'), findsOneWidget);
    expect(find.text('manzana'), findsNWidgets(2));
  });

  testWidgets('RF1.8: la basura global limpia toda la barra de una vez', (tester) async {
    await goCommunicate(tester);

    await tester.tap(find.text('banana'));
    await tester.pump();
    await tester.tap(find.text('manzana'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Limpiar frase'));
    await tester.pumpAndSettle();

    expect(find.text('Toca pictogramas para armar tu frase'), findsOneWidget);
    expect(find.text('banana'), findsOneWidget); // solo la card
    expect(find.text('manzana'), findsOneWidget); // solo la card
  });

  testWidgets('RF1.5: Play está visible siempre; con frase vacía no reproduce', (tester) async {
    await goCommunicate(tester);

    final play = find.byTooltip('Reproducir frase');
    expect(play, findsOneWidget);

    // Con frase vacía: deshabilitado, la voz no arranca.
    await tester.tap(play);
    await tester.pumpAndSettle();
    expect(voice.spokenWords, isEmpty);
    expect(find.text('Toca pictogramas para armar tu frase'), findsOneWidget);
  });
}
