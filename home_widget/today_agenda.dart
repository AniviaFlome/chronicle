import 'package:home_widget_generator/home_widget_generator.dart';

// Row time style: small bold accent ("08:40").
const _timeStyle = HWTextStyle(
  fontSize: 12,
  fontWeight: HWFontWeight.bold,
  color: HWColor.themed(
    light: HWColor.fixed(0xFF6750A4),
    dark: HWColor.fixed(0xFFD0BCFF),
  ),
);

// Row name style: white title on dark, near-black on light.
const _nameStyle = HWTextStyle(
  fontSize: 14,
  color: HWColor.themed(
    light: HWColor.fixed(0xFF1C1B1F),
    dark: HWColor.fixed(0xFFFFFFFF),
  ),
);

// Week-rail day style: small gray (other days). 11sp so two-digit
// dates (10/11) don't kiss in the 4x2 card.
const _railStyle = HWTextStyle(
  fontSize: 14,
  color: HWColor.themed(
    light: HWColor.fixed(0xFF49454F),
    dark: HWColor.fixed(0xFFCAC4D0),
  ),
);

/// Agenda widget (default 4x2, small 2x2): selectable 7-day agenda.
///
/// Medium slot: 7-day rail (tap a day to select it) + the selected day's
/// rows. Small slot: the selected day's rows only. Each day is pushed as
/// its own (time, name) list (day0 = today … day6); the selected day
/// index lives in the widget prefs (tap selection, resets to today on
/// each app push). Refreshed from the app on start; the periodic update
/// re-renders the stored lists.
@HomeWidget(
  name: 'TodayAgenda',
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
      'en': 'Today’s classes',
      'tr': 'Bugünkü dersler',
    },
    description: {
      'en': 'Lists today’s classes.',
      'tr': 'Bugünkü dersleri listeler.',
    },
  ),
  widget: HWSizeAdaptive(
    // Small (2x2) slot: weekday rail + divider + rows, no header.
    small: HWColumn(
      crossAxisAlignment: HWCrossAxisAlignment.start,
      children: [
        HWRow.builder(
          'week',
          spacing: 10,
          item: HWText(
            HWItemData(HWString('label')),
            style: _railStyle,
            textAlign: HWTextAlign.center,
          ),
          maxItems: 7,
          whenEmpty: HWText.fixed(''),
        ),
        // Full-width divider under the rail (same as medium slot). NOTE:
        // native adds 12dp top padding on the rows columns below (no
        // schema equivalent) — keep patch_all2.py in sync after regen.
        HWColoredBox(
          color: HWColor.themed(
            light: HWColor.fixed(0xFFCAC4D0),
            dark: HWColor.fixed(0xFF49454F),
          ),
          child: HWSizedBox(
            width: double.infinity,
            height: 1,
            child: HWText.fixed(''),
          ),
        ),
                HWColumn.builder(
          'day0',
          crossAxisAlignment: HWCrossAxisAlignment.start,
          item: HWRow(
            spacing: 4,
            children: [
              HWSizedBox(
                width: 40,
                child: HWText(
                  HWItemData(HWString('time')),
                  style: _timeStyle,
                  textAlign: HWTextAlign.start,
                ),
              ),
              HWText(
                HWItemData(HWString('name')),
                style: _nameStyle,
              ),
            ],
          ),
          maxItems: 3,
          whenEmpty: HWText.localized(
            {
              'en': 'No classes',
              'tr': 'Ders yok',
            },
            style: _nameStyle,
            textAlign: HWTextAlign.start,
          ),
        ),
        HWColumn.builder(
          'day1',
          crossAxisAlignment: HWCrossAxisAlignment.start,
          item: HWRow(
            spacing: 4,
            children: [
              HWSizedBox(
                width: 40,
                child: HWText(
                  HWItemData(HWString('time')),
                  style: _timeStyle,
                  textAlign: HWTextAlign.start,
                ),
              ),
              HWText(
                HWItemData(HWString('name')),
                style: _nameStyle,
              ),
            ],
          ),
          maxItems: 3,
          whenEmpty: HWText.localized(
            {
              'en': 'No classes',
              'tr': 'Ders yok',
            },
            style: _nameStyle,
            textAlign: HWTextAlign.start,
          ),
        ),
        HWColumn.builder(
          'day2',
          crossAxisAlignment: HWCrossAxisAlignment.start,
          item: HWRow(
            spacing: 4,
            children: [
              HWSizedBox(
                width: 40,
                child: HWText(
                  HWItemData(HWString('time')),
                  style: _timeStyle,
                  textAlign: HWTextAlign.start,
                ),
              ),
              HWText(
                HWItemData(HWString('name')),
                style: _nameStyle,
              ),
            ],
          ),
          maxItems: 3,
          whenEmpty: HWText.localized(
            {
              'en': 'No classes',
              'tr': 'Ders yok',
            },
            style: _nameStyle,
            textAlign: HWTextAlign.start,
          ),
        ),
        HWColumn.builder(
          'day3',
          crossAxisAlignment: HWCrossAxisAlignment.start,
          item: HWRow(
            spacing: 4,
            children: [
              HWSizedBox(
                width: 40,
                child: HWText(
                  HWItemData(HWString('time')),
                  style: _timeStyle,
                  textAlign: HWTextAlign.start,
                ),
              ),
              HWText(
                HWItemData(HWString('name')),
                style: _nameStyle,
              ),
            ],
          ),
          maxItems: 3,
          whenEmpty: HWText.localized(
            {
              'en': 'No classes',
              'tr': 'Ders yok',
            },
            style: _nameStyle,
            textAlign: HWTextAlign.start,
          ),
        ),
        HWColumn.builder(
          'day4',
          crossAxisAlignment: HWCrossAxisAlignment.start,
          item: HWRow(
            spacing: 4,
            children: [
              HWSizedBox(
                width: 40,
                child: HWText(
                  HWItemData(HWString('time')),
                  style: _timeStyle,
                  textAlign: HWTextAlign.start,
                ),
              ),
              HWText(
                HWItemData(HWString('name')),
                style: _nameStyle,
              ),
            ],
          ),
          maxItems: 3,
          whenEmpty: HWText.localized(
            {
              'en': 'No classes',
              'tr': 'Ders yok',
            },
            style: _nameStyle,
            textAlign: HWTextAlign.start,
          ),
        ),
        HWColumn.builder(
          'day5',
          crossAxisAlignment: HWCrossAxisAlignment.start,
          item: HWRow(
            spacing: 4,
            children: [
              HWSizedBox(
                width: 40,
                child: HWText(
                  HWItemData(HWString('time')),
                  style: _timeStyle,
                  textAlign: HWTextAlign.start,
                ),
              ),
              HWText(
                HWItemData(HWString('name')),
                style: _nameStyle,
              ),
            ],
          ),
          maxItems: 3,
          whenEmpty: HWText.localized(
            {
              'en': 'No classes',
              'tr': 'Ders yok',
            },
            style: _nameStyle,
            textAlign: HWTextAlign.start,
          ),
        ),
        HWColumn.builder(
          'day6',
          crossAxisAlignment: HWCrossAxisAlignment.start,
          item: HWRow(
            spacing: 4,
            children: [
              HWSizedBox(
                width: 40,
                child: HWText(
                  HWItemData(HWString('time')),
                  style: _timeStyle,
                  textAlign: HWTextAlign.start,
                ),
              ),
              HWText(
                HWItemData(HWString('name')),
                style: _nameStyle,
              ),
            ],
          ),
          maxItems: 3,
          whenEmpty: HWText.localized(
            {
              'en': 'No classes',
              'tr': 'Ders yok',
            },
            style: _nameStyle,
            textAlign: HWTextAlign.start,
          ),
        ),
      ],
    ),
    medium: HWColumn(
      crossAxisAlignment: HWCrossAxisAlignment.start,
      children: [
        // App-theme colors pushed at refresh time (0 = unset). Pristine
        // generated widgets ignore them (system Glance colors); the data
        // stays correct if native theming is ever reintroduced.
        HWDataOnly([
          HWInt('themeBg', defaultValue: 0),
          HWInt('themeFg', defaultValue: 0),
          HWInt('themeAccent', defaultValue: 0),
          // Day-selection reset: the app always pushes 0 (today); rail
          // taps overwrite it natively between pushes.
          HWInt('selectedDay', defaultValue: 0),
        ]),
        // 7-day rail (weekday names, rolling from today; day0 = today).
        // One short day name per cell (Mon/Tue, locale-aware); the selected
        // day is accent-marked
        // natively. Pushed as (date, isToday) pairs.
        HWRow.builder(
          'week',
          spacing: 10,
          item: HWText(
            HWItemData(HWString('label')),
            style: _railStyle,
            textAlign: HWTextAlign.center,
          ),
          maxItems: 7,
          whenEmpty: HWText.fixed(''),
        ),
        // Full-width divider under the rail (C5 mock). NOTE: native
        // adds 12dp top padding on the rows columns below (no schema
        // equivalent) — keep patch_all2.py in sync after regen.
        HWColoredBox(
          color: HWColor.themed(
            light: HWColor.fixed(0xFFCAC4D0),
            dark: HWColor.fixed(0xFF49454F),
          ),
          child: HWSizedBox(
            width: double.infinity,
            height: 1,
            child: HWText.fixed(''),
          ),
        ),
                HWColumn.builder(
          'day0',
          crossAxisAlignment: HWCrossAxisAlignment.start,
          item: HWRow(
            spacing: 4,
            children: [
              HWSizedBox(
                width: 40,
                child: HWText(
                  HWItemData(HWString('time')),
                  style: _timeStyle,
                  textAlign: HWTextAlign.start,
                ),
              ),
              HWText(
                HWItemData(HWString('name')),
                style: _nameStyle,
              ),
            ],
          ),
          maxItems: 4,
          whenEmpty: HWText.localized(
            {
              'en': 'No classes',
              'tr': 'Ders yok',
            },
            style: _nameStyle,
            textAlign: HWTextAlign.start,
          ),
        ),
        HWColumn.builder(
          'day1',
          crossAxisAlignment: HWCrossAxisAlignment.start,
          item: HWRow(
            spacing: 4,
            children: [
              HWSizedBox(
                width: 40,
                child: HWText(
                  HWItemData(HWString('time')),
                  style: _timeStyle,
                  textAlign: HWTextAlign.start,
                ),
              ),
              HWText(
                HWItemData(HWString('name')),
                style: _nameStyle,
              ),
            ],
          ),
          maxItems: 4,
          whenEmpty: HWText.localized(
            {
              'en': 'No classes',
              'tr': 'Ders yok',
            },
            style: _nameStyle,
            textAlign: HWTextAlign.start,
          ),
        ),
        HWColumn.builder(
          'day2',
          crossAxisAlignment: HWCrossAxisAlignment.start,
          item: HWRow(
            spacing: 4,
            children: [
              HWSizedBox(
                width: 40,
                child: HWText(
                  HWItemData(HWString('time')),
                  style: _timeStyle,
                  textAlign: HWTextAlign.start,
                ),
              ),
              HWText(
                HWItemData(HWString('name')),
                style: _nameStyle,
              ),
            ],
          ),
          maxItems: 4,
          whenEmpty: HWText.localized(
            {
              'en': 'No classes',
              'tr': 'Ders yok',
            },
            style: _nameStyle,
            textAlign: HWTextAlign.start,
          ),
        ),
        HWColumn.builder(
          'day3',
          crossAxisAlignment: HWCrossAxisAlignment.start,
          item: HWRow(
            spacing: 4,
            children: [
              HWSizedBox(
                width: 40,
                child: HWText(
                  HWItemData(HWString('time')),
                  style: _timeStyle,
                  textAlign: HWTextAlign.start,
                ),
              ),
              HWText(
                HWItemData(HWString('name')),
                style: _nameStyle,
              ),
            ],
          ),
          maxItems: 4,
          whenEmpty: HWText.localized(
            {
              'en': 'No classes',
              'tr': 'Ders yok',
            },
            style: _nameStyle,
            textAlign: HWTextAlign.start,
          ),
        ),
        HWColumn.builder(
          'day4',
          crossAxisAlignment: HWCrossAxisAlignment.start,
          item: HWRow(
            spacing: 4,
            children: [
              HWSizedBox(
                width: 40,
                child: HWText(
                  HWItemData(HWString('time')),
                  style: _timeStyle,
                  textAlign: HWTextAlign.start,
                ),
              ),
              HWText(
                HWItemData(HWString('name')),
                style: _nameStyle,
              ),
            ],
          ),
          maxItems: 4,
          whenEmpty: HWText.localized(
            {
              'en': 'No classes',
              'tr': 'Ders yok',
            },
            style: _nameStyle,
            textAlign: HWTextAlign.start,
          ),
        ),
        HWColumn.builder(
          'day5',
          crossAxisAlignment: HWCrossAxisAlignment.start,
          item: HWRow(
            spacing: 4,
            children: [
              HWSizedBox(
                width: 40,
                child: HWText(
                  HWItemData(HWString('time')),
                  style: _timeStyle,
                  textAlign: HWTextAlign.start,
                ),
              ),
              HWText(
                HWItemData(HWString('name')),
                style: _nameStyle,
              ),
            ],
          ),
          maxItems: 4,
          whenEmpty: HWText.localized(
            {
              'en': 'No classes',
              'tr': 'Ders yok',
            },
            style: _nameStyle,
            textAlign: HWTextAlign.start,
          ),
        ),
        HWColumn.builder(
          'day6',
          crossAxisAlignment: HWCrossAxisAlignment.start,
          item: HWRow(
            spacing: 4,
            children: [
              HWSizedBox(
                width: 40,
                child: HWText(
                  HWItemData(HWString('time')),
                  style: _timeStyle,
                  textAlign: HWTextAlign.start,
                ),
              ),
              HWText(
                HWItemData(HWString('name')),
                style: _nameStyle,
              ),
            ],
          ),
          maxItems: 4,
          whenEmpty: HWText.localized(
            {
              'en': 'No classes',
              'tr': 'Ders yok',
            },
            style: _nameStyle,
            textAlign: HWTextAlign.start,
          ),
        ),
      ],
    ),
  ),
)
class TodayAgenda {}
