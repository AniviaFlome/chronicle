# Changelog

## [Unreleased]

## [1.5.0] - 2026-10-02

### Added
- Dining menu source: ITU (Istanbul Technical University) — single
  "Genel" menu with lunch (11:30 - 14:00) and dinner (17:00 - 19:30),
  per-dish kcal and allergens. Pick it in Settings → Dining menu.
- Class quick-edit: long-press any class tile (calendar list,
  dashboard, classes page) to change its color, room, teacher,
  reminder or notes without opening the full editor. In the
  calendar time-grid, long-press still adjusts times, with a
  Quick edit button into the same sheet.
- Classes accept a generic "Notes" line (class code, section,
  anything) in the full editor and quick-edit; it shows on the
  class cards and in the occurrence details.
- Full-app e2e suite (`test/e2e_*_test.dart`, plain widget tests run in CI
  with the rest of `flutter test`): class surfacing on dashboard/calendar/classes,
  sheet mark-absent flow, absence quota tracking, exam-to-grades
  flow, menu cache fallback, settings and calendar-view restart
  persistence, and folder export/import round-trip.
- Linux releases now ship in three formats from the same bundle: the
  plain tarball, an AppImage, and a Flatpak bundle.
- Schedule slot editor offers customizable start-time preset chips
  (defaults: hourly 08:00-18:00). Edit them in Settings → Schedule →
  Slot start presets; tapping a chip fills the start time (auto-end
  still applies) while the fields stay for any other time.
- README install section carries the official "Get it on Obtainium"
  badge with a one-tap import link for the app.

### Changed
- Snappier data-folder sync: export scans tables and writes files
  concurrently, reuses already-loaded rows for attachments, and skips
  recopying unchanged blobs; conflict backups older than 30 days are
  pruned automatically. ITU menu dish details fetch with bounded
  concurrency instead of 40+ simultaneous connections.

### Fixed
- Calendar time-grid no longer loads classes in visible steps: the
  grid's day-range/marker/fixed-grid settings join the first-run
  gate (and the startup prewarm), so the first paint already uses
  final geometry instead of repositioning every block as each
  setting resolves.
- Focus custom-minutes field is now a chip like the presets: tapping
  it opens a minutes dialog (same 1..max validation, inline errors)
  instead of embedding a mismatched text box in the chip row.
- Xtra event tiles no longer wear an unearned football icon; they
  show a neutral event glyph (Xtra events have no type to depict).
- Grid event-block titles and time chips use regular weight; the
  semibold from the block restyle rendered badly.
- The ITU dining-menu source is named "İtü" under the Turkish locale
  ("Itu" in English).
- Focus timer ring is larger with a thicker stroke and now actually
  fills its box, so the countdown never overlaps it — including at
  200% system font sizes.
- Calendar week strip and absences grid no longer flash the
  week-start before jumping to today: they stay hidden until the
  jump lands, and only jump when today is in the shown week.
- Marked-absent classes no longer squeeze their name into a
  letter-per-line stack on narrow columns: the name stays on one
  line and the Absent marker sits below (list tiles) or leads the
  details line (grid blocks).
- Itu (formerly "ITU") menu dishes are title-cased
  ("Tutmaç Çorbası", not "TUTMAÇ ÇORBASI"), and the pointless
  single-option "Campus: Genel" picker is hidden. Days cached
  before the normalization are detected and refetched instead of
  showing ALL-CAPS until the cache expires.
- Hacettepe lunch and vegan show the real weekend window
  (12:00 - 13:30) on Saturdays and Sundays — the site publishes
  weekday hours there. Also fixed meal tabs shifting onto the
  wrong kinds when a tab is missing from the page.
- Calendar-day math (dashboard tomorrow, notification window,
  calendar export range, iCal recurrence stepping) uses
  wall-clock day shifts, so DST transitions can't skip or
  duplicate a day.
- The calendar no longer flashes a loading spinner on its first
  open after startup: the current week's providers are warmed
  post-frame so the first paint already holds data.
- Slow calendar loads show a shimmer skeleton (real headers plus
  placeholder bars in both list and grid geometry) instead of an
  empty week: content still appears all at once, independent warm
  inputs resolve concurrently to shorten the wait, and startup is
  never blocked waiting for week data.
- Custom school days on an academic year now survive a round-trip:
  saving e.g. weekend-inclusive days no longer resets to Mon–Fri.

### Removed
- Day streak displays on the Focus and Dashboard screens (and the
  now-unused streak helper, its tests and strings). Focus sessions
  are still recorded for the weekly statistics.
- The chronicle.sh launcher wrapper is gone from the Linux tarball;
  run the chronicle binary directly (it finds its bundled libraries
  itself).

## [1.4.0] - 2026-09-25

### Changed
- Absences list view shows only the per-class quota cards; the
  per-record history list (and its "No absences recorded" empty text)
  is gone — use the weeks grid or the class editor to manage records.
- The mark-absence dialog no longer asks for a theory/practical
  session kind; quotas are total-based, so new records default to it.

### Fixed
- Bilsis import no longer drops one of two overlapping classes sharing a
  grid cell: side-by-side lines are matched to their own course code, so
  both courses are imported with their own slots and details.

## [1.3.1] - 2026-09-24

### Fixed
- Absences list view shows the excused-state chips and class picker on
  top again (above the quota cards), matching the weeks-grid view.

## [1.3.0] - 2026-09-24

### Added
- Classes screen menu: "Delete all classes" bulk-deletes every class
  (with schedules and absence records) after confirmation.
- Settings → Data → "Import schedule": parses a supported course-table
  PDF (Hacettepe Bilsis Ders Programı) with pure-Dart text extraction
  (Android + Linux) and creates one class per course with weekly slots
  after a tick-to-select preview. Back-to-back rows of one course merge
  into a single block (08:40–10:30, not two one-hour slots).

### Changed
- Absences opens in the weeks-grid view by default (switch back anytime).
- Auto-sync now merges before exporting, watches the data folder, and
  imports on app resume — manual Export/Import remain as override.

### Fixed
- Absences grid no longer slides on every entry when the current week is
  already visible, and the auto-jump clamps to the scroll range so the
  latest weeks land on-screen instead of overshooting.
- Import skips single unparsable rows (e.g. from a newer app version)
  instead of aborting the whole import; the count shows in the
  import confirmation.
- Auto-sync no longer drops changes that arrive while a sync is running;
  queued work runs right after instead of waiting for the next edit.
- Auto-export no longer prunes blobs (a peer's new attachment can't be
  deleted before import); manual Export still prunes.
- Auto-import no longer uses cross-device wall-clock ordering, so clock
  skew can't permanently skip a peer export; late Syncthing files retry.
- Concurrent edits on both devices preserve the losing version under
  `conflicts/` instead of silently discarding it.
- Settings → Data now shows the last sync error and preserved-conflict
  count instead of logging to console only.
- Settings → Data: the Android file-access row sits with the folder
  picker again, so Export/Import stay adjacent instead of split apart.

## [1.2.3] - 2026-09-24

### Added
- Settings → Data shows a File access row on Android with one-tap
  "All files access" grant (the folder picker grant alone does not
  enable raw file reads on Android 11+).

### Fixed
- Import reports the underlying read error for an unreadable
  `manifest.json` (e.g. permission denied vs truncated sync) instead
  of a bare "couldn't read it".

## [1.2.2] - 2026-09-24

### Fixed
- Import distinguishes an unreadable `manifest.json` (e.g. missing
  Android file access) from a folder with no export yet, instead of
  reporting both as "no export".
- Android declares external-storage permissions so a Syncthing data
  folder is readable (broad access still needs the system "All files
  access" grant for Chronicle).
- Auto-sync no longer re-exports forever: the change watcher only
  listens to synced data tables, so export/import bookkeeping writes
  don't schedule another export. Previously every export rewrote the
  manifest within seconds, so Syncthing peers never converged on one
  manifest.

## [1.2.1] - 2026-09-23

### Fixed
- Import errors say what's wrong (folder gone vs no export yet vs
  foreign folder) instead of one blanket message.

## [1.2.0] - 2026-09-23

### Added
- Automatic data-folder sync while the app runs: changes export a few
  seconds after edits, folder updates import within ~30s and at startup.
  Toggle in Settings → Data; manual Export/Import remain as override.

### Fixed
- Attachment references are relative paths, so files survive reinstalls
  and user changes (legacy absolute rows still resolve). Sync blobs use
  readable `stem_shortid.ext` names; exports carry no absolute device
  paths. Old `uuid.ext` blobs still import.

## [1.1.0] - 2026-09-23

### Added
- File attachments for classes and academic years (PDFs, slides, program
  files). Picked via the platform picker, opened in the default app,
  synced through the data folder.
- Absence records carry an optional theory/practical tag, picked in the
  mark-absent dialog and shown in absence lists.

### Fixed
- Focus timer: dropped the "working on" picker; countdown stays inside
  the progress ring with large fonts.
- Menu: date no longer claims every day is today; Beytepe/Sıhhiye switch
  fits narrow phones; allergen chips and legend highlight match their
  shapes; day chevrons labeled correctly.
- Phone bottom bar: all 7 labels visible, single-line, no shifting; on
  Android the Absences view switch sits in the title row.
- Class file errors show a plain message; Linux release bundles sqlite.

### Changed
- Launcher icon is now a 7-day strip (was a calendar page).

## [1.0.0] - 2026-09-21

### Added
- Class schedules with weekly, A/B-week, custom-cycle and day-rotation slots.
- Calendar list and time-grid views with absence marking.
- Absence tracking with per-class quotas and a weeks-grid overview.
- Tasks with subtasks, reminders, repeats and exams with grades.
- Focus timer with custom work/break durations and streak statistics.
- Dining-hall menus (Hacettepe) with offline cache.
- Local data folder export/import for moving data between devices.
- Linux desktop bundle and Android APK builds.
