import 'hacettepe_provider.dart';
import 'itu_provider.dart';
import 'menu_provider.dart';
import '../../l10n/l10n.dart';

/// A dining-menu source entry: locale-aware display name plus factory.
typedef MenuSource = ({
  String Function(AppLocalizations) name,
  MenuProvider Function() create,
});

/// Every dining-menu source the app can use, keyed by provider id.
/// Add new universities here; the menu page and settings build from this.
final Map<String, MenuSource> menuSources = {
  'hacettepe': (name: (_) => 'Hacettepe', create: HacettepeMenuProvider.new),
  'itu': (name: (l10n) => l10n.menuSourceItuName, create: ItuMenuProvider.new),
};
