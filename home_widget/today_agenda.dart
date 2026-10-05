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
  fontSize: 11,
  color: HWColor.themed(
    light: HWColor.fixed(0xFF49454F),
    dark: HWColor.fixed(0xFFCAC4D0),
  ),
);

// Filler-row label style: small gray ("Tue 18:09" for upcoming classes).
const _laterStyle = HWTextStyle(
  fontSize: 12,
  color: HWColor.themed(
    light: HWColor.fixed(0xFF49454F),
    dark: HWColor.fixed(0xFFCAC4D0),
  ),
);

// Filler-row name style: gray class name for upcoming classes.
const _laterNameStyle = HWTextStyle(
  fontSize: 14,
  color: HWColor.themed(
    light: HWColor.fixed(0xFF49454F),
    dark: HWColor.fixed(0xFFCAC4D0),
  ),
);
const _railTodayStyle = HWTextStyle(
  fontSize: 11,
  fontWeight: HWFontWeight.bold,
  color: HWColor.themed(
    light: HWColor.fixed(0xFF6750A4),
    dark: HWColor.fixed(0xFFD0BCFF),
  ),
);

/// Agenda widget (default 2x2, wide 4x2): today's class agenda as a short list.
///
/// Visual language: accent "Today" header, then full-width rows with an
/// accent time and a white class name so the wide card fills. Each row is
/// pushed as a (time, name) pair; the time carries a trailing space as its
/// gap. Refreshed from the app on start; the periodic update re-renders
/// the stored list.
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
    // Small (2x2) slot: rows only, no header, no rail.
    small: HWColumn(
      crossAxisAlignment: HWCrossAxisAlignment.start,
      children: [
        HWColumn.builder(
          'classes',
          crossAxisAlignment: HWCrossAxisAlignment.start,
          item: HWRow(
            spacing: 8,
            children: [
              HWSizedBox(
                width: 78,
                child: HWText(
                  HWItemData(HWString('time')),
                  style: _timeStyle,
                ),
              ),
              HWText(
                HWItemData(HWString('name')),
                style: _nameStyle,
              ),
            ],
          ),
          maxItems: 2,
          whenEmpty: HWText.localized(
            {
              'en': 'No classes today',
              'tr': 'Bugün ders yok',
            },
            style: _nameStyle,
            textAlign: HWTextAlign.start,
          ),
        ),
        // Filler: upcoming classes after today, dimmed (kills the blank
        // card on sparse days). Pushed as (label, name) pairs.
        HWColumn.builder(
          'later',
          crossAxisAlignment: HWCrossAxisAlignment.start,
          item: HWRow(
            spacing: 8,
            children: [
              HWSizedBox(
                width: 78,
                child: HWText(
                  HWItemData(HWString('label')),
                  style: _laterStyle,
                ),
              ),
              HWText(
                HWItemData(HWString('name')),
                style: _laterNameStyle,
              ),
            ],
          ),
          maxItems: 1,
          whenEmpty: HWText.fixed(''),
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
        ]),
        // 7-day rail (C6 design): one single-line cell per day, today in
        // accent. Pushed as (initial, date, isToday) triples; the mock's
        // dots were dropped per review, so presence needs no field.
        HWRow.builder(
          'week',
          spacing: 10,
          item: HWBoolConditional(
            data: HWItemData(HWBool('isToday', defaultValue: false)),
            whenTrue: HWColumn(
              children: [
                HWText(
                  HWItemData(HWString('initial')),
                  style: _railTodayStyle,
                ),
                HWText(
                  HWItemData(HWString('date')),
                  style: _railTodayStyle,
                ),
              ],
            ),
            whenFalse: HWColumn(
              children: [
                HWText(
                  HWItemData(HWString('initial')),
                  style: _railStyle,
                ),
                HWText(
                  HWItemData(HWString('date')),
                  style: _railStyle,
                ),
              ],
            ),
          ),
          maxItems: 7,
          whenEmpty: HWText.fixed(''),
        ),
        // Full-width divider under the rail (C5 mock).
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
          'classes',
          crossAxisAlignment: HWCrossAxisAlignment.start,
          item: HWRow(
            spacing: 8,
            children: [
              HWSizedBox(
                width: 78,
                child: HWText(
                  HWItemData(HWString('time')),
                  style: _timeStyle,
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
              'en': 'No classes today',
              'tr': 'Bugün ders yok',
            },
            style: _nameStyle,
            textAlign: HWTextAlign.start,
          ),
        ),
        // Filler: upcoming classes after today, dimmed (kills the blank
        // card on sparse days). Pushed as (label, name) pairs.
        HWColumn.builder(
          'later',
          crossAxisAlignment: HWCrossAxisAlignment.start,
          item: HWRow(
            spacing: 8,
            children: [
              HWSizedBox(
                width: 78,
                child: HWText(
                  HWItemData(HWString('label')),
                  style: _laterStyle,
                ),
              ),
              HWText(
                HWItemData(HWString('name')),
                style: _laterNameStyle,
              ),
            ],
          ),
          maxItems: 2,
          whenEmpty: HWText.fixed(''),
        ),
      ],
    ),
  ),
)
class TodayAgenda {}
