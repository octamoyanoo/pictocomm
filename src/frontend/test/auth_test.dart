import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pictocomm/app.dart';
import 'package:pictocomm/core/error/app_exception.dart';
import 'package:pictocomm/features/auth/domain/entities/auth_session.dart';
import 'package:pictocomm/features/auth/domain/entities/user_account.dart';
import 'package:pictocomm/features/auth/presentation/providers/auth_provider.dart';
import 'package:pictocomm/features/profiles/domain/entities/child_profile.dart';
import 'package:pictocomm/features/profiles/presentation/providers/children_provider.dart';

import 'helpers/fakes.dart';

/// REQ-ACC-01: autenticación real (RF-6.1 a RF-6.8).
///
/// El backend real tiene sus tests (`src/backend/test/auth_test.dart`); acá
/// van el [AuthProvider] sobre el fake, el scoping de perfiles por cuenta
/// (RF-6.6) y los flujos de pantalla con sesión recordada (RF-6.4).
void main() {
  AuthProvider provider(FakeAuthRepository repository) => AuthProvider(authRepository: repository);

  group('AuthProvider (RF-6.1 a RF-6.5)', () {
    test('login exitoso deja la sesión activa con su cuenta', () async {
      final auth = provider(FakeAuthRepository());
      await auth.login(email: 'casa@pictocomm.app', password: 'secreta123');

      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentAccountId, 'account-test');
      expect(auth.state, isA<AuthAuthenticatedState>());
      final account = (auth.state as AuthAuthenticatedState).account;
      expect(account.email, 'casa@pictocomm.app');
    });

    test('login con credenciales incorrectas lanza invalidCredentials y NO loguea', () async {
      final auth = provider(FakeAuthRepository(failures: {'casa@pictocomm.app': AuthErrorCode.invalidCredentials}));

      await expectLater(auth.login(email: 'casa@pictocomm.app', password: 'no'), throwsA(
        isA<AuthException>().having((error) => error.code, 'code', AuthErrorCode.invalidCredentials),
      ));
      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentAccountId, isNull);
    });

    test('registro con email en uso lanza emailInUse', () async {
      final auth = provider(FakeAuthRepository(failures: {'casa@pictocomm.app': AuthErrorCode.emailInUse}));

      await expectLater(auth.register(name: 'Ana', email: 'casa@pictocomm.app', password: 'secreta123'), throwsA(
        isA<AuthException>().having((error) => error.code, 'code', AuthErrorCode.emailInUse),
      ));
    });

    test('logout limpia la sesión (RF-6.5)', () async {
      final auth = provider(FakeAuthRepository());
      await auth.login(email: 'casa@pictocomm.app', password: 'secreta123');
      await auth.logout();

      expect(auth.state, isA<AuthUnauthenticatedState>());
      expect(auth.currentAccountId, isNull);
    });

    test('restore con sesión recordada entra autenticado (RF-6.4)', () async {
      final session = AuthSession(
        account: const UserAccount(id: 'account-42', name: 'Ana', email: 'ana@mail.com'),
        token: 'token-guardado',
        expiresAt: DateTime.now().add(const Duration(days: 5)),
      );
      final auth = provider(FakeAuthRepository(existingSession: session));
      await auth.restore();

      expect(auth.currentAccountId, 'account-42');
    });

    test('restore sin sesión queda sin autenticar', () async {
      final auth = provider(FakeAuthRepository());
      await auth.restore();

      expect(auth.state, isA<AuthUnauthenticatedState>());
    });
  });

  group('perfiles por cuenta (RF-6.6)', () {
    final mine = ChildProfile(id: 'c1', name: 'Nina', accountId: 'account-a');
    final others = ChildProfile(id: 'c2', name: 'Bruno', accountId: 'account-b');
    final legacy = ChildProfile(id: 'c3', name: 'Tomi'); // sin cuenta (legacy)

    test('getChildren con accountId devuelve los suyos + los legacy', () async {
      final repository = FakeChildProfileRepository(children: [mine, others, legacy]);

      final visible = await repository.getChildren(accountId: 'account-a');

      expect(visible.map((child) => child.id), ['c1', 'c3']);
    });

    test('createChild tagea la cuenta dueña', () async {
      final repository = FakeChildProfileRepository();

      final created = await repository.createChild(ChildProfile(id: '', name: 'Mora'), accountId: 'account-a');

      expect(created.accountId, 'account-a');
      expect((await repository.getChildren(accountId: 'account-b')).map((child) => child.id), isNot(contains(created.id)));
    });

    test('ChildrenProvider filtra por la cuenta inyectada', () async {
      final provider_ = ChildrenProvider(
        childProfileRepository: FakeChildProfileRepository(children: [mine, others, legacy]),
        accountId: 'account-b',
      );
      await provider_.load();

      final state = provider_.state as ChildrenLoadedState;
      expect(state.children.map((child) => child.id), ['c2', 'c3']);
    });
  });

  group('flujo de pantalla (RF-6.4, RF-6.8)', () {
    testWidgets('login con credenciales incorrectas muestra el error y queda en login', (tester) async {
      final app = PictoCommApp(
        dependencies: fakeDependencies(
          authRepository: FakeAuthRepository(failures: {'casa@pictocomm.app': AuthErrorCode.invalidCredentials}),
        ),
      );
      await tester.pumpWidget(app);
      await tester.pump();

      await tester.enterText(find.byKey(const Key('login_email')), 'casa@pictocomm.app');
      await tester.enterText(find.byKey(const Key('login_password')), 'otraclave99');
      await tester.tap(find.text('Iniciar Sesión'));
      await tester.pumpAndSettle();

      // RF-6.8: mensaje bajo el botón, sin navegar.
      expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);
      expect(find.byKey(const Key('login_email')), findsOneWidget);
    });

    testWidgets('sin conexión muestra el error de conexión y queda en login', (tester) async {
      final app = PictoCommApp(
        dependencies: fakeDependencies(
          authRepository: FakeAuthRepository(failures: {'casa@pictocomm.app': AuthErrorCode.connection}),
        ),
      );
      await tester.pumpWidget(app);
      await tester.pump();

      await tester.enterText(find.byKey(const Key('login_email')), 'casa@pictocomm.app');
      await tester.enterText(find.byKey(const Key('login_password')), 'secreta123');
      await tester.tap(find.text('Iniciar Sesión'));
      await tester.pumpAndSettle();

      expect(find.text('No hay conexión con el servidor. Probá de nuevo.'), findsOneWidget);
    });

    testWidgets('con sesión recordada la app abre directo en el selector (RF-6.4)', (tester) async {
      final session = AuthSession(
        account: const UserAccount(id: 'account-42', name: 'Ana', email: 'ana@mail.com'),
        token: 'token-guardado',
        expiresAt: DateTime.now().add(const Duration(days: 5)),
      );
      final app = PictoCommApp(
        dependencies: fakeDependencies(
          children: [testChildProfile()],
          authRepository: FakeAuthRepository(existingSession: session),
        ),
      );
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // El login NO aparece: la sesión recordada saltea la pantalla inicial.
      expect(find.byKey(const Key('login_email')), findsNothing);
      expect(find.text('¿Quién se comunica hoy?'), findsOneWidget);
    });

    testWidgets('logout desde Perfil vuelve al login (RF-6.5)', (tester) async {
      final app = PictoCommApp(
        dependencies: fakeDependencies(children: [testChildProfile()]),
      );
      await tester.pumpWidget(app);
      await tester.pump();

      await tester.enterText(find.byKey(const Key('login_email')), 'casa@pictocomm.app');
      await tester.enterText(find.byKey(const Key('login_password')), 'secreta123');
      await tester.tap(find.text('Iniciar Sesión'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nina'));
      await tester.pumpAndSettle();

      // Perfil (modo adulto) → sección Cuenta → cerrar sesión.
      // Sin setSurfaceSize: agrandar la superficie descentra el diálogo
      // (los botones quedan bajo el borde inferior real) y los taps no dan.
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      // Confirmación (RF-6.5) y regreso a la raíz con el login.
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.byKey(const Key('logout_confirm')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login_email')), findsOneWidget);
      expect(find.text('Iniciar Sesión'), findsOneWidget);
    });
  });
}
