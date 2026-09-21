import 'package:flutter/material.dart';

/// App theme ids.
const defaultAppTheme = 'default';
const catppuccinAppTheme = 'catppuccin';
const nordAppTheme = 'nord';
const draculaAppTheme = 'dracula';
const gruvboxAppTheme = 'gruvbox';
const tokyoNightAppTheme = 'tokyo-night';

/// One selectable theme family.
class AppThemeDef {
  /// Stable id persisted in settings.
  final String id;
  final String name;

  /// Whether the user can pick an accent color for this theme.
  final bool supportsAccent;
  final Map<String, int> accents;
  final int defaultAccent;

  /// Surface ramp, dark brightness first.
  final ThemeRamp dark;
  final ThemeRamp light;

  const AppThemeDef({
    required this.id,
    required this.name,
    required this.supportsAccent,
    required this.accents,
    required this.defaultAccent,
    required this.dark,
    required this.light,
  });
}

class ThemeRamp {
  /// Main background.
  final Color surface;

  /// Cards, dialogs, sheets and navigation surfaces, darkest first.
  final Color lowest;
  final Color low;
  final Color container;
  final Color high;
  final Color highest;

  const ThemeRamp({
    required this.surface,
    required this.lowest,
    required this.low,
    required this.container,
    required this.high,
    required this.highest,
  });
}

/// Catppuccin Mocha base tones (dark) and Latte base tones (light).
abstract final class Catppuccin {
  static const mochaBase = Color(0xFF1E1E2E);
  static const mochaMantle = Color(0xFF181825);
  static const latteBase = Color(0xFFEFF1F5);
  static const latteMantle = Color(0xFFDCDFE8);

  /// Accent name to richer (Mocha) hex value.
  static const accents = <String, int>{
    'Rosewater': 0xFFF5E0DC,
    'Flamingo': 0xFFF2CDCD,
    'Pink': 0xFFF5C2E7,
    'Mauve': 0xFFCBA6F7,
    'Red': 0xFFF38BA8,
    'Maroon': 0xFFEBA0AC,
    'Peach': 0xFFFAB387,
    'Yellow': 0xFFF9E2AF,
    'Green': 0xFFA6E3A1,
    'Teal': 0xFF94E2D5,
    'Sky': 0xFF89DCEB,
    'Sapphire': 0xFF74C7EC,
    'Blue': 0xFF89B4FA,
    'Lavender': 0xFFB4BEFE,
  };

  /// Default accent (Mauve).
  static const defaultAccent = 0xFFCBA6F7;
}

const _defaultTheme = AppThemeDef(
  id: defaultAppTheme,
  name: 'Default',
  supportsAccent: false,
  accents: {},
  defaultAccent: 0xFF4F6BED,
  dark: ThemeRamp(
    surface: Color(0xFF131318),
    lowest: Color(0xFF0E0E11),
    low: Color(0xFF1B1B1F),
    container: Color(0xFF1F1F25),
    high: Color(0xFF2A2A32),
    highest: Color(0xFF35353F),
  ),
  light: ThemeRamp(
    surface: Color(0xFFFEF7FF),
    lowest: Color(0xFFFFFFFF),
    low: Color(0xFFF7F2FA),
    container: Color(0xFFF3EDF7),
    high: Color(0xFFECE6F0),
    highest: Color(0xFFE6E0E9),
  ),
);

const _catppuccinTheme = AppThemeDef(
  id: catppuccinAppTheme,
  name: 'Catppuccin',
  supportsAccent: true,
  accents: Catppuccin.accents,
  defaultAccent: Catppuccin.defaultAccent,
  dark: ThemeRamp(
    surface: Catppuccin.mochaBase,
    lowest: Color(0xFF11111B),
    low: Catppuccin.mochaMantle,
    container: Color(0xFF313244),
    high: Color(0xFF45475A),
    highest: Color(0xFF585B70),
  ),
  light: ThemeRamp(
    surface: Catppuccin.latteBase,
    lowest: Color(0xFFDCE0E8),
    low: Catppuccin.latteMantle,
    container: Color(0xFFCCD0DA),
    high: Color(0xFFBCC0CC),
    highest: Color(0xFFACB0BE),
  ),
);

const _nordTheme = AppThemeDef(
  id: nordAppTheme,
  name: 'Nord',
  supportsAccent: true,
  accents: {
    'Frost 1': 0xFF8FBCBB,
    'Frost 2': 0xFF88C0D0,
    'Frost 3': 0xFF81A1C1,
    'Frost 4': 0xFF5E81AC,
    'Aurora red': 0xFFBF616A,
    'Aurora orange': 0xFFD08770,
    'Aurora yellow': 0xFFEBCB8B,
    'Aurora green': 0xFFA3BE8C,
    'Aurora purple': 0xFFB48EAD,
  },
  defaultAccent: 0xFF88C0D0,
  dark: ThemeRamp(
    surface: Color(0xFF2E3440),
    lowest: Color(0xFF242933),
    low: Color(0xFF2A303C),
    container: Color(0xFF3B4252),
    high: Color(0xFF434C5E),
    highest: Color(0xFF4C566A),
  ),
  light: ThemeRamp(
    surface: Color(0xFFECEFF4),
    lowest: Color(0xFFD8DEE9),
    low: Color(0xFFE5E9F0),
    container: Color(0xFFDDE3EC),
    high: Color(0xFFD3D9E4),
    highest: Color(0xFFC6CDDB),
  ),
);

const _draculaTheme = AppThemeDef(
  id: draculaAppTheme,
  name: 'Dracula',
  supportsAccent: true,
  accents: {
    'Purple': 0xFFBD93F9,
    'Cyan': 0xFF8BE9FD,
    'Green': 0xFF50FA7B,
    'Orange': 0xFFFFB86C,
    'Pink': 0xFFFF79C6,
    'Red': 0xFFFF5555,
    'Yellow': 0xFFF1FA8C,
  },
  defaultAccent: 0xFFBD93F9,
  dark: ThemeRamp(
    surface: Color(0xFF282A36),
    lowest: Color(0xFF1E1F29),
    low: Color(0xFF23242F),
    container: Color(0xFF44475A),
    high: Color(0xFF52556B),
    highest: Color(0xFF60647E),
  ),
  light: ThemeRamp(
    surface: Color(0xFFF8F8F2),
    lowest: Color(0xFFE4E4DC),
    low: Color(0xFFECECDB),
    container: Color(0xFFDFDFC8),
    high: Color(0xFFD2D2B4),
    highest: Color(0xFFC4C4A0),
  ),
);

const _gruvboxTheme = AppThemeDef(
  id: gruvboxAppTheme,
  name: 'Gruvbox',
  supportsAccent: true,
  accents: {
    'Red': 0xFFFB4934,
    'Green': 0xFFB8BB26,
    'Yellow': 0xFFFABD2F,
    'Blue': 0xFF83A598,
    'Purple': 0xFFD3869B,
    'Aqua': 0xFF8EC07C,
    'Orange': 0xFFFE8019,
  },
  defaultAccent: 0xFFFABD2F,
  dark: ThemeRamp(
    surface: Color(0xFF282828),
    lowest: Color(0xFF1D2021),
    low: Color(0xFF232627),
    container: Color(0xFF3C3836),
    high: Color(0xFF504945),
    highest: Color(0xFF665C54),
  ),
  light: ThemeRamp(
    surface: Color(0xFFFBF1C7),
    lowest: Color(0xFFD5C4A1),
    low: Color(0xFFEBDBB2),
    container: Color(0xFFE3D3A8),
    high: Color(0xFFD8C69E),
    highest: Color(0xFFCCB891),
  ),
);

const _tokyoNightTheme = AppThemeDef(
  id: tokyoNightAppTheme,
  name: 'Tokyo Night',
  supportsAccent: true,
  accents: {
    'Blue': 0xFF7AA2F7,
    'Cyan': 0xFF7DCFFF,
    'Magenta': 0xFFBB9AF7,
    'Green': 0xFF9ECE6A,
    'Yellow': 0xFFE0AF68,
    'Red': 0xFFF7768E,
    'Orange': 0xFFFF9E64,
    'Purple': 0xFF9D7CD8,
    'Teal': 0xFF41A6B6,
  },
  defaultAccent: 0xFF7AA2F7,
  dark: ThemeRamp(
    surface: Color(0xFF1A1B26),
    lowest: Color(0xFF16161E),
    low: Color(0xFF1E202E),
    container: Color(0xFF292E42),
    high: Color(0xFF363C5A),
    highest: Color(0xFF444B6A),
  ),
  light: ThemeRamp(
    surface: Color(0xFFD5D6DB),
    lowest: Color(0xFFB4B5BD),
    low: Color(0xFFC4C5CC),
    container: Color(0xFFC0C1C9),
    high: Color(0xFFB2B3BB),
    highest: Color(0xFFA3A4AD),
  ),
);

/// All selectable themes in display order.
const appThemes = [
  _defaultTheme,
  _catppuccinTheme,
  _nordTheme,
  _draculaTheme,
  _gruvboxTheme,
  _tokyoNightTheme,
];

/// Looks up a theme by id, falling back to Default for unknown values.
AppThemeDef lookupAppTheme(String id) {
  for (final theme in appThemes) {
    if (theme.id == id) return theme;
  }
  return _defaultTheme;
}

/// Builds the app [ThemeData] for a brightness, theme id and accent color.
///
/// Unknown theme ids fall back to Default. The accent only applies to
/// themes with [AppThemeDef.supportsAccent]; every theme gets a full
/// surface ramp so cards, dialogs, sheets and navigation match.
ThemeData buildAppTheme({
  required String themeId,
  required int accentValue,
  required Brightness brightness,
}) {
  final def = lookupAppTheme(themeId);
  final dark = brightness == Brightness.dark;
  final ramp = dark ? def.dark : def.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: def.supportsAccent
        ? Color(accentValue)
        : Color(def.defaultAccent),
    brightness: brightness,
    surface: ramp.surface,
    surfaceDim: ramp.lowest,
    surfaceContainerLowest: ramp.lowest,
    surfaceContainerLow: ramp.low,
    surfaceContainer: ramp.container,
    surfaceContainerHigh: ramp.high,
    surfaceContainerHighest: ramp.highest,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    dialogTheme: DialogThemeData(backgroundColor: ramp.high),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: ramp.low,
      showDragHandle: true,
    ),
    timePickerTheme: TimePickerThemeData(backgroundColor: ramp.high),
    datePickerTheme: DatePickerThemeData(backgroundColor: ramp.high),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: ramp.highest,
      contentTextStyle: TextStyle(color: scheme.onSurface),
    ),
    popupMenuTheme: PopupMenuThemeData(color: ramp.high),
  );
}

/// Opaque class/event block background: the class color blended toward the
/// surface, so grid shading underneath never shows through. The blend is
/// stronger in dark mode to keep text contrast. Always fully opaque.
/// The class color is first harmonized toward the theme seed (primary) so
/// saturated palette entries visibly follow the active color scheme
/// (Default/Catppuccin/Nord/…) and accent choice.
Color classBlockColor(ColorScheme scheme, Color klass) {
  final harmonized = Color.lerp(klass, scheme.primary, 0.35) ?? klass;
  return Color.lerp(
    scheme.surface,
    harmonized,
    scheme.brightness == Brightness.dark ? 0.45 : 0.30,
  )!;
}

/// Border/accent for a class block: harmonized class color, never raw neon.
/// Blends strongly toward the scheme primary so class colors visibly change
/// when the theme family or accent changes.
Color classAccentColor(ColorScheme scheme, Color klass) =>
    Color.lerp(klass, scheme.primary, 0.35) ?? klass;

/// Readable foreground for [background] (a [classBlockColor] result).
/// Prefers onSurface when contrast is sufficient, else black/white.
Color classOnBlockColor(ColorScheme scheme, Color background) {
  final brightness = ThemeData.estimateBrightnessForColor(background);
  if (brightness == Brightness.dark) return const Color(0xFFFFFFFF);
  // Light backgrounds: use onSurface for theme consistency; it is near-black
  // on all light ramps. Fall back to black if scheme is unusual.
  return scheme.onSurface;
}
