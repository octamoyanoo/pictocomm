import '../domain/child_profile.dart';

/// Contrato de acceso a los perfiles de niños.
abstract interface class ProfileRepository {
  Future<List<ChildProfile>> getProfiles();

  /// `null` si no hay ninguno guardado.
  Future<ChildProfile?> getActiveProfile();

  /// Guarda y activa el perfil. Si `id` está vacío se genera uno nuevo.
  Future<ChildProfile> saveProfile(ChildProfile profile);

  /// Activa un perfil ya existente.
  Future<void> setActiveProfile(String id);
}
