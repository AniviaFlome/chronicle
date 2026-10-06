import 'package:home_widget_generator/home_widget_generator.dart';

// Header label style: small semibold accent (M3 primary tones).
const _headerStyle = HWTextStyle(
  fontSize: 12,
  fontWeight: HWFontWeight.w600,
  color: HWColor.themed(
    light: HWColor.fixed(0xFF6750A4),
    dark: HWColor.fixed(0xFFD0BCFF),
  ),
);

// Class title style: large bold, near-black on light, white on dark.
const _titleStyle = HWTextStyle(
  fontSize: 20,
  fontWeight: HWFontWeight.bold,
  color: HWColor.themed(
    light: HWColor.fixed(0xFF1C1B1F),
    dark: HWColor.fixed(0xFFFFFFFF),
  ),
);

// Detail line style: small gray (time range, room).
const _detailStyle = HWTextStyle(
  fontSize: 12,
  color: HWColor.themed(
    light: HWColor.fixed(0xFF49454F),
    dark: HWColor.fixed(0xFFCAC4D0),
  ),
);

// "Then ..." line style: small, accent-tinted like the header.
const _thenStyle = HWTextStyle(
  fontSize: 12,
  color: HWColor.themed(
    light: HWColor.fixed(0xFF6750A4),
    dark: HWColor.fixed(0xFFD0BCFF),
  ),
);

/// Small (2x2) widget: the current or next class today.
///
/// Visual language: accent header, big bold title, gray detail line, plus
/// a "Then ..." line naming the class after so the card fills instead of
/// leaving blank space. All dynamic text is pre-formatted in Dart (plain
/// [HWString]) so no plurals or placeholders are needed in widget strings.
/// The four fields share one timeline: the app pushes one entry per class
/// (keyed at its display-from time) plus a closing "done" entry, and native
/// code resolves the latest entry not after the render time.
@HomeWidget(
  name: 'NextClass',
  android: HomeWidgetAndroidConfiguration(
    minWidth: 180,
    minHeight: 110,
    targetCellWidth: 3,
    targetCellHeight: 2,
    updatePeriodMillis: 1800000,
  ),
  localization: HomeWidgetLocalization(
    defaultLocale: 'en',
    supportedLocales: ['en', 'tr'],
    name: {
      'en': 'Next class',
      'tr': 'Sonraki ders',
    },
    description: {
      'en': 'Shows the current or next class today.',
      'tr': 'Bugünkü mevcut veya sonraki dersi gösterir.',
    },
  ),
  widget: HWSizeAdaptive(
    small: HWRow(
      crossAxisAlignment: HWCrossAxisAlignment.start,
      spacing: 12,
      children: [
        // Slim accent rail (C6 design). Fixed placeholder color here;
        // native code swaps it for the app-theme accent at render time
        // (same crash-safe when-table as the text colors).
        HWColoredBox(
          color: HWColor.fixed(0xFF4F6BED),
          child: HWSizedBox(
            width: 6,
            height: double.infinity,
            child: HWText.fixed(''),
          ),
        ),
        HWColumn(
      crossAxisAlignment: HWCrossAxisAlignment.start,
      children: [
        // App-theme colors pushed at refresh time (0 = unset). Pristine
        // generated widgets ignore them (system Glance colors); the data
        // stays correct if native theming is ever reintroduced.
        HWDataOnly([
          HWInt('themeBg', defaultValue: 0),
          HWInt('themeFg', defaultValue: 0),
          HWInt('themeAccent', defaultValue: 0),
        ]),
        HWText.localized(
          {
            'en': 'Next class',
            'tr': 'Sonraki ders',
          },
          style: _headerStyle,
          textAlign: HWTextAlign.start,
        ),
        HWText(
          HWTimedData(HWString('className', defaultValue: '—')),
          style: _titleStyle,
          textAlign: HWTextAlign.start,
        ),
        HWText(
          HWTimedData(HWString('detailLine', defaultValue: '')),
          style: _detailStyle,
          textAlign: HWTextAlign.start,
        ),
        HWText(
          HWTimedData(HWString('thenLine', defaultValue: '')),
          style: _thenStyle,
          textAlign: HWTextAlign.start,
        ),
      ],
        ),
      ],
    ),
  ),
)
class NextClass {}
