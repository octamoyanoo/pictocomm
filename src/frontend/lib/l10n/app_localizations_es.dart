// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get navInicio => 'Inicio';

  @override
  String get navPictogramas => 'Pictogramas';

  @override
  String get navComunicar => 'Comunicar';

  @override
  String get navPerfil => 'Perfil';

  @override
  String get routeNotFound => 'Ruta no encontrada';

  @override
  String get loginTagline => 'Comunicación visual para todos';

  @override
  String get emailLabel => 'Correo electrónico';

  @override
  String get emailHint => 'tu@email.com';

  @override
  String get emailRequired => 'Ingresá tu correo';

  @override
  String get emailInvalid => 'El correo no es válido';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get passwordHint => '••••••••';

  @override
  String get passwordRequired => 'Ingresá tu contraseña';

  @override
  String get loginButton => 'Iniciar Sesión';

  @override
  String get noAccount => '¿No tienes cuenta? ';

  @override
  String get registerLink => 'Regístrate aquí';

  @override
  String get nameLabel => 'Nombre';

  @override
  String get nameExampleHint => 'Tu nombre';

  @override
  String get nameRequired => 'Ingresá tu nombre';

  @override
  String get passwordTooShort => 'Debe tener al menos 8 caracteres';

  @override
  String get confirmPasswordLabel => 'Confirmar contraseña';

  @override
  String get passwordsMismatch => 'Las contraseñas no coinciden';

  @override
  String get createAccountButton => 'Crear Cuenta';

  @override
  String get signupTagline => 'Creá tu cuenta para empezar';

  @override
  String get haveAccount => '¿Ya tienes cuenta? ';

  @override
  String get loginLinkHere => 'Inicia Sesión';

  @override
  String get hola => 'Hola 👋';

  @override
  String holaName(String name) {
    return 'Hola, $name 👋';
  }

  @override
  String get changeChildTooltip => 'Cambiar de niño';

  @override
  String get addMenuTooltip => 'Agregar catálogo o pictograma';

  @override
  String get newCatalog => 'Nuevo catálogo';

  @override
  String get newCatalogSub => 'Crear una categoría';

  @override
  String get newPicto => 'Nuevo pictograma';

  @override
  String get newPictoSub => 'Agregar una imagen a una categoría';

  @override
  String noResults(String query) {
    return 'Sin resultados para \"$query\"';
  }

  @override
  String get searchHint => 'Buscar pictogramas...';

  @override
  String get myCatalogs => 'Mis Catálogos';

  @override
  String get verTodos => 'Ver todos';

  @override
  String pictogramaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pictogramas',
      one: '1 pictograma',
    );
    return '$_temp0';
  }

  @override
  String get pictogramasTitle => 'Pictogramas';

  @override
  String get comunicarTitle => 'Comunicar';

  @override
  String get sentenceStripEmpty => 'Toca pictogramas para armar tu frase';

  @override
  String get removeLastTooltip => 'Quitar último';

  @override
  String get clearSentenceTooltip => 'Limpiar frase';

  @override
  String get playTooltip => 'Reproducir frase';

  @override
  String get allCategoriesChip => 'Todos';

  @override
  String get emptyCategoryHint => 'No hay pictogramas en esta categoría';

  @override
  String get voiceUnavailable => 'Voz no disponible en este dispositivo';

  @override
  String get close => 'Cerrar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get next => 'Seguir';

  @override
  String get keep => 'Conservar';

  @override
  String get deleteForever => 'Eliminar definitivamente';

  @override
  String get confirmDeleteTitle => '¿Confirmar el borrado?';

  @override
  String get deleteIrreversible => 'Esta acción no se puede deshacer.';

  @override
  String deleteCategoryTitle(String name) {
    return '¿Eliminar \"$name\"?';
  }

  @override
  String deleteCategoryContent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Se borra el catálogo y su contenido ($count pictogramas de este niño).',
      one: 'Se borra el catálogo y su contenido (1 pictograma de este niño).',
    );
    return '$_temp0';
  }

  @override
  String get deleteCatalogTooltip => 'Eliminar catálogo';

  @override
  String get categoryEmpty => 'Todavía no hay pictogramas en esta categoría';

  @override
  String deletePictoTitle(String name) {
    return '¿Eliminar \"$name\"?';
  }

  @override
  String get deletePictoContent =>
      'El pictograma se borra del dispositivo para este niño.';

  @override
  String get deletePictoButton => 'Eliminar pictograma';

  @override
  String get addPictoTitle => 'Nuevo pictograma';

  @override
  String get imageLoadError => 'No se pudo cargar la imagen';

  @override
  String get urlDownloadError =>
      'No se pudo descargar la imagen (el sitio puede bloquearlo). Guardala en el dispositivo y elegila desde la galería.';

  @override
  String get selectChildFirst =>
      'Elegí primero un niño en \"Cambiar de niño\" (RF3.4)';

  @override
  String get nameFieldRequired => 'Ingresá un nombre';

  @override
  String get imageRequired => 'Elegí una imagen';

  @override
  String get categoryRequired => 'Elegí una categoría';

  @override
  String get saveError => 'No se pudo guardar. Intentá de nuevo.';

  @override
  String get nameFieldLabel => 'Nombre';

  @override
  String get nameFieldHint => 'Ej: Agua';

  @override
  String get firstCatalogWarning =>
      'Primero creá un catálogo para poder guardar pictogramas';

  @override
  String get categoryFieldLabel => 'Categoría';

  @override
  String get savePictoButton => 'Guardar pictograma';

  @override
  String get tapToPickImage => 'Tocá para elegir una imagen';

  @override
  String get webImageTitle => 'Imagen desde la web';

  @override
  String get webImageContent =>
      'En Google Imágenes: mantené apretada la imagen → \"Copiar dirección de imagen\" y pegala acá.';

  @override
  String get urlInputHint => 'https://...';

  @override
  String get download => 'Descargar';

  @override
  String get gallery => 'Galería';

  @override
  String get camera => 'Cámara';

  @override
  String get cameraUnavailable => 'No disponible en el navegador';

  @override
  String get pasteImageUrl => 'Pegar URL de imagen';

  @override
  String get pasteUrlSub => 'Ej: una imagen de Google Imágenes';

  @override
  String get addCategoryTitle => 'Nuevo catálogo';

  @override
  String get categoryNameLabel => 'Nombre de la categoría';

  @override
  String get categoryNameHint => 'Ej: Bebidas';

  @override
  String get colorLabel => 'Color';

  @override
  String get saveCategoryButton => 'Guardar catálogo';

  @override
  String get duplicateCategory => 'Ya existe una categoría con ese nombre';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get childrenSection => 'Niños';

  @override
  String get addChildTooltip => 'Agregar niño';

  @override
  String get noChildrenYet => 'No hay niños cargados todavía';

  @override
  String get accountSection => 'Mi cuenta';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get deleteProfileTooltip => 'Eliminar perfil';

  @override
  String profilesLoadError(String message) {
    return 'No se pudo leer los perfiles: $message';
  }

  @override
  String selectorLoadError(String message) {
    return 'No se pudo cargar los perfiles: $message';
  }

  @override
  String get selectorTitle => '¿Quién se comunica hoy?';

  @override
  String get selectorSubtitle => 'Toca tu foto para empezar';

  @override
  String get selectorEmptyTitle => 'Todavía no hay perfiles de niño';

  @override
  String get selectorEmptySubtitle => 'Creá el primero para empezar';

  @override
  String get createProfile => 'Crear perfil';

  @override
  String get addChildDialog => 'Agregar niño';

  @override
  String get addChildAction => 'Agregar';

  @override
  String deleteChildTitle(String name) {
    return '¿Eliminar a $name?';
  }

  @override
  String get deleteChildContent =>
      'El perfil del niño se borra del dispositivo, junto a su configuración.';

  @override
  String deleteChildFinalContent(String name) {
    return '\"$name\" se borrará definitivamente. Esta acción no se puede deshacer.';
  }

  @override
  String get emptyCatalogTitle => 'Aún no hay pictogramas';

  @override
  String get emptyCatalogSubtitle => 'Cuando agregues imágenes aparecerán aquí';

  @override
  String get languageSection => 'Idioma';
}
