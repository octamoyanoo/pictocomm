// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navInicio => 'Home';

  @override
  String get navPictogramas => 'Pictograms';

  @override
  String get navComunicar => 'Communicate';

  @override
  String get navPerfil => 'Profile';

  @override
  String get routeNotFound => 'Route not found';

  @override
  String get loginTagline => 'Visual communication for everyone';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'you@email.com';

  @override
  String get emailRequired => 'Enter your email';

  @override
  String get emailInvalid => 'That email is not valid';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => '••••••••';

  @override
  String get passwordRequired => 'Enter your password';

  @override
  String get loginButton => 'Sign In';

  @override
  String get noAccount => 'No account yet? ';

  @override
  String get registerLink => 'Sign up here';

  @override
  String get nameLabel => 'Name';

  @override
  String get nameExampleHint => 'Your name';

  @override
  String get nameRequired => 'Enter your name';

  @override
  String get passwordTooShort => 'It must be at least 8 characters long';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get passwordsMismatch => 'Passwords do not match';

  @override
  String get createAccountButton => 'Create Account';

  @override
  String get signupTagline => 'Create your account to get started';

  @override
  String get haveAccount => 'Already have an account? ';

  @override
  String get loginLinkHere => 'Sign In';

  @override
  String get hola => 'Hi 👋';

  @override
  String holaName(String name) {
    return 'Hi, $name 👋';
  }

  @override
  String get changeChildTooltip => 'Change child';

  @override
  String get addMenuTooltip => 'Add catalog or pictogram';

  @override
  String get newCatalog => 'New catalog';

  @override
  String get newCatalogSub => 'Create a category';

  @override
  String get newPicto => 'New pictogram';

  @override
  String get newPictoSub => 'Add an image to a category';

  @override
  String noResults(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get searchHint => 'Search pictograms...';

  @override
  String get myCatalogs => 'My Catalogs';

  @override
  String get verTodos => 'See all';

  @override
  String pictogramaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pictograms',
      one: '1 pictogram',
    );
    return '$_temp0';
  }

  @override
  String get pictogramasTitle => 'Pictograms';

  @override
  String get comunicarTitle => 'Communicate';

  @override
  String get sentenceStripEmpty => 'Tap pictograms to build your sentence';

  @override
  String get removeLastTooltip => 'Remove last';

  @override
  String get clearSentenceTooltip => 'Clear sentence';

  @override
  String get playTooltip => 'Play sentence';

  @override
  String get allCategoriesChip => 'All';

  @override
  String get emptyCategoryHint => 'No pictograms in this category';

  @override
  String get voiceUnavailable => 'Voice not available on this device';

  @override
  String get close => 'Close';

  @override
  String get cancel => 'Cancel';

  @override
  String get next => 'Continue';

  @override
  String get keep => 'Keep';

  @override
  String get deleteForever => 'Delete permanently';

  @override
  String get confirmDeleteTitle => 'Confirm deletion?';

  @override
  String get deleteIrreversible => 'This action cannot be undone.';

  @override
  String deleteCategoryTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String deleteCategoryContent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'The catalog and its contents will be deleted ($count pictograms of this child).',
      one: 'The catalog and its contents will be deleted (1 pictogram of this child).',
    );
    return '$_temp0';
  }

  @override
  String get deleteCatalogTooltip => 'Delete catalog';

  @override
  String get categoryEmpty => 'No pictograms in this category yet';

  @override
  String deletePictoTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get deletePictoContent =>
      'The pictogram will be deleted from this device for this child.';

  @override
  String get deletePictoButton => 'Delete pictogram';

  @override
  String get addPictoTitle => 'New pictogram';

  @override
  String get imageLoadError => 'The image could not be loaded';

  @override
  String get urlDownloadError =>
      'The image could not be downloaded (the site may block it). Save it on this device and pick it from the gallery.';

  @override
  String get selectChildFirst =>
      'Pick a child first in \"Change child\" (RF3.4)';

  @override
  String get nameFieldRequired => 'Enter a name';

  @override
  String get imageRequired => 'Pick an image';

  @override
  String get categoryRequired => 'Pick a category';

  @override
  String get saveError => 'Could not save. Please try again.';

  @override
  String get nameFieldLabel => 'Name';

  @override
  String get nameFieldHint => 'e.g. Water';

  @override
  String get firstCatalogWarning =>
      'Create a catalog first so you can save pictograms';

  @override
  String get categoryFieldLabel => 'Category';

  @override
  String get savePictoButton => 'Save pictogram';

  @override
  String get tapToPickImage => 'Tap to pick an image';

  @override
  String get webImageTitle => 'Image from the web';

  @override
  String get webImageContent =>
      'In Google Images: press and hold the image → \"Copy image address\" and paste it here.';

  @override
  String get urlInputHint => 'https://...';

  @override
  String get download => 'Download';

  @override
  String get gallery => 'Gallery';

  @override
  String get camera => 'Camera';

  @override
  String get cameraUnavailable => 'Not available in the browser';

  @override
  String get pasteImageUrl => 'Paste image URL';

  @override
  String get pasteUrlSub => 'e.g. an image from Google Images';

  @override
  String get addCategoryTitle => 'New catalog';

  @override
  String get categoryNameLabel => 'Category name';

  @override
  String get categoryNameHint => 'e.g. Drinks';

  @override
  String get colorLabel => 'Color';

  @override
  String get saveCategoryButton => 'Save catalog';

  @override
  String get duplicateCategory => 'A category with that name already exists';

  @override
  String get profileTitle => 'Profile';

  @override
  String get childrenSection => 'Children';

  @override
  String get addChildTooltip => 'Add child';

  @override
  String get noChildrenYet => 'No children added yet';

  @override
  String get accountSection => 'My account';

  @override
  String get signOut => 'Sign out';

  @override
  String get deleteProfileTooltip => 'Delete profile';

  @override
  String profilesLoadError(String message) {
    return 'Could not read the profiles: $message';
  }

  @override
  String selectorLoadError(String message) {
    return 'Could not load the profiles: $message';
  }

  @override
  String get selectorTitle => 'Who is communicating today?';

  @override
  String get selectorSubtitle => 'Tap your photo to start';

  @override
  String get selectorEmptyTitle => 'No child profiles yet';

  @override
  String get selectorEmptySubtitle => 'Create the first one to get started';

  @override
  String get createProfile => 'Create profile';

  @override
  String get addChildDialog => 'Add child';

  @override
  String get addChildAction => 'Add';

  @override
  String deleteChildTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get deleteChildContent =>
      'The child profile will be deleted from this device, along with its settings.';

  @override
  String deleteChildFinalContent(String name) {
    return '\"$name\" will be deleted permanently. This action cannot be undone.';
  }

  @override
  String get emptyCatalogTitle => 'No pictograms yet';

  @override
  String get emptyCatalogSubtitle => 'Images you add will appear here';

  @override
  String get languageSection => 'Language';
}
