import '../../features/catalog/data/datasources/custom_catalog_data_source.dart';
import '../../features/catalog/data/datasources/local_catalog_data_source.dart';
import '../../features/catalog/data/datasources/remote_catalog_data_source.dart';
import '../../features/catalog/data/repositories/local_picto_repository.dart';
import '../../features/catalog/domain/repositories/category_repository.dart';
import '../../features/catalog/domain/repositories/picto_repository.dart';
import '../../features/voice/data/tts_voice_provider.dart';
import '../../features/voice/domain/voice_provider.dart';

final class AppDependencies {
  const AppDependencies({
    required this.categoryRepository,
    required this.pictoRepository,
    required this.voiceProvider,
  });

  final CategoryRepository categoryRepository;
  final PictoRepository pictoRepository;
  final VoiceProvider voiceProvider;

  static AppDependencies bootstrap() {
    final localPictoRepository = LocalPictoRepository(
      localDataSource: const LocalCatalogDataSource(),
      customDataSource: CustomCatalogDataSource(),
      remoteDataSource: const UnimplementedRemoteCatalogDataSource(),
    );
    return AppDependencies(
      categoryRepository: localPictoRepository,
      pictoRepository: localPictoRepository,
      // Voz v1 (RF1.10): TTS del sistema. El día que se pase al modo híbrido
      // (RF1.11) se reemplaza esta línea, sin tocar pantallas ni providers.
      voiceProvider: TtsVoiceProvider(),
    );
  }
}
