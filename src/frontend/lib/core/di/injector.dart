import '../../features/auth/data/datasources/http_auth_data_source.dart';
import '../../features/auth/data/datasources/local_session_data_source.dart';
import '../../features/auth/data/repositories/local_auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/catalog/data/datasources/custom_catalog_data_source.dart';
import '../../features/catalog/data/datasources/http_remote_catalog_data_source.dart';
import '../../features/catalog/data/datasources/local_catalog_data_source.dart';
import '../../features/catalog/data/repositories/local_picto_repository.dart';
import '../../features/catalog/domain/repositories/category_repository.dart';
import '../../features/catalog/domain/repositories/picto_repository.dart';
import '../../features/profiles/data/datasources/local_child_profile_data_source.dart';
import '../../features/profiles/data/repositories/local_child_profile_repository.dart';
import '../../features/profiles/domain/repositories/child_profile_repository.dart';
import '../../features/voice/data/tts_voice_provider.dart';
import '../../features/voice/domain/voice_provider.dart';

final class AppDependencies {
  const AppDependencies({
    required this.categoryRepository,
    required this.pictoRepository,
    required this.childProfileRepository,
    required this.voiceProvider,
    required this.authRepository,
    this.catalogRepository,
  });

  final CategoryRepository categoryRepository;
  final PictoRepository pictoRepository;
  final ChildProfileRepository childProfileRepository;
  final VoiceProvider voiceProvider;

  /// REQ-ACC-01 (RF-6.x): verificación de credenciales + sesión recordada.
  /// El único camino al remote de auth (como el sync para el catálogo).
  final AuthRepository authRepository;

  /// REQ-BCK-02 (RF-5.19): repositorio concreto para el servicio de sync
  /// (outbox + descarga). `null` solo en fakes de test.
  final LocalPictoRepository? catalogRepository;

  static AppDependencies bootstrap() {
    final localPictoRepository = LocalPictoRepository(
      localDataSource: const LocalCatalogDataSource(),
      customDataSource: CustomCatalogDataSource(),
      // REQ-BCK-01: el remote real reemplaza al stub; la app sigue leyendo
      // siempre de local (RF-5.11) y el sync corre aparte (RF-5.5).
      remoteDataSource: HttpRemoteCatalogDataSource(),
    );
    return AppDependencies(
      categoryRepository: localPictoRepository,
      pictoRepository: localPictoRepository,
      childProfileRepository: LocalChildProfileRepository(
        dataSource: LocalChildProfileDataSource(),
        // RF2.7: borrar un perfil purga sus pictos personalizados en la misma
        // operación (cascada por composición, sin dependencia entre features).
        purgePictosForChild: localPictoRepository.deletePictosForChild,
      ),
      // Voz v1 (RF1.10): TTS del sistema. El día que se pase al modo híbrido
      // (RF1.11) se reemplaza esta línea, sin tocar pantallas ni providers.
      voiceProvider: TtsVoiceProvider(),
      // REQ-ACC-01: autenticación real contra el backend + sesión recordada
      // en SharedPreferences (RF-6.4). Con sesión, la app abre sin login.
      authRepository: LocalAuthRepository(
        remoteDataSource: HttpAuthDataSource(),
        sessionDataSource: const LocalSessionDataSource(),
      ),
      catalogRepository: localPictoRepository,
    );
  }
}
