import 'package:pictocomm/l10n/app_localizations.dart';

import '../../../../core/error/app_exception.dart';

/// Traduce un [AuthErrorCode] al mensaje l10n correspondiente (RF-6.8): las
/// pantallas de login/registro muestran este texto bajo el formulario.
String authErrorMessage(AuthErrorCode code, AppLocalizations l10n) {
  return switch (code) {
    AuthErrorCode.invalidCredentials => l10n.authInvalidCredentials,
    AuthErrorCode.emailInUse => l10n.authEmailInUse,
    AuthErrorCode.connection => l10n.authConnectionError,
    AuthErrorCode.unexpected => l10n.authUnexpectedError,
  };
}
