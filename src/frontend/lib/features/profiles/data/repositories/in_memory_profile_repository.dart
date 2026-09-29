import '../../domain/child_profile.dart';
import '../../domain/profile_repository.dart';

/// Implementación en memoria de [ProfileRepository].
///
/// Sirve para que la app funcione antes de que exista la persistencia. Cuando
/// haya almacenamiento real se cambia esta clase, no las pantallas.
class InMemoryProfileRepository implements ProfileRepository {
  InMemoryProfileRepository({List<ChildProfile> seed = const <ChildProfile>[]})
      : _profiles = List<ChildProfile>.from(seed);

  final List<ChildProfile> _profiles;
  String? _activeId;

  @override
  Future<List<ChildProfile>> getProfiles() async =>
      List<ChildProfile>.unmodifiable(_profiles);

  @override
  Future<ChildProfile?> getActiveProfile() async {
    if (_activeId == null) return null;
    for (final ChildProfile p in _profiles) {
      if (p.id == _activeId) return p;
    }
    return null;
  }

  @override
  Future<ChildProfile> saveProfile(ChildProfile profile) async {
    final int idx = _profiles.indexWhere((ChildProfile p) => p.id == profile.id);
    if (idx == -1) {
      _profiles.add(profile);
    } else {
      _profiles[idx] = profile;
    }
    _activeId ??= profile.id;
    return profile;
  }

  @override
  Future<void> setActiveProfile(String id) async {
    if (_profiles.any((ChildProfile p) => p.id == id)) {
      _activeId = id;
      return;
    }
    throw StateError('No existe el perfil $id');
  }
}
