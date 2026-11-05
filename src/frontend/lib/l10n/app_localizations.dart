import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// No description provided for @navInicio.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navInicio;

  /// No description provided for @navPictogramas.
  ///
  /// In es, this message translates to:
  /// **'Pictogramas'**
  String get navPictogramas;

  /// No description provided for @navComunicar.
  ///
  /// In es, this message translates to:
  /// **'Comunicar'**
  String get navComunicar;

  /// No description provided for @navPerfil.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get navPerfil;

  /// No description provided for @routeNotFound.
  ///
  /// In es, this message translates to:
  /// **'Ruta no encontrada'**
  String get routeNotFound;

  /// No description provided for @loginTagline.
  ///
  /// In es, this message translates to:
  /// **'Comunicación visual para todos'**
  String get loginTagline;

  /// No description provided for @emailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In es, this message translates to:
  /// **'tu@email.com'**
  String get emailHint;

  /// No description provided for @emailRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresá tu correo'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In es, this message translates to:
  /// **'El correo no es válido'**
  String get emailInvalid;

  /// No description provided for @passwordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In es, this message translates to:
  /// **'••••••••'**
  String get passwordHint;

  /// No description provided for @passwordRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresá tu contraseña'**
  String get passwordRequired;

  /// No description provided for @loginButton.
  ///
  /// In es, this message translates to:
  /// **'Iniciar Sesión'**
  String get loginButton;

  /// No description provided for @noAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? '**
  String get noAccount;

  /// No description provided for @registerLink.
  ///
  /// In es, this message translates to:
  /// **'Regístrate aquí'**
  String get registerLink;

  /// No description provided for @nameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get nameLabel;

  /// No description provided for @nameExampleHint.
  ///
  /// In es, this message translates to:
  /// **'Tu nombre'**
  String get nameExampleHint;

  /// No description provided for @nameRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresá tu nombre'**
  String get nameRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In es, this message translates to:
  /// **'Debe tener al menos 8 caracteres'**
  String get passwordTooShort;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get confirmPasswordLabel;

  /// No description provided for @passwordsMismatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get passwordsMismatch;

  /// No description provided for @createAccountButton.
  ///
  /// In es, this message translates to:
  /// **'Crear Cuenta'**
  String get createAccountButton;

  /// No description provided for @signupTagline.
  ///
  /// In es, this message translates to:
  /// **'Creá tu cuenta para empezar'**
  String get signupTagline;

  /// No description provided for @haveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta? '**
  String get haveAccount;

  /// No description provided for @loginLinkHere.
  ///
  /// In es, this message translates to:
  /// **'Inicia Sesión'**
  String get loginLinkHere;

  /// No description provided for @hola.
  ///
  /// In es, this message translates to:
  /// **'Hola 👋'**
  String get hola;

  /// No description provided for @holaName.
  ///
  /// In es, this message translates to:
  /// **'Hola, {name} 👋'**
  String holaName(String name);

  /// No description provided for @changeChildTooltip.
  ///
  /// In es, this message translates to:
  /// **'Cambiar de niño'**
  String get changeChildTooltip;

  /// No description provided for @addMenuTooltip.
  ///
  /// In es, this message translates to:
  /// **'Agregar catálogo o pictograma'**
  String get addMenuTooltip;

  /// No description provided for @newCatalog.
  ///
  /// In es, this message translates to:
  /// **'Nuevo catálogo'**
  String get newCatalog;

  /// No description provided for @newCatalogSub.
  ///
  /// In es, this message translates to:
  /// **'Crear una categoría'**
  String get newCatalogSub;

  /// No description provided for @newPicto.
  ///
  /// In es, this message translates to:
  /// **'Nuevo pictograma'**
  String get newPicto;

  /// No description provided for @newPictoSub.
  ///
  /// In es, this message translates to:
  /// **'Agregar una imagen a una categoría'**
  String get newPictoSub;

  /// No description provided for @noResults.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados para \"{query}\"'**
  String noResults(String query);

  /// No description provided for @searchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar pictogramas...'**
  String get searchHint;

  /// No description provided for @myCatalogs.
  ///
  /// In es, this message translates to:
  /// **'Mis Catálogos'**
  String get myCatalogs;

  /// No description provided for @verTodos.
  ///
  /// In es, this message translates to:
  /// **'Ver todos'**
  String get verTodos;

  /// No description provided for @pictogramaCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 pictograma} other{{count} pictogramas}}'**
  String pictogramaCount(int count);

  /// No description provided for @pictogramasTitle.
  ///
  /// In es, this message translates to:
  /// **'Pictogramas'**
  String get pictogramasTitle;

  /// No description provided for @comunicarTitle.
  ///
  /// In es, this message translates to:
  /// **'Comunicar'**
  String get comunicarTitle;

  /// No description provided for @sentenceStripEmpty.
  ///
  /// In es, this message translates to:
  /// **'Toca pictogramas para armar tu frase'**
  String get sentenceStripEmpty;

  /// No description provided for @removeLastTooltip.
  ///
  /// In es, this message translates to:
  /// **'Quitar último'**
  String get removeLastTooltip;

  /// No description provided for @clearSentenceTooltip.
  ///
  /// In es, this message translates to:
  /// **'Limpiar frase'**
  String get clearSentenceTooltip;

  /// No description provided for @playTooltip.
  ///
  /// In es, this message translates to:
  /// **'Reproducir frase'**
  String get playTooltip;

  /// No description provided for @allCategoriesChip.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get allCategoriesChip;

  /// No description provided for @emptyCategoryHint.
  ///
  /// In es, this message translates to:
  /// **'No hay pictogramas en esta categoría'**
  String get emptyCategoryHint;

  /// No description provided for @voiceUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Voz no disponible en este dispositivo'**
  String get voiceUnavailable;

  /// No description provided for @close.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get close;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @next.
  ///
  /// In es, this message translates to:
  /// **'Seguir'**
  String get next;

  /// No description provided for @keep.
  ///
  /// In es, this message translates to:
  /// **'Conservar'**
  String get keep;

  /// No description provided for @deleteForever.
  ///
  /// In es, this message translates to:
  /// **'Eliminar definitivamente'**
  String get deleteForever;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Confirmar el borrado?'**
  String get confirmDeleteTitle;

  /// No description provided for @deleteIrreversible.
  ///
  /// In es, this message translates to:
  /// **'Esta acción no se puede deshacer.'**
  String get deleteIrreversible;

  /// No description provided for @deleteCategoryTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar \"{name}\"?'**
  String deleteCategoryTitle(String name);

  /// No description provided for @deleteCategoryContent.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Se borra el catálogo y su contenido (1 pictograma de este niño).} other{Se borra el catálogo y su contenido ({count} pictogramas de este niño).}}'**
  String deleteCategoryContent(int count);

  /// No description provided for @deleteCatalogTooltip.
  ///
  /// In es, this message translates to:
  /// **'Eliminar catálogo'**
  String get deleteCatalogTooltip;

  /// No description provided for @categoryEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay pictogramas en esta categoría'**
  String get categoryEmpty;

  /// No description provided for @deletePictoTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar \"{name}\"?'**
  String deletePictoTitle(String name);

  /// No description provided for @deletePictoContent.
  ///
  /// In es, this message translates to:
  /// **'El pictograma se borra del dispositivo para este niño.'**
  String get deletePictoContent;

  /// No description provided for @deletePictoButton.
  ///
  /// In es, this message translates to:
  /// **'Eliminar pictograma'**
  String get deletePictoButton;

  /// No description provided for @addPictoTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo pictograma'**
  String get addPictoTitle;

  /// No description provided for @imageLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la imagen'**
  String get imageLoadError;

  /// No description provided for @urlDownloadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo descargar la imagen (el sitio puede bloquearlo). Guardala en el dispositivo y elegila desde la galería.'**
  String get urlDownloadError;

  /// No description provided for @selectChildFirst.
  ///
  /// In es, this message translates to:
  /// **'Elegí primero un niño en \"Cambiar de niño\" (RF3.4)'**
  String get selectChildFirst;

  /// No description provided for @nameFieldRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresá un nombre'**
  String get nameFieldRequired;

  /// No description provided for @imageRequired.
  ///
  /// In es, this message translates to:
  /// **'Elegí una imagen'**
  String get imageRequired;

  /// No description provided for @categoryRequired.
  ///
  /// In es, this message translates to:
  /// **'Elegí una categoría'**
  String get categoryRequired;

  /// No description provided for @saveError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar. Intentá de nuevo.'**
  String get saveError;

  /// No description provided for @nameFieldLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get nameFieldLabel;

  /// No description provided for @nameFieldHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Agua'**
  String get nameFieldHint;

  /// No description provided for @firstCatalogWarning.
  ///
  /// In es, this message translates to:
  /// **'Primero creá un catálogo para poder guardar pictogramas'**
  String get firstCatalogWarning;

  /// No description provided for @categoryFieldLabel.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get categoryFieldLabel;

  /// No description provided for @savePictoButton.
  ///
  /// In es, this message translates to:
  /// **'Guardar pictograma'**
  String get savePictoButton;

  /// No description provided for @tapToPickImage.
  ///
  /// In es, this message translates to:
  /// **'Tocá para elegir una imagen'**
  String get tapToPickImage;

  /// No description provided for @webImageTitle.
  ///
  /// In es, this message translates to:
  /// **'Imagen desde la web'**
  String get webImageTitle;

  /// No description provided for @webImageContent.
  ///
  /// In es, this message translates to:
  /// **'En Google Imágenes: mantené apretada la imagen → \"Copiar dirección de imagen\" y pegala acá.'**
  String get webImageContent;

  /// No description provided for @urlInputHint.
  ///
  /// In es, this message translates to:
  /// **'https://...'**
  String get urlInputHint;

  /// No description provided for @download.
  ///
  /// In es, this message translates to:
  /// **'Descargar'**
  String get download;

  /// No description provided for @gallery.
  ///
  /// In es, this message translates to:
  /// **'Galería'**
  String get gallery;

  /// No description provided for @camera.
  ///
  /// In es, this message translates to:
  /// **'Cámara'**
  String get camera;

  /// No description provided for @cameraUnavailable.
  ///
  /// In es, this message translates to:
  /// **'No disponible en el navegador'**
  String get cameraUnavailable;

  /// No description provided for @pasteImageUrl.
  ///
  /// In es, this message translates to:
  /// **'Pegar URL de imagen'**
  String get pasteImageUrl;

  /// No description provided for @pasteUrlSub.
  ///
  /// In es, this message translates to:
  /// **'Ej: una imagen de Google Imágenes'**
  String get pasteUrlSub;

  /// No description provided for @addCategoryTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo catálogo'**
  String get addCategoryTitle;

  /// No description provided for @categoryNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la categoría'**
  String get categoryNameLabel;

  /// No description provided for @categoryNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Bebidas'**
  String get categoryNameHint;

  /// No description provided for @colorLabel.
  ///
  /// In es, this message translates to:
  /// **'Color'**
  String get colorLabel;

  /// No description provided for @saveCategoryButton.
  ///
  /// In es, this message translates to:
  /// **'Guardar catálogo'**
  String get saveCategoryButton;

  /// No description provided for @duplicateCategory.
  ///
  /// In es, this message translates to:
  /// **'Ya existe una categoría con ese nombre'**
  String get duplicateCategory;

  /// No description provided for @profileTitle.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get profileTitle;

  /// No description provided for @childrenSection.
  ///
  /// In es, this message translates to:
  /// **'Niños'**
  String get childrenSection;

  /// No description provided for @addChildTooltip.
  ///
  /// In es, this message translates to:
  /// **'Agregar niño'**
  String get addChildTooltip;

  /// No description provided for @noChildrenYet.
  ///
  /// In es, this message translates to:
  /// **'No hay niños cargados todavía'**
  String get noChildrenYet;

  /// No description provided for @accountSection.
  ///
  /// In es, this message translates to:
  /// **'Mi cuenta'**
  String get accountSection;

  /// No description provided for @signOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get signOut;

  /// No description provided for @deleteProfileTooltip.
  ///
  /// In es, this message translates to:
  /// **'Eliminar perfil'**
  String get deleteProfileTooltip;

  /// No description provided for @profilesLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo leer los perfiles: {message}'**
  String profilesLoadError(String message);

  /// No description provided for @selectorLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar los perfiles: {message}'**
  String selectorLoadError(String message);

  /// No description provided for @selectorTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Quién se comunica hoy?'**
  String get selectorTitle;

  /// No description provided for @selectorSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Toca tu foto para empezar'**
  String get selectorSubtitle;

  /// No description provided for @selectorEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay perfiles de niño'**
  String get selectorEmptyTitle;

  /// No description provided for @selectorEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Creá el primero para empezar'**
  String get selectorEmptySubtitle;

  /// No description provided for @createProfile.
  ///
  /// In es, this message translates to:
  /// **'Crear perfil'**
  String get createProfile;

  /// No description provided for @addChildDialog.
  ///
  /// In es, this message translates to:
  /// **'Agregar niño'**
  String get addChildDialog;

  /// No description provided for @addChildAction.
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get addChildAction;

  /// No description provided for @deleteChildTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar a {name}?'**
  String deleteChildTitle(String name);

  /// No description provided for @deleteChildContent.
  ///
  /// In es, this message translates to:
  /// **'El perfil del niño se borra del dispositivo, junto a su configuración.'**
  String get deleteChildContent;

  /// No description provided for @deleteChildFinalContent.
  ///
  /// In es, this message translates to:
  /// **'\"{name}\" se borrará definitivamente. Esta acción no se puede deshacer.'**
  String deleteChildFinalContent(String name);

  /// No description provided for @emptyCatalogTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay pictogramas'**
  String get emptyCatalogTitle;

  /// No description provided for @emptyCatalogSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Cuando agregues imágenes aparecerán aquí'**
  String get emptyCatalogSubtitle;

  /// No description provided for @languageSection.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get languageSection;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
