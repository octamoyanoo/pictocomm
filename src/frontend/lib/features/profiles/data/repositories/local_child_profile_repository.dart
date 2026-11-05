import '../../../../core/error/app_exception.dart';
import '../../domain/entities/child_profile.dart';
import '../../domain/repositories/child_profile_repository.dart';
import '../datasources/local_child_profile_data_source.dart';
import '../models/child_profile_model.dart';

final class LocalChildProfileRepository implements ChildProfileRepository {
  const LocalChildProfileRepository({required this.dataSource});

  final LocalChildProfileDataSource dataSource;

  @override
  Future<List<ChildProfile>> getChildren() async {
    try {
      final models = await dataSource.loadChildren();
      return [for (final model in models) model.toChild()];
    } on Object catch (error) {
      throw DataSourceException('No se pudieron leer los perfiles: $error');
    }
  }

  @override
  Future<ChildProfile> createChild(ChildProfile child) async {
    final name = child.name.trim();
    if (name.isEmpty) {
      throw const DataSourceException('El nombre del niño no puede estar vacío');
    }
    final persisted = ChildProfile(
      id: 'child-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      age: child.age,
      avatarColor: child.avatarColor,
      photoUrl: child.photoUrl,
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
  }
}
