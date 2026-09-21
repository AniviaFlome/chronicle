import 'hacettepe_provider.dart';
import 'menu_provider.dart';

/// A dining-menu source entry: display name plus factory.
typedef MenuSource = ({String name, MenuProvider Function() create});

/// Every dining-menu source the app can use, keyed by provider id.
/// Add new universities here; the menu page and settings build from this.
final Map<String, MenuSource> menuSources = {
  'hacettepe': (name: 'Hacettepe', create: HacettepeMenuProvider.new),
};
