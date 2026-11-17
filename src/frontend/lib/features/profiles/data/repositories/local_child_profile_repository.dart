import '../../../../core/error/app_exception.dart';
import '../../domain/entities/child_profile.dart';
import '../../domain/repositories/child_profile_repository.dart';
import '../datasources/local_child_profile_data_source.dart';
import '../models/child_profile_model.dart';

final class LocalChildProfileRepository implements ChildProfileRepository {
  const LocalChildProfileRepository({
    required this.dataSource,
    this.purgePictosForChild,
  });

  final LocalChildProfileDataSource dataSource;

  /// Ids únicos aunque dos creaciones caigan en el mismo microsegundo.
  static int _idCounter = 0;

  /// RF2.7 (cascada): al borrar un perfil, sus pictos personalizados van con
  /// él. El wiring vive en el composition root (sin dependencia cruzada de
  /// features: el catálogo inyecta la función, perfiles solo la llama).
  final Future<void> Function(String childId)? purgePictosForChild;

  @override
  Future<List<ChildProfile>> getChildren({String? accountId}) async {
    try {
      final models = await dataSource.loadChildren();
      // RF-6.6: con cuenta logueada, solo sus perfiles (+ los legacy sin
      // cuenta). Sin filtro (gestión sin sesión), todos.
      final visible = accountId == null
          ? models
          : models.where((model) => model.accountId == null || model.accountId == accountId);
      return [for (final model in visible) model.toChild()];
    } on Object catch (error) {
      throw DataSourceException('No se pudieron leer los perfiles: $error');
    }
  }

  @override
  Future<ChildProfile> createChild(ChildProfile child, {String? accountId}) async {
    final name = child.name.trim();
    if (name.isEmpty) {
      throw const DataSourceException('El nombre del niño no puede estar vacío');
    }
    final persisted = ChildProfile(
      id: 'child-${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}',
      name: name,
      age: child.age,
      avatarColor: child.avatarColor,
      photoUrl: child.photoUrl,
      accountId: accountId,
    );
    final models = [...await dataSource.loadChildren()];
    models.add(ChildProfileModel.fromChild(persisted));
    await dataSource.saveChildren(models);
    return persisted;
  }

  /// RF3.11: actualiza el perfil (en v1, su foto). Reemplaza por id; si no
  /// existe, lanza [DataSourceException].
  @override
  Future<ChildProfile> updateChild(ChildProfile child) async {
    final models = [...await dataSource.loadChildren()];
    final index = models.indexWhere((model) => model.id == child.id);
    if (index < 0) {
      throw const DataSourceException('El perfil del niño no existe');
    }
    final persisted = ChildProfile(
      id: models[index].id,
      name: child.name == models[index].name ? child.name : child.name.trim(),
      age: child.age,
      avatarColor: child.avatarColor,
      photoUrl: child.photoUrl,
      // RF-6.6: la dueña no cambia al editar (la foto, en v1).
      accountId: models[index].accountId,
    );
    models[index] = ChildProfileModel.fromChild(persisted);
    await dataSource.saveChildren(models);
    return persisted;
  }

  @override
  Future<void> deleteChild(String id) async {
    final models = [...await dataSource.loadChildren()];
    final remaining = models.where((model) => model.id != id).toList();
    await dataSource.saveChildren(remaining);
    // RF2.7: "borra también sus datos" — los pictos del chico quedan fuera
    // del dispositivo en la misma operación de borrado.
    await purgePictosForChild?.call(id);
  }

  @override
  Future<String?> getLastChildId({String? accountId}) async {
    try {
      return await dataSource.loadLastChildId(accountId: accountId);
    } on Object catch (error) {
      throw DataSourceException('No se pudo leer el último chico activo: $error');
    }
  }

  @override
  Future<void> setLastChildId(String? childId, {String? accountId}) async {
    try {
      await dataSource.saveLastChildId(childId, accountId: accountId);
    } on Object catch (error) {
      throw DataSourceException('No se pudo guardar el último chico activo: $error');
    }
  }
}
