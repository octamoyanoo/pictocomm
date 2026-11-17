import 'package:pictocomm/core/di/injector.dart';
import 'package:pictocomm/core/theme/app_theme.dart';
import 'package:pictocomm/core/error/app_exception.dart';
import 'package:pictocomm/features/auth/domain/entities/auth_session.dart';
import 'package:pictocomm/features/auth/domain/entities/user_account.dart';
import 'package:pictocomm/features/auth/domain/repositories/auth_repository.dart';
import 'package:pictocomm/features/catalog/data/datasources/remote_catalog_data_source.dart';import 'package:pictocomm/features/catalog/data/models/category_model.dart';
import 'package:pictocomm/features/catalog/data/models/picto_model.dart';
import 'package:pictocomm/features/catalog/domain/entities/category.dart';
import 'package:pictocomm/features/catalog/domain/entities/picto.dart';
import 'package:pictocomm/features/catalog/domain/repositories/category_repository.dart';
import 'package:pictocomm/features/catalog/domain/repositories/picto_repository.dart';
import 'package:pictocomm/features/profiles/domain/entities/child_profile.dart';
import 'package:pictocomm/features/profiles/domain/repositories/child_profile_repository.dart';
import 'package:pictocomm/features/voice/domain/voice_provider.dart';

final class FakeCategoryRepository implements CategoryRepository {
  FakeCategoryRepository({List<Category> categories = const <Category>[]}) : _categories = [...categories];

  final List<Category> _categories;

  List<Category> get categories => List.unmodifiable(_categories);

  @override
  Future<List<Category>> getCategories() async => _categories;

  @override
  Future<Category> createCategory(Category category) async {
    final name = category.name.trim();
    for (final stored in _categories) {
      if (stored.name.toLowerCase() == name.toLowerCase()) {
        throw DuplicateCatalogException('Ya existe una categoría "$name"');
      }
    }
    final persisted = Category(
      id: 'custom-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      color: category.color,
      icon: category.icon,
      custom: true,
    );
    _categories.add(persisted);
    return persisted;
  }

  /// REQ-CAT-02 (RF-3.17): renombra/recolorea manteniendo el id. Igual que
  /// el repo real: nombre vacío y duplicados se rechazan.
  @override
  Future<Category> updateCategory(Category category) async {
    final name = category.name.trim();
    if (name.isEmpty) {
      throw const DataSourceException('El nombre de la categoría no puede estar vacío');
    }
    final index = _categories.indexWhere((stored) => stored.id == category.id);
    if (index < 0) {
      throw const DataSourceException('La categoría no existe');
    }
    final stored = _categories[index];
    if (!stored.custom) {
      throw const DataSourceException('El catálogo incluido no se puede editar (RF-3.17)');
    }
    for (final other in _categories) {
      if (other.id != category.id && other.name.toLowerCase() == name.toLowerCase()) {
        throw DuplicateCatalogException('Ya existe una categoría "$name"');
      }
    }
    final updated = Category(
      id: stored.id,
      name: name,
      color: category.color,
      icon: category.icon,
      custom: true,
    );
    _categories[index] = updated;
    return updated;
  }

  /// RF3.9: borra la categoría solo si es custom (en fakes, todo lo de la
  /// lista lo es, salvo las seeded explicitas con custom false). El
  /// [childProfileId] se ignora a proposito: la cascada por chico vive en el
  /// datasource real (los fakes no comparten storage con pictos).
  @override
  Future<void> deleteCategory(String id, {String? childProfileId}) async {
    final stored = _categories.where((category) => category.id == id).firstOrNull;
    if (stored == null || !stored.custom) {
      throw const DataSourceException('La categoría no es borrable o no existe');
    }
    _categories.removeWhere((category) => category.id == id);
  }
}

final class FakePictoRepository implements PictoRepository {
  FakePictoRepository({List<Picto> pictos = const <Picto>[]}) : _pictos = [...pictos];

  final List<Picto> _pictos;

  List<Picto> get pictos => List.unmodifiable(_pictos);

  @override
  Future<List<Picto>> getPictos({String? categoryId, String? childProfileId}) async {
    // RF3.6: con chico activo, los custom sin dueño siguen visibles (RF3.7);
    // los owned solo su dueño. Sin filtro, la gestión ve todo.
    final visible = childProfileId == null
        ? _pictos
        : _pictos.where((picto) => picto.source == PictoSource.bundled || picto.childProfileId == null || picto.childProfileId == childProfileId).toList();
    if (categoryId == null) {
      return visible;
    }
    // REQ-CAT-02 (RF-3.15): filtro por pertenencia (multi-categoría).
    return visible.where((p) => p.belongsTo(categoryId)).toList();
  }

  @override
  Future<Picto?> getPicto(String id) async {
    for (final picto in _pictos) {
      if (picto.id == id) {
        return picto;
      }
    }
    return null;
  }

  @override
  Future<Picto> createPicto(Picto picto) async {
    final label = picto.label.trim();
    if (label.isEmpty) {
      throw const DataSourceException('El nombre del pictograma no puede estar vacío');
    }
    if (picto.imageUrl == null || picto.imageUrl!.isEmpty) {
      throw const DataSourceException('Elegí una imagen para el pictograma');
    }
    // REQ-CAT-02 (RF-3.13): al menos una categoría.
    if (picto.categoryIds.isEmpty) {
      throw const DataSourceException('Elegí al menos una categoría para el pictograma');
    }
    final now = DateTime.now().toUtc();
    final persisted = Picto(
      id: 'custom-${now.microsecondsSinceEpoch}',
      label: picto.label,
      categoryIds: [...picto.categoryIds],
      source: PictoSource.custom,
      imageUrl: picto.imageUrl,
      childProfileId: picto.childProfileId,
      createdAt: now,
      updatedAt: now,
    );
    _pictos.add(persisted);
    return persisted;
  }

  /// REQ-CAT-02 (RF-3.16/RF-3.18): edición con las mismas reglas que el repo
  /// real — solo custom, dueño intocable salvo asignación de legacy, y
  /// `updatedAt` avanzado.
  @override
  Future<Picto> updatePicto(Picto picto, {String? childProfileId}) async {
    final label = picto.label.trim();
    if (label.isEmpty) {
      throw const DataSourceException('El nombre del pictograma no puede estar vacío');
    }
    if (picto.imageUrl == null || picto.imageUrl!.isEmpty) {
      throw const DataSourceException('Elegí una imagen para el pictograma');
    }
    if (picto.categoryIds.isEmpty) {
      throw const DataSourceException('Elegí al menos una categoría para el pictograma');
    }
    final index = _pictos.indexWhere((stored) => stored.id == picto.id);
    if (index < 0 || _pictos[index].source != PictoSource.custom) {
      throw const DataSourceException('Solo se pueden editar pictogramas personalizados (RF-3.18)');
    }
    final target = _pictos[index];
    if (childProfileId != null && target.childProfileId != null && target.childProfileId != childProfileId) {
      throw const DataSourceException('El pictograma pertenece a otro chico (RF-3.18)');
    }
    final now = DateTime.now().toUtc();
    final persisted = Picto(
      id: target.id,
      label: label,
      categoryIds: [...picto.categoryIds],
      source: PictoSource.custom,
      imageUrl: picto.imageUrl,
      childProfileId: target.childProfileId ?? picto.childProfileId,
      createdAt: target.createdAt,
      updatedAt: now,
    );
    _pictos[index] = persisted;
    return persisted;
  }

  /// RF3.8: solo custom y, con dueño, solo el chico activo lo borra.
  @override
  Future<void> deletePicto(String id, {String? childProfileId}) async {
    final stored = _pictos.where((picto) => picto.id == id).firstOrNull;
    if (stored == null || stored.source != PictoSource.custom) {
      throw const DataSourceException('Solo se pueden borrar pictogramas personalizados');
    }
    if (childProfileId != null && stored.childProfileId != null && stored.childProfileId != childProfileId) {
      throw const DataSourceException('El pictograma pertenece a otro chico');
    }
    _pictos.removeWhere((picto) => picto.id == id);
  }

  /// RF2.7: purge de todos los pictos del chico. Registra los purgados para
  /// que los tests puedan asertar la cascada.
  @override
  Future<void> deletePictosForChild(String childProfileId) async {
    _purgedChildIds.add(childProfileId);
    _pictos.removeWhere((picto) => picto.childProfileId == childProfileId);
  }

  final List<String> _purgedChildIds = [];

  /// Ids de chicos pasados por `deletePictosForChild`, en orden.
  List<String> get purgedChildIds => List.unmodifiable(_purgedChildIds);
}

final class ExplodingRemoteDataSource implements RemoteCatalogDataSource {
  const ExplodingRemoteDataSource();

  @override
  Future<List<CategoryModel>> getCategories() async {
    throw const UnimplementedFeatureException('ExplodingRemoteDataSource: la app no debe tocar el remoto en lectura');
  }

  @override
  Future<List<PictoModel>> getPictos({String? categoryId, DateTime? since, int limit = 100}) async {
    throw const UnimplementedFeatureException('ExplodingRemoteDataSource: la app no debe tocar el remoto en lectura');
  }

  @override
  Future<PictoModel> getPicto(String id) async {
    throw const UnimplementedFeatureException('ExplodingRemoteDataSource: la app no debe tocar el remoto en lectura');
  }

  @override
  Future<PictoModel> postPicto(PictoModel picto, {required String imageBase64, required String imageMime}) async {
    throw const UnimplementedFeatureException('ExplodingRemoteDataSource: subida inesperada');
  }

  @override
  Future<PictoModel> putPicto(PictoModel picto, {String? imageBase64, String? imageMime}) async {
    throw const UnimplementedFeatureException('ExplodingRemoteDataSource: subida inesperada');
  }

  @override
  Future<PictoModel> deletePicto(String id) async {
    throw const UnimplementedFeatureException('ExplodingRemoteDataSource: subida inesperada');
  }

  @override
  Future<CategoryModel> postCategory(CategoryModel category) async {
    throw const UnimplementedFeatureException('ExplodingRemoteDataSource: subida inesperada');
  }

  @override
  Future<CategoryModel> putCategory(CategoryModel category) async {
    throw const UnimplementedFeatureException('ExplodingRemoteDataSource: subida inesperada');
  }

  @override
  Future<CategoryModel> deleteCategory(String id) async {
    throw const UnimplementedFeatureException('ExplodingRemoteDataSource: subida inesperada');
  }
}

/// Backend "en memoria" para tests del sync (REQ-BCK-01): respeta el mismo
/// contrato que el HTTP real — filtra por `categoryId`, `since` (estricto) y
/// `limit`. Registra los `since` pedidos para verificar el incremental
/// (RF-5.7). Con [error] simulado, todo método falla (backend caído, RF-5.10).
final class FakeRemoteCatalogDataSource implements RemoteCatalogDataSource {
  FakeRemoteCatalogDataSource({
    List<CategoryModel> categories = const <CategoryModel>[],
    List<PictoModel> pictos = const <PictoModel>[],
    this._error,
  }) : _categories = [...categories],
       _pictos = [...pictos];

  final List<CategoryModel> _categories;
  final List<PictoModel> _pictos;
  Object? Function()? _error;

  /// Valores de `since` recibidos por `getPictos`, en orden.
  final List<DateTime?> pictosSinceCalls = [];

  /// Cambia el error simulado en caliente (backend caído → disponible).
  void setError(Object? Function()? error) => _error = error;

  /// Pictos remotos vigentes (mutables para simular cambios en el backend).
  List<PictoModel> get pictos => _pictos;

  void addPicto(PictoModel picto) => _pictos.add(picto);

  @override
  Future<List<CategoryModel>> getCategories() async {
    _throwIfError();
    return _categories;
  }

  @override
  Future<List<PictoModel>> getPictos({String? categoryId, DateTime? since, int limit = 100}) async {
    _throwIfError();
    pictosSinceCalls.add(since);
    return _pictos
        .where((picto) => categoryId == null || picto.categoryIds.contains(categoryId))
        // RF-5.14: con `since` el server también devuelve tumbas recientes
        // (deletedAt posterior), como el backend real.
        .where(
          (picto) => since == null ||
              picto.deletedAt?.isAfter(since) == true ||
              (picto.deletedAt == null && picto.updatedAt.isAfter(since)),
        )
        .take(limit)
        .toList();
  }

  @override
  Future<PictoModel> getPicto(String id) async {
    _throwIfError();
    for (final picto in _pictos) {
      if (picto.id == id) {
        return picto;
      }
    }
    throw const DataSourceException('picto no encontrado');
  }

  // ---- Subida (REQ-BCK-02): registra las ops para verificar el flush ----

  /// Operaciones de subida recibidas, en orden: "$op:$id".
  final List<String> writeCalls = [];

  PictoModel _upsertRemote(PictoModel incoming) {
    // RF-5.12: como el server real, lo subido por dispositivos se SIRVE como
    // remote (id `custom-*` intacto) para que renderice con Image.network
    // en los otros dispositivos (RNF-5.15).
    final served = incoming.source == PictoSource.remote
        ? incoming
        : PictoModel(
            id: incoming.id,
            label: incoming.label,
            categoryIds: incoming.categoryIds,
            imageUrl: incoming.imageUrl,
            source: PictoSource.remote,
            createdAt: incoming.createdAt,
            updatedAt: incoming.updatedAt,
            childProfileId: incoming.childProfileId,
            deletedAt: incoming.deletedAt,
          );
    final index = _pictos.indexWhere((picto) => picto.id == served.id);
    if (index >= 0) {
      final existing = _pictos[index];
      // RNF-5.10: last-write-wins — la respuesta trae la versión ganadora.
      final winner = served.updatedAt.isAfter(existing.updatedAt) ? served : existing;
      _pictos[index] = winner;
      return winner;
    }
    _pictos.add(served);
    return served;
  }

  @override
  Future<PictoModel> postPicto(PictoModel picto, {required String imageBase64, required String imageMime}) async {
    _throwIfError();
    writeCalls.add('post:${picto.id}');
    final existing = _pictos.where((picto_) => picto_.id == picto.id).firstOrNull;
    if (existing != null) {
      // 409 con la versión guardada (el repositorio adopta si es más nueva).
      return existing;
    }
    return _upsertRemote(picto);
  }

  @override
  Future<PictoModel> putPicto(PictoModel picto, {String? imageBase64, String? imageMime}) async {
    _throwIfError();
    writeCalls.add('put:${picto.id}');
    return _upsertRemote(picto);
  }

  @override
  Future<PictoModel> deletePicto(String id) async {
    _throwIfError();
    writeCalls.add('delete:$id');
    final tombstone = PictoModel(
      id: id,
      label: '',
      categoryIds: const [],
      imageUrl: '',
      source: PictoSource.remote,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt: DateTime.now().toUtc(),
      deletedAt: DateTime.now().toUtc(),
    );
    final index = _pictos.indexWhere((picto) => picto.id == id);
    if (index >= 0) {
      _pictos[index] = tombstone;
    }
    return tombstone;
  }

  final List<CategoryModel> _writtenCategories = [];

  /// Categorías subidas (post/put), para asertar en los tests.
  List<CategoryModel> get writtenCategories => List.unmodifiable(_writtenCategories);

  @override
  Future<CategoryModel> postCategory(CategoryModel category) async {
    _throwIfError();
    writeCalls.add('post:${category.id}');
    _writtenCategories.add(category);
    return category;
  }

  @override
  Future<CategoryModel> putCategory(CategoryModel category) async {
    _throwIfError();
    writeCalls.add('put:${category.id}');
    _writtenCategories.add(category);
    return category;
  }

  @override
  Future<CategoryModel> deleteCategory(String id) async {
    _throwIfError();
    writeCalls.add('delete:$id');
    return CategoryModel(id: id, name: '', color: 0xFF7C5CBF, icon: 'category', deletedAt: DateTime.now().toUtc());
  }

  void _throwIfError() {
    final error = _error?.call();
    if (error != null) {
      throw error;
    }
  }
}

/// Voz "en silencio" para tests: respeta el contrato (speak completa solo
/// cuando la palabra "terminó de sonar") pero no pronuncia nada. Registra
/// lo pedido para que los tests puedan verificar qué se quiso reproducir.
final class FakeVoiceProvider implements VoiceProvider {
  FakeVoiceProvider({List<String> words = const <String>[]}) : _words = [...words];

  final List<String> _words;

  /// Palabras pedidas a `speak`, en orden.
  List<String> get spokenWords => List.unmodifiable(_words);

  bool _stopped = false;

  /// `true` si se llamó `stop` al menos una vez.
  bool get isStopped => _stopped;

  @override
  Future<void> speak(String word) async {
    if (word.trim().isEmpty) {
      throw const VoiceException('No se puede pronunciar un texto vacío');
    }
    _words.add(word);
  }

  @override
  Future<void> stop() async {
    _stopped = true;
  }

  @override
  Future<void> dispose() async {}
}

final class FakeChildProfileRepository implements ChildProfileRepository {
  FakeChildProfileRepository({
    List<ChildProfile> children = const <ChildProfile>[],
    this.purgePictosForChild,
  }) : _children = [...children];

  final List<ChildProfile> _children;

  /// RF2.7: cascada inyectada, igual que el repo real (misma firma).
  final Future<void> Function(String childId)? purgePictosForChild;

  List<ChildProfile> get children => List.unmodifiable(_children);

  @override
  Future<List<ChildProfile>> getChildren({String? accountId}) async {
    // RF-6.6: con cuenta, solo sus perfiles + los legacy (sin cuenta).
    final visible = accountId == null
        ? _children
        : _children.where((child) => child.accountId == null || child.accountId == accountId);
    return [...visible];
  }

  @override
  Future<ChildProfile> createChild(ChildProfile child, {String? accountId}) async {
    final name = child.name.trim();
    if (name.isEmpty) {
      throw const DataSourceException('El nombre del niño no puede estar vacío');
    }
    final persisted = ChildProfile(
      id: 'child-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      age: child.age,
      avatarColor: child.avatarColor,
      // El contrato real persiste la foto (RF3.11); el fake también.
      photoUrl: child.photoUrl,
      // RF-6.6: el fake también taggea la cuenta dueña.
      accountId: accountId,
    );
    _children.add(persisted);
    return persisted;
  }

  @override
  Future<ChildProfile> updateChild(ChildProfile child) async {
    final index = _children.indexWhere((element) => element.id == child.id);
    if (index < 0) {
      throw const DataSourceException('El perfil del niño no existe');
    }
    _children[index] = child;
    return child;
  }

  @override
  Future<void> deleteChild(String id) async {
    _children.removeWhere((child) => child.id == id);
    // RF2.7: cascada espejo del repo real.
    await purgePictosForChild?.call(id);
  }
}

/// Perfil de chico de prueba: los tests de flujo entran a sesión a traves del
/// selector (RF2.1) tocando su tarjeta.
ChildProfile testChildProfile() => ChildProfile(
  id: 'test-nina',
  name: 'Nina',
  avatarColor: AppColors.avatarPalette.first,
);

/// REQ-ACC-01: autenticación "en memoria" para tests de flujo. Por default
/// cualquier login/registro con formato válido entra (el formulario valida),
/// igual que el fake original; `failures` permite simular errores puntuales.
final class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({Map<String, AuthErrorCode>? failures, this.existingSession}) : _failures = failures; // ignore: prefer_initializing_formals

  /// email normalizado → código de error a lanzar en login/registro.
  final Map<String, AuthErrorCode>? _failures;

  /// Sesión ya guardada en el dispositivo (para tests de RF-6.4).
  final AuthSession? existingSession;

  AuthSession? _session;

  AuthSession _newSession(UserAccount account) => AuthSession(
    account: account,
    token: 'fake-token-${account.id}',
    expiresAt: DateTime.now().add(const Duration(days: 30)),
  );

  void _throwIfFailure(String email) {
    final code = _failures?[email.trim().toLowerCase()];
    if (code != null) {
      throw AuthException('fallo simulado para $email', code: code);
    }
  }

  @override
  Future<AuthSession> register({required String name, required String email, required String password}) async {
    _throwIfFailure(email);
    final account = UserAccount(id: 'account-test', name: name, email: email.trim().toLowerCase());
    _session = _newSession(account);
    return _session!;
  }

  @override
  Future<AuthSession> login({required String email, required String password}) async {
    _throwIfFailure(email);
    final account = UserAccount(
      id: 'account-test',
      name: email.split('@').first,
      email: email.trim().toLowerCase(),
    );
    _session = _newSession(account);
    return _session!;
  }

  @override
  Future<AuthSession?> restoreSession() async => _session ?? existingSession;

  @override
  Future<void> logout() async {
    _session = null;
  }
}

AppDependencies fakeDependencies({
  List<Category> categories = const <Category>[],
  List<Picto> pictos = const <Picto>[],
  List<ChildProfile> children = const <ChildProfile>[],
  VoiceProvider? voiceProvider,
  AuthRepository? authRepository,
}) {
  return AppDependencies(
    categoryRepository: FakeCategoryRepository(categories: categories),
    pictoRepository: FakePictoRepository(pictos: pictos),
    childProfileRepository: FakeChildProfileRepository(children: children),
    voiceProvider: voiceProvider ?? FakeVoiceProvider(),
    authRepository: authRepository ?? FakeAuthRepository(),
  );
}
