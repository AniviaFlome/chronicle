import 'package:flutter/widgets.dart';

import 'app_localizations.dart';
import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

export 'app_localizations.dart';
export 'app_localizations_en.dart';
export 'app_localizations_tr.dart';

/// `context.l10n` with an English fallback so unit/widget tests that pump
/// screens without localization delegates still read English strings.
extension L10nX on BuildContext {
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ?? AppLocalizationsEn();
}

/// Resolves [AppLocalizations] without a [BuildContext] (e.g. background
/// notifications): stored override, else the system language.
AppLocalizations localizationsForCode(String code) =>
    code == 'tr' ? AppLocalizationsTr() : AppLocalizationsEn();
