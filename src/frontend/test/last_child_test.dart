import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pictocomm/app.dart';
import 'package:pictocomm/features/catalog/presentation/screens/home_screen.dart';
import 'package:pictocomm/features/profiles/domain/entities/child_profile.dart';
import 'package:pictocomm/features/profiles/presentation/providers/children_provider.dart';
import 'package:pictocomm/features/profiles/presentation/providers/session_provider.dart';
import 'package:pictocomm/features/profiles/presentation/screens/child_selector_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fakes.dart';
import 'package:pictocomm/features/profiles/data/datasources/local_child_profile_data_source.dart';
import 'package:pictocomm/features/profiles/data/repositories/local_child_profile_repository.dart';

/// REQ-PER-01: el último chico activo de la cuenta se persiste y se restaura
/// como marca visual en el selector. La app SIEMPRE arranca en el selector
/// (RF2.1): la marca NO activa la sesión, el tap de siempre sí.
void main() {
  group('persistencia por cuenta (repositorio real + SharedPreferences mock)', () {
    test('cada cuenta guarda su propio childId (sin fugas entre cuentas)', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      const repository = LocalChildProfileRepository(dataSource: LocalChildProfileDataSource());

      await repository.setLastChildId('child-a', accountId: 'account-1');
      await repository.setLastChildId('child-b', accountId: 'account-2');

      expect(await repository.getLastChildId(accountId: 'account-1'), 'child-a');
      expect(await repository.getLastChildId(accountId: 'account-2'), 'child-b');
      // Otra cuenta (o sin sesión) no hereda la preselección de ninguna.
      expect(await repository.getLastChildId(accountId: 'account-3'), isNull);
      expect(await repository.getLastChildId(), isNull);
    });

    test('sin cuenta logueada usa la clave legacy compartida', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      const repository = LocalChildProfileRepository(dataSource: LocalChildProfileDataSource());

      await repository.setLastChildId('child-legacy');
      expect(await repository.getLastChildId(), 'child-legacy');

      // La clave legacy es independiente de las claves por cuenta.
      expect(await repository.getLastChildId(accountId: 'account-1'), isNull);
    });

    test('setLastChildId(null) limpia la clave de esa cuenta', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      const repository = LocalChildProfileRepository(dataSource: LocalChildProfileDataSource());

      await repository.setLastChildId('child-a', accountId: 'account-1');
      await repository.setLastChildId(null, accountId: 'account-1');

      expect(await repository.getLastChildId(accountId: 'account-1'), isNull);
      // Borrar una clave inexistente es idempotente.
      await repository.setLastChildId(null, accountId: 'account-9');
      expect(await repository.getLastChildId(accountId: 'account-9'), isNull);
    });
  });

  group('SessionProvider persiste cada cambio de chico activo (fake)', () {
    test('setActiveChild guarda el chico por su cuenta dueña y lo marca', () async {
      final repository = FakeChildProfileRepository();
      final session = SessionProvider(childProfileRepository: repository);

      session.setActiveChild(
        const ChildProfile(id: 'child-a', name: 'Nina', accountId: 'account-1'),
      );

      expect(session.activeChild?.id, 'child-a');
      expect(session.lastChildId, 'child-a');
      expect(repository.lastChildIdFor('account-1'), 'child-a');
    });

    test('legacy (sin cuenta) persiste en la clave legacy', () async {
      final repository = FakeChildProfileRepository();
      final session = SessionProvider(childProfileRepository: repository);

      session.setActiveChild(const ChildProfile(id: 'child-a', name: 'Nina'));

      expect(repository.lastChildIdFor(null), 'child-a');
      expect(repository.lastChildIdFor('account-1'), isNull);
    });

    test('borrar al chico marcado limpia su clave persistida', () async {
      final repository = FakeChildProfileRepository();
      final session = SessionProvider(childProfileRepository: repository);
      session.setActiveChild(const ChildProfile(id: 'child-a', name: 'Nina', accountId: 'account-1'));

      session.clearIfDeleted('child-a');

      expect(session.activeChild, isNull);
      expect(session.lastChildId, isNull);
      expect(repository.lastChildIdFor('account-1'), isNull);
    });

    test('borrar otro chico no toca la marca del activo', () async {
      final repository = FakeChildProfileRepository();
      final session = SessionProvider(childProfileRepository: repository);
      session.setActiveChild(const ChildProfile(id: 'child-a', name: 'Nina', accountId: 'account-1'));

      session.clearIfDeleted('child-otro');

      expect(session.activeChild?.id, 'child-a');
      expect(session.lastChildId, 'child-a');
      expect(repository.lastChildIdFor('account-1'), 'child-a');
    });

    test('logout (clear) resetea la marca en memoria pero la clave queda por cuenta', () async {
      final repository = FakeChildProfileRepository();
      final session = SessionProvider(childProfileRepository: repository);
      session.setActiveChild(const ChildProfile(id: 'child-a', name: 'Nina', accountId: 'account-1'));

      session.clear();

      expect(session.activeChild, isNull);
      expect(session.lastChildId, isNull);
      // REQ-PER-01: la preselección es por cuenta, el logout no la borra.
      expect(repository.lastChildIdFor('account-1'), 'child-a');
    });
  });

  group('restauración al cargar los chicos de la cuenta (ChildrenProvider)', () {
    test('restaura el childId persistido como marca, sin activar la sesión', () async {
      final repository = FakeChildProfileRepository(
        children: [
          const ChildProfile(id: 'child-a', name: 'Nina', accountId: 'account-1'),
          const ChildProfile(id: 'child-b', name: 'Benja', accountId: 'account-1'),
        ],
      );
      await repository.setLastChildId('child-b', accountId: 'account-1');
      final session = SessionProvider();
      final provider_ = ChildrenProvider(
        childProfileRepository: repository,
        accountId: 'account-1',
        sessionProvider: session,
      );

      await provider_.load();

      final state = provider_.state as ChildrenLoadedState;
      expect(state.children.map((child) => child.id), containsAll(['child-a', 'child-b']));
      // Solo marca: la sesión sigue sin chico activo (RF2.1).
      expect(session.lastChildId, 'child-b');
      expect(session.activeChild, isNull);
    });

    test('una cuenta no preselecciona el chico de otra', () async {
      final repository = FakeChildProfileRepository(
        children: [const ChildProfile(id: 'child-b', name: 'Benja', accountId: 'account-1')],
      );
      await repository.setLastChildId('child-b', accountId: 'account-1');
      final session = SessionProvider();
      final provider_ = ChildrenProvider(
        childProfileRepository: repository,
        // Otra cuenta: los chicos de account-1 ni siquiera son visibles.
        accountId: 'account-2',
        sessionProvider: session,
      );

      await provider_.load();

      expect(session.lastChildId, isNull);
      expect(session.activeChild, isNull);
    });

    test('chico marcado borrado: sin marca y la clave persistida queda limpia', () async {
      final repository = FakeChildProfileRepository(
        children: [const ChildProfile(id: 'child-a', name: 'Nina', accountId: 'account-1')],
      );
      await repository.setLastChildId('child-viejo', accountId: 'account-1');
      final session = SessionProvider();
      final provider_ = ChildrenProvider(
        childProfileRepository: repository,
        accountId: 'account-1',
        sessionProvider: session,
      );

      await provider_.load();

      expect(session.lastChildId, isNull);
      expect(session.activeChild, isNull);
      expect(repository.lastChildIdFor('account-1'), isNull);
    });

    test('sin marca persistida (primera vez) no marca nada', () async {
      final repository = FakeChildProfileRepository(
        children: [const ChildProfile(id: 'child-a', name: 'Nina', accountId: 'account-1')],
      );
      final session = SessionProvider();
      final provider_ = ChildrenProvider(
        childProfileRepository: repository,
        accountId: 'account-1',
        sessionProvider: session,
      );

      await provider_.load();

      expect(session.lastChildId, isNull);
      expect(session.activeChild, isNull);
      expect(repository.lastChildIdFor('account-1'), isNull);
    });
  });

  group('flujo del selector (widget)', () {
    Future<void> login(WidgetTester tester) async {
      // REQ-ACC-01: el primer frame es splash mientras se restaura la sesión;
      // un pump deja visible el login.
      await tester.pump();
      await tester.enterText(find.byKey(const Key('login_email')), 'casa@pictocomm.app');
      await tester.enterText(find.byKey(const Key('login_password')), 'secreta123');
      await tester.tap(find.text('Iniciar Sesión'));
      await tester.pumpAndSettle();
    }

    SessionProvider sessionOf(WidgetTester tester) {
      final context = tester.element(find.byType(ChildSelectorScreen).first);
      return Provider.of<SessionProvider>(context, listen: false);
    }

    testWidgets('la tarjeta del último chico activo aparece marcada, sin entrar a la sesión', (tester) async {
      final repository = FakeChildProfileRepository(
        children: [
          const ChildProfile(id: 'child-nina', name: 'Nina', accountId: 'account-test'),
          const ChildProfile(id: 'child-benja', name: 'Benja', accountId: 'account-test'),
        ],
      );
      await repository.setLastChildId('child-nina', accountId: 'account-test');

      await tester.pumpWidget(
        PictoCommApp(
          dependencies: fakeDependencies(
            childProfileRepository: repository,
          ),
        ),
      );
      await login(tester);

      // El selector sigue siendo la pantalla de arranque (RF2.1).
      expect(find.text('¿Quién se comunica hoy?'), findsOneWidget);
      // REQ-PER-01: la marca visual está SOLO en la tarjeta de Nina.
      expect(find.text('Último en usar'), findsOneWidget);
      expect(find.text('Nina'), findsOneWidget);
      expect(find.text('Benja'), findsOneWidget);
      // NO se entró a la sesión: no hay home y la sesión no tiene chico.
      expect(find.byType(HomeScreen), findsNothing);
      final session = sessionOf(tester);
      expect(session.activeChild, isNull);
      expect(session.lastChildId, 'child-nina');
    });

    testWidgets('el chico marcado borrado no marca ninguna tarjeta y limpia la clave', (tester) async {
      final repository = FakeChildProfileRepository(
        children: [
          const ChildProfile(id: 'child-nina', name: 'Nina', accountId: 'account-test'),
          const ChildProfile(id: 'child-benja', name: 'Benja', accountId: 'account-test'),
        ],
      );
      await repository.setLastChildId('child-viejo', accountId: 'account-test');

      await tester.pumpWidget(
        PictoCommApp(
          dependencies: fakeDependencies(
            childProfileRepository: repository,
          ),
        ),
      );
      await login(tester);

      expect(find.text('¿Quién se comunica hoy?'), findsOneWidget);
      expect(find.text('Último en usar'), findsNothing);
      final session = sessionOf(tester);
      expect(session.lastChildId, isNull);
      expect(session.activeChild, isNull);
      expect(repository.lastChildIdFor('account-test'), isNull);
    });

    testWidgets('tocar la tarjeta marcada activa la sesión como siempre y persiste el chico', (tester) async {
      final repository = FakeChildProfileRepository(
        children: [
          const ChildProfile(id: 'child-nina', name: 'Nina', accountId: 'account-test'),
          const ChildProfile(id: 'child-benja', name: 'Benja', accountId: 'account-test'),
        ],
      );
      await repository.setLastChildId('child-nina', accountId: 'account-test');

      await tester.pumpWidget(
        PictoCommApp(
          dependencies: fakeDependencies(
            childProfileRepository: repository,
          ),
        ),
      );
      await login(tester);

      // Tap en la tarjeta de Benja (no marcada): el flujo no cambia.
      await tester.tap(find.text('Benja'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      final context = tester.element(find.byType(HomeScreen).first);
      final session = Provider.of<SessionProvider>(context, listen: false);
      expect(session.activeChild?.id, 'child-benja');
      // REQ-PER-01: el nuevo chico activo queda persistido como marca.
      expect(session.lastChildId, 'child-benja');
      expect(repository.lastChildIdFor('account-test'), 'child-benja');
    });
  });
}
