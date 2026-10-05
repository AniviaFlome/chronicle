import 'package:home_widget_generator/home_widget_generator.dart';

// Header style: small semibold accent with a pre-formatted count
// ("Due tasks · 3").
const _headerStyle = HWTextStyle(
  fontSize: 12,
  fontWeight: HWFontWeight.w600,
  color: HWColor.themed(
    light: HWColor.fixed(0xFF6750A4),
    dark: HWColor.fixed(0xFFD0BCFF),
  ),
);

// Row title style: white on dark, near-black on light. The checkbox is a
// "☐ " text prefix pushed in the title itself; overdue rows keep the
// `! ` marker after it.
const _titleStyle = HWTextStyle(
  fontSize: 14,
  color: HWColor.themed(
    light: HWColor.fixed(0xFF1C1B1F),
    dark: HWColor.fixed(0xFFFFFFFF),
  ),
);

// Row date style: small gray (" · 2026-10-06").
const _dateStyle = HWTextStyle(
  fontSize: 12,
  color: HWColor.themed(
    light: HWColor.fixed(0xFF49454F),
    dark: HWColor.fixed(0xFFCAC4D0),
  ),
);

/// Small (2x2) widget: the top 3 open tasks with due dates.
///
/// Compact sibling of the full 4x4 Due tasks widget: same row format
/// (checkbox-prefix title + gray date), capped at 3 rows so the small
/// card fills without clipping. Refreshed from the app on start; the
/// periodic update re-renders the stored list.
@HomeWidget(
  name: 'DueTasksCompact',
  android: HomeWidgetAndroidConfiguration(
    minWidth: 110,
    minHeight: 110,
    targetCellWidth: 2,
    targetCellHeight: 2,
    updatePeriodMillis: 1800000,
  ),
  localization: HomeWidgetLocalization(
    defaultLocale: 'en',
    supportedLocales: ['en', 'tr'],
    name: {
      'en': 'Due tasks',
      'tr': 'Yaklaşan Görevler',
    },
    description: {
      'en': 'Shows the next 3 open tasks with due dates.',
      'tr': 'Yaklaşan 3 açık görevi gösterir.',
    },
  ),
  widget: HWSizeAdaptive(
    small: HWColumn(
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
        HWText(
          HWString('headerLine', defaultValue: 'Due tasks'),
          style: _headerStyle,
          textAlign: HWTextAlign.start,
        ),
        HWColumn.builder(
          'tasks',
          crossAxisAlignment: HWCrossAxisAlignment.start,
          item: HWRow(
            children: [
              HWText(
                HWItemData(HWString('title')),
                style: _titleStyle,
              ),
              HWText(
                HWItemData(HWString('date')),
                style: _dateStyle,
              ),
            ],
          ),
          maxItems: 3,
          whenEmpty: HWText.localized(
            {
              'en': 'Nothing due',
              'tr': 'Vadesi gelen yok',
            },
            style: _titleStyle,
            textAlign: HWTextAlign.start,
          ),
        ),
      ],
    ),
  ),
)
class DueTasksCompact {}
