// `Category` choca con la anotación homónima de flutter/foundation.dart.
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:provider/provider.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/child_profile.dart';
import '../../domain/profile_repository.dart';

/// Estado de los perfiles de niños.
///
/// Un solo perfil está activo por sesión: define el orden de categorías y los
/// favoritos que ve el niño.
class ProfilesProvider extends ChangeNotifier {
  ProfilesProvider(this._repository);

  final ProfileRepository _repository;

  List<ChildProfile> _profiles = <ChildProfile>[];
  ChildProfile? _active;
  bool _isLoading = false;
  AppException? _error;

  List<ChildProfile> get profiles => _profiles;
  ChildProfile? get active => _active;
  bool get isLoading => _isLoading;
  AppException? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _profiles = await _repository.getProfiles();
      _active = await _repository.getActiveProfile();
    } on AppException catch (e) {
      _error = e;
    } on Object catch (e) {
      _error = StorageException('No se pudieron cargar los perfiles', cause: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> activate(String id) async {
    try {
      await _repository.setActiveProfile(id);
      _active = await _repository.getActiveProfile();
    } on AppException catch (e) {
      _error = e;
    } on Object catch (e) {
      _error = StorageException('No se pudo activar el perfil', cause: e);
    }
    notifyListeners();
  }
}

extension ProfilesContext on BuildContext {
  ProfilesProvider get profiles => read<ProfilesProvider>();
  ProfilesProvider get profilesWatch => watch<ProfilesProvider>();
}
