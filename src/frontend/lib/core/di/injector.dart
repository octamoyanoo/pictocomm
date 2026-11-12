import 'dart:async';

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
  });

  final CategoryRepository categoryRepository;
  final PictoRepository pictoRepository;
  final ChildProfileRepository childProfileRepository;
  final VoiceProvider voiceProvider;

  static AppDependencies bootstrap() {
    final localPictoRepository = LocalPictoRepository(
      localDataSource: const LocalCatalogDataSource(),
      customDataSource: CustomCatalogDataSource(),
      // REQ-BCK-01: el remote real reemplaza al stub; la app sigue leyendo
      // siempre de local (RF-5.11) y el sync corre aparte (RF-5.5).
      remoteDataSource: HttpRemoteCatalogDataSource(),
    );
    // RF-5.5: sync al arrancar, fire-and-forget — no bloquea el primer frame
    // ni toca pantallas/providers. Si el backend no está, falla en silencio
    // (RF-5.10, lo maneja el repositorio).
    unawaited(localPictoRepository.syncFromRemote());
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
    );
  }
}
